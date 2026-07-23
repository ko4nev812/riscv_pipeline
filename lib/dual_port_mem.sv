//------------------------------------------------------------------------------
//  project:       RISC-V (SberLab Novosibirsk State University)
//
//  modules:       dual_port_mem_m
//                 tdp_ram_m (when DUAL_PORT_BRAM_MEM_IP undefined) 
//
//  description:   True dual-port block RAM with per-byte write enables.
//                 Supports read-first (RF) and write-first (WF) modes
//                 independently for each port.
//
//------------------------------------------------------------------------------

`ifdef DUAL_PORT_BRAM_MEM_IP
`undef DUAL_PORT_BRAM_MEM_IP
`endif // DUAL_PORT_BRAM_MEM_IP

//******************************************************************************
//******************************************************************************
module dual_port_mem_m
                #(
                   parameter     INIT_FILE = "",
                   parameter int PORTA_ADDR_WIDTH    = 12,
                   parameter int PORTA_DATA_BYTE_NUM = 4,
                   parameter int PORTB_ADDR_WIDTH    = 12,
                   parameter int PORTB_DATA_BYTE_NUM = 4
                 )
(
    //--- port A
    input  logic                             clka,
    
    input  logic                             ena,
    input  logic [PORTA_DATA_BYTE_NUM-1:0]   wea,
    input  logic [PORTA_ADDR_WIDTH-1:0]      addra,
    input  logic [PORTA_DATA_BYTE_NUM*8-1:0] dina,
    output logic [PORTA_DATA_BYTE_NUM*8-1:0] douta,
    
    //--- port B
    input  logic                             clkb,
    
    input  logic                             enb,
    input  logic [PORTB_DATA_BYTE_NUM-1:0]   web,
    input  logic [PORTB_ADDR_WIDTH-1:0]      addrb,
    input  logic [PORTB_DATA_BYTE_NUM*8-1:0] dinb,
    output logic [PORTB_DATA_BYTE_NUM*8-1:0] doutb
);

//==============================================================================
//    Instances
//==============================================================================

`ifdef DUAL_PORT_BRAM_MEM_IP

tdp_bram_ip tdp_bram_inst
(
    //--- port A
    .clka     ( clka  ),
    .ena      ( ena   ),
    .wea      ( wea   ),
    .addra    ( addra ),
    .dina     ( dina  ),
    .douta    ( douta ),

    //--- port B
    .clkb     ( clkb  ),
    .enb      ( enb   ),
    .web      ( web   ),
    .addrb    ( addrb ),
    .dinb     ( dinb  ),
    .doutb    ( doutb )
);

`else  // DUAL_PORT_BRAM_MEM_IP

//------------------------------------------------------------------------------
initial begin
    if(PORTA_ADDR_WIDTH != PORTB_ADDR_WIDTH) begin
        $fatal(2, "[E] In module (%m) - bad parameters (case 1)\n");
    end
    if(PORTA_DATA_BYTE_NUM != PORTB_DATA_BYTE_NUM) begin
        $fatal(2, "[E] In module (%m) - bad parameters (case 2)\n");
    end
end

//------------------------------------------------------------------------------
tdp_ram_m
            #(
                 .INIT_FILE  ( INIT_FILE           ),
                 .ADDR_WIDTH ( PORTA_ADDR_WIDTH    ),
                 .COL_WIDTH  ( 8                   ),
                 .COL_NUM    ( PORTA_DATA_BYTE_NUM ),
                 .PORTA_MODE ( "RF"                ),
                 .PORTB_MODE ( "WF"                )
             )
tdp_bram_inst
(
    //--- port A
    .clka     ( clka  ),
    .ena      ( ena   ),
    .wea      ( wea   ),
    .addra    ( addra ),
    .dina     ( dina  ),
    .douta    ( douta ),

    //--- port B
    .clkb     ( clkb  ),
    .enb      ( enb   ),
    .web      ( web   ),
    .addrb    ( addrb ),
    .dinb     ( dinb  ),
    .doutb    ( doutb )
);


`endif // DUAL_PORT_BRAM_MEM_IP

endmodule : dual_port_mem_m

//******************************************************************************
//******************************************************************************

`ifndef DUAL_PORT_BRAM_MEM_IP

module automatic tdp_ram_m
                #(
                   parameter     INIT_FILE   = "",
                   parameter int ADDR_WIDTH  = 12,
                   parameter int COL_WIDTH   =  8,
                   parameter int COL_NUM     =  4,
                   parameter     PORTA_MODE  = "RF",
                   parameter     PORTB_MODE  = "RF",
                   
                   localparam type ColSel_t = logic [COL_NUM-1:0],
                   localparam type Addr_t   = logic [ADDR_WIDTH-1:0],
                   localparam type Data_t   = logic [COL_WIDTH*COL_NUM-1:0]
                 )
(
    //--- port A
    input  logic     clka,
    
    input  logic     ena,
    input  ColSel_t  wea,
    input  Addr_t    addra,
    input  Data_t    dina,
    output Data_t    douta,
    
    //--- port B
    input  logic     clkb,
    
    input  logic     enb,
    input  ColSel_t  web,
    input  Addr_t    addrb,
    input  Data_t    dinb,
    output Data_t    doutb
);

//==============================================================================
//    Settings
//==============================================================================

localparam RAM_SIZE = 2**ADDR_WIDTH;

//==============================================================================
//    Objects
//==============================================================================

(* ram_style="block" *)
Data_t ram[RAM_SIZE] = '{ default: 'x };

//==============================================================================
//     Logic
//==============================================================================

//------------------------------------------------------------------------------
initial begin
    if(INIT_FILE != "") begin
        $readmemh(INIT_FILE, ram, 0);
    end
end

genvar i;

//------------------------------------------------------------------------------
//    port A operation
//------------------------------------------------------------------------------
generate
    //--- read-first mode
    if(PORTA_MODE == "RF") begin
        for(i = 0; i < COL_NUM; i++) begin
            always_ff @(posedge clka) begin
                if(ena) begin
                    if(wea[i]) begin
                        ram[addra][i*COL_WIDTH +: COL_WIDTH] <= dina[i*COL_WIDTH +: COL_WIDTH];
                    end
                    douta[i*COL_WIDTH +: COL_WIDTH] <= ram[addra][i*COL_WIDTH +: COL_WIDTH] ;
                end
            end
        end
    end
    //--- write-first mode
    if(PORTA_MODE == "WF") begin
        for(i = 0; i < COL_NUM; i++) begin
            always_ff @(posedge clka) begin
                if(ena) begin
                    if(wea[i]) begin
                        ram[addra][i*COL_WIDTH +: COL_WIDTH] <= dina[i*COL_WIDTH +: COL_WIDTH];
                        douta[i*COL_WIDTH +: COL_WIDTH]      <= dina[i*COL_WIDTH +: COL_WIDTH] ;
                    end else begin
                        douta[i*COL_WIDTH +: COL_WIDTH]      <= ram[addra][i*COL_WIDTH +: COL_WIDTH] ;
                    end
                end
            end
        end
    end
endgenerate

//------------------------------------------------------------------------------
//    port B operation
//------------------------------------------------------------------------------
generate
    //--- read-first mode
    if(PORTB_MODE == "RF") begin
        for(i = 0; i < COL_NUM; i++) begin
            always_ff @(posedge clkb) begin
                if(enb) begin
                    if(web[i]) begin
                        ram[addrb][i*COL_WIDTH +: COL_WIDTH] <= dinb[i*COL_WIDTH +: COL_WIDTH];
                    end
                    doutb[i*COL_WIDTH +: COL_WIDTH] <= ram[addrb][i*COL_WIDTH +: COL_WIDTH] ;
                end
            end
        end
    end
    //--- write-first mode
    if(PORTB_MODE == "WF") begin
        for(i = 0; i < COL_NUM; i++) begin
            always_ff @(posedge clkb) begin
                if(enb) begin
                    if(web[i]) begin
                        ram[addrb][i*COL_WIDTH +: COL_WIDTH] <= dinb[i*COL_WIDTH +: COL_WIDTH];
                        doutb[i*COL_WIDTH +: COL_WIDTH]      <= dinb[i*COL_WIDTH +: COL_WIDTH] ;
                    end else begin
                        doutb[i*COL_WIDTH +: COL_WIDTH]      <= ram[addrb][i*COL_WIDTH +: COL_WIDTH] ;
                    end
                end
            end
        end
    end
endgenerate

endmodule : tdp_ram_m

`endif // DUAL_PORT_BRAM_MEM_IP