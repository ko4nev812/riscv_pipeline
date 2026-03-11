`include "risc_branch.svh"

module branch_unit_tb
    import risc_branch_pkg::*;
#(
    parameter int XLEN = 32
)
();

timeunit      1ns;
timeprecision 1ps;

//==============================================================================
// Objects
//==============================================================================

logic [XLEN-1:0] rd1;
logic [XLEN-1:0] rd2;
logic            br_un;
BRU_SEL_t        sel;

logic            br_eq;
logic            br_lt;
logic            pc_sel;

bit error_flag = 0;

//==============================================================================
// DUT
//==============================================================================

branch_unit_m
#(
    .XLEN ( XLEN )
)
dut
(
    .rd1   ( rd1   ),
    .rd2   ( rd2   ),
    .br_un ( br_un ),
    .sel   ( sel   ),
    .br_eq ( br_eq ),
    .br_lt ( br_lt ),
    .pc_sel( pc_sel )
);

//==============================================================================
// Tasks
//==============================================================================

task automatic check_case(
    input logic [XLEN-1:0] t_rd1,
    input logic [XLEN-1:0] t_rd2,
    input logic            t_br_un,
    input BRU_SEL_t        t_sel,
    inout bit              err
);
    logic exp_eq;
    logic exp_lt;
    logic exp_pc_sel;
begin
    rd1   = t_rd1;
    rd2   = t_rd2;
    br_un = t_br_un;
    sel   = t_sel;
    #1;

    exp_eq = (t_rd1 == t_rd2);

    if (t_br_un) begin
        exp_lt = (t_rd1 < t_rd2);
    end
    else begin
        exp_lt = ($signed(t_rd1) < $signed(t_rd2));
    end

    case (t_sel)
        BRU_NONE : exp_pc_sel = 1'b0;
        BRU_JAL  : exp_pc_sel = 1'b1;
        BRU_JALR : exp_pc_sel = 1'b1;
        BRU_BEQ  : exp_pc_sel =  exp_eq;
        BRU_BNE  : exp_pc_sel = !exp_eq;
        BRU_BLT  : exp_pc_sel =  exp_lt;
        BRU_BGE  : exp_pc_sel = !exp_lt;
        default  : exp_pc_sel = 1'b0;
    endcase

    if (br_eq !== exp_eq) begin
        err = 1;
        $display("br_eq mismatch: sel=%0d br_un=%0b rd1=%h rd2=%h got=%0b exp=%0b",
                 t_sel, t_br_un, t_rd1, t_rd2, br_eq, exp_eq);
    end

    if (br_lt !== exp_lt) begin
        err = 1;
        $display("br_lt mismatch: sel=%0d br_un=%0b rd1=%h rd2=%h got=%0b exp=%0b",
                 t_sel, t_br_un, t_rd1, t_rd2, br_lt, exp_lt);
    end

    if (pc_sel !== exp_pc_sel) begin
        err = 1;
        $display("pc_sel mismatch: sel=%0d br_un=%0b rd1=%h rd2=%h got=%0b exp=%0b",
                 t_sel, t_br_un, t_rd1, t_rd2, pc_sel, exp_pc_sel);
    end
end
endtask

//==============================================================================
// Test sequence
//==============================================================================

initial begin
    // ----------------------------
    // NONE
    // ----------------------------
    check_case(32'h0000_0000, 32'h0000_0000, 1'b0, BRU_NONE, error_flag);
    #10;

    // ----------------------------
    // JAL / JALR
    // ----------------------------
    check_case(32'h0000_0000, 32'h0000_0000, 1'b0, BRU_JAL,  error_flag);
    #10;
    check_case(32'h1234_5678, 32'h8765_4321, 1'b1, BRU_JALR, error_flag);
    #10;

    // ----------------------------
    // BEQ
    // ----------------------------
    check_case(32'h0000_0005, 32'h0000_0005, 1'b0, BRU_BEQ, error_flag);
    #10;
    check_case(32'h0000_0005, 32'h0000_0006, 1'b0, BRU_BEQ, error_flag);
    #10;

    // ----------------------------
    // BNE
    // ----------------------------
    check_case(32'h0000_0005, 32'h0000_0006, 1'b0, BRU_BNE, error_flag);
    #10;
    check_case(32'hFFFF_FFFF, 32'hFFFF_FFFF, 1'b0, BRU_BNE, error_flag);
    #10;

    // ----------------------------
    // BLT signed
    // ----------------------------
    check_case(32'h0000_0003, 32'h0000_0005, 1'b0, BRU_BLT, error_flag);
    #10;
    check_case(32'h0000_0005, 32'h0000_0003, 1'b0, BRU_BLT, error_flag);
    #10;
    check_case(32'hFFFF_FFFF, 32'h0000_0001, 1'b0, BRU_BLT, error_flag); // -1 < 1
    #10;
    check_case(32'h0000_0001, 32'hFFFF_FFFF, 1'b0, BRU_BLT, error_flag); // 1 < -1
    #10;

    // ----------------------------
    // BGE signed
    // ----------------------------
    check_case(32'h0000_0005, 32'h0000_0003, 1'b0, BRU_BGE, error_flag);
    #10;
    check_case(32'hFFFF_FFFF, 32'hFFFF_FFFF, 1'b0, BRU_BGE, error_flag);
    #10;
    check_case(32'hFFFF_FFFE, 32'hFFFF_FFFB, 1'b0, BRU_BGE, error_flag); // -2 >= -5
    #10;
    check_case(32'hFFFF_FFFB, 32'hFFFF_FFFE, 1'b0, BRU_BGE, error_flag); // -5 >= -2
    #10;

    // ----------------------------
    // BLTU = BRU_BLT + br_un=1
    // ----------------------------
    check_case(32'h0000_0001, 32'hFFFF_FFFF, 1'b1, BRU_BLT, error_flag);
    #10;
    check_case(32'hFFFF_FFFF, 32'h0000_0001, 1'b1, BRU_BLT, error_flag);
    #10;
    check_case(32'h7FFF_FFFF, 32'h8000_0000, 1'b1, BRU_BLT, error_flag);
    #10;
    check_case(32'h8000_0000, 32'h7FFF_FFFF, 1'b1, BRU_BLT, error_flag);
    #10;

    // ----------------------------
    // BGEU = BRU_BGE + br_un=1
    // ----------------------------
    check_case(32'hFFFF_FFFF, 32'h0000_0001, 1'b1, BRU_BGE, error_flag);
    #10;
    check_case(32'h0000_0001, 32'hFFFF_FFFF, 1'b1, BRU_BGE, error_flag);
    #10;
    check_case(32'hABCD_EF01, 32'hABCD_EF01, 1'b1, BRU_BGE, error_flag);
    #10;

    if (!error_flag) begin
        $display("SUCCESS: all branch tests passed");
    end
    else begin
        $display("FAILED: branch tests have errors");
    end

    $finish;
end

endmodule : branch_unit_tb