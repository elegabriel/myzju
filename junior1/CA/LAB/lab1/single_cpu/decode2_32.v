`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:31:44 03/24/2015 
// Design Name: 
// Module Name:    decode2_32 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module decode2_32(in1,in2,c,out
    );
	input wire [31:0] in1,in2;
	input wire c;
	output wire [31:0] out;
	
	assign out=c?in1:in2;

endmodule
