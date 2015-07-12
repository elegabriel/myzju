`timescale 1ns / 1ps

module decode4_32(in1,in2,in3,in4,c1,c2,c3,out
    );
	input [31:0] in1,in2,in3,in4;
	input c1,c2,c3;
	output [31:0] out;
	
	wire [31:0] tmp1,tmp2,tmp3;
	
	assign out = (c1)?in1:tmp1;
	assign tmp1 = (c2)?in2:tmp2;
	assign tmp2 = (c3)?in3:tmp3;
	assign tmp3 = in4;

endmodule
