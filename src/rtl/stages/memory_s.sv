`include "risc-v.svh"

module memory_stage import risc_v_pkg::*;(
    output ISB_memory_t isb_memory,

    input ISB_execute_t isb_execute,


    //--- dmem interface 
    output Addr_t        dmem_addr,
    output ByteDataEna_t dmem_byte_we,
    output Data_t        dmem_data_in,
    input  Data_t        dmem_data_out,

    input logic clk,
    input logic rst
);

logic       dmem_we;
logic [2:0] dmem_funct3;
logic [1:0] dmem_byte_off;
Data_t      dmem_rdata_out;
Data_t      dmem_wdata_in;

assign dmem_addr   = isb_execute.alu_out;
assign dmem_we     = isb_execute.dmem_sel[3];
assign dmem_funct3 = isb_execute.dmem_sel[2:0];
assign dmem_byte_off = dmem_addr[1:0];
assign dmem_wdata_in = isb_execute.rf_rd2;

risc_v_dmem_wr_port_m dmem_wr_port_inst
(
    // -- in
    .dmem_we (dmem_we),
    .funct3 (dmem_funct3),
    .byte_addr (dmem_byte_off),
    .data_in (dmem_wdata_in),
    // -- out
    .we (dmem_byte_we),
    .data_out (dmem_data_in)
);

risc_v_dmem_rd_port_m dmem_rd_port_inst
(
    // -- in
    .funct3 (dmem_funct3),
    .byte_addr (dmem_byte_off),
    .data_in(dmem_data_out),
    // -- out
    .data_out(dmem_rdata_out)
);


logic reg_wr;
assign reg_wr = isb_execute.reg_wr;
RegAddr_t rd;
assign rd = isb_execute.rd;

always_ff @(posedge clk) begin
    isb_memory.dmem_data_out <= dmem_rdata_out;
    isb_memory.alu_out <= isb_execute.alu_out;
    isb_memory.pc4 <= isb_execute.pc4;
    isb_memory.rd <= rd;
    isb_memory.reg_wr <= reg_wr;
    isb_memory.wb_sel <= isb_execute.wb_sel;

    isb_memory.valid <= isb_execute.valid;

    if(rst) isb_memory <= '0;
end



endmodule : memory_stage