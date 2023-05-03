`timescale 1ns / 1ps
//testbench module

module tb();

////////////////////////
// local declarations //
////////////////////////

//cloking signals
logic        clkin, rstn;

//Control signals
logic        SCLK, DIN, SYNC_b, LDAC_b;

//user signals
logic [15:0] tdata;
logic [2:0]  tuser;
logic        tvalid;

///////////////
//connections//
///////////////
ad5318 dac(
    .clkin(clkin),      //FPGA clocking
    .rstn(rstn),
    
    //signals in DAC
    .SCLK(SCLK),
    .DIN(DIN),
    .SYNC_b(SYNC_b),
    .LDAC_b(LDAC_b),
    
    //module signals
    .tdata(tdata),
    .tvalid(tvalid),
    .tuser(tuser),
    .tready()
);

dac_ad5318 device(
    .SCLK(SCLK),          //cloking
    .SYNC_b(SYNC_b),      //synchronization signal
    .DIN(DIN),            //input data
    .LDAC_b(LDAC_b),      //DAC-register control signal 
 
    .VoutA(),             //output chanels
    .VoutB(),
    .VoutC(),
    .VoutE(),
    .VoutF(),
    .VoutG(),
    .VoutH()
);

parameter PERIOD = 10.0;
initial forever begin
      #(PERIOD/2) clkin = 1'b1;
      #(PERIOD/2) clkin = 1'b0;
end

initial
begin 
    //reset signal setup
    rstn = 0;
    #100;
    rstn = 1;
    #100;
    
    //ref setup
    tdata <= 16'b1000000000110000;
    tvalid <= 1'b1;
    #75
    tvalid <= 1'b0;
    
    //power-on all out's
    #1000
    tdata <= 16'b1100000000000000;
    tvalid <= 1'b1;
    #75
    tvalid <= 1'b0;
    
    //set value 1 on chanel E
    #1000
    tdata <= 16'b0000000000000001;
    tuser <=  3'b100;
    tvalid <= 1'b1;
    #75
    tvalid <= 1'b0;
    
    //single update LDAC command
    #1000
    tdata <= 16'b1010000000000010;
    tvalid <= 1'b1;
    #75
    tvalid <= 1'b0;
    
end

endmodule
