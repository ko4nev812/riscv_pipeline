//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

`include "risc-v.svh"

//------------------------------------------------------------------------------
module imem_lutram import risc_v_pkg::*;
        #(
            parameter INIT_FILE  = "",
            parameter ADDR_WIDTH = (IMEM_ADDR_BYTE_WIDTH - BYTE_ADDR_WIDTH)
        )
(
    input  logic [ADDR_WIDTH-1:0] addr,
    output Instr_t    instr
);
    
    localparam MEM_DEPTH = 2 ** ADDR_WIDTH;

    Instr_t mem[0:MEM_DEPTH-1];
    initial begin
        mem = '{default: '0};
        if (INIT_FILE != "") begin
             $readmemh(INIT_FILE, mem, 0);
        end
    end
    
    assign instr = mem[addr];

endmodule : imem_lutram

//------------------------------------------------------------------------------
module imem_bram import risc_v_pkg::*;
        #(
            parameter INIT_FILE  = "",
            parameter ADDR_WIDTH = (IMEM_ADDR_BYTE_WIDTH - BYTE_ADDR_WIDTH)
        )
(
    input  logic                  clk,
    input  logic [ADDR_WIDTH-1:0] addr,
    output Instr_t                instr
);

dual_port_mem_m
        #(
            .INIT_FILE        ( INIT_FILE ),
            .PORTA_ADDR_WIDTH ( ADDR_WIDTH ),
            .PORTB_ADDR_WIDTH ( ADDR_WIDTH )
        )
imem_inst        
(
    //--- port A
    .clka  ( clk          ),
    .ena   ( 1'b1         ),
    .wea   ( 4'b0         ),
    .addra ( addr         ),
    .dina  ( '0           ), 
    .douta ( instr        ),
    //--- port B not connected
    .clkb  ( clk          ),
    .enb   ( 1'b0         ),
    .web   ( 4'b0         ),
    .addrb ( '0           ),
    .dinb  ( '0           ),
    .doutb (              )
);

endmodule : imem_bram




