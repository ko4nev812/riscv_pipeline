`include "risc_alu.svh"

module risc_v_shifter_m
  import risc_alu_pkg::*;
#(
    parameter int XLEN = 32
) (
    input logic [XLEN-1:0] data,
    input shift_shamt_t shamt,
    input shift_sel_t sel,

    output logic [XLEN-1:0] res
);


`ifdef SHIFTER_ABSTRACT

  always_comb begin
    case (sel)
      SLLI: res = data << shamt;
      SRLI: res = data >> shamt;
      SRAI: res = $signed(data) >>> shamt;
      default: res = 'X;
    endcase
  end

`else  // SHIFTER_ABSTRACT

  always_comb begin  // shifter_logic

    logic [XLEN-1:0] curData = data;
    logic [XLEN-1:0] tmp;


    if (sel == SLLI) begin  // SLLI

      for (int i = 0; i < $clog2(XLEN); i++) begin
        int localOffset = 1 << i;

        // offset bits
        for (int j = localOffset; j < XLEN; j++) begin
          if (shamt[i]) tmp[j] = curData[j-localOffset];
          else tmp[j] = curData[j];
        end

        // right zeroes
        for (int j = 0; j < localOffset; j++) begin
          if (shamt[i]) tmp[j] = 0;
          else tmp[j] = curData[j];
        end
      
        curData = tmp;
      end

    end  // SLLI

    else if (sel == SRAI || sel == SRLI) begin // SRAI and SRLI

      logic fill;
      for (int i = 0; i < $clog2(XLEN); i++) begin
        int localOffset = 1 << i;

        // offset bits
        for (int j = 0; j < XLEN - localOffset; j++) begin
          if (shamt[i]) tmp[j] = curData[j+localOffset];
          else tmp[j] = curData[j];
        end

        // left filling
        fill = (sel == SRLI) ? 0 : curData[XLEN-1];
        for (int j = XLEN - localOffset; j < XLEN; j++) begin
          if (shamt[i]) tmp[j] = fill;
          else tmp[j] = curData[j];
        end

        curData = tmp;
      end
    end  // SRAI and SRLI    

    else begin // default
      res = 'X;
    end  // default

    res = curData;

  end  // shifter_logic

`endif

endmodule  // risc_v_shifter_m
