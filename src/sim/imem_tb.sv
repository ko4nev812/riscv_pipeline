`include "tb.svh"

module imem_tb import tb_pkg::*;
();
    timeunit      1ns;
    timeprecision 1ps;
    
    int fail_count = 0;
    int pass_count = 0;
    
    logic [TEST_ADDR_WIDTH-1:0] addr;
    Instr_t instr;

    imem_sim_m #(
        .INIT_FILE(TEST_MEM_FILE),
        .ADDR_WIDTH(TEST_ADDR_WIDTH)
    ) dut (
        .addr(addr),
        .instr(instr)
    );

    function automatic bit check_value
    (
        input string  test_name,
        input Instr_t actual,
        input Instr_t expected,
        input logic [TEST_ADDR_WIDTH-1:0] addr
    );
        if (actual == expected) begin
            $display("[PASS] %0s: addr=0x%08h, got=0x%08h, expected=0x%08h", test_name, addr, actual, expected);
            return 0;
        end else begin
            $display("[FAIL] %0s: addr=0x%08h, got=0x%08h, expected=0x%08h", test_name, addr, actual, expected);
            return 1;
        end
    endfunction : check_value

    function automatic void create_test_mem_file
    (
        input string filename,
        input int    num_words
    );
        int fd;
        fd = $fopen(filename, "w");
        if (!fd) begin
            $error("Cannot create file: %s", filename);
            $fatal;
        end
        
        $display("Creating test memory file: %s with %0d words", filename, num_words);
        
        for (int i = 0; i < num_words; i++) begin
            Instr_t data;

            data = i * 32'h11010101;
            $fdisplay(fd, "%08h", data);
            $display("  Word[%0d] = 0x%08h", i, data);
        end
        
        $fclose(fd);
        $display("Test memory file created successfully");
    endfunction : create_test_mem_file
    
    initial begin
        create_test_mem_file(TEST_MEM_FILE, TEST_MEM_DEPTH);
    end

    task automatic test_sequential_read(
        ref   logic [TEST_ADDR_WIDTH-1:0] addr,
        ref   Instr_t instr,
        input int     num_words,
        ref   int     pass_count,
        ref   int     fail_count
    );
        $display("\n=== Starting Sequential Read Test ===");
        
        for (int i = 0; i < num_words; i++) begin
            Instr_t expected;
            bit err;
            expected = i * 32'h11010101;
            addr = i << 2;

            #2ns

            err = check_value(
                "sequential_read", 
                instr,
                expected, 
                addr
            );
            if (err == 0) begin
                pass_count += 1;
            end else begin
                fail_count += 1;
            end
        end
        
        $display("=== Sequential Read Test Completed ===");
    endtask : test_sequential_read

    task automatic test_random_read(
        ref   logic [TEST_ADDR_WIDTH-1:0] addr,
        ref   Instr_t instr,
        input int     num_words,
        ref   int     pass_count,
        ref   int     fail_count
    );
        $display("\n=== Starting Random Read Test ===");
        
        for (int i = 0; i < 4 * num_words; i++) begin
            Instr_t expected;
            int     index;
            bit     err;
            index = $urandom_range(0, num_words-1);
            addr = index << 2;

            expected = index * 32'h11010101;

            #2ns
            
            err = check_value(
                "random_read",
                instr,
                expected,
                addr
            );

            if (err == 0) begin
                pass_count += 1;
            end else begin
                fail_count += 1;
            end
        end
        
        $display("=== Random Read Test Completed ===");
    endtask : test_random_read

    task automatic test_cycle_read(
        ref   logic [TEST_ADDR_WIDTH-1:0] addr,
        ref   Instr_t instr,
        input int     num_words,
        ref   int     pass_count,
        ref   int     fail_count
    );
        $display("\n=== Starting Cycle Read Test ===");
        
        for (int i = 0; i < 2 * num_words; i++) begin
            Instr_t expected;
            bit err;
            expected = (i % num_words) * 32'h11010101;
            addr = i << 2;

            #2ns

            err = check_value(
                "cycle_read", 
                instr,
                expected, 
                addr
            );
            if (err == 0) begin
                pass_count += 1;
            end else begin
                fail_count += 1;
            end
        end
        
        $display("=== Cycle Read Test Completed ===");
    endtask : test_cycle_read
    
    initial begin
        int test_count;
        $display("\n=== IMEM Testbench Started ===");
        $display("Address width: %0d bites", TEST_ADDR_WIDTH);
        $display("Memory depth: %0d words", TEST_MEM_DEPTH);
        $display("Test file: %s", TEST_MEM_FILE);
        
        test_sequential_read(
            addr,
            instr,
            TEST_MEM_DEPTH,
            pass_count,
            fail_count
        );

        test_random_read(
            addr,
            instr,
            TEST_MEM_DEPTH,
            pass_count,
            fail_count
        );

        test_cycle_read(
            addr,
            instr,
            TEST_MEM_DEPTH,
            pass_count,
            fail_count
        );
        
        $display("\n=== TEST SUMMARY ===");
        test_count = pass_count + fail_count;
        $display("Total tests:  %0d", test_count);
        $display("Passed:       %0d", pass_count);
        $display("Failed:       %0d", fail_count);
        
        if (fail_count == 0) begin
            $display("\nAll tests PASSED!");
        end else begin
            $display("\n%0d tests FAILED", fail_count);
        end
        
        $display("\n=== IMEM Testbench Finished ===");
        $finish;
    end
    
endmodule