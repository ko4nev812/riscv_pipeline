//------------------------------------------------------------------------------
//  project:       RISC-V (SberLab Novosibirsk State University)
//
//  modules:       rv_nsu_tb 
//
//  description:   
//------------------------------------------------------------------------------

`include "tb.svh"
`include "sha3_256.svh"
`include "trace_logger.svh"
`include "risc-v.svh"

//`define TRACE_LOGGER_ENA


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
`ifdef TRACE_LOGGER_ENA
    #1000us;
`else
    #20us;
`endif  
    $stop(0);
end

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//--- Trace Logger process

`ifdef TRACE_LOGGER_ENA
parameter logic STANDALONE_TEST = 1;
parameter int MAX_INSTR_NUM = 200;

string test_name;
risc_v_pkg::str_t  str_test_name;

cpu_if_t cpu_if
(
    .clk        ( cpu_system_duv.cpu_clk    ),
    .rst        ( cpu_system_duv.rst        ),
    .rst_strobe ( cpu_system_duv.rst_strobe ),
    .iaddr      ( cpu_system_duv.imem_addr  ),
    .instr      ( cpu_system_duv.instr      ),
    .test_name  ( test_name                 )
);

assign str_test_name = risc_v_pkg::string2str(test_name);

initial begin
    static TraceLogger tl = new(cpu_if, MAX_INSTR_NUM, STANDALONE_TEST);
    tl.run();
    $stop(0);
end
`endif  // TRACE_LOGGER_ENA
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

//==============================================================================

//------------------------------------------------------------------------------
cpu_system cpu_system_duv
(
    .ref_clk ( ref_clk ),
    `ifdef CFG_NAME_BASYS_3
        .led ()
    `endif
);

endmodule : rv_nsu_tb

