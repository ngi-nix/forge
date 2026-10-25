// Runs a WASI program in a Web Worker,
// so that the main thread can stop it with `Worker.terminate()`.
import { ConsoleStdout, File, OpenFile, WASI, wasi } from "@bjorn3/browser_wasi_shim";

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

self.onmessage = async ({ data: { module, args, stdin } }) => {
  const stdinFile = new File(new TextEncoder().encode(stdin), { readonly: true });
  const wasiRuntime = new WASI(args, [], [new OpenFile(stdinFile), output("stdout"), output("stderr")]);
  try {
    const instance = await WebAssembly.instantiate(module, {
      wasi_snapshot_preview1: wasiRuntime.wasiImport,
    });
    self.postMessage({ kind: "exit", code: wasiRuntime.start(instance) });
  } catch (error) {
    self.postMessage({ kind: "error", text: String(error) });
  }
};
