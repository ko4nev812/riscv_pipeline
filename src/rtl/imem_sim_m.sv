`include "risc-v.svh"

module imem_sim_m import risc_v_pkg::*;
        #(
            parameter INIT_FILE  = "",
            parameter ADDR_WIDTH = IMEM_ADDR_WIDTH
        )
(
    input  logic [ADDR_WIDTH-1:0] addr,
    output Instr_t    instr
);
    
    localparam MEM_DEPTH = 2 ** (ADDR_WIDTH-2);

    Instr_t mem[0:MEM_DEPTH-1];
    initial begin
        mem = '{default: '0};
        if (INIT_FILE != "") begin
             $readmemh(INIT_FILE, mem, 0);
        end
    end
    
    assign instr = mem[addr[ADDR_WIDTH-1:2]];

endmodule

`ifdef SAMPLE
//******************************************************************************
//******************************************************************************
module distributed_rom_m
                #(
                   parameter int ADDR_WIDTH,
                   parameter int WORD_WIDTH,
                   parameter int ROM_SIZE = 2**ADDR_WIDTH,
                   parameter     INIT_FILE = ""  
                 )
(
    input  logic [ADDR_WIDTH-1:0] addr,
    output logic [WORD_WIDTH-1:0] data
);

//==============================================================================
//    Objects
//==============================================================================

(* rom_style="distributed" *)
logic [WORD_WIDTH-1:0] rom[ROM_SIZE];

//==============================================================================
//     Logic
//==============================================================================

//------------------------------------------------------------------------------
initial begin
    if(INIT_FILE != "") begin
        $readmemh(INIT_FILE, rom, 0);
    end
end

//------------------------------------------------------------------------------
assign data = rom[addr];

endmodule

`endif // SAMPLE

`ifdef IP
module ip_rom_m
                #(
                   parameter int ADDR_WIDTH,
                   parameter int WORD_WIDTH,
                   parameter int ROM_SIZE = 2**ADDR_WIDTH,
                   parameter     INIT_FILE = ""  
                 )
(
    input  logic [ADDR_WIDTH-1:0] addr,
    output logic [WORD_WIDTH-1:0] data
);
logic sys_clk;

blk_mem_sdp blk_mem_sdp_inst
(
// /* synthesis syn_black_box black_box_pad_pin="clka,ena,wea[0:0],addra[9:0],dina[31:0],clkb,enb,addrb[9:0],doutb[31:0]" */;
  
  //---
  .clka  ( sys_clk ),
  .ena   (    1'b0 ),
  .wea   (    1'b0 ),
  .addra (    '0   ),
  .dina  (    '0   ),

  //---
  .clkb  ( sys_clk ),
  .enb   (    1'b1 ),
  .addrb ( addr    ),
  .doutb ( data    )
);

`endif // IP