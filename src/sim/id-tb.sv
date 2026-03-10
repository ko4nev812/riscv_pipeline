`include "risc-v.svh"

// Testbench for id module (updated for new branch logic)
module id_tb import risc_v_pkg::*;
();

    timeunit      1ns;
    timeprecision 1ns;

    // Decoder module interaction variables
    Id_instr_t         instr;
    Id_controls_in_t   input_controls;
    Id_controls_out_t  output_controls;
    logic              illegal;

    // Testbench variables
    Id_controls_out_t  output_controls_expect;
    logic              illegal_expect;

    id dut (
        .instr            (instr),
        .input_controls   (input_controls),
        .output_controls  (output_controls),
        .illegal          (illegal)
    );

    function automatic Id_instr_t crop_instruction(input logic [31:0] instr);
        Id_instr_t cropped_instr = {
            instr[30],
            instr[14],
            instr[13],
            instr[12],
            instr[6],
            instr[5],
            instr[4],
            instr[3],
            instr[2]
        };
        return cropped_instr;
    endfunction

    task automatic check(
        input Id_controls_out_t  output_controls_expect,
        input logic              illegal_expect_
    );
        assert(
            output_controls.reg_wr   ==? output_controls_expect.reg_wr &&
            output_controls.dmem_we  ==? output_controls_expect.dmem_we &&
            output_controls.br_un    ==? output_controls_expect.br_un &&
            output_controls.pc_sel   ==? output_controls_expect.pc_sel &&
            output_controls.alu_sel  ==? output_controls_expect.alu_sel &&
            output_controls.wb_sel   ==? output_controls_expect.wb_sel &&
            output_controls.imm_type ==? output_controls_expect.imm_type &&
            illegal                  ==? illegal_expect_
        ) begin
            $display("[PASS  ]");
        end else begin
            $display("[  FAIL]:\n",
                "actual: reg_wr=%b ", output_controls.reg_wr,
                    "dmem_we=%b ",    output_controls.dmem_we,
                    "br_un=%b ",      output_controls.br_un,
                    "pc_sel=%b ",     output_controls.pc_sel,
                    "alu_sel=%b ",    output_controls.alu_sel,
                    "wb_sel=%b ",     output_controls.wb_sel,
                    "imm_type=%b ",   output_controls.imm_type,
                    "illegal=%b\n",   illegal,
                "expect: reg_wr=%b ", output_controls_expect.reg_wr,
                    "dmem_we=%b ",    output_controls_expect.dmem_we,
                    "br_un=%b ",      output_controls_expect.br_un,
                    "pc_sel=%b ",     output_controls_expect.pc_sel,
                    "alu_sel=%b ",    output_controls_expect.alu_sel,
                    "wb_sel=%b ",     output_controls_expect.wb_sel,
                    "imm_type=%b ",   output_controls_expect.imm_type,
                    "illegal=%b ",    illegal_expect);
        end
    endtask

    initial begin
        $display("ID testbench started.");

        // BEQ
        #5;
        $display("BEQ test:");
        instr = crop_instruction(32'bxxxxxxx_xxxxx_xxxxx_000_xxxxx_1100011);
        input_controls = '{ br_eq : 1'b1, br_lt : 1'b0 };

        output_controls_expect = { 1'b0, 1'b0, 1'bx, 1'bx, SHIFT_ANY, 1'b0, 1'b0, ALU_ADD, WB_ANY, INSTR_TYPE_B };
        illegal_expect = 1'b0;
        #5 check(output_controls_expect, illegal_expect);
    end

endmodule : id_tb
