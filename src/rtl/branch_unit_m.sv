`include "risc-v.svh"

module branch_unit_m
#(
    parameter int XLEN = 32
)
(
    input  logic [XLEN-1:0] rd1,
    input  logic [XLEN-1:0] rd2,
    input  logic            br_un,   // 0 = signed compare, 1 = unsigned compare

    output logic            br_eq,
    output logic            br_lt
);

//timeunit      1ns;
//timeprecision 1ps;

always_comb begin
    // comparator
    br_eq = (rd1 == rd2);

    if (br_un) begin
        br_lt = (rd1 < rd2);
    end else begin
        br_lt = ($signed(rd1) < $signed(rd2));
    end
end

endmodule : branch_unit_m