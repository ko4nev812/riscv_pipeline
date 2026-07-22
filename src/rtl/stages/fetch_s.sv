`include "risc-v.svh"

module fetch_stage import risc_v_pkg::*;
(
    output ISB_fetch_t isb_fetch,
    input logic isb_fetch_stall,
    input logic isb_fetch_flush,

    input logic jf_exe,
    input logic jf_id,
    input Data_t alu_out,
    input Data_t imm_pc,

    input logic clk,
    input logic rst,
    input logic stall_pc,

    // --- imem interface
    output Addr_t imem_addr,
    input  Instr_t imem_instr
);

Addr_t next_pc;
Addr_t pc;

always_comb begin
    next_pc = pc+4;

    if (rst)
        next_pc = PC_START_ADDR;
    if (stall_pc)
        next_pc = pc;
    if (jf_exe)
        next_pc = alu_out;
    if (jf_id)
        next_pc = imm_pc;
end


always_ff @(posedge clk) begin
    pc <= next_pc;
end

assign imem_addr = next_pc;

always_ff @(posedge clk) begin
    if(!isb_fetch_stall) begin
        isb_fetch.pc      <= pc;
        isb_fetch.instr   <= imem_instr;
        isb_fetch.valid   <= !rst;
    end
    if(isb_fetch_flush) begin
        isb_fetch.instr <= '0;
        isb_fetch.valid <= '0;
    end

    if(rst) isb_fetch <= '0;
end

endmodule : fetch_stage