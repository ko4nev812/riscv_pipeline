`ifndef RISC_ALU_SVH
`define RISC_ALU_SVH 

`include "risc-v.svh"

package risc_alu_pkg;
  import risc_v_pkg::XLEN;

  //_____SHIFTER______
  typedef logic [$clog2(XLEN)-1:0] shift_shamt_t;

  typedef enum logic [2:0] {
    SLLI = 3'b100,
    SRLI = 3'b010,
    SRAI = 3'b001
  } shift_sel_t;

endpackage

`endif  // RISC_ALU_SVH
