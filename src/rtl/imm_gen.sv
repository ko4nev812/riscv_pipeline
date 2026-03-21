`include "risc-v.svh"


/*
 * Module `imm_gen`
 *
 *   Signal-immediate generator
 *
 *   Inputs:
 *     - instr:    logic[31:0]  Instruction
 *     - imm_type: logic[2:0]   Immediate type: (0) - Not immediate, (1) - I-type, (2) - S-type, (3) - B-type,
 *                                                                   (4) - U-type, (5) - J-type
 *   Outputs:
 *     - imm:      logic[31:0]  The generated immediate.
 */
/*
 *       31               25 24     20 19     15 14     12 11         7  6       0
 *      ┌─────────────────────────────┬─────────┬─────────┬─────────────┬─────────┐
 *   I  │           imm[11:0]         │ rs1     │ funct3  │    rd       │ opcode  │  I (1)
 *      ├───────────────────┬─────────┼─────────┼─────────┼─────────────┼─────────┤
 *   S  │      imm[11:5]    │ rs2     │ rs1     │ funct3  │  imm[4:0]   │ opcode  │  S (2)
 *      ├────┬──────────────┼─────────┼─────────┼─────────┼────────┬────┼─────────┤
 *   B  │[12]│   imm[10:5]  │ rs2     │ rs1     │ funct3  │imm[4:1]│[11]│ opcode  │  B (3)
 *      ├────┴──────────────┴─────────┴─────────┴─────────┼────────┴────┼─────────┤
 *   U  │                 imm[31:12]                      │    rd       │ opcode  │  U (4)
 *      ├────┬───────────────────┬────┬───────────────────┼─────────────┼─────────┤
 *   J  │[20]|       imm[10:1]   │[11]│     imm[19:12]    │    rd       │ opcode  │  J (5)
 *      └────┴───────────────────┴────┴───────────────────┴────────┴────┴─────────┘
 *       31   30               21  20  19               12 11     8   7  6       0
 */
module imm_gen import risc_v_pkg::*;
(
    input  Instr_t     instr,
    input  Imm_type_t  imm_type,
    output Imm_t       imm
);


    always_comb begin
        case (imm_type)
            IMM_I_TYPE: imm = {{20{instr[31]}}, instr[31:20]};                                            // I-type
            IMM_S_TYPE: imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};                               // S-type
            IMM_B_TYPE: imm = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:9], 2'b00};   // B-type
            IMM_U_TYPE: imm = {instr[31:12], 12'b0};                                                      // U-type
            IMM_J_TYPE: imm = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:22], 2'b00}; // J-type

            // In B and J type fill the last 2 bits with zeros.

            default:    imm = 32'b0;
        endcase
    end
    
endmodule : imm_gen