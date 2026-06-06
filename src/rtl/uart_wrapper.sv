`include "risc-v.svh"

module uart_mmio_wrapper import risc_v_pkg::*;
        #(  
            parameter BAUD_RATE  = RV_BAUD_RATE,
            parameter TIME_BASE  = RV_TIME_BASE,
            parameter DATA_WIDTH = RV_DATA_WIDTH
        )
(
    input  logic clk,
    input  logic rst,

    input  wire  RXD,

    output wire  TXD,
    
    input  ByteDataEna_t byte_we,

    input  UARTMapAddrs reg_addr,

    input  Data_t wdata,
    output Data_t rdata
);
    // MMIO registers
    logic [DATA_WIDTH-1:0] tx_data_reg;
    logic                  txdv_reg;

    // Signals from UART modules
    logic                  uart_ready;
    logic [DATA_WIDTH-1:0] uart_rx_data;
    logic                  uart_rxdv;
    
    logic we;
    assign we = (byte_we != '0);
    logic rxdv_clear;
    assign rxdv_clear = reg_addr == RXDATA_ADDR && !we;

    uart_rx #(
        .BAUD_RATE(BAUD_RATE),
        .TIME_BASE(TIME_BASE),
        .DATA_WIDTH(DATA_WIDTH)
    ) rx_inst (
        .clk(clk),
        .rst(rst),

        .rxd(RXD),

        .rxdv_clear(rxdv_clear),
        .rx_data(uart_rx_data),
        .rxdv(uart_rxdv)
    );
    
    uart_tx #(
        .BAUD_RATE(BAUD_RATE),
        .TIME_BASE(TIME_BASE),
        .DATA_WIDTH(DATA_WIDTH)
    ) tx_inst (
        .clk(clk),
        .rst(rst),

        .txd(TXD),

        .tx_data(tx_data_reg),
        .txdv(txdv_reg),
        .ready(uart_ready)
    );

    //----------------------------------------------------------------
    // Write MMIO logic

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            tx_data_reg <= {DATA_WIDTH{1'b0}};
            txdv_reg    <= 1'b0;
        end else begin
            txdv_reg <= 1'b0;
            if (reg_addr == TXDATA_ADDR && we && uart_ready) begin
                unique case (1'b1)
                    byte_we[0]: tx_data_reg <= wdata[7:0];
                    byte_we[1]: tx_data_reg <= wdata[15:8];
                    byte_we[2]: tx_data_reg <= wdata[23:16];
                    byte_we[3]: tx_data_reg <= wdata[31:24];
                endcase
                txdv_reg <= 1'b1;
            end
            
        end
    end

    //----------------------------------------------------------------
    // Read MMIO logic

    always_comb begin
        rdata = {XLEN{1'b0}};
        
        case (reg_addr)
            TXDATA_ADDR: begin
                rdata = {{XLEN-DATA_WIDTH{1'b0}}, tx_data_reg};
            end
            
            TXSTATUS_ADDR: begin
                rdata = {{XLEN-1{1'b0}}, uart_ready};
            end
            
            RXSTATUS_ADDR: begin
                rdata = {{XLEN-1{1'b0}}, uart_rxdv};
            end
            
            RXDATA_ADDR: begin
                rdata = {{XLEN-DATA_WIDTH{1'b0}}, uart_rx_data};
            end
            
            default: begin
                rdata = {XLEN{1'b0}};
            end
        endcase
    end

endmodule : uart_mmio_wrapper