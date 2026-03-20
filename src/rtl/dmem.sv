`timescale 1ns / 1ps

module dmem #(
    parameter int MEM_BYTES = 4096,
    parameter string INIT_FILE = ""
) (
    input  logic        clk,
    input  logic        mem_read,
    input  logic        mem_write,
    input  logic [31:0] addr,
    input  logic [31:0] wdata,
    input  logic [2:0]  funct3,
    output logic [31:0] rdata
);
    // Byte-addressable memory.
    logic [7:0] mem [0:MEM_BYTES-1];

    // Optional initialization from a hex file, otherwise clear to zero
    initial begin
        int i;
        for (i = 0; i < MEM_BYTES; i++) begin
            mem[i] = 8'h00;
        end
        if (INIT_FILE != "") begin
            $readmemh(INIT_FILE, mem);
        end
    end

    function automatic [7:0] read_byte(input logic [31:0] a);
        begin
            if (a < MEM_BYTES) begin
                read_byte = mem[a];
            end else begin
                read_byte = 8'h00;
            end
        end
    endfunction

    // Write logic: SB/SH/SW, little-endian.
    always_ff @(posedge clk) begin
        if (mem_write) begin
            case (funct3)
                3'b000: begin // SB
                    if (addr < MEM_BYTES) begin
                        mem[addr] <= wdata[7:0];
                    end
                end
                3'b001: begin // SH
                    if (addr < MEM_BYTES) begin
                        mem[addr] <= wdata[7:0];
                    end
                    if ((addr + 1) < MEM_BYTES) begin
                        mem[addr + 1] <= wdata[15:8];
                    end
                end
                3'b010: begin // SW
                    if (addr < MEM_BYTES) begin
                        mem[addr] <= wdata[7:0];
                    end
                    if ((addr + 1) < MEM_BYTES) begin
                        mem[addr + 1] <= wdata[15:8];
                    end
                    if ((addr + 2) < MEM_BYTES) begin
                        mem[addr + 2] <= wdata[23:16];
                    end
                    if ((addr + 3) < MEM_BYTES) begin
                        mem[addr + 3] <= wdata[31:24];
                    end
                end
                default: begin
                end
            endcase
        end
    end

    // Read logic: LB/LH/LW/LBU/LHU, little-endian.
    always_comb begin
        logic [7:0]  b0;
        logic [7:0]  b1;
        logic [7:0]  b2;
        logic [7:0]  b3;
        logic [15:0] half;
        logic [31:0] word;

        b0 = read_byte(addr);
        b1 = read_byte(addr + 1);
        b2 = read_byte(addr + 2);
        b3 = read_byte(addr + 3);
        half = {b1, b0};
        word = {b3, b2, b1, b0};

        rdata = 32'h0000_0000;
        if (mem_read) begin
            case (funct3)
                3'b000: rdata = {{24{b0[7]}}, b0};      // LB
                3'b001: rdata = {{16{half[15]}}, half}; // LH
                3'b010: rdata = word;                   // LW
                3'b100: rdata = {24'h0, b0};            // LBU
                3'b101: rdata = {16'h0, half};          // LHU
                default: rdata = word;
            endcase
        end
    end

endmodule
