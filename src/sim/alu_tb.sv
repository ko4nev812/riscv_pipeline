`include "risc-v.svh"

//==============================================================================
// Testcases description
//------------------------------------------------------------------------------
//                                     ADD
// For two's complement there is no difference between signed and unsigned add
// 
// 01. 0 + 0
// 02. 0 + a
// 03. a + b, b = -a
// 04. 0b011...1111 + 1
// 05. 0b011...1111 + 0b011...1111
// 06. 0b111...1111 + 0
// 07. 0b111...1111 + 1
// 08. 0b111...1111 + 0b111...1111
// 09. rand + rand
//------------------------------------------------------------------------------
//                                     SUB
// For two's complement there is no difference between signed and unsigned sub
// 01. 0 - 0
// 02. a - 0
// 03. 0 - a
// 04. a - a
// 05. a - (-a)
// 06. 0b111...1111 - 1
// 07. 0b111...1110 - 0b111...1111
// 08. rand - rand
//------------------------------------------------------------------------------
//                                     AND
// 01. 0 & 0
// 02. 0 & 1
// 03. 1 & 0
// 04. 1 & 1
// 05. 0b111...1111 & 1
// 06. 0b111...1111 & 0
// 07. 0b111...1111 & 0b111...1110
// 08. rand & rand
//------------------------------------------------------------------------------
//                                     OR
// 01. 0 | 0
// 02. 0 | 1
// 03. 1 | 0
// 04. 1 | 1
// 05. 0b111...1111 | 1
// 06. 0b111...1111 | 0
// 07. 0b111...1111 | 0b111...1110
// 08. rand | rand
//------------------------------------------------------------------------------
//                                     XOR
// 01. 0 ^ 0
// 02. 0 ^ 1
// 03. 1 ^ 0
// 04. 1 ^ 1
// 05. 0b111...1111 ^ 1
// 06. 0b111...1111 ^ 0
// 07. 0b111...1111 ^ 0b111...1110
// 08. rand ^ rand
//==============================================================================
//                                  SLT / SLTU
// 01. 0 < 1
// 02. -1 < 0
// 03. 1 < 1
// 04. 1 < -1
// 05. -1 < 1
// 06. 0b111...1111 < 0b111...1110
// 07. rand ^ rand
//==============================================================================
//                                    JALR
// 01. 0, 4
// 02. 4, 4
// 03. 32, 16
// 04. 32, 5
// 05. 1, 1
// 06. 15, 4
// 07. rand ^ rand
//==============================================================================

module alu_tb_simple import risc_v_pkg::*;
();

timeunit      1ns;
timeprecision 1ps;

//==============================================================================
//    Settings
//==============================================================================

parameter int N = 32;

//==============================================================================
//    Tasks
//==============================================================================

task automatic check_add(
    logic [N-1:0] a,
    logic [N-1:0] b,
    logic [N-1:0] res,
    ref bit       err

);
    assert( (a+b) == res ) else begin
    err = 1;
    $display("Mismatch (add): a=%x, b=%x, res=%x, ref_res=%x", a, b, res, (a+b));
    end
endtask

task automatic check_sub(
    logic [N-1:0] a,
    logic [N-1:0] b,
    logic [N-1:0] res,
    ref bit       err

);
    assert( (a-b) == res ) else begin
    err = 1;
    $display("Mismatch (sub): a=%x, b=%x, res=%x, ref_res=%x", a, b, res, (a-b));
    end
endtask

task automatic check_and(
    logic [N-1:0] a,
    logic [N-1:0] b,
    logic [N-1:0] res,
    ref bit       err

);
    assert( (a&b) == res ) else begin
    err = 1;
    $display("Mismatch (and): a=%x, b=%x, res=%x, ref_res=%x", a, b, res, (a&b));
    end
endtask

task automatic check_or(
    logic [N-1:0] a,
    logic [N-1:0] b,
    logic [N-1:0] res,
    ref bit       err

);
    assert( (a|b) == res ) else begin
    err = 1;
    $display("Mismatch (or): a=%x, b=%x, res=%x, ref_res=%x", a, b, res, (a|b));
    end
endtask

task automatic check_xor(
    logic [N-1:0] a,
    logic [N-1:0] b,
    logic [N-1:0] res,
    ref bit       err

);
    assert( (a^b) == res ) else begin
    err = 1;
    $display("Mismatch (xor): a=%x, b=%x, res=%x, ref_res=%x", a, b, res, (a^b));
    end
endtask

task automatic check_slt(
    logic [N-1:0] a,
    logic [N-1:0] b,
    logic [N-1:0] res,
    ref bit       err

);

    logic [N-1:0] ref_res = signed'(a) < signed'(b);
    assert( ref_res == res ) else begin
    err = 1;
    $display("Mismatch (slt): a=%x, b=%x, res=%x, ref_res=%x", a, b, res, ref_res);
    end
endtask

task automatic check_sltu(
    logic [N-1:0] a,
    logic [N-1:0] b,
    logic [N-1:0] res,
    ref bit       err

);
    assert( (a < b) == res ) else begin
    err = 1;
    $display("Mismatch (sltu): a=%x, b=%x, res=%x, ref_res=%x", a, b, res, (a<b));
    end
endtask

task automatic check_bypass(
    logic [N-1:0] a,
    logic [N-1:0] b,
    logic [N-1:0] res,
    ref bit       err

);
    assert( b == res ) else begin
    err = 1;
    $display("Mismatch (bypass): a=%x, b=%x, res=%x, ref_res=%x", a, b, res, b);
    end
endtask

task automatic check_jalr(
    logic [N-1:0] a,
    logic [N-1:0] b,
    logic [N-1:0] res,
    ref bit       err

);

    logic [N-1:0] ref_res = a + b;
    ref_res[0] = 0;
    assert( ref_res == res ) else begin
    err = 1;
    $display("Mismatch (slt): a=%x, b=%x, res=%x, ref_res=%x", a, b, res, ref_res);
    end
endtask

//==============================================================================
//    Objects
//==============================================================================

ALU_SEL_t     sel;
logic [N-1:0] a;
logic [N-1:0] b;
logic [N-1:0] res;

//==============================================================================
//    Test values
//==============================================================================

parameter int RANDOM_CHECKS_COUNT = 8;

parameter int ADD_CHECKS_COUNT = 8;
logic [N-1:0] add_a_values [0:ADD_CHECKS_COUNT-1] = '{ 0, 0, -5, 32'b0111_1111_1111_1111_1111_1111_1111_1111, 32'b0111_1111_1111_1111_1111_1111_1111_1111, 32'b1111_1111_1111_1111_1111_1111_1111_1111, 32'b1111_1111_1111_1111_1111_1111_1111_1111, 32'b1111_1111_1111_1111_1111_1111_1111_1111 };
logic [N-1:0] add_b_values [0:ADD_CHECKS_COUNT-1] = '{ 0, 5, 5, 1, 32'b0111_1111_1111_1111_1111_1111_1111_1111, 0, 1, 32'b1111_1111_1111_1111_1111_1111_1111_1111 };

parameter int SUB_CHECKS_COUNT = 7;
logic [N-1:0] sub_a_values [0:SUB_CHECKS_COUNT-1] = '{ 0, 5, 0, 5, 8, 32'b1111_1111_1111_1111_1111_1111_1111_1111, 32'b1111_1111_1111_1111_1111_1111_1111_1111 };
logic [N-1:0] sub_b_values [0:SUB_CHECKS_COUNT-1] = '{ 0, 0, 5, 5, -8, 1, 32'b1111_1111_1111_1111_1111_1111_1111_1111 };

parameter int LOGIC_CHECKS_COUNT = 7;
logic [N-1:0] logic_a_values [0:LOGIC_CHECKS_COUNT-1] = '{ 0, 0, 1, 1, 32'b1111_1111_1111_1111_1111_1111_1111_1111, 32'b1111_1111_1111_1111_1111_1111_1111_1111, 32'b1111_1111_1111_1111_1111_1111_1111_1111 };
logic [N-1:0] logic_b_values [0:LOGIC_CHECKS_COUNT-1] = '{ 0, 1, 0, 1, 1, 0, 32'b1111_1111_1111_1111_1111_1111_1111_1110 };

parameter int SLT_CHECKS_COUNT = 6;
logic [N-1:0] slt_a_values [0:SLT_CHECKS_COUNT-1] = '{ 0, -1, 1, 1, -1, 32'b1111_1111_1111_1111_1111_1111_1111_1111 };
logic [N-1:0] slt_b_values [0:SLT_CHECKS_COUNT-1] = '{ 1, 0, 1, -1, 1, 32'b1111_1111_1111_1111_1111_1111_1111_1110 };

parameter int JALR_CHECKS_COUNT = 6;
logic [N-1:0] jalr_a_values [0:JALR_CHECKS_COUNT-1] = '{ 0, 4, 32, 32, 1, 15 };
logic [N-1:0] jalr_b_values [0:JALR_CHECKS_COUNT-1] = '{ 4, 4, 16, 5, 1, 4 };

parameter int BYPASS_RAND_CHECKS_COUNT = 4;

initial begin
    automatic bit err_flag = 0;

    sel = ALU_ADD;
    for(int i = 0; i < ADD_CHECKS_COUNT; i++) begin
        a = add_a_values[i];
        b = add_b_values[i];
        #10;
        check_add(a, b, res, err_flag);     
    end
    for(int i = 0; i < RANDOM_CHECKS_COUNT; i++) begin
        a = $urandom_range(0, (1 << N) - 1);
        b = $urandom_range(0, (1 << N) - 1);
        #10;
        check_add(a, b, res, err_flag);      
    end

    sel = ALU_SUB;
    for(int i = 0; i < SUB_CHECKS_COUNT; i++) begin
        a = sub_a_values[i];
        b = sub_b_values[i];
        #10;
        check_sub(a, b, res, err_flag);     
    end
    for(int i = 0; i < RANDOM_CHECKS_COUNT; i++) begin
        a = $urandom_range(0, (1 << N) - 1);
        b = $urandom_range(0, (1 << N) - 1);
        #10;
        check_sub(a, b, res, err_flag);      
    end

    for(int i = 0; i < LOGIC_CHECKS_COUNT; i++) begin
        sel = ALU_AND;
        a = logic_a_values[i];
        b = logic_b_values[i];
        #10;
        check_and(a, b, res, err_flag);
        sel = ALU_OR;
        #10;
        check_or(a, b, res, err_flag);
        sel = ALU_XOR;
        #10;
        check_xor(a, b, res, err_flag);
    end
    for(int i = 0; i < RANDOM_CHECKS_COUNT; i++) begin
        sel = ALU_AND;
        a = $urandom_range(0, (1 << N) - 1);
        b = $urandom_range(0, (1 << N) - 1);
        #10;
        check_and(a, b, res, err_flag);
        sel = ALU_OR;
        #10;
        check_or(a, b, res, err_flag);
        sel = ALU_XOR;
        #10;
        check_xor(a, b, res, err_flag);   
    end

    sel = ALU_SLT;
    for(int i = 0; i < SLT_CHECKS_COUNT; i++) begin
        a = slt_a_values[i];
        b = slt_b_values[i];
        #10;
        check_slt(a, b, res, err_flag);     
    end
    for(int i = 0; i < RANDOM_CHECKS_COUNT; i++) begin
        a = $urandom_range(0, (1 << N) - 1);
        b = $urandom_range(0, (1 << N) - 1);
        #10;
        check_slt(a, b, res, err_flag);      
    end

    sel = ALU_SLTU;
    for(int i = 0; i < SLT_CHECKS_COUNT; i++) begin
        a = slt_a_values[i];
        b = slt_b_values[i];
        #10;
        check_sltu(a, b, res, err_flag);     
    end
    for(int i = 0; i < RANDOM_CHECKS_COUNT; i++) begin
        a = $urandom_range(0, (1 << N) - 1);
        b = $urandom_range(0, (1 << N) - 1);
        #10;
        check_sltu(a, b, res, err_flag);      
    end

    sel = ALU_JALR;
    for(int i = 0; i < JALR_CHECKS_COUNT; i++) begin
        a = jalr_a_values[i];
        b = jalr_b_values[i];
        #10;
        check_jalr(a, b, res, err_flag);     
    end
    for(int i = 0; i < RANDOM_CHECKS_COUNT; i++) begin
        a = $urandom_range(0, (1 << N) - 1);
        b = $urandom_range(0, (1 << N) - 1);
        #10;
        check_jalr(a, b, res, err_flag);      
    end
 
    sel = ALU_BYP;
    for(int i = 0; i < BYPASS_RAND_CHECKS_COUNT; i++) begin
        a = $urandom_range(0, (1 << N) - 1);
        b = $urandom_range(0, (1 << N) - 1);
        #10;
        check_bypass(a, b, res, err_flag);      
    end

    // end
    a = 'x;
    b = 'x;
    #10;
    if(err_flag == 0) begin
        $display("SUCCESS");
    end  
    $stop(2);
end

//==============================================================================
//    Instances
//==============================================================================

alu_m alu      
(
    .sel ( sel ),
    .a   ( a   ),
    .b   ( b   ),
    .res ( res )  
);

endmodule : alu_tb_simple