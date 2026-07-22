`include "risc-v.svh"

module decode_stage import risc_v_pkg::*;
(
    output ISB_decode_t isb_decode,
    input logic isb_decode_stall,
    input logic isb_decode_flush,

    input ISB_fetch_t isb_fetch,


    // --- reg file interface
    output RegAddr_t rf_rs1,
    output RegAddr_t rf_rs2,
    input Data_t rf_rd1,
    input Data_t rf_rd2,

    // branch and jal instruction
    output Addr_t imm_pc,
    output logic jf_id,

    input logic clk,
    input logic rst
);

Instr_t instr;

Imm_input_t Ig_Imm_input;
Data_t imm;

Id_instr_t id_instr;
Id_controls_in_t id_controls_in;
Id_controls_out_t id_output_controls;
logic id_illegal;

assign instr = isb_fetch.instr;

assign Ig_Imm_input = instr[31:7];
assign rf_rs1 = instr[19:15];
assign rf_rs2 = instr[24:20];


// ====== INSTRUCTION DECODER ======
assign id_instr.funct7 = instr[30];
assign id_instr.funct3 = instr[14:12];
assign id_instr.opcode = instr[6:2];
assign id_instr.ones   = instr[1:0];

(* keep_hierarchy = `PRJ_KEEP_HIEARARCHY *)
id_m id_inst
(
    .instr ( id_instr ),
    .input_controls ( id_controls_in ),
    .output_controls (id_output_controls),
    .illegal (id_illegal)
);


// ====== IMM_GEN ======
imm_gen_m imm_gen_inst
(
    .Imm_in (Ig_Imm_input),
    .imm_type (id_output_controls.imm_type),
    .imm (imm)
);
assign isb_decode.imm = imm;
assign jf_id = imm + isb_fetch.pc;




// ====== Branch unit ======
branch_unit_m branch_unit_inst
(
    .rd1(rf_rd1),
    .rd2(rf_rd2),
    .br_un(id_output_controls.br_un),
    .br_eq(id_controls_in.br_eq),
    .br_lt(id_controls_in.br_lt)
);


logic jf_exe;
assign jf_exe = id_output_controls.jf_exe;
logic opcode;
assign opcode = id_instr.opcode;


always_ff @(posedge clk) begin
    if(!isb_decode_stall) begin
        isb_decode.rf_rd1 <= rf_rd1;
        isb_decode.rf_rd2 <= rf_rd2;
        isb_decode.imm <= imm;
        isb_decode.pc <= isb_fetch.pc;
        isb_decode.rd <= instr[11:7];
        isb_decode.rs1 <= rf_rs1;
        isb_decode.rs2 <= rf_rs2;

        isb_decode.a_sel <= id_output_controls.a_sel;
        isb_decode.b_sel <= id_output_controls.b_sel;
        isb_decode.jf_exe <= id_output_controls.jf_exe;
        isb_decode.alu_sel <= id_output_controls.alu_sel;
        isb_decode.shift_sel <= id_output_controls.sh_sel;
        isb_decode.alushift_sel <= id_output_controls.alushift_sel;
        isb_decode.dmem_sel <= id_output_controls.dmem_sel;
        isb_decode.wb_sel <= id_output_controls.wb_sel;
        isb_decode.reg_wr <= id_output_controls.reg_wr;

        isb_decode.valid <= isb_fetch.valid;
    end
    if(isb_decode_flush) begin
        isb_decode.jf_exe <= 0;
        isb_decode.reg_wr <= 0;
        isb_decode.dmem_sel <= DMEMS_ANY;
        isb_decode.valid <= 0;
    end

    if(rst) isb_decode <= '0;
end

endmodule : decode_stage