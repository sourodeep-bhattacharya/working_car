module serialGPIO(
    input clock,
    input [1:1] JB,
    output [1:1] JC,

    output [7:0] LED,  // general purpose outputs
    input [7:0] SW  // general purpose inputs
);

wire RxD_data_ready;
wire [7:0] RxD_data;
async_receiver RX(.clk(clock), .RxD(JB), .RxD_data_ready(RxD_data_ready), .RxD_data(RxD_data));
always @(posedge clock) if(RxD_data_ready) LED <= RxD_data;
//assign LED = 8'b00000101;
async_transmitter TX(.clk(clock), .TxD(JC), .TxD_start(RxD_data_ready), .TxD_data(SW));
endmodule
