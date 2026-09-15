// cortex-debug's debug adapter speaks the DAP protocol over stdout, but its
// bundle also carries stray console.log() debug prints -- the PEmicro server
// class logs "Getting Exec" every time it resolves the server binary, and
// there are ~20 more scattered around. Inside VS Code the extension host
// captures those. Run standalone, they land in the middle of a Content-Length
// header and nvim-dap's rpc parser dies with:
//
//   Content-Length not found in headers: Getting Exec Content-Length: 176
//
// Point the whole console at stderr, which nvim-dap collects into its log and
// the REPL, leaving stdout to carry nothing but the protocol. Note that
// process.stdout.write is untouched -- that *is* the transport.
//
// Loaded via `node --require` from custom.plugins.cortex_debug so it runs
// before the adapter does.

const { Console } = require("console");

globalThis.console = new Console({ stdout: process.stderr, stderr: process.stderr });
