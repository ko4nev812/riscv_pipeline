`include "risc_alu.svh"

timeunit 1ns; timeprecision 1ps;

module shifter_alu_tb
  import risc_alu_pkg::*;
#(
    parameter int XLEN = 32
) ();

  //==============================================================================
  //    Init
  //==============================================================================

  logic [XLEN-1:0] data;
  shift_shamt_t shamt;
  shift_sel_t sel;
  logic [XLEN-1:0] res;

  risc_v_shifter_m #(
      .XLEN(XLEN)
  ) shift (
      .data (data),
      .shamt(shamt),
      .sel  (sel),
      .res  (res)
  );

  bit error_flag = 0;

  //==============================================================================
  //    Tasks
  //==============================================================================

  task automatic check_shift(input [XLEN-1:0] test_data, input shift_shamt_t test_shamt,
                             input shift_sel_t test_sel, inout bit err);
    logic [XLEN-1:0] expected;
    begin
      data  = test_data;
      shamt = test_shamt;
      sel   = test_sel;
      #1;

      case (test_sel)
        SLLI: expected = test_data << test_shamt;
        SRLI: expected = test_data >> test_shamt;
        SRAI: expected = $signed(test_data) >>> test_shamt;
        default: expected = 'X;
      endcase

      if (res != expected) begin
        err = 1;
        $display("Shift mismatch! sel=%0b, data=%h, shamt=%0d, res=%h, expected=%h", test_sel,
                 test_data, test_shamt, res, expected);
      end
    end
  endtask

  //==============================================================================
  //    Runs
  //==============================================================================

  initial begin

    // BASE
    check_shift(32'hF0F0_F0F0, 4, SLLI, error_flag);
    #10;
    check_shift(32'hF0F0_F0F0, 4, SRLI, error_flag);
    #10;
    check_shift(32'hF0F0_F0F0, 4, SRAI, error_flag);
    #10;

    // ZEROES
    check_shift(32'h0000_0000, 8, SLLI, error_flag);
    #10;
    check_shift(32'h0000_0000, 8, SRLI, error_flag);
    #10;
    check_shift(32'h0000_0000, 8, SRAI, error_flag);
    #10;

    // ONES
    check_shift(32'hFFFF_FFFF, 16, SLLI, error_flag);
    #10;
    check_shift(32'hFFFF_FFFF, 16, SRLI, error_flag);
    #10;
    check_shift(32'hFFFF_FFFF, 16, SRAI, error_flag);
    #10;

    // SMALL
    check_shift(32'h0000_00F0, 2, SLLI, error_flag);
    #10;
    check_shift(32'h0000_00F0, 2, SRLI, error_flag);
    #10;
    check_shift(32'h0000_00F0, 2, SRAI, error_flag);
    #10;

    // MAX OFFSET
    check_shift(32'h1234_5678, 31, SLLI, error_flag);
    #10;
    check_shift(32'h1234_5678, 31, SRLI, error_flag);
    #10;
    check_shift(32'h8234_5678, 31, SRAI, error_flag);
    #10;

    // NO OFFSET
    check_shift(32'h89AB_CDEF, 0, SLLI, error_flag);
    #10;
    check_shift(32'h89AB_CDEF, 0, SRLI, error_flag);
    #10;
    check_shift(32'h89AB_CDEF, 0, SRAI, error_flag);
    #10;


    if (!error_flag) $display("All shift tests passed!");
    else $display("Shift tests not passed");

    $finish;

  end

endmodule
