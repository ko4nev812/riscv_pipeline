# SHA3 DPI trace

This branch adds an optional simulation-only SHA3-256 column for the TraceLogger DMEM trace.

## Main entrypoint

Use the normal project script:


cd <repo-root>
source xbld.tcl


`xbld.tcl` now generates two config headers in `cfg/`:

- `mem_init_path.svh` - existing generated memory init config;
- `trace_config.svh` - generated TraceLogger/SHA3 config.

## Generated trace config

After `source xbld.tcl`, open:

/rv-nsu/cfg/trace_config.svh


Typical generated content:

`define TRACE_LOGGER_ENA
`define TRACE_TEST_DIR "/rv-nsu/prg/uBench/hex"
`define TRACE_TEST_LST "ub.lst"
`define TRACE_SHA3_DPI_ENA

To disable only SHA3 while keeping the TraceLogger CSV flow:

//`define TRACE_SHA3_DPI_ENA

To disable the TraceLogger runner:

//`define TRACE_LOGGER_ENA

If you run `source xbld.tcl` again, `trace_config.svh` is regenerated. For a permanent default, edit `trace_logger_ena` or `trace_sha3_dpi_ena` near the top of `xbld.tcl`.

## Running simulation

The test directory must contain:

- `ub.lst` - list of hex tests;
- `*.hex` - tests listed in `ub.lst`;
- `res/` - output directory for CSV files.

`xbld.tcl` creates `prg/uBench/hex/res` automatically, but it does not generate missing hex files.

In Vivado Tcl Console:

cd <repo-root>
source xbld.tcl
launch_simulation
run all

With SHA3 enabled, XSim should print:

=== SHA3 DPI self-test PASS

Each TraceLogger CSV gets a final column:

dmem_sha3

Repeated hashes are normal while DMEM does not change. Store tests such as `sw_test` should change `dmem_sha3` after a memory write takes effect.

## OpenSSL discovery

`sha3_dpi.cpp` loads OpenSSL `libcrypto` at simulation runtime. On Windows it searches common DLL names through `PATH`; on Linux/macOS it uses the platform dynamic loader search path.

If the library is not found, set an explicit path before launching Vivado:

$env:RV_NSU_LIBCRYPTO = "C:\path\to\libcrypto-3-x64.dll"

or in Tcl:

set ::env(RV_NSU_LIBCRYPTO) {C:/path/to/libcrypto-3-x64.dll}

This variable points only to OpenSSL itself. It is not used to enable TraceLogger/SHA3 macros.


## Synthesis

The SHA3 DPI code is simulation-only:

- `sha3_dpi.cpp` is added to `sim_1`, not to `sources_1`;
- `sha3_dpi.svh` is included only under `TRACE_SHA3_DPI_ENA`;
- synthesis uses `cpu_system` and should not see DPI-C functions.
