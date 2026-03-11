`timescale 1ns / 1ps

`include "risc-v.svh"

module ig_tb import risc_v_pkg::*;
();
    // `imm_hen` arguments
    Instr_t instr;
    Imm_type_t imm_type;
    Imm_t imm;

    // testbench variables
    integer error_count = 0;
    integer test_count = 0;

    imm_gen ig_instance (
        .instr (instr),
        .imm_type (imm_type),
        .imm (imm)
    );

    initial begin
        // 1. Simple ADDI positive immediate:
        //      - `imm` == 100
        instr = 32'b000001100100_10101_000_00101_0010011;
        imm_type = IMM_I_TYPE;
        #10;
        $display("Test 1. I-type ADDI positive: expected imm=100, got=%d %s",
                 ig_instance.imm, (ig_instance.imm == 100) ? "[PASS]" : "[FAIL]");

        // 2. ADDI negative immediate (sign-extended):
        //      - `imm` == -32 (0xFFFFFFE0)
        instr = 32'b111111100000_10101_000_00101_0010011;
        imm_type = IMM_I_TYPE;
        #10;
        $display("Test 2. I-type ADDI negative: expected imm=-32, got=%d %s",
                 ig_instance.imm, (ig_instance.imm == -32) ? "[PASS]" : "[FAIL]");

        // 3. I-type with max positive immediate (11-bit max):
        //      - `imm` == 2047
        instr = 32'b011111111111_10101_000_00101_0010011;
        imm_type = IMM_I_TYPE;
        #10;
        $display("Test 3. I-type max positive: expected imm=2047, got=%d %s",
                 ig_instance.imm, (ig_instance.imm == 2047) ? "[PASS]" : "[FAIL]");

        /// 4. S-type store with positive offset:
        //      - `imm` == 101
        instr = 32'b0000011_00100_10101_010_00101_0100011;
        imm_type = IMM_S_TYPE;
        #10;
        $display("Test 4. S-type SW positive: expected imm=101, got=%d %s",
                 ig_instance.imm, (ig_instance.imm == 101) ? "[PASS]" : "[FAIL]");

        // 5. S-type store with negative offset:
        //      - `imm` == -64
        instr = 32'b1111110_00000_10101_010_00000_0100011;
        imm_type = IMM_S_TYPE;
        #10;
        $display("Test 5. S-type SW negative: expected imm=-64, got=%d %s",
                 ig_instance.imm, (ig_instance.imm == -64) ? "[PASS]" : "[FAIL]");
        
        // 6. B-type branch with positive offset (even):
        //      - `imm` == 100
        instr = 32'b0_000011_10101_00001_000_0010_0_1100011;
        imm_type = IMM_B_TYPE;
        #10;
        $display("Test 6. B-type BEQ positive: expected imm=100, got=%d %s",
                 ig_instance.imm, (ig_instance.imm == 100) ? "[PASS]" : "[FAIL]");

        // 7. B-type branch with negative offset:
        //      - `imm` == -64
        instr = 32'b1_111110_10101_00001_000_0000_1_1100011;
        imm_type = IMM_B_TYPE;
        #10;
        $display("Test 7. B-type BEQ negative: expected imm=-64, got=%d %s",
                 ig_instance.imm, (ig_instance.imm == -64) ? "[PASS]" : "[FAIL]");
        
        // 8. U-type LUI with positive immediate:
        //      - `imm` == 0x12345000
        instr = 32'b00010010001101000101_01010_0110111;
        imm_type = IMM_U_TYPE;
        #10;
        $display("Test 8. U-type LUI: expected imm=0x%h, got=0x%h %s",
                 32'h12345000, ig_instance.imm, (ig_instance.imm == 32'h12345000) ? "[PASS]" : "[FAIL]");

        // 9. J-type JAL with positive offset:
        //      - `imm` == 1000
        instr = 32'b0_0111110100_0_00000000_01010_1101111;
        imm_type = IMM_J_TYPE;
        #10;
        $display("Test 9. J-type JAL positive: expected imm=1000, got=%d %s",
                 ig_instance.imm, (ig_instance.imm == 1000) ? "[PASS]" : "[FAIL]");

        // 10. R-type ADD (no immediate - should be 0):
        //      - `imm` == 0
        instr = 32'b0000000_00010_00001_000_01010_0110011;
        imm_type = IMM_NC;
        #10;
        $display("Test 10. R-type ADD (no imm): expected imm=0, got=%d %s",
                 ig_instance.imm, (ig_instance.imm == 0) ? "[PASS]" : "[FAIL]");

        $finish;
    end

endmodule : ig_tb