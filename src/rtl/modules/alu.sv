`include "risc-v.svh"

module alu_m import risc_v_pkg::*;
               #(
                    parameter int XLEN = 32
                )
(
    input  ALU_SEL_t        sel,
    input  logic [XLEN-1:0] a,
    input  logic [XLEN-1:0] b,
    output logic [XLEN-1:0] res
);

always_comb begin
  case (sel)
    ALU_ADD    : res = a + b;
    ALU_SUB    : res = a - b;
    ALU_AND    : res = a & b;
    ALU_OR     : res = a | b;
    ALU_XOR    : res = a ^ b;
    ALU_SLT    : res = signed'(a) < signed'(b);
    ALU_SLTU   : res = a < b;
    ALU_JALR   : begin
                   res = a + b;
                   res[0] = 0;
                 end
    ALU_LUI    : res = b; // bypass
    default: res = 'X;
  endcase
end

endmodule : alu_m