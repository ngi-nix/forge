// Runs the WASI programs of the browser runtime.
// Elm sends `runWasi` and receives the program output with `onWasiEvent`.

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

export const initWasi = (app) => {
  let running = null;

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

  app.ports.runWasi.subscribe(async ({ url, program, args, stdin }) => {
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
    run.worker.postMessage({ module, args: argv, stdin });
  });

  app.ports.stopWasi.subscribe(() => {
    if (running !== null) {
      fail("Stopped.");
    }
  });
};
