`include "risc-v.svh"

/*
 * Module `id`
 *
 *   Decodes all RV32I instructions
 *
 *   Inputs:
 *     -           instr:  Id_instr_t           necessary instruction bits
 *   Outputs:
 *     - output_controls:  Id_controls_out_t    output signals
 *     -         illegal:  logic                instruction is - 0: legal, 1: illegal
 */
module id_m import risc_v_pkg::*;
(
    input  Id_instr_t         instr,
    output Id_controls_out_t  output_controls,
    output logic              illegal
);
    parameter int CASE_SIZE = $bits(Id_instr_t);

    `define set_default_signals                                                                               \
        output_controls = { 1'b0, DMEMS_ANY, 1'bx, 1'bx, SHIFT_ANY, BRANCH_ANY, ALU_ANY, WB_ANY, 1'b0, AS_ANY, INSTR_TYPE_ANY }; \
        illegal = 1'b1;

    logic [(CASE_SIZE - 1):0] case_key;

    always_comb begin
        case_key = {instr.funct7, instr.funct3, instr.opcode};
        illegal = 1'b0;

        if (instr.ones != 'b11) begin
            `set_default_signals;
        end else begin
            casex (case_key)
                // MNEMONIC  funct7_funct3_opcode_breq_brlt     reg_wr  dmem_sel    a_sel  b_sel  sh_sel      branch_sel    alu_sel    wb_sel        jf_exe  alushift_sel  imm_type
                /* LUI   */  'bx_xxx_01101: output_controls = { 1'b1,   DMEMS_ANY,  1'bx,  1'b0,  SHIFT_ANY,  BRANCH_ANY,   ALU_LUI,   WB_ALU_OUT,   1'b0,   AS_ALU_OUT,   INSTR_TYPE_U };
                /* AUIPC */  'bx_xxx_00101: output_controls = { 1'b1,   DMEMS_ANY,  1'b0,  1'b0,  SHIFT_ANY,  BRANCH_ANY,   ALU_ADD,   WB_ALU_OUT,   1'b0,   AS_ALU_OUT,   INSTR_TYPE_U };
                /* JAL   */  'bx_xxx_11011: output_controls = { 1'b1,   DMEMS_ANY,  1'b0,  1'b0,  SHIFT_ANY,  BRANCH_ANY,   ALU_ADD,   WB_PC4_OUT,   1'b1,   AS_ANY,       INSTR_TYPE_J };
                /* JALR  */  'b0_000_11001: output_controls = { 1'b1,   DMEMS_ANY,  1'b1,  1'b0,  SHIFT_ANY,  BRANCH_ANY,   ALU_JALR,  WB_PC4_OUT,   1'b1,   AS_ANY,       INSTR_TYPE_I };
    
                //       we set flag `br_un` according to instruction, but also set `pc_sel=1` to move to the next instruction `PC+4` instead of branch
                /* BEQ   */  'bx_000_11000: output_controls = { 1'b0,   DMEMS_ANY,  1'b0,  1'b0,  SHIFT_ANY,  BRANCH_BEQ,   ALU_ADD,   WB_ANY,       1'b0,   AS_ALU_OUT,   INSTR_TYPE_B };
                /* BNE   */  'bx_001_11000: output_controls = { 1'b0,   DMEMS_ANY,  1'b0,  1'b0,  SHIFT_ANY,  BRANCH_BNE,   ALU_ADD,   WB_ANY,       1'b0,   AS_ALU_OUT,   INSTR_TYPE_B };
                /* BLT   */  'bx_100_11000: output_controls = { 1'b0,   DMEMS_ANY,  1'b0,  1'b0,  SHIFT_ANY,  BRANCH_BLT,   ALU_ADD,   WB_ANY,       1'b0,   AS_ALU_OUT,   INSTR_TYPE_B };
                /* BGE   */  'bx_101_11000: output_controls = { 1'b0,   DMEMS_ANY,  1'b0,  1'b0,  SHIFT_ANY,  BRANCH_BGE,   ALU_ADD,   WB_ANY,       1'b0,   AS_ALU_OUT,   INSTR_TYPE_B };
                /* BLTU  */  'bx_110_11000: output_controls = { 1'b0,   DMEMS_ANY,  1'b0,  1'b0,  SHIFT_ANY,  BRANCH_BLTU,  ALU_ADD,   WB_ANY,       1'b0,   AS_ALU_OUT,   INSTR_TYPE_B };
                /* BGEU  */  'bx_111_11000: output_controls = { 1'b0,   DMEMS_ANY,  1'b0,  1'b0,  SHIFT_ANY,  BRANCH_BGEU,  ALU_ADD,   WB_ANY,       1'b0,   AS_ALU_OUT,   INSTR_TYPE_B };
    
                /* LB    */  'bx_000_00000: output_controls = { 1'b1,   DMEMS_LB,   1'b1,  1'b0,  SHIFT_ANY,  BRANCH_ANY,   ALU_ADD,   WB_DMEM_OUT,  1'b0,   AS_ALU_OUT,   INSTR_TYPE_I };
                /* LH    */  'bx_001_00000: output_controls = { 1'b1,   DMEMS_LH,   1'b1,  1'b0,  SHIFT_ANY,  BRANCH_ANY,   ALU_ADD,   WB_DMEM_OUT,  1'b0,   AS_ALU_OUT,   INSTR_TYPE_I };
                /* LW    */  'bx_010_00000: output_controls = { 1'b1,   DMEMS_LW,   1'b1,  1'b0,  SHIFT_ANY,  BRANCH_ANY,   ALU_ADD,   WB_DMEM_OUT,  1'b0,   AS_ALU_OUT,   INSTR_TYPE_I };
                /* LBU   */  'bx_100_00000: output_controls = { 1'b1,   DMEMS_LBU,  1'b1,  1'b0,  SHIFT_ANY,  BRANCH_ANY,   ALU_ADD,   WB_DMEM_OUT,  1'b0,   AS_ALU_OUT,   INSTR_TYPE_I };
                /* LHU   */  'bx_101_00000: output_controls = { 1'b1,   DMEMS_LHU,  1'b1,  1'b0,  SHIFT_ANY,  BRANCH_ANY,   ALU_ADD,   WB_DMEM_OUT,  1'b0,   AS_ALU_OUT,   INSTR_TYPE_I };
                /* SB    */  'bx_000_01000: output_controls = { 1'b0,   DMEMS_SB,   1'b1,  1'b0,  SHIFT_ANY,  BRANCH_ANY,   ALU_ADD,   WB_ANY,       1'b0,   AS_ALU_OUT,   INSTR_TYPE_S };
                /* SH    */  'bx_001_01000: output_controls = { 1'b0,   DMEMS_SH,   1'b1,  1'b0,  SHIFT_ANY,  BRANCH_ANY,   ALU_ADD,   WB_ANY,       1'b0,   AS_ALU_OUT,   INSTR_TYPE_S };
                /* SW    */  'bx_010_01000: output_controls = { 1'b0,   DMEMS_SW,   1'b1,  1'b0,  SHIFT_ANY,  BRANCH_ANY,   ALU_ADD,   WB_ANY,       1'b0,   AS_ALU_OUT,   INSTR_TYPE_S };
                /* ADDI  */  'bx_000_00100: output_controls = { 1'b1,   DMEMS_ANY,  1'b1,  1'b0,  SHIFT_ANY,  BRANCH_ANY,   ALU_ADD,   WB_ALU_OUT,   1'b0,   AS_ALU_OUT,   INSTR_TYPE_I };
                /* SLTI  */  'bx_010_00100: output_controls = { 1'b1,   DMEMS_ANY,  1'b1,  1'b0,  SHIFT_ANY,  BRANCH_ANY,   ALU_SLT,   WB_ALU_OUT,   1'b0,   AS_ALU_OUT,   INSTR_TYPE_I };
                /* SLTIU */  'bx_011_00100: output_controls = { 1'b1,   DMEMS_ANY,  1'b1,  1'b0,  SHIFT_ANY,  BRANCH_ANY,   ALU_SLTU,  WB_ALU_OUT,   1'b0,   AS_ALU_OUT,   INSTR_TYPE_I };
                /* XORI  */  'bx_100_00100: output_controls = { 1'b1,   DMEMS_ANY,  1'b1,  1'b0,  SHIFT_ANY,  BRANCH_ANY,   ALU_XOR,   WB_ALU_OUT,   1'b0,   AS_ALU_OUT,   INSTR_TYPE_I };
                /* ORI   */  'bx_110_00100: output_controls = { 1'b1,   DMEMS_ANY,  1'b1,  1'b0,  SHIFT_ANY,  BRANCH_ANY,   ALU_OR,    WB_ALU_OUT,   1'b0,   AS_ALU_OUT,   INSTR_TYPE_I };
                /* ANDI  */  'bx_111_00100: output_controls = { 1'b1,   DMEMS_ANY,  1'b1,  1'b0,  SHIFT_ANY,  BRANCH_ANY,   ALU_AND,   WB_ALU_OUT,   1'b0,   AS_ALU_OUT,   INSTR_TYPE_I };
                /* SLLI  */  'b0_001_00100: output_controls = { 1'b1,   DMEMS_ANY,  1'bx,  1'b0,  SHIFT_SLL,  BRANCH_ANY,   ALU_ANY,   WB_ALU_OUT,   1'b0,   AS_SHIFT_OUT, INSTR_TYPE_ANY };
                /* SRLI  */  'b0_101_00100: output_controls = { 1'b1,   DMEMS_ANY,  1'bx,  1'b0,  SHIFT_SRL,  BRANCH_ANY,   ALU_ANY,   WB_ALU_OUT,   1'b0,   AS_SHIFT_OUT, INSTR_TYPE_ANY };
                /* SRAI  */  'b1_101_00100: output_controls = { 1'b1,   DMEMS_ANY,  1'bx,  1'b0,  SHIFT_SRA,  BRANCH_ANY,   ALU_ANY,   WB_ALU_OUT,   1'b0,   AS_SHIFT_OUT, INSTR_TYPE_ANY };
                /* ADD   */  'b0_000_01100: output_controls = { 1'b1,   DMEMS_ANY,  1'b1,  1'b1,  SHIFT_ANY,  BRANCH_ANY,   ALU_ADD,   WB_ALU_OUT,   1'b0,   AS_ALU_OUT,   INSTR_TYPE_ANY };
                /* SUB   */  'b1_000_01100: output_controls = { 1'b1,   DMEMS_ANY,  1'b1,  1'b1,  SHIFT_ANY,  BRANCH_ANY,   ALU_SUB,   WB_ALU_OUT,   1'b0,   AS_ALU_OUT,   INSTR_TYPE_ANY };
                /* SLL   */  'b0_001_01100: output_controls = { 1'b1,   DMEMS_ANY,  1'bx,  1'b1,  SHIFT_SLL,  BRANCH_ANY,   ALU_ANY,   WB_ALU_OUT,   1'b0,   AS_SHIFT_OUT, INSTR_TYPE_ANY };
                /* SLT   */  'b0_010_01100: output_controls = { 1'b1,   DMEMS_ANY,  1'b1,  1'b1,  SHIFT_ANY,  BRANCH_ANY,   ALU_SLT,   WB_ALU_OUT,   1'b0,   AS_ALU_OUT,   INSTR_TYPE_ANY };
                /* SLTU  */  'b0_011_01100: output_controls = { 1'b1,   DMEMS_ANY,  1'b1,  1'b1,  SHIFT_ANY,  BRANCH_ANY,   ALU_SLTU,  WB_ALU_OUT,   1'b0,   AS_ALU_OUT,   INSTR_TYPE_ANY };
                /* XOR   */  'b0_100_01100: output_controls = { 1'b1,   DMEMS_ANY,  1'b1,  1'b1,  SHIFT_ANY,  BRANCH_ANY,   ALU_XOR,   WB_ALU_OUT,   1'b0,   AS_ALU_OUT,   INSTR_TYPE_ANY };
                /* SRL   */  'b0_101_01100: output_controls = { 1'b1,   DMEMS_ANY,  1'bx,  1'b1,  SHIFT_SRL,  BRANCH_ANY,   ALU_ANY,   WB_ALU_OUT,   1'b0,   AS_SHIFT_OUT, INSTR_TYPE_ANY };
                /* SRA   */  'b1_101_01100: output_controls = { 1'b1,   DMEMS_ANY,  1'bx,  1'b1,  SHIFT_SRA,  BRANCH_ANY,   ALU_ANY,   WB_ALU_OUT,   1'b0,   AS_SHIFT_OUT, INSTR_TYPE_ANY };
                /* OR    */  'b0_110_01100: output_controls = { 1'b1,   DMEMS_ANY,  1'b1,  1'b1,  SHIFT_ANY,  BRANCH_ANY,   ALU_OR,    WB_ALU_OUT,   1'b0,   AS_ALU_OUT,   INSTR_TYPE_ANY };
                /* AND   */  'b0_111_01100: output_controls = { 1'b1,   DMEMS_ANY,  1'b1,  1'b1,  SHIFT_ANY,  BRANCH_ANY,   ALU_AND,   WB_ALU_OUT,   1'b0,   AS_ALU_OUT,   INSTR_TYPE_ANY };
    
                /* There goes unsupported instructions, we consider them as NOPs */
                /* FENCE
                   FENCE.TSO
                   PAUSE */  'bx_000_00011: output_controls = { 1'b0, DMEMS_ANY, 1'bx, 1'bx, SHIFT_ANY, BRANCH_ANY, ALU_ANY, WB_ANY, 1'b0, AS_ANY, INSTR_TYPE_ANY };
                /* ECALL
                   EBREAK */ 'b0_000_11100: output_controls = { 1'b0, DMEMS_ANY, 1'bx, 1'bx, SHIFT_ANY, BRANCH_ANY, ALU_ANY, WB_ANY, 1'b0, AS_ANY, INSTR_TYPE_ANY };
    
                default: begin
                    `set_default_signals;
                end
            endcase
        end
    end

endmodule : id_m
