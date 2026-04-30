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
    
    //--- dmem interface 
    output Addr_t        dmem_addr,
    output ByteDataEna_t dmem_byte_we,
    output Data_t        dmem_data_in,
    input  Data_t        dmem_data_out

    //--- additional status info (i.e. for exceptions)
    //output logic         illegal_instr
);

//timeunit      1ns;
//timeprecision 1ps;

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

//--- IG
Imm_input_t Ig_Imm_input;


//--- DMEM
logic       dmem_we;
logic [2:0] dmem_funct3;
logic [1:0] dmem_byte_off;
Data_t      dmem_rdata_out;
Data_t      dmem_wdata_in;

//==============================================================================
assign imem_addr = pc;

assign dmem_addr   = rf_rd1 + imm;  // TODO: +imm
assign dmem_we     = id_output_controls.dmem_we;
assign dmem_funct3 = instr[14:12];
assign dmem_byte_off = dmem_addr[1:0];
assign dmem_wdata_in  = rf_rd2;

assign alu_in_a = id_output_controls.a_sel? rf_rd1 : pc;
assign alu_in_b = id_output_controls.b_sel? rf_rd2 : imm;

assign shift_shamt = id_output_controls.b_sel? rf_rd2[4:0] : instr[24:20];

assign rf_we3 = id_output_controls.reg_wr & !rst;

//source for write to RF: 0: PC+4, 1: ALU out, 2: shifter out, 3: dmem out
always_comb begin
    case (id_output_controls.wb_sel)
        WB_PC4_OUT     : rf_wd3 = pc+4;
        WB_ALU_OUT     : rf_wd3 = alu_out;
        WB_SHIFTER_OUT : rf_wd3 = shifter_out;
        WB_DMEM_OUT    : rf_wd3 = dmem_rdata_out;
        default: rf_wd3 = 'X;
    endcase
end

assign Ig_Imm_input = instr[31:7];

assign id_instr.funct7 = instr[30];
assign id_instr.funct3 = instr[14:12];
assign id_instr.opcode = instr[6:2];
assign rs1 = instr[19:15];
assign rs2 = instr[24:20];
assign rd = instr[11:7];
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
    .Imm_in (Ig_Imm_input),
    .imm_type (id_output_controls.imm_type),
    .imm (imm)
);

//--------------------- DMEM ------------------------
risc_v_dmem_wr_port_m dmem_wr_port_inst
(
    // -- in
    .dmem_we (dmem_we),
    .funct3 (dmem_funct3),
    .byte_addr (dmem_byte_off),
    .data_in (dmem_wdata_in),
    // -- out
    .we (dmem_byte_we),
    .data_out (dmem_data_in)
);

risc_v_dmem_rd_port_m dmem_rd_port_inst
(
    // -- in
    .funct3 (dmem_funct3),
    .byte_addr (dmem_byte_off),
    .data_in(dmem_data_out),
    // -- out
    .data_out(dmem_rdata_out)
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

