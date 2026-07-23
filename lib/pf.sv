//------------------------------------------------------------------------------
//  project:     lib
//
//  modules:     rst_m
//
//  description: pulse and reset formers  
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
module rst_m #( parameter N = 3 )
(
    input  logic clk,
    input  logic ena,
    output logic rst
);

timeunit      1ns;
timeprecision 1ps;

//---
logic [$clog2(N)-1:0] cnt = 0;
logic                 out = 0;

//---
always_ff @(posedge clk) begin
    if(ena) begin
        if(cnt < N) begin
            cnt <= cnt + 1;
            out <= 0;
        end
        else begin
            out <= 1;
        end
    end    
end

//---
assign rst = ~out;

endmodule : rst_m

