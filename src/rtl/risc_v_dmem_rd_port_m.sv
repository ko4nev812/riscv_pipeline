//------------------------------------------------------------------------------
//  project:       RISC-V (SberLab Novosibirsk State University)
//
//  modules:       risc_v_dmem_rd_port_m
//                 dmem_rd_port_sign_gen_m
//
//  description:   Data memory read port — byte/halfword/word selection
//                 with sign/zero extension based on funct3 encoding:
//                   LB  (000) — load byte,     sign-extend
//                   LH  (001) — load halfword, sign-extend
//                   LW  (010) — load word
//                   LBU (100) — load byte,     zero-extend
//                   LHU (101) — load halfword, zero-extend
//
//------------------------------------------------------------------------------

//******************************************************************************
//******************************************************************************
module dmem_rd_port_sign_gen_m import risc_v_pkg::*;
                #(
                    parameter ENDIANNESS = "LITTLE"
                )
(
    //---
    input  LoadInstr_t      instr,
    input  ByteAddr_t       byte_addr,

    //---
    input  var ByteData_t   data,

    //---
    output Byte_t           sign
);

//==============================================================================
//    Logic
//==============================================================================

always_comb begin
    case (instr)
        LOAD_LB:  sign = {8{data[byte_addr][7]}};
        LOAD_LH:  sign = {8{data[{byte_addr[1], 1'b1}][7]}};
        default:  sign = '0;
    endcase
end

endmodule : dmem_rd_port_sign_gen_m

//******************************************************************************
//******************************************************************************
module risc_v_dmem_rd_port_m import risc_v_pkg::*;
                #(
                    parameter ENDIANNESS = "LITTLE"
                )
(
    //---
    input  logic [2:0]  funct3,
    input  ByteAddr_t   byte_addr,

    //---
    input  Data_t       data_in,

    //---
    output Data_t       data_out
);

//==============================================================================
//    Objects
//==============================================================================

ByteData_t byte_data;
Byte_t     sign;

//==============================================================================
//    Instances
//==============================================================================

dmem_rd_port_sign_gen_m #(.ENDIANNESS(ENDIANNESS))
sign_gen_inst
(
    .instr     ( LoadInstr_t'(funct3) ),
    .byte_addr ( byte_addr            ),
    .data      ( byte_data            ),
    .sign      ( sign                 )
);

//==============================================================================
//    Logic
//==============================================================================

//------------------------------------------------------------------------------
//    Decompose word into bytes
//------------------------------------------------------------------------------
always_comb begin
    for (int i = 0; i < DATA_BYTE_NUM; i++) begin
        byte_data[i] = data_in[i*8 +: 8];
    end
end

//------------------------------------------------------------------------------
//    Assemble output
//------------------------------------------------------------------------------
always_comb begin
    case (funct3[1:0])
        2'b00: begin
            data_out = {sign, sign, sign, byte_data[byte_addr]};
        end
        2'b01: begin
            data_out = {sign, sign,
                        byte_data[{byte_addr[1], 1'b1}],
                        byte_data[{byte_addr[1], 1'b0}]};
        end
        2'b10: begin
            data_out = data_in;
        end
        default: begin
            data_out = data_in;
        end
    endcase
end

endmodule : risc_v_dmem_rd_port_m
