`timescale 1ns / 1ps
/**
* 
* READ THIS DESCRIPTION:
*
* This is the Wrapper module that will serve as the header file combining your processor, 
* RegFile and Memory elements together.
*
* This file will be used to generate the bitstream to upload to the FPGA.
* We have provided a sibling file, Wrapper_tb.v so that you can test your processor's functionality.
* 
* We will be using our own separate Wrapper_tb.v to test your code. You are allowed to make changes to the Wrapper files 
* for your own individual testing, but we expect your final processor.v and memory modules to work with the 
* provided Wrapper interface.
* 
* Refer to Lab 5 documents for detailed instructions on how to interface 
* with the memory elements. Each imem and dmem modules will take 12-bit 
* addresses and will allow for storing of 32-bit values at each address. 
* Each memory module should receive a single clock. At which edges, is 
* purely a design choice (and thereby up to you). 
* 
* You must change line 36 to add the memory file of the test you created using the assembler
* For example, you would add sample inside of the quotes on line 38 after assembling sample.s
*
**/

module Wrapper (clk, reset2, LED, JA, JB, JC, SW, ACL_MISO, ACL_MOSI, ACL_SCLK, ACL_CSN, AN, DP, SEG);
   input wire clk, reset2;
   input wire [15:0] SW;
   output wire [2:1] JA;
   input wire [1:1] JC;
   output wire [2:1] JB;
   input wire ACL_MISO;
   
   wire reset;
   assign reset = 1'b0;
   output wire [15:0] LED;
   
   output wire [6:0] SEG;
   output wire DP;
   output wire [7:0] AN;
   output wire ACL_MOSI;            
   output wire ACL_SCLK;            
   output wire ACL_CSN;

	wire[17:0] limit;

	assign limit = 10;
reg clock = 0;
	reg[17:0] counter = 0;
	always @(posedge clk) begin
		if(counter < limit)
			counter <= counter + 1;
		else begin
				counter <= 0;
				clock <= ~clock;
		end 
	end
   wire rwe, mwe;
   wire[4:0] rd, rs1, rs2;
   wire[31:0] instAddr, instData, 
       rData, regA, regB,
       memAddr, memDataIn, memDataOut;
   
   wire [8:0] pwmDataIn;
   wire [8:0] pwmData1;
   wire [8:0] pwmData2;
   wire updatePwm1;
   wire updatePwm2;
       //assign LED = instAddr[15:0];
       
       
       

   // ADD YOUR MEMORY FILE HERE
   localparam INSTR_FILE = "project";
   wire [9:0] newGyro;
   assign newGyro = {1'b0, gyro[13:10], 1'b0, gyro[8:5]};
   // Main Processing Unit
   processor CPU(.clock(clock), .reset(reset), 
                               
       // ROM
       .address_imem(instAddr), .q_imem(instData),
                                   
       // Regfile
       .ctrl_writeEnable(rwe),     .ctrl_writeReg(rd),
       .ctrl_readRegA(rs1),     .ctrl_readRegB(rs2), 
       .data_writeReg(rData), .data_readRegA(regA), .data_readRegB(regB), 
                                   
       // RAM
       .wren(mwe), .address_dmem(memAddr), 
       .data(memDataIn), .q_dmem(memDataOut),
       .pwm_data1(pwmData1),
       .pwm_data2(pwmData2),
       .updatePwm1(updatePwm1),
       .updatePwm2(updatePwm2),
       .gyro(newGyro),
       .forceSensor(JC[1])); 
   
   // Instruction Memory (ROM)
   ROM #(.MEMFILE({INSTR_FILE, ".mem"}))
   InstMem(.clk(clock), 
       .addr(instAddr[11:0]), 
       .dataOut(instData));
   
   // Register File
   regfile RegisterFile(.clock(clock), 
       .ctrl_writeEnable(rwe), .ctrl_reset(reset), 
       .ctrl_writeReg(rd),
       .ctrl_readRegA(rs1), .ctrl_readRegB(rs2), 
       .data_writeReg(rData), .data_readRegA(regA), .data_readRegB(regB));
                       
   // Processor Memory (RAM)
   RAM ProcMem(.clk(clock), 
       .wEn(mwe), 
       .addr(memAddr[11:0]), 
       .dataIn(memDataIn), 
       .dataOut(memDataOut));
       
   
   wire chSel, audioOut, audioEn;
   wire tone;

    reg [8:0] pwm_data1;
    always @(posedge clock) begin
        if (updatePwm1)
            pwm_data1 <= pwmData1;
        else 
            pwm_data1 <= pwm_data1;
    end
    
        reg [8:0] pwm_data2;
    always @(posedge clock) begin
        if (updatePwm2)
            pwm_data2 <= pwmData2;
        else 
            pwm_data2 <= pwm_data2;
    end
    
    
   pwn p1(.clk(clock), .tone(tone), .chSel(chSel), .audioOut(audioOut), .audioEn(audioEn), .SW(pwm_data1));
   assign LED[7:0] = pwm_data1;
   assign LED[15:8] = pwm_data2;
    //assign LED[14:0] = gyro;
   wire tone2, chSel2, audioEn2;
   wire audioOut2;
   pwn p2(.clk(clock), .tone(tone2), .chSel(chSel2), .audioOut(audioOut2), .audioEn(audioEn2), .SW(pwm_data2));
   
   assign JA[1] = audioOut;
   assign JB[1] = audioOut2;
   
   wire [23:0] div;
   assign div = 100000000/9600; 
   
   wire [30:0] i_setup;
   assign i_setup = {1'b0, 2'b00, 1'b0, 1'b0, 2'b00, 24'b0};
   wire o_wr;
   wire [7:0] data;
   
   //rxuart receiver(.i_clk(clock), .i_reset(reset2), .i_setup(i_setup), .i_uart_rx(JC[1]), .o_wr(o_wr), .o_data(data), .o_break(), .o_parity_err(), .o_frame_err(), .o_ck_uart());
   
   
   wire [30:0] i_setup_tx;
   assign i_setup_tx = {1'b0, 2'b00, 1'b0, 1'b0, 2'b00, 24'b0};
   
   wire o_uart_tx, o_busy;
   
   wire[7:0] i_data;
   assign i_data = 8'b00000101;
   
   //txuart transmitter(.i_clk(clock), .i_reset(reset2), .i_setup(i_setup_tx), .o_uart_tx(JB[1]), .i_wr(1'b1), .i_data(i_data), .i_break(1'b0), .i_cts_n(1'b1), .o_busy(o_busy));
   wire busy, valid;
   // rxtx retr(clock, 1'b0, JB[1], JC[1], i_data, 1'b1, busy, data, valid);


//    assign LED[9] = data[7];
//    assign LED[8] = data[6];
//    assign LED[9] = data[5];
//  assign LED[8] = data[4];
//    assign LED[9] = data[3];
//    assign LED[8] = data[2];
//    assign LED[9] = data[1];
   //assign LED[8] = data[1];

    // Existing Wrapper module content...

   // Definitions and instances above remain unchanged.

//   // UART Receiver and Transmitter Integration
//   // Configuring UART Receiver
//   wire [7:0] uart_rx_data;
//   wire uart_rx_data_valid;
//   uart_rx receiver (
//       .clk(clock),
//       .rst_n(reset2),
//       .rx(JC[1]),               // Assuming JC[1] is the RX line from UART
//       .rx_data(uart_rx_data),
//       .rx_dv(uart_rx_data_valid)
//   );

//   // Configuring UART Transmitter
//   wire uart_tx_busy;
//   wire [7:0] uart_tx_data = SW[7:0]; // Example: Using switches for UART data input
//   wire uart_tx_enable = SW[8];       // Example: Using a switch to trigger transmission
//    uart_tx transmitter (
//        .clk(clock),
//        .rst_n(reset2),
//        .tx_data(uart_tx_data),
//        .tx_en(uart_tx_enable),
//        .tx(JB[1]),                 // Assuming JB[1] is the TX line for UART
//        .tx_busy(uart_tx_busy)
//    );

   // LED output for debugging or display purposes
   // Displaying UART RX data and status on LEDs
//    assign LED[7:0] = uart_rx_data; // Display received data
     //assign LED[7:0] = 8'b00000101; // Display re
     //assign LED[8] = JB[1];
   //assign LED[8] = uart_rx_data_valid; // Indicator if received data is valid
   //assign LED[9] = uart_tx_busy;   // Indicator if transmitter is busy

   // You might want to use additional LEDs or signals to display other statuses or control bits.
   wire [14:0] gyro;
   top accel(.CLK100MHZ(clk), .ACL_MISO(ACL_MISO), .ACL_MOSI(ACL_MOSI), .ACL_SCLK(ACL_SCLK), .ACL_CSN(ACL_CSN), .LED(gyro), .SEG(SEG), .DP(DP), .AN(AN));
//    assign LED[14:0] = gyro;
   
//Force sensor input     
   
//   reg JB_sync; // Synchronized JB input

   // Synchronize JB input using a flip-flop
//    always @(posedge clock or negedge reset2) begin
//        if (!reset2) begin
//            JB_sync <= 1'b0; // Reset JB_sync on reset
//        end else begin
//            JB_sync <= JB[1]; // Synchronize JB input
//        end
//    end
   
   // Continuous assignment for LED output based on synchronized JB input
//   wire test, test_out;
   // assign LED[14] = JB[1]; 
   

//    and a0(LED[5], test, 1'b1);    
   
   //assign JC[1] = test_out;
   
//    assign LED[5] = test;
//    assign LED[8] = 1'b0;
   
   
//    reg force_input = 1'b0;
//    always@(posedge clock) begin
//        force_input = JB[1];
//    end
   
   //assign LED_force[8] = force_input;
   
// UART Configuration Parameters
//    localparam integer BAUD_RATE = 115200;  // Set your desired baud rate
//    localparam integer CLOCK_FREQ = 100000000;  // System clock frequency in Hz
//    localparam integer CLOCKS_PER_BAUD = CLOCK_FREQ / BAUD_RATE;

//    // UART Interface Wires
//    wire uart_rx, uart_tx;
//    wire [7:0] rx_data;
//    wire rx_data_valid, tx_busy;
//    reg i_wr; // Control signal for writing to the UART transmitter

//    // Instantiate UART Receiver
//    rxuartlite #(.CLOCKS_PER_BAUD(CLOCKS_PER_BAUD)) uart_rx_inst (
//        .i_clk(clock),
//        .i_reset(reset),
//        .i_uart_rx(uart_rx),
//        .o_wr(rx_data_valid),
//        .o_data(rx_data)
//    );

//    // Instantiate UART Transmitter
//    txuartlite #(.CLOCKS_PER_BAUD(CLOCKS_PER_BAUD)) uart_tx_inst (
//        .i_clk(clock),
//        .i_reset(reset),
//        .i_wr(i_wr),
//        .i_data(8'b11111111), // Transmit a fixed 8-bit value of 11111111
//        .o_uart_tx(uart_tx),
//        .o_busy(tx_busy)
//    );

//    // Control logic for UART transmission
//    always @(posedge clock) begin
//         if (!tx_busy) begin
//            i_wr <= 1'b1; // Only write when the transmitter is not busy
//        end else begin
//            i_wr <= 1'b0; // Reset write enable to avoid continuous transmission
//        end
//    end

//    // Assignments for external pins and indicators
//    assign JC[1] = uart_tx;  // Connect UART transmit line to JC[1]
//    assign uart_rx = JB[1];  // Connect UART receive line to JB[1]
//    assign LED[7:0] = rx_data;  // Display received UART data on LEDs
//    assign LED[8] = rx_data_valid;  // Indicator if received data is valid
//    assign LED[9] = tx_busy;  // Indicator if UART transmitter is busy

// Define clock cycles per bit for UART based on clock frequency and baud rate

// UART Transmission and Reception Wires
//wire tx_done;
//wire rx_dv;
//wire [7:0] rx_byte;

//// Instantiate UART Transmitter with explicit parameter setting
//uart_tx uart_tx_inst (
//   .i_Clock(clock),
//   .i_Tx_DV(SW[0]),  // Trigger transmission using a switch
//   .i_Tx_Byte(8'hFF),  // Sending a byte of 0xFF
//   .o_Tx_Active(),
//   .o_Tx_Serial(JC[1]),  // Connect JC[1] to external UART RX
//   .o_Tx_Done(tx_done)
//);

//// Instantiate UART Receiver with explicit parameter setting
//uart_rx2 uart_rx_inst (
//   .i_Clock(clock),
//   .i_Rx_Serial(JB[1]),  // Connect JB[1] to external UART TX
//   .o_Rx_DV(rx_dv),
//   .o_Rx_Byte(rx_byte)
//);
//wire RxD_data_ready;
//wire [7:0] RxD_data;
//wire RxD;



//// LED outputs for debugging
//assign LED[7:0] = rx_byte;   // Display received data
//assign LED[8] = rx_dv;       // Indicator if received data is valid
//assign LED[9] = tx_done;     // Indicator if transmission is accel

endmodule
