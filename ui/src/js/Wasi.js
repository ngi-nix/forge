// Runs the WASI programs of the browser runtime.
// Elm sends `runWasi`, `addWasiFiles` and `removeWasiFile`,
// and receives the program output and the files with `onWasiEvent`.

const timeoutMilliseconds = 10000;
const outputLimit = 1024 * 1024;

// Split a command line into words like `shlex.split` of Python:
// single quotes, double quotes and backslashes, but no expansions.
export const splitArgs = (line) => {
  const isSpace = (c) => " \t\r\n".includes(c);
  const words = [];
  let word = null;
  let i = 0;
  while (i < line.length) {
    const c = line[i];
    if (isSpace(c)) {
      if (word !== null) {
        words.push(word);
        word = null;
      }
      i += 1;
    } else if (c === "'") {
      const end = line.indexOf("'", i + 1);
      if (end < 0) {
        throw new Error("No closing quotation");
      }
      word = (word ?? "") + line.slice(i + 1, end);
      i = end + 1;
    } else if (c === "\"") {
      word = word ?? "";
      i += 1;
      for (;;) {
        if (i >= line.length) {
          throw new Error("No closing quotation");
        }
        const d = line[i];
        if (d === "\"") {
          i += 1;
          break;
        } else if (d === "\\" && i + 1 < line.length && "\\\"".includes(line[i + 1])) {
          word += line[i + 1];
          i += 2;
        } else {
          word += d;
          i += 1;
        }
      }
    } else if (c === "\\") {
      if (i + 1 >= line.length) {
        throw new Error("No escaped character");
      }
      word = (word ?? "") + line[i + 1];
      i += 2;
    } else {
      word = (word ?? "") + c;
      i += 1;
    }
  }
  if (word !== null) {
    words.push(word);
  }
  return words;
};

// Compile each WASI program only one time.
const modules = new Map();
const compile = (url) => {
  if (!modules.has(url)) {
    const module = fetch(url)
      .then((response) => {
        if (!response.ok) {
          throw new Error(`HTTP ${response.status}`);
        }
        return response.arrayBuffer();
      })
      .then((bytes) => WebAssembly.compile(bytes));
    module.catch(() => modules.delete(url));
    modules.set(url, module);
  }
  return modules.get(url);
};

const fetchBytes = async (url) => {
  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(`HTTP ${response.status}`);
  }
  return new Uint8Array(await response.arrayBuffer());
};

// The files of the working directory of one app.
// Elm sends `workdir = { app, examples: [{ name, url }], reset }` with each request.
// If `reset` is true or the app changes, the files are the examples again.
const initWorkdir = (app) => {
  let store = { app: null, files: new Map() };
  let queue = Promise.resolve();

  const revoke = () => {
    for (const { url } of store.files.values()) {
      URL.revokeObjectURL(url);
    }
  };

  // Replace the files with `[{ name, data }]` and send them to Elm.
  const set = (files) => {
    revoke();
    store.files = new Map(
      files.map(({ name, data }) => [name, { data, url: URL.createObjectURL(new Blob([data])) }]),
    );
    app.ports.onWasiEvent.send({
      kind: "files",
      app: store.app,
      files: [...store.files].map(([name, { data, url }]) => ({ name, size: data.byteLength, url })),
    });
  };

  const load = async ({ app: appName, examples, reset }) => {
    if (reset || store.app !== appName) {
      revoke();
      store = { app: appName, files: new Map() };
      const files = await Promise.all(
        examples.map(async ({ name, url }) => ({ name, data: await fetchBytes(new URL(url, document.baseURI).href) })),
      );
      store.files = new Map(files.map(({ name, data }) => [name, { data, url: "" }]));
    }
    return [...store.files].map(([name, { data }]) => ({ name, data }));
  };

  // Run the operations one after the other, so that they do not mix.
  const enqueue = (operation) => {
    const result = queue.then(operation);
    queue = result.catch(() => {});
    return result;
  };

  return {
    files: (workdir) => enqueue(() => load(workdir)),
    set: (files) => enqueue(() => set(files)),
    update: (workdir, change) => enqueue(async () => set(await change(await load(workdir)))),
  };
};

export const initWasi = (app) => {
  let running = null;
  const workdir = initWorkdir(app);

  const sendError = (text) => app.ports.onWasiEvent.send({ kind: "error", text });

  app.ports.addWasiFiles.subscribe(({ workdir: dir, files }) =>
    workdir
      .update(dir, async (current) => {
        const added = await Promise.all(
          files.map(async (file) => ({ name: file.name, data: new Uint8Array(await file.arrayBuffer()) })),
        );
        const names = new Set(added.map(({ name }) => name));
        return [...current.filter(({ name }) => !names.has(name)), ...added];
      })
      .catch((error) => sendError(`Cannot add the files: ${error.message}`))
  );

  app.ports.removeWasiFile.subscribe(({ workdir: dir, name }) =>
    workdir
      .update(dir, async (current) => current.filter((file) => file.name !== name))
      .catch((error) => sendError(`Cannot remove the file: ${error.message}`))
  );

  const stop = () => {
    if (running !== null) {
      running.worker?.terminate();
      clearTimeout(running.timer);
      running = null;
    }
  };

  const fail = (text) => {
    stop();
    app.ports.onWasiEvent.send({ kind: "error", text });
  };

  app.ports.runWasi.subscribe(async ({ url, program, args, stdin, workdir: dir }) => {
    stop();
    const run = {};
    running = run;

    let argv;
    try {
      argv = [program, ...splitArgs(args)];
    } catch (error) {
      fail(`Cannot read the arguments: ${error.message}`);
      return;
    }

    let module;
    try {
      module = await compile(new URL(url, document.baseURI).href);
    } catch (error) {
      if (running === run) {
        fail(`Cannot load ${url}: ${error.message}`);
      }
      return;
    }
    let files;
    try {
      files = await workdir.files(dir);
    } catch (error) {
      if (running === run) {
        fail(`Cannot load the files: ${error.message}`);
      }
      return;
    }
    if (running !== run) {
      return;
    }

    let outputSize = 0;
    run.worker = new Worker(new URL("js/WasiWorker.js", document.baseURI));
    run.worker.onmessage = ({ data }) => {
      if (running !== run) {
        return;
      }
      outputSize += data.text?.length ?? 0;
      if (outputSize > outputLimit) {
        fail(`The program wrote more than ${outputLimit} characters.`);
        return;
      }
      if (data.kind === "workdir") {
        workdir.set(data.files);
        return;
      }
      app.ports.onWasiEvent.send(data);
      if (data.kind === "exit" || data.kind === "error") {
        stop();
      }
    };
    run.worker.onerror = (event) => {
      if (running === run) {
        fail(event.message);
      }
    };
    run.timer = setTimeout(() => {
      if (running === run) {
        fail(`The program did not stop in ${timeoutMilliseconds / 1000} seconds.`);
      }
    }, timeoutMilliseconds);
    run.worker.postMessage({ module, args: argv, stdin, files });
  });

  app.ports.stopWasi.subscribe(() => {
    if (running !== null) {
      fail("Stopped.");
    }
  });
};
