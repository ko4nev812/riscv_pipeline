`include "risc-v.svh"

module execute_stage import risc_v_pkg::*;(
    output ISB_execute_t isb_execute,

    input ISB_decode_t isb_decode,

    // jalr instruction
    output logic jf_exe,
    output Addr_t alures,


    input logic clk,
    input logic rst
);

//--- ALU
Data_t    alu_in_a;
Data_t    alu_in_b;
Data_t    alu_out;

//--- Shifter
Data_t shifter_out;
shift_shamt_t shift_shamt;


assign alu_in_a = isb_decode.a_sel? isb_decode.rf_rd1 : isb_decode.pc;
assign alu_in_b = isb_decode.b_sel? isb_decode.rf_rd2 : isb_decode.imm;

assign shift_shamt = isb_decode.b_sel? isb_decode.rf_rd2[4:0] : isb_decode.rs2;


// ====== ALU ======
(* keep_hierarchy = `PRJ_KEEP_HIEARARCHY *)
alu_m
#(
    .XLEN ( XLEN )
)
alu_inst
(
    .sel ( isb_decode.alu_sel  ),   
    .a   ( alu_in_a ),
    .b   ( alu_in_b ),
    .res ( alu_out  )
);


// ====== Shifter ======
risc_v_shifter_m
#(
    .XLEN ( XLEN )
)
shifter_inst
(
   .data (isb_decode.rf_rd1),
   .shamt (shift_shamt),
   .sel(isb_decode.shift_sel),
   .res (shifter_out)
);

assign jf_exe = isb_decode.jf_exe;
assign alures = alu_out;

logic reg_wr;
assign reg_wr = isb_decode.reg_wr;

RegAddr_t rd;
assign rd = isb_decode.rd;

always_ff @(posedge clk) begin
    isb_execute.alu_out <= isb_decode.alushift_sel? shifter_out : alu_out;
    isb_execute.pc4 <= isb_decode.pc + 4;
    isb_execute.rd  <= isb_decode.rd;
    isb_execute.dmem_sel <= isb_decode.dmem_sel;
    isb_execute.reg_wr <= isb_decode.reg_wr;
    isb_execute.rf_rd2 <= isb_decode.rf_rd2;
    isb_execute.wb_sel <= isb_decode.wb_sel;
    isb_execute.valid <= isb_decode.valid;

    if (rst) isb_execute <= '0;
end

endmodule : execute_stage