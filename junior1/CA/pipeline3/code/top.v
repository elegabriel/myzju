`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:43:52 03/31/2015 
// Design Name: 
// Module Name:    top 
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
module top(CCLK, SW, BTNN, BTNE, BTNS, BTNW,LED,
	LCDE, LCDRS, LCDRW, LCDDAT
);
	input wire CCLK;
	input wire [3:0] SW;
	input wire BTNN,BTNE,BTNW,BTNS;
	output wire LCDE, LCDRS, LCDRW;
	output wire [3:0] LCDDAT;
	output wire [7:0] LED;
	
	wire btnclk;
	wire rst;
	reg sw_reg,sw_reg_ins;
	wire btsw,btreg;
	assign LED[3:0]=SW[3:0];
	assign LED[4]=btnclk;
	assign LED[5]=rst;
	assign LED[6]=btsw;
	assign LED[7]=btreg;
	
	reg [7:0] clk_cnt;
	
	wire btnbtn = btsw | btreg | btnclk ;
	
	always @(posedge btnbtn or posedge rst)
	begin
		if(rst)
		begin
			sw_reg<=0;
			sw_reg_ins<=0;
			clk_cnt <= 0;
		end
		else if(btsw)
			sw_reg_ins <= ~sw_reg_ins;
		else if(btnclk)
			clk_cnt <= clk_cnt+1;
		else if(btreg)
			sw_reg <= ~sw_reg;	
	end
	
	wire [31:0] instr;
	wire [5:0] op, func;
	wire [4:0] rs,rt,rd,shamt,td;
	wire [15:0] imm;
	wire [25:0] addr;
	wire [31:0] saout;
	wire JR, J, JAL, LW, WREG, WMEM, RDorRT, SE, SA, IorR, BJ;
	wire [4:0] Aluc;
	wire [31:0] a, b, aluresult;	//alu in/out
	wire [4:0] r1, r2, r3, w1;	//Reg
	wire [31:0] d1, d2, d3, wdata;	//Reg
	wire [31:0] seout;	//signed extended
	wire [31:0] pcplus4, pcin, pcout, immaddr, jaddr;
	wire [31:0] memdata;
	wire equal_result;
	
	//IF
	wire [31:0] tmp_pcin,tmp_pcout;
	//	ID
	wire [31:0] id_pcplus4, id_instr;//,tmp_d1,tmp_d2;
	wire [4:0] id_td;
	wire WREG_id;
	//	EX
	wire [31:0] ex_a, ex_b, ex_d2,ex_instr;
	wire [4:0] ex_td;
	wire [4:0] ex_Aluc;
	wire ex_WREG, ex_WMEM, ex_LW;
	//	ME
	wire [31:0] me_aluresult, me_d2,me_instr,me_memdata;
	wire [4:0] me_td;
	wire me_WREG, me_WMEM, me_LW;

	//	WB
	wire [31:0] wb_memdata;
	wire [4:0] wb_td;
	wire wb_WREG;//wb_LW;

	//
	wire stall;
	
	
	
	wire [31:0] dis_data;
	wire [7:0] dis_addr;
	
	wire [7:0] IF,ID,EX,MEM;
	exin exin1(btnclk, rst, instr, IF);
	exin exin2(btnclk, rst, id_instr, ID);
	exin exin3(btnclk, rst, ex_instr, EX);
	exin exin4(btnclk, rst, me_instr, MEM);

	
	assign dis_data=(sw_reg_ins)?instr:{IF,ID,EX,MEM};//assign dis_data=(sw_reg_ins)?instr:d3;
	assign dis_addr=(sw_reg_ins)?{8'b00100001}:{3'b000,r3};
	
	assign r2=rt;
	assign r3={sw_reg,SW};
	
	assign btnclk=BTNN;//anti_jitter at0(.clk(CCLK),.rst(rst),.sig_i(BTNN),.sig_o(btnclk));//
	assign rst = BTNE;//anti_jitter at1(.clk(CCLK),.rst(rst),.sig_i(BTNE),.sig_o(rst));//
	assign btsw = BTNW;//anti_jitter at2(.clk(CCLK),.rst(rst),.sig_i(BTNW),.sig_o(btsw));//
	assign btreg = BTNS;//anti_jitter at3(.clk(CCLK),.rst(rst),.sig_i(BTNS),.sig_o(btreg));//

	//////////////////////////////////////////////////////////////////////////////////
	//	PC
	//////////////////////////////////////////////////////////////////////////////////
	assign pcin=(J|JAL|JR|BJ)?(tmp_pcin+4):(tmp_pcin);
	assign pcout=(J|JAL|JR|BJ)?(tmp_pcin):(tmp_pcout);
	
	pc pc(
    	.clk(btnclk), .rst(rst), .stall(stall),
		.i_pc(pcin), .o_pc(tmp_pcout)//?
	);

	pc_plus4 pc_plus4(
		.i_pc(pcout), .o_pc(pcplus4)
    );

	decode4_32 pc_in(
		.in1(jaddr), .in2(d1), .in3(immaddr), .in4(id_pcplus4), .c1(J | JAL), .c2(JR), .c3(BJ), .out(tmp_pcin)
	);

	instrmem instrmem(
		.clka(btnclk),.addra(pcout[11:2]),.douta(instr[31:0])
	);

	//////////////////////////////////////////////////////////////////////////////////
	//	IF-ID
	//////////////////////////////////////////////////////////////////////////////////
	IF_ID IF_ID(
		.clk(btnclk), .rst(rst), .stall(stall), .BJ(J|JAL|JR|BJ),
		.if_pcplus4(pcplus4), .if_instr(instr),
		.id_pcplus4(id_pcplus4), .id_instr(id_instr)
	);

	assign op=id_instr[31:26];
	assign rs=id_instr[25:21];
	assign rt=id_instr[20:16];
	assign rd=id_instr[15:11];
	assign shamt=id_instr[10:6];
	assign func=id_instr[5:0];
	assign imm=id_instr[15:0];
	assign addr=id_instr[25:0];
	assign saout={27'b0,shamt};

	cpu_ctl cpu_ctl(
		.op(op), .func(func), .equal_result(equal_result),
		.JR(JR), .J(J), .JAL(JAL), .LW(LW),
		.WREG(WREG), .WMEM(WMEM),. RDorRT(RDorRT),
		.SE(SE), .SA(SA), .IorR(IorR), .BJ(BJ),
		.Aluc(Aluc)
	);

	assign WREG_id=JAL & WREG;
	assign td=(RDorRT)?rd:rt;
//	assign d1 = (wb_td==r1)?wb_memdata:tmp_d1;
	
	//forwarding
	wire [31:0] d1_tmp1, d1_tmp2, d2_tmp1, d2_tmp2, d1_tmp3, d2_tmp3;
	
	assign d1 = (ex_td==r1 & |r1)? aluresult : d1_tmp1;
	assign d1_tmp1 = (me_td==r1 & |r1)? me_memdata : d1_tmp2;
	assign d1_tmp2 = (wb_td==r1 & |r1)? wb_memdata : d1_tmp3;
	
	assign d2 = (ex_td==r2 & |r2)? aluresult : d2_tmp1;
	assign d2_tmp1 = (me_td==r2 & |r2)? me_memdata : d2_tmp2;
	assign d2_tmp2 = (wb_td==r2 & |r2)? wb_memdata : d2_tmp3;
	
//	assign d2 = (wb_td==r2)?wb_memdata:tmp_d2;

	reg32 reg32(
		.clk(btnclk), .rst(rst), .wea(WREG_id | wb_WREG),//.wea(WREG_id | me_WREG | me_LW),//
		.r1(r1), .r2(r2), .r3(r3), .w1(w1),
		.wdata(wdata), .out1(d1_tmp3), .out2(d2_tmp3), .out3(d3)
    );

	imm_addr imm_addr(
		.imm(imm), .pc(id_pcplus4), .out(immaddr)
	);

	j_addr j_addr(
		.addr(addr), .pc(id_pcplus4), .out(jaddr)
	);

	isequal isequal(
		.in1(d1), .in2(d2), .result(equal_result)
    );

	se se(
		.in(imm), .SE(SE), .out(seout)
    );

	decode2_32 alu_a(
		.in1(saout), .in2(d1), .c(SA), .out(a)
	);

	decode2_32 alu_b(
		.in1(seout), .in2(d2), .c(IorR), .out(b)
	);

	decode2_5 reg_read(
		.in1(5'b11111), .in2(rs), .c(JR), .out(r1)
	);

	decode2_5 reg_write(
		.in1(wb_td), .in2(5'b11111), .c(wb_WREG), .out(w1)//.in1(me_td), .in2(5'b11111), .c(wb_WREG), .out(w1)//
	);

	decode2_32 reg_wdata(
		.in1(wb_memdata), .in2(id_pcplus4), .c(wb_WREG), .out(wdata)//.in1(me_memdata), .in2(id_pcplus4), .c(wb_WREG), .out(wdata)//
	);


	//////////////////////////////////////////////////////////////////////////////////
	//	ID-EX
	//////////////////////////////////////////////////////////////////////////////////
	ID_EX ID_EX(
		.clk(btnclk), .rst(rst), .BJ(J|JAL|JR|BJ),
		.id_a(a), .id_b(b), .id_td(td), .id_d2(d2), .id_Aluc(Aluc), .id_WREG(WREG & ~LW & |td), .id_WMEM(WMEM), .id_LW(LW & |td),.id_instr(id_instr),
		.ex_a(ex_a), .ex_b(ex_b), .ex_td(ex_td), .ex_d2(ex_d2), .ex_Aluc(ex_Aluc), .ex_WREG(ex_WREG), .ex_WMEM(ex_WMEM), .ex_LW(ex_LW),.ex_instr(ex_instr)
	);

	alu alu(
		.a(ex_a), .b(ex_b), .aluc(ex_Aluc), .result(aluresult)
	);

	//////////////////////////////////////////////////////////////////////////////////
	//	EX-MEM
	//////////////////////////////////////////////////////////////////////////////////
	EX_ME EX_ME(
		.clk(btnclk), .rst(rst),
		.ex_aluresult(aluresult), .ex_td(ex_td), .ex_d2(ex_d2), .ex_WREG(ex_WREG ), .ex_WMEM(ex_WMEM), .ex_LW(ex_LW ),.ex_instr(ex_instr),
		.me_aluresult(me_aluresult), .me_td(me_td), .me_d2(me_d2), .me_WREG(me_WREG), .me_WMEM(me_WMEM), .me_LW(me_LW),.me_instr(me_instr)
	);
	
	Data_Mem Data_Mem(
		.clka(btnclk),.wea(me_WMEM),.addra(aluresult[11:2]),.dina(me_d2),.douta(memdata)//.clka(btnclk),.wea(me_WMEM),.addra(me_aluresult[11:2]),.dina(me_d2),.douta(memdata)
	);

	assign me_memdata=(me_WREG)?me_aluresult:memdata;
	//////////////////////////////////////////////////////////////////////////////////
	//	MEM-WB
	//////////////////////////////////////////////////////////////////////////////////
	
	
	ME_WB ME_WB(
		.clk(btnclk), .rst(rst),
		.me_memdata(me_memdata), .me_td(me_td), .me_WREG(me_WREG | me_LW),
		.wb_memdata(wb_memdata), .wb_td(wb_td), .wb_WREG(wb_WREG)
	);

	display2 ds(
		.clk(CCLK),.rst(rst),.instr(instr),.reg_data(d3),.stage({IF,ID,EX,MEM}),.clk_cnt(clk_cnt),.reg_addr({3'b0,r3}),
		.lcd_rs(LCDRS), .lcd_rw(LCDRW), .lcd_e(LCDE), .lcd_dat(LCDDAT)
	);

	//////////////////////////////////////////////////////////////////////////////////
	//	WB
	//////////////////////////////////////////////////////////////////////////////////
	
	//////////////////////////////////////////////////////////////////////////////////
	//	Stall Control Logic
	//////////////////////////////////////////////////////////////////////////////////
	StallControlLogic scl(
		.rs(instr[25:21]),.rt(instr[20:16]),.op(instr[31:26]), .func(instr[5:0]),
		.id_td(td), .id_LW(LW & |td),
		.stall(stall)
	);
endmodule

