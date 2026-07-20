`include "risc-v.svh"

module risc_v_shifter_m
  import risc_v_pkg::*;
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
      SHIFT_SLL: res = data << shamt;
      SHIFT_SRL: res = data >> shamt;
      SHIFT_SRA: res = $signed(data) >>> shamt;
      default: res = 'X;
    endcase
  end

`else  // SHIFTER_ABSTRACT

  logic [XLEN-1:0] curData;
  logic [XLEN-1:0] tmp;

  always_comb begin  // shifter_logic

    curData = data;

    if (sel == SHIFT_SLL) begin  // SHIFT_SLL

      for (int i = 0; i < $clog2(XLEN); i++) begin
        automatic int localOffset = 1 << i;

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

    else if (sel == SHIFT_SRA || sel == SHIFT_SRL) begin // SHIFT_SRA and SHIFT_SRL

      logic fill;
      for (int i = 0; i < $clog2(XLEN); i++) begin
        automatic int localOffset = 1 << i;

        // offset bits
        for (int j = 0; j < XLEN - localOffset; j++) begin
          if (shamt[i]) tmp[j] = curData[j+localOffset];
          else tmp[j] = curData[j];
        end

        // left filling
        fill = (sel == SHIFT_SRL) ? 0 : curData[XLEN-1];
        for (int j = XLEN - localOffset; j < XLEN; j++) begin
          if (shamt[i]) tmp[j] = fill;
          else tmp[j] = curData[j];
        end

        curData = tmp;
      end
    end  // SHIFT_SRA and SHIFT_SRL    

    else begin // default
      curData = 'X;
    end  // default

    res = curData;

  end  // shifter_logic

`endif

endmodule  // risc_v_shifter_m
