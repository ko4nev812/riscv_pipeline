`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/22/2025 09:49:07 PM
// Design Name: 
// Module Name: pc_TB
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module TB_program_counter;
    parameter int WIDTH = 32;
    parameter logic [WIDTH-1:0] PC_START_ADDR = 32'h1000_0000;
    
    logic clk, rst, br_taken;
    logic [WIDTH-1:0] pc, pc_br;
    logic [WIDTH-1:0] BR_VALUE = 32'h1234_5678;
    
    // clk
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100 MHz clock
    end
    
    program_counter #(
        .WIDTH(WIDTH),
        .PC_START_ADDR(PC_START_ADDR)
    ) DUT (
        .*
    );
    
    initial begin
        // 1. Init
        rst = 0;
        br_taken = 0;
    
        // 2. Reset test
        @(posedge clk);
        #2;
        rst = 1;
        repeat(3) @(posedge clk);
        #2;
        assert (pc == PC_START_ADDR) else $error("reset failed: pc=0x%h, expected=0x%h", pc, PC_START_ADDR);
        rst = 0;
    
        // 3. Increment test
        @(posedge clk);
        #2;
        for (int i = 1; i < 10; i++) begin
            logic [WIDTH-1:0] expected_pc = PC_START_ADDR + i * 4;
            assert (pc == expected_pc) else $error("Cycle %0d: pc=0x%h, expected=0x%h", i, pc, expected_pc);
            @(posedge clk);
            #2;
        end
    
        // 4. Reset during increment
        @(posedge clk);
        #2;
        rst = 1;
        @(posedge clk);
        #2;
        assert (pc == PC_START_ADDR) else $error("Reset during op failed");
        rst = 0;
    
        // 5. Set branch value
        @(posedge clk);
        #2;
        br_taken = 1;
        pc_br = BR_VALUE;
        @(posedge clk);
        #2;
        assert (pc == BR_VALUE) else $error("branch set failed: pc=0x%h, expected=0x%h", pc, BR_VALUE);
        br_taken = 0;

        // 6. Set reset value and branch value at once
        @(posedge clk);
        #2;
        br_taken = 1;
        rst = 1;
        @(posedge clk);
        #2;
        assert (pc == PC_START_ADDR) else $error("Reset during branch set failed");

        // 7. Finishing simulation
        @(posedge clk);
        #2;
        $finish;
    end
     
endmodule // TB_program_counter_m
