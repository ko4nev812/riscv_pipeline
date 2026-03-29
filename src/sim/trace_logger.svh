//------------------------------------------------------------------------------
// project:        RISC-V (SberLab Novosibirsk State University)                                                    
// package:        
//                                                                              
// description:    
//------------------------------------------------------------------------------

`ifndef TRAVE_LOGGER_SVH
`define TRAVE_LOGGER_SVH

`include "risc-v.svh"

//******************************************************************************
//******************************************************************************

string TEST_DIR = "C:/Users/User/10-RV-NSU/prj-main/rv-nsu/prg/uBench"; // TODO: use tcl generated names
string TEST_LST = "ub.lst";                                             // TODO: use tcl generated names


//------------------------------------------------------------------------------
interface cpu_if_t
(
    input logic clk,
    input logic rst,
    output logic rst_strobe,
    input risc_v_pkg::Addr_t  iaddr,
    input risc_v_pkg::Instr_t instr
);
endinterface : cpu_if_t

typedef virtual cpu_if_t cpu_vif_t;

//------------------------------------------------------------------------------
class TraceLogger;
    cpu_vif_t cpu_vif;
    int cnt_clk;
    string test_dir; 
    string test_array[];
    int MAX_CLK_CNT;

    //--------------------------------------------------------------------------
    function new(input cpu_vif_t cpu_vif_, input int max_clk_cnt_);
        cpu_vif = cpu_vif_;
        test_dir = TEST_DIR; // TODO: remove hardcoded 'test_dir'
        MAX_CLK_CNT = max_clk_cnt_;
        $display("=== TraceLogger new()");
    endfunction : new

    //--------------------------------------------------------------------------
    function void get_test_list();
        int idx;
        string str;
        integer fd;

        $display("%s", { test_dir, "/", TEST_LST });
        fd = $fopen({ test_dir, "/", TEST_LST },"r"); // TODO: check file open error
        idx = 0;
        while($fscanf(fd, "%s", str) > 0) begin
            test_array = new[idx+1](test_array);
            test_array[idx] = str;
            idx++;
        end    
        $fclose(fd);

        //--- debug
        for(idx = 0; idx < test_array.size(); idx++) begin
            $display("%d %s",idx+1, test_array[idx]);
        end    
    endfunction : get_test_list

    //--------------------------------------------------------------------------
    task run();
        string fname;
        int test_idx;

        //---
        $display("=== TraceLogger run() start");
        $timeformat(-9, 0, "", 10);
        get_test_list();

        //---
        cpu_vif.rst_strobe = 1'b0;
        wait(cpu_vif.rst == 0);

        fork
            for(test_idx = 0; test_idx < test_array.size(); test_idx++) begin
                fname = { test_dir, "/", test_array[test_idx] };
                $display("+++ test: %4d (%12s) started", test_idx+1, test_array[test_idx]);
                cpu_vif.rst_strobe = 1'b1;
                repeat (2) @(posedge cpu_vif.clk);
                $readmemh(fname, $root.rv_nsu_tb.cpu_system_duv.imem.mem, 0);             // TODO: remove hardcoded 'imem'
                $root.rv_nsu_tb.cpu_system_duv.cpu.rf_inst.regFile = '{ default: '0 };    // TODO: remove hardcoded 'regFile'
                repeat (8) @(posedge cpu_vif.clk);
                cpu_vif.rst_strobe = 1'b0;
                cnt_clk = 0;    

                //---
                forever begin
                    @(posedge cpu_vif.clk);
                    if(!cpu_vif.rst) begin
                        cnt_clk++;
                        $display("%t %6d %8x %8x %s", $realtime, cnt_clk, cpu_vif.iaddr, cpu_vif.instr, risc_v_pkg::disasm(cpu_vif.instr));
                        if(cnt_clk >= MAX_CLK_CNT) begin
                            $display("--- test: %4d finished, MAX_CLK_CNT reached\n", test_idx+1);
                            break;
                        end
                    end    
                end
                //---
            end    
        join
        $display("=== TraceLogger run() end");
    endtask : run

endclass : TraceLogger

`endif // TRAVE_LOGGER_SVH
