`timescale 1ns / 1ps


// UG901 (v2019.2), Synthesis pg126 December 19, 2018 www.xilinx.com
// Simple Dual-Port Block RAM with Two Clocks
// Correct Modelization with a Shared Variable
// Simple Dual-Port Block RAM with Two Clocks
// File: simple_dual_two_clocks.v
module simple_dual_two_clock_bram
#(  
    parameter ADDR_W = 10, 
    parameter DATA_W = 16,
    parameter DEPTH = 1024,
    parameter USE_INIT_FILE = 1'b0,
    parameter INIT_FILE_NAME = ""
)
// ports
 (clka,clkb,ena,enb,wea,addra,addrb,dia,dob);
    input clka,clkb,ena,enb,wea;
    input [ADDR_W-1:0] addra,addrb;
    input [DATA_W-1:0] dia;
    output [DATA_W-1:0] dob;
reg [DATA_W-1:0] ram [0:DEPTH-1];
reg [DATA_W-1:0] dob;

initial begin
    if (USE_INIT_FILE)
    begin 
        $readmemh(INIT_FILE_NAME,ram);  
    end 
end

always @(posedge clka)
begin
    if (ena)
    begin
        if (wea)
            ram[addra] <= dia;
        end
    end

always @(posedge clkb)
begin
    if (enb)
    begin
        dob <= ram[addrb];
    end
end
endmodule