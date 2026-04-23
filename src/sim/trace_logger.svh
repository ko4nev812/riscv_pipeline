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

`ifndef IMEM_BRAM
    `define IMEM_OBJ_NAME $root.rv_nsu_tb.cpu_system_duv.imem_inst.mem
`else    
    `define IMEM_OBJ_NAME $root.rv_nsu_tb.cpu_system_duv.imem_inst.imem_inst.tdp_bram_inst.ram
`endif    
`define DMEM_OBJ_NAME $root.rv_nsu_tb.cpu_system_duv.dmem_inst.tdp_bram_inst.ram
`define RF_OBJ_NAME   $root.rv_nsu_tb.cpu_system_duv.cpu.rf_inst.regFile
`define RF_DBG_NUM    31

string TEST_DIR = "C:/Users/User/10-RV-NSU/prj-main/rv-nsu/prg/uBench/hex"; // TODO: use tcl generated names
string TEST_LST = "ub.lst";                                                 // TODO: use tcl generated names


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
    const int NREGS = 32;
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
        `IMEM_OBJ_NAME = '{ default: '0 };
        $readmemh(fname, `IMEM_OBJ_NAME, 0);
    endfunction : load_imem

    //--------------------------------------------------------------------------
    function void init_RF();
        `RF_OBJ_NAME = '{ default: '0 };
    endfunction : init_RF

    //--------------------------------------------------------------------------
    function void zero_DMEM();
        `DMEM_OBJ_NAME = '{ default: '0 };
    endfunction : zero_DMEM

    //--------------------------------------------------------------------------
    function int get_reg(input int reg_idx);
        return  `RF_OBJ_NAME[reg_idx];
    endfunction : get_reg

    //--------------------------------------------------------------------------
    function Test_Result_t test_stop_condition();
        int reg_val = get_reg(`RF_DBG_NUM);
        return Test_Result_t'(reg_val);
    endfunction : test_stop_condition

    //--------------------------------------------------------------------------
    function string get_test_name(input string fname);
        int i = 0;
        for(i = 0; i < fname.len(); i++) begin
            if(fname[i] == ".")
                break;
        end    
        return fname.substr(0, i-1);
    endfunction : get_test_name

    //--------------------------------------------------------------------------
    function void print_header(input integer fd);
        int i;
        $fwrite(fd,"model_time, instr_count, instr_addr, instr_code, disasm");
        for(i = 0; i < NREGS; i++) begin
            $fwrite(fd,", x%1d", i);
        end
        $fwrite(fd,"\n");    
    endfunction : print_header

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
        string test_file_full_name;
        string test_file_short_name;
        string test_base_name;
        int test_idx;
        Test_Result_t test_res;
        integer fd_res;
        int i;
        int pass_test_num;
        int failed_test_num;
        int time_expired_test_num;

        failed_test_num = 0;
        time_expired_test_num = 0;

        //---
        $display("=== TraceLogger run() start");
        $timeformat(-9, 0, "", 10);
        get_test_list();

        //---
        cpu_vif.rst_strobe = 1'b0;
        wait(cpu_vif.rst == 0);

        fork
            for(test_idx = 0; test_idx < test_array.size(); test_idx++) begin
                test_file_short_name = test_array[test_idx];
                test_base_name = get_test_name(test_file_short_name);
                test_file_full_name = { test_dir, "/", test_file_short_name };
                fd_res = $fopen({ test_dir, "/res/", test_base_name, ".csv" },"w");
                print_header(fd_res);
                cpu_vif.test_name = test_file_short_name;
                $display("+++ test: %4d (%12s) started", test_idx+1, cpu_vif.test_name);
                cpu_vif.rst_strobe = 1'b1;
                repeat (2) @(posedge cpu_vif.clk);
                load_imem(test_file_full_name);
                init_RF();
                zero_DMEM();
                repeat (8) @(posedge cpu_vif.clk);
                cpu_vif.rst_strobe = 1'b0;
                instr_cnt = 0;    

                //---
                forever begin
                    @(posedge cpu_vif.clk);
                    if(!cpu_vif.rst) begin
                        instr_cnt++;
                        //--- TODO: make function
                        $fwrite(fd_res,"%t %6d %8x %8x \"%s\"", $realtime, instr_cnt, cpu_vif.iaddr, cpu_vif.instr, risc_v_pkg::disasm(cpu_vif.instr));
                        for(i = 0; i < NREGS; i++) begin
                            $fwrite(fd_res,", %8x", get_reg(i));
                        end
                        $fwrite(fd_res,"\n");    
                        //---
                        if(instr_cnt >= max_instr_num) begin
                            if(standalone_test) begin
                                $display("--- test: %4d (%s) FAIL, max_instr_num reached\n", test_idx+1, cpu_vif.test_name);
                                time_expired_test_num++;
                            end else begin
                                $display("--- test: %4d (%s) finished, max_instr_num reached\n", test_idx+1, cpu_vif.test_name);
                            end    

                            break;
                        end

                        if(standalone_test) begin : standalone_block
                            test_res = test_stop_condition();
                            if(test_res != TEST_RUN) begin
                                if(test_res == TEST_PASS) begin
                                    $display("--- test: %4d (%s) PASS\n", test_idx+1, cpu_vif.test_name);
                                    pass_test_num++;
                                end else begin
                                    $display("--- test: %4d (%s) FAIL, error_code: %02d\n", test_idx+1, cpu_vif.test_name, test_res);
                                    failed_test_num++;
                                end       
                                break;
                            end
                        end : standalone_block
                    end    
                end
                //---
                $fclose(fd_res);
            end    
        join
        cpu_vif.rst_strobe = 1'b1;
        cpu_vif.test_name = "finish";
        repeat (20) @(posedge cpu_vif.clk);
        $display("=== TraceLogger run() end");
        $display("");
        $display("--- Test num:            %4d", test_array.size());
        if(standalone_test) begin
            $display(" Test passed:            %4d", pass_test_num);
            $display(" Test failed:            %4d", failed_test_num);
            $display(" Test with time expired: %4d", time_expired_test_num);
        end
        $display("");
    endtask : run

endclass : TraceLogger

`endif // TRAVE_LOGGER_SVH
