# SHA3 DPI trace

This branch adds an optional simulation-only SHA3-256 trace column for DMEM.

## Required inputs

By default, TraceLogger currently reads tests from the existing hardcoded project path:

```text
C:/Users/User/10-RV-NSU/prj-main/rv-nsu/prg/uBench/hex
```

That directory must contain:

- `ub.lst` - list of hex tests to run;
- `*.hex` - test images listed in `ub.lst`;
- `res/` - output directory for CSV files.

Create the result directory if needed:

```powershell
New-Item -ItemType Directory -Force C:\Users\User\10-RV-NSU\prj-main\rv-nsu\prg\uBench\hex\res
```

If the repository is cloned elsewhere, update `TEST_DIR` in `src/sim/trace_logger.svh` locally

## Enable SHA3 trace

In Vivado Tcl Console or Vivado batch Tcl, set both flags before `source xbld.tcl`:

```tcl
set ::env(RV_NSU_TRACE_LOGGER) 1
set ::env(RV_NSU_TRACE_SHA3_DPI) 1
cd <repo-root>
source xbld.tcl
launch_simulation
run all
```

For SHA3 self-test only, set just:

```tcl
set ::env(RV_NSU_TRACE_SHA3_DPI) 1
```

With SHA3 enabled, XSim should print:

```text
=== SHA3 DPI self-test PASS
```

## OpenSSL discovery

`sha3_dpi.cpp` tries common `libcrypto` names at runtime. On Windows it searches through `PATH`.
If the DLL is not found, set an explicit path before launching Vivado:

```powershell
$env:RV_NSU_LIBCRYPTO = "C:\path\to\libcrypto-3-x64.dll"
```

Or in Vivado Tcl:

```tcl
set ::env(RV_NSU_LIBCRYPTO) {C:/path/to/libcrypto-3-x64.dll}
```

No OpenSSL library is committed to the repository.

## CSV output

When both `RV_NSU_TRACE_LOGGER=1` and `RV_NSU_TRACE_SHA3_DPI=1` are set, each CSV row gets a final column:

```text
dmem_sha3
```

The hash covers the full DMEM array visible in simulation:

Repeated hashes are normal while DMEM does not change. Store tests such as `sw_test` should show a different `dmem_sha3` after a memory write takes effect.

## Synthesis

Do not set the SHA3/TraceLogger environment variables for the normal synthesis flow.
`sha3_dpi.cpp` is added only to `sim_1`, and `sha3_dpi.svh` is included only under `TRACE_SHA3_DPI_ENA`, so synthesis should not see the DPI code.