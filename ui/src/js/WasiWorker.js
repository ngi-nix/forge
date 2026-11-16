// Runs a WASI program in a Web Worker,
// so that the main thread can stop it with `Worker.terminate()`.
import {
  ConsoleStdout,
  Directory,
  File,
  OpenDirectory,
  OpenFile,
  PreopenDirectory,
  WASI,
  wasi,
} from "@bjorn3/browser_wasi_shim";

// The shim returns `ENOTSUP` for `path_readlink`, thus `typst` cannot open its input file.
// The files in memory are not symbolic links, thus return `EINVAL` as POSIX does.
// Change the prototype, because the shim makes `OpenDirectory` objects for subdirectories.
OpenDirectory.prototype.path_readlink = function(path) {
  const { ret } = this.path_filestat_get(0, path);
  return { ret: ret === wasi.ERRNO_SUCCESS ? wasi.ERRNO_INVAL : ret, data: null };
};

// The shim returns `ENOTSUP` when a program sets the times of a file, thus `bzip2` stops.
// The files in memory have no times, thus ignore the change.
OpenFile.prototype.fd_filestat_set_times = function() {
  return wasi.ERRNO_SUCCESS;
};
OpenDirectory.prototype.path_filestat_set_times = function(flags, path) {
  return this.path_filestat_get(flags, path).ret;
};

// The output pane is not a terminal.
// This prevents programs from writing terminal escape codes.
class OutputPipe extends ConsoleStdout {
  fd_fdstat_get() {
    const result = super.fd_fdstat_get();
    result.fdstat.fs_filetype = wasi.FILETYPE_UNKNOWN;
    return result;
  }

  fd_filestat_get() {
    const result = super.fd_filestat_get();
    result.filestat.filetype = wasi.FILETYPE_UNKNOWN;
    return result;
  }
}

const output = (kind) => {
  const decoder = new TextDecoder();
  return new OutputPipe((data) => self.postMessage({ kind, text: decoder.decode(data, { stream: true }) }));
};

// Make the tree of the working directory from `[{ name, data }]`.
// The names can contain `/`.
const makeTree = (files) => {
  const root = new Map();
  for (const { name, data } of files) {
    const parts = name.split("/");
    let dir = root;
    for (const part of parts.slice(0, -1)) {
      if (!(dir.get(part) instanceof Map)) {
        dir.set(part, new Map());
      }
      dir = dir.get(part);
    }
    dir.set(parts.at(-1), data);
  }
  // Make the directories from the bottom up, so that each directory knows its parent.
  const make = (entries) =>
    new Map(
      [...entries].map(([name, entry]) => [name, entry instanceof Map ? new Directory(make(entry)) : new File(entry)]),
    );
  return make(root);
};

// Read the files of the working directory as `[{ name, data }]`.
const readTree = (dir, prefix = "") =>
  [...dir.entries()].flatMap(([name, entry]) =>
    entry instanceof Directory
      ? readTree(entry.contents, `${prefix}${name}/`)
      : [{ name: prefix + name, data: entry.data }]
  );

self.onmessage = async ({ data: { module, args, stdin, files } }) => {
  const stdinFile = new File(new TextEncoder().encode(stdin), { readonly: true });
  const workdir = new PreopenDirectory(".", makeTree(files));
  const wasiRuntime = new WASI(args, [], [new OpenFile(stdinFile), output("stdout"), output("stderr"), workdir]);
  let event;
  try {
    const instance = await WebAssembly.instantiate(module, {
      wasi_snapshot_preview1: wasiRuntime.wasiImport,
    });
    event = { kind: "exit", code: wasiRuntime.start(instance) };
  } catch (error) {
    event = { kind: "error", text: String(error) };
  }
  // Send the files before the end of the run.
  self.postMessage({ kind: "workdir", files: readTree(workdir.dir.contents) });
  self.postMessage(event);
};
