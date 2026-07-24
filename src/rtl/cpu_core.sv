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

ISB_fetch_t isb_fetch;
ISB_decode_t isb_decode;
ISB_execute_t isb_execute;
ISB_memory_t isb_memory;

// fetch
logic jf_exe_E;
//logic jf_id_D;
Data_t alu_out_E;
//Data_t imm_pc_D;

// reg file
RegAddr_t rf_rs1;
RegAddr_t rf_rs2;
Data_t rf_rd1;
Data_t rf_rd2;

Data_t rf_wd3;
logic  rf_we3;
RegAddr_t rf_rd;


HDU_input_t  hdu_in;
HDU_output_t hdu_out;

Dmem_memory_stage_input_t dmem_input;

//--------------------- REGISTER FILE ---------------------------
(* keep_hierarchy = `PRJ_KEEP_HIEARARCHY *)
register_fil_m
#(
    .XLEN ( XLEN )
)
rf_inst
(
    .clk  ( clk    ),

    .rsi1 ( rf_rs1    ),
    .rs1  ( rf_rd1 ),

    .rsi2 ( rf_rs2    ),
    .rs2  ( rf_rd2 ),

    .rdi  ( rf_rd     ),
    .rd   ( rf_wd3 ),

    .we   ( rf_we3 )
);

// ============ INSTRUCTION FETCH =============
fetch_stage fetch_s_inst(
    .isb_fetch( isb_fetch ),
    .isb_fetch_stall( hdu_out.if_id_stall ),
    .isb_fetch_flush( hdu_out.if_id_flush ),

    .jf_exe( jf_exe_E ),
    .alu_out( alu_out_E ),

    .clk( clk ),
    .rst( rst ),
    .stall_pc( hdu_out.stall_pc ),

    .imem_addr( imem_addr ),
    .imem_instr( instr )
);
// ============ INSTRUCTION DECODE =============
decode_stage decode_s_inst(
    .isb_decode( isb_decode ),
    .isb_decode_stall( hdu_out.id_ex_stall ),
    .isb_decode_flush( hdu_out.id_ex_flush ),
    
    .isb_fetch( isb_fetch ),

    .rf_rs1( rf_rs1 ),
    .rf_rs2( rf_rs2 ),
    .rf_rd1( rf_rd1 ),
    .rf_rd2( rf_rd2 ),

    .clk( clk ),
    .rst( rst )
);

// ============ EXECUTE =============
execute_stage execute_s_inst(
    .isb_execute( isb_execute ),
    .isb_decode( isb_decode ),

    .dmem_input(dmem_input),
    
    .jf_exe( jf_exe_E ),
    .alures( alu_out_E ),

    .clk( clk ),
    .rst( rst )
);
// ============ MEMORY =============
memory_stage memory_s_inst(
    .isb_memory( isb_memory ),
    .isb_execute( isb_execute ),
    .dmem_input(dmem_input),

    .dmem_addr( dmem_addr ),
    .dmem_byte_we( dmem_byte_we ),
    .dmem_data_in( dmem_data_in ),
    .dmem_data_out( dmem_data_out ),

    .clk( clk ),
    .rst( rst )
);

// ============ WRITEBACK =============
writeback_stage writeback_s_inst(
    .isb_memory( isb_memory ),

    .rf_wd3( rf_wd3 ),
    .rf_we3( rf_we3 ),
    .rf_rd( rf_rd )
);


// ============== HDU ==================
always_comb begin
    hdu_in.jf_exe_D = decode_s_inst.jf_exe;
    hdu_in.rf_rs1_D = decode_s_inst.rf_rs1;
    hdu_in.rf_rs2_D = decode_s_inst.rf_rs2;
    hdu_in.opcode_D = decode_s_inst.opcode;
    hdu_in.jf_exe_E = execute_s_inst.jf_exe;
    hdu_in.rf_rd_E = execute_s_inst.rd;
    hdu_in.rf_we_E = execute_s_inst.reg_wr;
    hdu_in.rf_rd_M = memory_s_inst.rd;
    hdu_in.rf_we_M = memory_s_inst.reg_wr;
    hdu_in.rf_rd_W = writeback_s_inst.rf_rd;
    hdu_in.rf_we_W = writeback_s_inst.rf_we3;

end


hazard_detection_unit hdu_inst (
    .hdu_in( hdu_in ),
    .hdu_out( hdu_out )
);



endmodule : cpu_core_m

