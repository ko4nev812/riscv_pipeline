# RISC-V I32 Core - SystemVerilog Implementation

## Overview
A synthesizable 32-bit RISC-V processor core implementing the **RV32I Base Integer Instruction Set**, designed for Xilinx Artix-7 FPGAs using SystemVerilog and Vivado design tools.

## Project Status
**Development Phase** 
The core is currently in development. 
Future improvements and extensions are planned.

## Architecture
- 32-bit RISC-V
- Little-endian byte ordering

## Requirements
### Software
- **Xilinx Vivado** 2019.2 or later
- **SystemVerilog** support enabled

## Vivado Usage

Generate the Vivado project from the repository root:

```tcl
cd <repo-root>
source xbld.tcl
```

The script creates the project in `cfg/` and generates config headers such as `cfg/mem_init_path.svh`.

Run behavioral simulation:

```tcl
launch_simulation
run all
```

Run synthesis:

```tcl
set_property top cpu_system [get_filesets sources_1]
update_compile_order -fileset sources_1
launch_runs synth_1 -jobs 4
wait_on_run synth_1
get_property STATUS [get_runs synth_1]
```

## Simulation Notes
- SHA3 DPI TraceLogger flow: see `README_SHA3_DPI.md`

### Hardware
- **FPGA**: Xilinx Artix-7
