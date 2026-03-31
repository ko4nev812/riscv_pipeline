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

`define IMEM_OBJ_NAME $root.rv_nsu_tb.cpu_system_duv.imem.mem
`define RF_OBJ_NAME   $root.rv_nsu_tb.cpu_system_duv.cpu.rf_inst.regFile
`define RF_DBG_NUM    31

string TEST_DIR = "C:/Users/User/10-RV-NSU/prj-main/rv-nsu/prg/uBench"; // TODO: use tcl generated names
string TEST_LST = "ub.lst";                                             // TODO: use tcl generated names


//------------------------------------------------------------------------------
interface cpu_if_t
(
    input logic clk,
    input logic rst,
    output logic rst_strobe,
    input risc_v_pkg::Addr_t  iaddr,
    input risc_v_pkg::Instr_t instr,
    output string test_name
);
endinterface : cpu_if_t

typedef virtual cpu_if_t cpu_vif_t;

typedef enum int {
    TEST_RUN  = 0,
    TEST_PASS = 1,
    TEST_FAIL = 2
} Test_Result_t;
//=== ALU

//------------------------------------------------------------------------------
class TraceLogger;
    cpu_vif_t cpu_vif;
    int instr_cnt;
    string test_dir; 
    string test_array[];
    logic standalone_test;
    int max_instr_num;

    //--------------------------------------------------------------------------
    function new(input cpu_vif_t cpu_vif_, input int max_instr_num_, input logic standalone_test_);
        cpu_vif = cpu_vif_;
        test_dir = TEST_DIR; // TODO: remove hardcoded 'test_dir'
        max_instr_num = max_instr_num_;
        cpu_vif.test_name = "no_test";
        standalone_test = standalone_test_;
        $display("=== TraceLogger new()");
    endfunction : new

    //--------------------------------------------------------------------------
    function void load_imem(input string fname);
        $readmemh(fname, `IMEM_OBJ_NAME, 0);
    endfunction : load_imem

    //--------------------------------------------------------------------------
    function void init_RF();
        `RF_OBJ_NAME = '{ default: '0 };
    endfunction : init_RF

    //--------------------------------------------------------------------------
    function Test_Result_t test_stop_condition();
        int reg_val = `RF_OBJ_NAME[`RF_DBG_NUM];
        return Test_Result_t'(reg_val);
    endfunction : test_stop_condition

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
        Test_Result_t test_res;

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
                cpu_vif.test_name = test_array[test_idx];
                $display("+++ test: %4d (%12s) started", test_idx+1, cpu_vif.test_name);
                cpu_vif.rst_strobe = 1'b1;
                repeat (2) @(posedge cpu_vif.clk);
                load_imem(fname);
                init_RF();
                repeat (8) @(posedge cpu_vif.clk);
                cpu_vif.rst_strobe = 1'b0;
                instr_cnt = 0;    

                //---
                forever begin
                    @(posedge cpu_vif.clk);
                    if(!cpu_vif.rst) begin
                        instr_cnt++;
                        //$display("%t %6d %8x %8x %s", $realtime, instr_cnt, cpu_vif.iaddr, cpu_vif.instr, risc_v_pkg::disasm(cpu_vif.instr));
                        if(instr_cnt >= max_instr_num) begin
                            if(standalone_test) begin
                                $display("--- test: %4d (%s) FAIL, max_instr_num reached\n", test_idx+1, cpu_vif.test_name);
                            end else begin
                                $display("--- test: %4d (%s) finished, max_instr_num reached\n", test_idx+1, cpu_vif.test_name);
                            end    

                            break;
                        end

                        //---
                        if(standalone_test) begin : standalone_block
                            test_res = test_stop_condition();
                            if(test_res != TEST_RUN) begin
                                if(test_res == TEST_PASS) begin
                                    $display("--- test: %4d (%s) PASS\n", test_idx+1, cpu_vif.test_name);
                                end else begin
                                    $display("--- test: %4d (%s) FAIL, error_code: %02d\n", test_idx+1, cpu_vif.test_name, test_res);
                                end       
                                break;
                            end
                        end : standalone_block
                    end    
                end
                //---
            end    
        join
        $display("=== TraceLogger run() end");
    endtask : run

endclass : TraceLogger

`endif // TRAVE_LOGGER_SVH
