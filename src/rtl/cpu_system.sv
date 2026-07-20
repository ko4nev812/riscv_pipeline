//------------------------------------------------------------------------------
//  project:       RISC-V (SberLab Novosibirsk State University)
//
//  modules:       cpu_system (core and uncore)
//
//  description:   - RISC-V processor (RV32I ISA) single-cycle uArch
//                 - core and uncore parts
//                 - hardware platform (development board) for standalone RISC-V processor test
//------------------------------------------------------------------------------

`include "risc-v.svh"
`include "mem_init_path.svh"  
//******************************************************************************
//******************************************************************************
module cpu_system import risc_v_pkg::*;

(
    //--------------------------------------------------------------------------
    input  logic  ref_clk,
    `ifdef UART_ENABLE
        input  wire uart_rxd,
        output wire uart_txd,
    `endif
    //--------------------------------------------------------------------------
    `ifdef CFG_NAME_BASYS_3
        output logic [`LED_NUM-1:0]  led
    `endif
);

//timeunit      1ns;
//timeprecision 1ps;

//==============================================================================

logic cpu_clk;
logic rst;
logic pll_locked;

logic         imem_clk;
Addr_t        imem_addr;
Instr_t       instr;

logic         dmem_clka;
ByteDataEna_t dmem_byte_we;
Addr_t        dmem_addr;
Data_t        dmem_wdata;
Data_t        dmem_rdata;

`ifdef UART_ENABLE
    Data_t        data_to_cpu;
    logic         uart_ena;
`endif

logic clk2;
logic clk3;

logic rst_strobe = 1'b0;
logic cpu_rst;

assign cpu_rst = rst | rst_strobe;
`ifdef UART_ENABLE
    assign uart_ena = dmem_addr[31:28] == 4'b0010;
`endif
//==============================================================================
`ifdef SIMULATOR
str_t asm_instr;
assign asm_instr = disasm(instr);
`endif

//==============================================================================

//---
//(* keep_hierarchy = `PRJ_KEEP_HIEARARCHY  *)
pll pll_inst
(
    .clk_in    ( ref_clk    ),
    .clk_out1  ( cpu_clk    ),
    .clk_out2  ( clk2       ),
    .clk_out3  ( clk3       ),
    .locked    ( pll_locked )
);

assign imem_clk  = clk2;
assign dmem_clka = clk3;

//--- reset (related to clk)
(* keep_hierarchy = `PRJ_KEEP_HIEARARCHY *)
rst_m rst_inst
(
    .clk     ( cpu_clk    ),
    .ena     ( pll_locked ),
    .rst     ( rst        )
);

//---    risc-v cpu core
(* keep_hierarchy = `PRJ_KEEP_HIEARARCHY *)
cpu_core_m cpu
(
    //---
    .clk           ( cpu_clk       ),
    .rst           ( cpu_rst       ),

    //--- imem interface
    .imem_addr     ( imem_addr     ),
    .instr         ( instr         ),

    //--- dmem interface
    .dmem_addr     ( dmem_addr     ), 
    .dmem_byte_we  ( dmem_byte_we  ), 
    .dmem_data_in  ( dmem_wdata    ), 
`ifdef UART_ENABLE
    .dmem_data_out ( data_to_cpu   ) 
`else 
    .dmem_data_out ( dmem_rdata    ) 
`endif
);

//--------------------- instruction memory (IMEM) -------------------------
`ifndef IMEM_BRAM
(* keep_hierarchy = `PRJ_KEEP_HIEARARCHY *)
imem_lutram_m 
        #(
            .INIT_FILE  (`IMEM_INIT_FILE                         ),
            .ADDR_WIDTH ( IMEM_ADDR_BYTE_WIDTH - BYTE_ADDR_WIDTH )
        )
imem_inst        
(
    .addr  ( imem_addr[2 +: (IMEM_ADDR_BYTE_WIDTH - BYTE_ADDR_WIDTH)] ),
    .instr ( instr )
);

`else
(* keep_hierarchy = `PRJ_KEEP_HIEARARCHY *)
imem_bram_m
        #(
            .INIT_FILE  (`IMEM_INIT_FILE                         ),
            .ADDR_WIDTH ( IMEM_ADDR_BYTE_WIDTH - BYTE_ADDR_WIDTH )
        )
imem_inst        
(
    .clk   ( imem_clk ),
    .addr  ( imem_addr[2 +: (IMEM_ADDR_BYTE_WIDTH - BYTE_ADDR_WIDTH)] ),
    .instr ( instr )
);
`endif // IMEM_BRAM


//--------------------- data memory (DMEM) --------------------------------
(* keep_hierarchy = `PRJ_KEEP_HIEARARCHY *)
dual_port_mem_m
        #(
            .INIT_FILE        (`DMEM_INIT_FILE),
            .PORTA_ADDR_WIDTH ( DMEM_PORT_ADDR_WIDTH ),
            .PORTB_ADDR_WIDTH ( DMEM_PORT_ADDR_WIDTH )
        )
dmem_inst        
(
    //--- port A
    .clka  ( dmem_clka    ),
    .ena   ( 1'b1         ),
    .wea   ( dmem_byte_we ),
    .addra ( dmem_addr[2 +: DMEM_PORT_ADDR_WIDTH] ),
    .dina  ( dmem_wdata   ), 
    .douta ( dmem_rdata   ),
    //--- port B not connected
    .clkb  ( dmem_clka    ),
    .enb   ( 1'b0         ),
    .web   ( 4'b0         ),
    .addrb ( '0           ),
    .dinb  ( '0           ),
    .doutb (              )
);

// ------------------ uart subsystem -------------------------------------
`ifdef UART_ENABLE
    logic [1:0]   uart_reg_offset;
    Data_t        uart_rdata;

    always_comb begin
        uart_reg_offset = dmem_addr[3:2];
        data_to_cpu = uart_ena ? uart_rdata : dmem_rdata;
    end

    uart_mmio_wrapper uart_inst (
        .clk(dmem_clka),
        .rst(cpu_rst),
    
        .RXD(uart_rxd),
        .TXD(uart_txd),
    
        .byte_we(dmem_byte_we),
        .reg_addr(uart_reg_offset),
        .wdata(dmem_wdata),
        .rdata(uart_rdata)
    );
`endif

//--------------------- simplest port -------------------------------------
localparam logic [DMEM_PORT_ADDR_WIDTH:0] LED_PORT_ADDR = {1'b1, {DMEM_PORT_ADDR_WIDTH{1'b0}}, 2'b00}; // { 1 - high bit, DMEM_PORT_ADDR_WIDTH-width zeros, 2-low-zeros }

always_ff @(posedge cpu_clk) begin
    if(cpu_rst) begin
        led <= '0;
    end else begin
        if(dmem_byte_we == 4'b1111) begin
            if(dmem_addr[0 +: (DMEM_PORT_ADDR_WIDTH + 1)] == LED_PORT_ADDR) begin
                led <= dmem_wdata[`LED_NUM-1:0];
            end
        end
    end
end

endmodule : cpu_system

