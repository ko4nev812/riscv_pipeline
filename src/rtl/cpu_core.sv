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

//--- Shifter
Data_t shifter_out;
shift_shamt_t shift_shamt;

//--- ALU
Data_t    alu_in_a;
Data_t    alu_in_b;
Data_t    alu_out;

//--- ID
Id_instr_t id_instr;
Id_controls_in_t id_controls_in;
Id_controls_out_t id_output_controls;
logic id_illegal;
    
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

assign alu_in_a = id_output_controls.a_sel? rf_rd1 : pc;
assign alu_in_b = id_output_controls.b_sel? rf_rd2 : imm;

assign shift_shamt = id_output_controls.b_sel? rf_rd2[4:0] : instr[24:20];

assign rf_we3 = id_output_controls.reg_wr & !rst;
assign rf_wd3 = alu_out;

assign id_instr.funct7 = instr[30];
assign id_instr.funct3 = instr[14:12];
assign id_instr.opcode = instr[6:2];

//==============================================================================

//--------------------- PROGRAM COUNTER -----------------------------------------------
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
    .br_taken ( ~id_output_controls.pc_sel ),
    .pc_br    ( alu_out  ),
    .pc       ( pc       )
);

//--------------------- INSTRUCTION DECODER -------------------------------------------
(* keep_hierarchy = `PRJ_KEEP_HIEARARCHY *)
id id_inst
(
    .instr ( id_instr ),
    .input_controls ( id_controls_in ),
    .output_controls (id_output_controls),
    .illegal (id_illegal)
);
//--------------------- REGISTER FILE -------------------------------------------------
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

//--------------------- ALU -----------------------------------------------------
(* keep_hierarchy = `PRJ_KEEP_HIEARARCHY *)
alu_m
#(
    .XLEN ( XLEN )
)
alu_inst
(
    .sel ( id_output_controls.alu_sel  ),   
    .a   ( alu_in_a ),
    .b   ( alu_in_b ),
    .res ( alu_out  )
);

//--------------------- Shifter ------------------------
risc_v_shifter_m
#(
    .XLEN ( XLEN )
)
shifter_inst
(
   .data (rf_rd1),
   .shamt (shift_shamt),
   .sel(id_output_controls.sh_sel),
   .res (shifter_out)
);

//--------------------- IMM_GEN ------------------------
imm_gen imm_gen_inst
(
    .instr (instr),
    .imm_type (id_output_controls.imm_type),
    .imm (imm)
);

//--------------------- Branch unit --------------------
branch_unit_m
#(
    .XLEN ( XLEN )
)
branch_unit_inst
(
    .rd1(rf_rd1),
    .rd2(rf_rd2),
    .br_un(id_output_controls.br_un),
    .br_eq(id_controls_in.br_eq),
    .br_lt(id_controls_in.br_lt)
);

endmodule : cpu_core_m

