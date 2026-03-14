//------------------------------------------------------------------------------
//  project:       RISC-V (SberLab Novosibirsk State University)
//
//  modules:       rv_nsu_tb 
//
//  description:   
//------------------------------------------------------------------------------

`include "tb.svh"
`include "risc-v.svh"

//******************************************************************************
//******************************************************************************
module rv_nsu_tb import tb_pkg::*;
();

timeunit      1ns;
timeprecision 1ps;

//==============================================================================
parameter int CLK_PERIOD = 10;

//==============================================================================

//--- clock 
logic ref_clk = 0;

initial begin
    forever begin
        #(CLK_PERIOD/2) ref_clk = ~ref_clk;
    end
end

//--- simulation stop
initial begin
    #20000ns;
    $stop(2);
end

//==============================================================================

//------------------------------------------------------------------------------
cpu_system cpu_system_duv
(
    .ref_clk ( ref_clk ),
    `ifdef CFG_NAME_BASYS_3
        .led ()
    `endif
    //--------------------------------------------------------------------------
    `ifdef SYS_DEBUG_OUT
        ,
        .dbg_insn_addr   (),
        .dbg_insn_opcode (),
        .dbg_insn_funct3 (),
        .dbg_clk_vec     (),
        .dbg_pll_locked  ()
    `endif
);

endmodule : rv_nsu_tb

