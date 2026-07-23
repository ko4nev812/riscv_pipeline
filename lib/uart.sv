typedef enum logic[1:0] {
    IDLE       = 2'b00,
    START_BIT  = 2'b01,
    DATA_BITS  = 2'b10,
    STOP_BIT   = 2'b11
} State;

module uart_rx
        #(
            parameter BAUD_RATE  = 115200,
            parameter TIME_BASE  = 100, // ns per system clock period
            parameter DATA_WIDTH = 8
        ) 
(
    input clk, // system clock, typically approx 100 MHz
    input rst, // system reset

    input  wire rxd, // Rx input (backend) from PHY

    input  logic                  rxdv_clear,
    output logic [DATA_WIDTH-1:0] rx_data, // Rx data output (frontend), parallel read
    output logic                  rxdv     // Rx data received (?)
);
    localparam CLKS_PER_BIT   = (1000_000_000 / TIME_BASE) / BAUD_RATE;
    localparam BAUD_CNT_WIDTH = $clog2(CLKS_PER_BIT);
    localparam DATA_IDX_WIDTH = $clog2(DATA_WIDTH);
    localparam MID_SAMPLE     = CLKS_PER_BIT / 2;

    State state;
    logic [BAUD_CNT_WIDTH-1:0] baud_cnt;
    logic [DATA_IDX_WIDTH-1:0] data_idx;
    logic [DATA_WIDTH-1:0]     data;

    logic sample_point;
    logic bit_end;

    logic rxd_sync;

    always_ff @(posedge clk) begin
        rxd_sync <= rxd;
        
        sample_point <= (baud_cnt == MID_SAMPLE - 1);
        bit_end <= (baud_cnt == CLKS_PER_BIT - 1);
    end

    always_ff @(posedge clk or posedge rst) begin
        if(rst) begin
            state    <= IDLE;
            baud_cnt <= '0;
            data_idx <= '0;
            data     <= '0;
            rxdv     <= '0;
            rx_data  <= '0;
        end else begin
            if (rxdv_clear) begin
                rxdv <= 1'b0;
            end

            unique case (state)
                IDLE: begin
                    baud_cnt <= '0;
                    data_idx <= '0;
                    
                    if (!rxd_sync) begin
                        state <= START_BIT;
                    end
                end

                START_BIT: begin
                    baud_cnt <= baud_cnt + 1;
                    
                    if (sample_point) begin
                        if (rxd_sync != 1'b0) begin
                            state <= IDLE;
                        end
                    end
                    
                    if (bit_end) begin
                        baud_cnt <= '0;
                        state <= DATA_BITS;
                    end
                end

                DATA_BITS: begin
                    if (bit_end) begin
                        baud_cnt <= '0;
                        if (data_idx == DATA_WIDTH-1) begin
                            state <= STOP_BIT;
                        end else begin
                            data_idx <= data_idx + 1;
                        end
                    end else begin
                        baud_cnt <= baud_cnt + 1;
                    
                        if (sample_point) begin
                            data[data_idx] <= rxd_sync;
                        end
                    end
                end

                STOP_BIT: begin
                    baud_cnt <= baud_cnt + 1;
                    
                    if (sample_point) begin
                        if (rxd_sync == 1'b1) begin
                            rx_data <= data;
                            rxdv    <= 1;
                        end
                    end
                    
                    if (bit_end) begin
                        state <= IDLE;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule : uart_rx

module uart_tx
        #(  
            parameter BAUD_RATE  = 115200,
            parameter TIME_BASE  = 100, // ns per system clock period
            parameter DATA_WIDTH = 8
        )
(
    input clk, // system clock, typically approx 100 MHz
    input rst, // system reset
                            
    output wire txd, // Tx output (backend) to PHY

    input  logic [DATA_WIDTH-1:0] tx_data, // Tx data input (frontend), parallel load
    input  logic                  txdv,    // start Tx  - it's good to block Transmit when !ready 
    output logic                  ready    // Tx ready
);

    localparam CLKS_PER_BIT = (1000_000_000 / TIME_BASE) / BAUD_RATE;
    localparam BAUD_CNT_WIDTH = $clog2(CLKS_PER_BIT);
    localparam BIT_CNT_WIDTH  = $clog2(DATA_WIDTH + 1);
    localparam DATA_IDX_WIDTH = $clog2(DATA_WIDTH);
    
    State state;
    logic [BAUD_CNT_WIDTH-1:0] baud_cnt;
    logic [DATA_IDX_WIDTH-1:0] bit_idx;
    logic [BIT_CNT_WIDTH-1:0]  bit_cnt;
    logic [DATA_WIDTH-1:0]     data;
    logic tx_reg;

    logic bit_end;
    always_ff @(posedge clk) begin
        bit_end <= (baud_cnt == CLKS_PER_BIT - 1);
    end
    
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state    <= IDLE;
            baud_cnt <= '0;
            bit_idx  <= '0;
            data     <= '0;
            tx_reg   <= 'b1;
            ready    <= 'b1;
        end else begin
            unique case (state)
                IDLE: begin
                    tx_reg <= 'b1;
                    ready  <= 'b1;
                    
                    if (txdv && ready) begin
                        data  <= tx_data;
                        state <= START_BIT;
                        ready <= 1'b0;

                        baud_cnt <= '0;
                    end
                end
                
                START_BIT: begin
                    tx_reg <= 1'b0;
                    baud_cnt <= baud_cnt + 1;
                    
                    if (bit_end) begin
                        baud_cnt <= '0;
                        state    <= DATA_BITS;
                        bit_idx  <= '0;
                    end
                end
                
                DATA_BITS: begin
                    tx_reg   <= data[bit_idx];
                    baud_cnt <= baud_cnt + 1;
                    
                    if (bit_end) begin
                        baud_cnt <= '0;
                        if (bit_idx == DATA_WIDTH - 1) begin
                            state <= STOP_BIT;
                        end else begin
                            bit_idx <= bit_idx + 1;
                        end
                    end
                end
                
                STOP_BIT: begin
                    tx_reg   <= 1'b1;
                    baud_cnt <= baud_cnt + 1;
                    
                    if (bit_end) begin
                        state <= IDLE;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end
    
    assign txd = tx_reg;
    
endmodule : uart_tx

