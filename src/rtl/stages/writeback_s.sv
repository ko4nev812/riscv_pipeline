`include "risc-v.svh"


module writeback_stage import risc_v_pkg::*;(
    input ISB_memory_t isb_memory,

    output Data_t rf_wd3,
    output logic  rf_we3,
    output RegAddr_t rf_rd

);


always_comb begin
    case (isb_memory.wb_sel)
        WB_PC4_OUT     : rf_wd3 = isb_memory.pc4;
        WB_ALU_OUT     : rf_wd3 = isb_memory.alu_out;
        WB_DMEM_OUT    : rf_wd3 = isb_memory.dmem_data_out;
        default: rf_wd3 = 'X;
    endcase
end

assign rf_we3 = isb_memory.reg_wr;
assign rf_rd  = isb_memory.rd;


endmodule : writeback_stage