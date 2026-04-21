// `define REG_CNT 32
// `define REG_BUS ($clog2(`REG_CNT)) // REG_BUS = 5
// `define XLEN 32

module register_file #(
    parameter  XLEN = 32,
    parameter  REG_CNT = 32,
    localparam REG_BUS = ($clog2(REG_CNT))
) (
    input logic clk,

    input logic [REG_BUS-1:0] rsi1,
    output logic [XLEN-1:0] rs1,

    input logic [REG_BUS-1:0] rsi2,
    output logic [XLEN-1:0] rs2,

    input logic [REG_BUS-1:0] rdi,
    input logic [XLEN-1:0] rd,

    input logic we
);

  timeunit      1ns;
  timeprecision 1ps;

  //logic [XLEN-1:0] regFile[0:REG_CNT-1];
  logic [XLEN-1:0] regFile[0:REG_CNT-1] = '{ default: '0 };
  
  //initial begin
  //  regFile[0] = 1'd0;
  //end

  function automatic logic [XLEN-1:0] rs(input [REG_BUS-1:0] rsi);
    rs = regFile[rsi];
  endfunction

  always_comb begin
    rs1 = regFile[rsi1];
    rs2 = regFile[rsi2];
  end

  always_ff @(posedge clk) begin : save_rd
    if (we && rdi != 0) begin
      regFile[rdi] <= rd;
    end
  end

endmodule : register_file
