//------------------------------------------------------------------------------
//  project:       RISC-V (SberLab Novosibirsk State University)
//     
//  modules:       cpu_core_m 
//     
//  description:   - RISC-V processor (RV32I ISA) single-cycle uArch
//                 - processor core
//------------------------------------------------------------------------------

`include "risc-v.svh"

//******************************************************************************
//******************************************************************************
module cpu_core_m import risc_v_pkg::*;
(
    //---
    input  logic         clk,
    input  logic         rst,
    
    //--- imem interface
    output Addr_t        imem_addr,
    input  Instr_t       instr,    
    
    //--- dmem interface (TBD)
    //output Addr_t        dmem_addr,
    //output logic         dmem_we,
    //output ByteDataEna_t dmem_byte_we,
    //output Data_t        dmem_wd,
    //input  Data_t        dmem_rd,
    
    //--- additional status info (i.e. for exceptions)
    //output logic         illegal_instr
    output logic [15:0]  debug  
);

timeunit      1ns;
timeprecision 1ps;

//==============================================================================

//---
Addr_t pc;
Addr_t pc_br = '0;
logic br_taken = 1'b0;

//---
RegAddr_t rs1;
RegAddr_t rs2;
RegAddr_t rd;
logic we3;
Data_t imm;
logic b_sel;

//---
Data_t rf_rd1;
Data_t rf_rd2;
Data_t rf_wd3;
logic  rf_we3;

//---
Data_t    alu_in_a;
Data_t    alu_in_b;
Data_t    alu_out;


`ifdef RF_DEBUG_OUT
    Data_t dbg_reg;  
`endif

//==============================================================================

//--------------------------------------------------------------------------
`ifdef RF_DEBUG_OUT
    assign debug = dbg_reg[31:16];  
`else
    assign debug[15:1] = alu_out[14:0];
    assign debug[0] = ^alu_out;
`endif


assign imem_addr = pc;

assign alu_in_a = rf_rd1;
assign alu_in_b = b_sel ? imm : rf_rd2;

assign rf_we3 = we3 & !rst;
assign rf_wd3 = alu_out;

//==============================================================================

//--------------------------------------------------------------------------
(* keep_hierarchy = `PRJ_KEEP_HIEARARCHY *)
program_counter
#(
    .WIDTH         ( $bits(Addr_t) ),
    .PC_START_ADDR ( PC_START_ADDR)
)
pc_inst
(
    .clk      ( clk ),
    .rst      ( rst ),
    .br_taken ( br_taken ),
    .pc_br    ( pc_br    ),
    .pc       ( pc       )
);

//--------------------------------------------------------------------------
(* keep_hierarchy = `PRJ_KEEP_HIEARARCHY *)
id id_inst
(
    .instr ( instr ),
    .rs1   ( rs1   ),
    .rs2   ( rs2   ),
    .rd    ( rd    ),
    .we3   ( we3   ),
    .imm   ( imm   ),
    .b_sel ( b_sel )
);

//--------------------------------------------------------------------------
(* keep_hierarchy = `PRJ_KEEP_HIEARARCHY *)
register_file
#(
    .XLEN ( XLEN )
)
rf_inst
(
    .clk  ( clk    ),

    .rsi1 ( rs1    ),
    .rs1  ( rf_rd1 ),

    .rsi2 ( rs2    ),
    .rs2  ( rf_rd2 ),

    .rdi  ( rd     ),
    .rd   ( rf_wd3 ),

    .we   ( rf_we3 )
    `ifdef RF_DEBUG_OUT
      ,
      .dbg_reg (dbg_reg) 
    `endif
);

//--------------------------------------------------------------------------
(* keep_hierarchy = `PRJ_KEEP_HIEARARCHY *)
alu_m
#(
    .XLEN ( XLEN )
)
alu_inst
(
    .sel ( ADD  ),   
    .a   ( alu_in_a ),
    .b   ( alu_in_b ),
    .res ( alu_out  )
);

endmodule : cpu_core_m

