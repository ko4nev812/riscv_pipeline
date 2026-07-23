//------------------------------------------------------------------------------
//  project:       RISC-V (SberLab Novosibirsk State University)
//
//  module:        risc_v_dmem_wr_port_m
//
//  description:   Data memory write port — generates byte write enables
//                 and aligned write data for store operations:
//                   SB (000) — store byte
//                   SH (001) — store halfword
//                   SW (010) — store word
//
//------------------------------------------------------------------------------

//******************************************************************************
//******************************************************************************
module risc_v_dmem_wr_port_m import risc_v_pkg::*;
                #(
                    parameter ENDIANNESS = "LITTLE"
                )
(
    //---
    input  logic                     dmem_we,
    input  logic [2:0]               funct3,
    input  ByteAddr_t                byte_addr,

    //---
    input  Data_t                    data_in,

    //---
    output logic [DATA_BYTE_NUM-1:0] we,
    output Data_t                    data_out
);

//==============================================================================
//    Logic
//==============================================================================

always_comb begin
    we       = '0;
    data_out = '0;

    if (dmem_we) begin
        casex (funct3)
            3'bx00: begin // SB
                data_out = {DATA_BYTE_NUM{data_in[7:0]}};
                we       = 4'b0001 << byte_addr;
            end
            3'bx01: begin // SH
                data_out = {(DATA_BYTE_NUM/2){data_in[15:0]}};
                we       = byte_addr[1] ? 4'b1100 : 4'b0011;
            end
            3'bx10: begin // SW
                data_out = data_in;
                we       = '1;
            end
            default: begin
                we       = '0;
                data_out = '0;
            end
        endcase
    end
end

endmodule : risc_v_dmem_wr_port_m
