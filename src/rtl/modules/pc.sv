//`timescale 1ns / 1ps

module program_counter
#(
    parameter int  WIDTH = 32,
    parameter logic [WIDTH-1:0] PC_START_ADDR = '0
)
(
    input  logic clk,
    input  logic rst, // active high
    input  logic br_taken,
    input  logic [WIDTH-1:0] pc_br,
    output logic [WIDTH-1:0] pc
);

    timeunit      1ns;
    timeprecision 1ps;

    logic [WIDTH-1:0] assign_pc;

    always_comb begin
        if (br_taken) begin
            assign_pc = pc_br;
        end else begin
            assign_pc = pc + 4;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            pc <= PC_START_ADDR;
        end else begin
            pc <= assign_pc;
        end
    end
endmodule : program_counter
