//------------------------------------------------------------------------------
//  project:       RISC-V (SberLab Novosibirsk State University)
//
//  modules:       cpu_system (core and uncore)
//
//  description:   - RISC-V processor (RV32I ISA) single-cycle uArch
//                 - core and uncore parts
//                 - hardware platform (development board) for standalone RISC-V processor test
//------------------------------------------------------------------------------

`include "risc-v.svh"
`include "imem_init_path.svh"  
//******************************************************************************
//******************************************************************************
module cpu_system import risc_v_pkg::*;

(
    //--------------------------------------------------------------------------
    input  logic  ref_clk,

    //--------------------------------------------------------------------------
    `ifdef CFG_NAME_BASYS_3
        output logic [`LED_NUM-1:0]  led
    `endif

    //--------------------------------------------------------------------------
    `ifdef SYS_DEBUG_OUT
        ,
        output logic [3:0] dbg_insn_addr,
        output logic [6:0] dbg_insn_opcode,
        output logic [2:0] dbg_insn_funct3,
        output logic [2:0] dbg_clk_vec,
        output logic       dbg_pll_locked
    `endif
);

//timeunit      1ns;
//timeprecision 1ps;

//==============================================================================
`ifdef SIMULATOR
str_t asm_instr;
assign asm_instr = disasm(instr);
`endif

//==============================================================================

logic cpu_clk;
logic rst;
logic pll_locked;

logic         imem_clk;
Addr_t        imem_addr;
Instr_t       instr;

logic clk2;
logic clk3;

//==============================================================================
`ifdef SYS_DEBUG_OUT
    logic [15:0] dbg_counter;
    always_ff @(posedge cpu_clk) begin
        dbg_counter <= dbg_counter + 1;
    end
    
    logic [3:0] reg_insn_addr;
    logic [6:0] reg_insn_opcode;
    logic [2:0] reg_insn_funct3;

    always_ff @(posedge cpu_clk) begin
        reg_insn_addr <= imem_addr[5:2];
        //dbg_insn_addr <= reg_insn_addr;
    end    
    always_ff @(posedge cpu_clk) begin
        reg_insn_opcode <= instr[6:0];
        //dbg_insn_opcode <= reg_insn_opcode;
    end    
    always_ff @(posedge cpu_clk) begin
        reg_insn_funct3 <= instr[14:12];
        //dbg_insn_funct3 <= reg_insn_funct3;
    end    

    assign dbg_insn_addr = reg_insn_addr;
    assign dbg_insn_opcode = reg_insn_opcode;
    assign dbg_insn_funct3 = reg_insn_funct3;

    assign dbg_clk_vec    = { clk3, clk2, cpu_clk };
    assign dbg_pll_locked = pll_locked;
`endif

//==============================================================================


//---
`define USE_PLL
`ifdef USE_PLL
    //(* keep_hierarchy = `PRJ_KEEP_HIEARARCHY  *)
    pll pll_inst
    (
        .clk_in    ( ref_clk    ),
        .clk_out1  ( cpu_clk    ),
        .clk_out2  ( clk2       ),
        .clk_out3  ( clk3       ),
        .locked    ( pll_locked )
    );

    assign imem_clk = cpu_clk;
`else
    assign cpu_clk  = ref_clk;
    assign imem_clk = cpu_clk;
    assign pll_locked = 1'b1;
`endif // USE_PLL


//--- reset (related to clk)
(* keep_hierarchy = `PRJ_KEEP_HIEARARCHY *)
rst_m rst_inst
(
    .clk     ( cpu_clk    ),
    .ena     ( pll_locked ),
    .rst     ( rst        )
);

//---    risc-v cpu core
(* keep_hierarchy = `PRJ_KEEP_HIEARARCHY *)
cpu_core_m cpu
(
    //---
    .clk           ( cpu_clk       ),
    .rst           ( rst           ),

    //--- imem interface
    .imem_addr     ( imem_addr     ),
    .instr         ( instr         ),

    //--- dmem interface
    // TBD
    
    //--- debug output
    .debug         ( led           )
);

//---    instruction memory
(* keep_hierarchy = `PRJ_KEEP_HIEARARCHY *)
imem_sim_m 
        #(
            .INIT_FILE  (`IMEM_INIT_FILE),
            .ADDR_WIDTH ( IMEM_ADDR_WIDTH )
        )
imem        
(
    .addr  ( imem_addr[0 +: IMEM_ADDR_WIDTH] ), // in old implementation 'imem_addr[2 +: IMEM_ADDR_WIDTH]'
    .instr ( instr )
);

endmodule : cpu_system

