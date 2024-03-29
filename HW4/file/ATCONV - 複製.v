`timescale 1ns/10ps
module  ATCONV(
	input		clk,
	input		reset,
	output	reg	busy,	
	input		ready,	
			
	output reg	[11:0]	iaddr,
	input signed [12:0]	idata,
	
	output	reg 	cwr,
	output  reg	[11:0]	caddr_wr,
	output reg 	[12:0] 	cdata_wr,
	
	output	reg 	crd,
	output reg	[11:0] 	caddr_rd,
	input 	[12:0] 	cdata_rd,
	
	output reg 	csel
	);

reg signed [12:0]IMG_MEM [0:4095];
reg signed[12:0]IMAGE_PAD [0:4623];
reg signed[12:0]L0_MEM [0:4095];

reg [11:0]input_count=0;
reg [12:0]padding_count=0;
reg [11:0]conv_count=0;
reg [11:0]yaxis=0;
reg [11:0]xaxis=0;
reg [11:0]relu_count=0;
reg [11:0]L0write_count=0;

reg [3:0] state, nextstate;
localparam READY = 4'd0;
localparam INPUT = 4'd1;
localparam PADDING = 4'd2;
localparam CONV = 4'd3;
localparam RELU = 4'd4;
localparam WRITEL0 = 4'd5;
localparam MAXP = 4'd6;

integer i, j;

always@(posedge clk or posedge reset)begin
	if(reset) state<=READY;
	else state<=nextstate;
end

always@(posedge clk or posedge reset)begin
	if(reset) begin
		input_count<=0;
		padding_count<=0;
		conv_count<=0;
		yaxis<=0;
		xaxis<=0;
		relu_count<=0;
		L0write_count<=0;
		busy<=0;
	end
	else begin
	case(state)
	READY:begin
		if(ready)begin
			busy<=1;
			iaddr<=input_count;
			input_count<=input_count+1;
		end
	end
	INPUT:begin
		iaddr<=input_count;
		IMG_MEM[iaddr]<=idata;
		input_count<=input_count+1;
	end
	CONV:begin
		//padding+conv寫法
		conv_count<=conv_count+1;
		xaxis<=xaxis+1;
		if(conv_count%64==0)begin
			yaxis<=yaxis+1;
			xaxis<=0;
		end 
		//左上
		if(conv_count==0)begin
			L0_MEM[conv_count]<=-(IMG_MEM[conv_count]>>4)- (IMG_MEM[conv_count]>>3)- (IMG_MEM[conv_count+2]>>4)
								-(IMG_MEM[conv_count]>>2)+ IMG_MEM[conv_count]- (IMG_MEM[conv_count+2]>>2)
								-(IMG_MEM[conv_count+128]>>4)- (IMG_MEM[conv_count+128]>>3)- (IMG_MEM[conv_count+130]>>4)- 13'b0000000001100;			
		end	
		else if(conv_count==1)begin
			L0_MEM[conv_count]<=-(IMG_MEM[conv_count-1]>>4)- (IMG_MEM[conv_count]>>3)- (IMG_MEM[conv_count+2]>>4)
								-(IMG_MEM[conv_count-1]>>2)+ IMG_MEM[conv_count]- (IMG_MEM[conv_count+2]>>2)
								-(IMG_MEM[conv_count+127]>>4)- (IMG_MEM[conv_count+128]>>3)- (IMG_MEM[conv_count+130]>>4)- 13'b0000000001100;
		end			
		else if(conv_count==64)begin
			L0_MEM[conv_count]<=-(IMG_MEM[conv_count-64]>>4)- (IMG_MEM[conv_count-64]>>3)- (IMG_MEM[conv_count-62]>>4)
								-(IMG_MEM[conv_count]>>2)+ IMG_MEM[conv_count]- (IMG_MEM[conv_count+2]>>2)
								-(IMG_MEM[conv_count+128]>>4)- (IMG_MEM[conv_count+128]>>3)- (IMG_MEM[conv_count+130]>>4)- 13'b0000000001100;	
		end	
		else if(conv_count==65)begin
			L0_MEM[conv_count]<=-(IMG_MEM[conv_count-64]>>4)- (IMG_MEM[conv_count-63]>>3)- (IMG_MEM[conv_count-61]>>4)
								-(IMG_MEM[conv_count-1]>>2)+ IMG_MEM[conv_count]- (IMG_MEM[conv_count+2]>>2)
								-(IMG_MEM[conv_count+127]>>4)- (IMG_MEM[conv_count+128]>>3)- (IMG_MEM[conv_count+130]>>4)- 13'b0000000001100;			
		end	

		//右上
		else if(conv_count==62)begin
			L0_MEM[conv_count]<=-(IMG_MEM[conv_count-2]>>4)- (IMG_MEM[conv_count]>>3)- (IMG_MEM[conv_count+1]>>4)
								-(IMG_MEM[conv_count-2]>>2)+ IMG_MEM[conv_count]- (IMG_MEM[conv_count+1]>>2)
								-(IMG_MEM[conv_count+126]>>4)- (IMG_MEM[conv_count+128]>>3)- (IMG_MEM[conv_count+129]>>4)- 13'b0000000001100;
		end
		else if(conv_count==63)begin
			L0_MEM[conv_count]<=-(IMG_MEM[conv_count-2]>>4)- (IMG_MEM[conv_count]>>3)- (IMG_MEM[conv_count]>>4)
								-(IMG_MEM[conv_count-2]>>2)+ IMG_MEM[conv_count]- (IMG_MEM[conv_count]>>2)
								-(IMG_MEM[conv_count+126]>>4)- (IMG_MEM[conv_count+128]>>3)- (IMG_MEM[conv_count+128]>>4)- 13'b0000000001100;
		end
		else if(conv_count==126)begin
			L0_MEM[conv_count]<=-(IMG_MEM[conv_count-66]>>4)- (IMG_MEM[conv_count-64]>>3)- (IMG_MEM[conv_count-63]>>4)
								-(IMG_MEM[conv_count-2]>>2)+ IMG_MEM[conv_count]- (IMG_MEM[conv_count+1]>>2)
								-(IMG_MEM[conv_count+126]>>4)- (IMG_MEM[conv_count+128]>>3)- (IMG_MEM[conv_count+129]>>4)- 13'b0000000001100;
		end
		else if(conv_count==127)begin
			L0_MEM[conv_count]<=-(IMG_MEM[conv_count-66]>>4)- (IMG_MEM[conv_count-64]>>3)- (IMG_MEM[conv_count-64]>>4)
								-(IMG_MEM[conv_count-2]>>2)+ IMG_MEM[conv_count]- (IMG_MEM[conv_count]>>2)
								-(IMG_MEM[conv_count+126]>>4)- (IMG_MEM[conv_count+128]>>3)- (IMG_MEM[conv_count+128]>>4)- 13'b0000000001100;
		end

		//左下
		else if(conv_count==4032)begin
			L0_MEM[conv_count]<=-(IMG_MEM[conv_count-128]>>4)- (IMG_MEM[conv_count-128]>>3)- (IMG_MEM[conv_count-126]>>4)
								-(IMG_MEM[conv_count]>>2)+ IMG_MEM[conv_count]- (IMG_MEM[conv_count+2]>>2)
								-(IMG_MEM[conv_count]>>4)- (IMG_MEM[conv_count]>>3)- (IMG_MEM[conv_count+2]>>4)- 13'b0000000001100;
		end
		else if(conv_count==4033)begin
			L0_MEM[conv_count]<=-(IMG_MEM[conv_count-129]>>4)- (IMG_MEM[conv_count-128]>>3)- (IMG_MEM[conv_count-126]>>4)
								-(IMG_MEM[conv_count-1]>>2)+ IMG_MEM[conv_count]- (IMG_MEM[conv_count+2]>>2)
								-(IMG_MEM[conv_count-1]>>4)- (IMG_MEM[conv_count]>>3)- (IMG_MEM[conv_count+2]>>4)- 13'b0000000001100;
		end
		else if(conv_count==3968)begin
			L0_MEM[conv_count]<=-(IMG_MEM[conv_count-128]>>4)- (IMG_MEM[conv_count-128]>>3)- (IMG_MEM[conv_count-126]>>4)
								-(IMG_MEM[conv_count]>>2)+ IMG_MEM[conv_count]- (IMG_MEM[conv_count+2]>>2)
								-(IMG_MEM[conv_count+64]>>4)- (IMG_MEM[conv_count+64]>>3)- (IMG_MEM[conv_count+66]>>4)- 13'b0000000001100;
		end
		else if(conv_count==3969)begin
			L0_MEM[conv_count]<=-(IMG_MEM[conv_count-129]>>4)- (IMG_MEM[conv_count-128]>>3)- (IMG_MEM[conv_count-126]>>4)
								-(IMG_MEM[conv_count-1]>>2)+ IMG_MEM[conv_count]- (IMG_MEM[conv_count+2]>>2)
								-(IMG_MEM[conv_count+63]>>4)- (IMG_MEM[conv_count+64]>>3)- (IMG_MEM[conv_count+66]>>4)- 13'b0000000001100;
		end
		
		//右下
		else if(conv_count==4095)begin
			L0_MEM[conv_count]<=-(IMG_MEM[conv_count-130]>>4)- (IMG_MEM[conv_count-128]>>3)- (IMG_MEM[conv_count-128]>>4)
								-(IMG_MEM[conv_count-2]>>2)+ IMG_MEM[conv_count]- (IMG_MEM[conv_count]>>2)
								-(IMG_MEM[conv_count-2]>>4)- (IMG_MEM[conv_count]>>3)- (IMG_MEM[conv_count]>>4)- 13'b0000000001100;
		end
		else if(conv_count==4094)begin
			L0_MEM[conv_count]<=-(IMG_MEM[conv_count-130]>>4)- (IMG_MEM[conv_count-128]>>3)- (IMG_MEM[conv_count-127]>>4)
								-(IMG_MEM[conv_count-2]>>2)+ IMG_MEM[conv_count]- (IMG_MEM[conv_count+1]>>2)
								-(IMG_MEM[conv_count-2]>>4)- (IMG_MEM[conv_count]>>3)- (IMG_MEM[conv_count+1]>>4)- 13'b0000000001100;
		end
		else if(conv_count==4030)begin
			L0_MEM[conv_count]<=-(IMG_MEM[conv_count-130]>>4)- (IMG_MEM[conv_count-128]>>3)- (IMG_MEM[conv_count-125]>>4)
								-(IMG_MEM[conv_count-2]>>2)+ IMG_MEM[conv_count]- (IMG_MEM[conv_count+1]>>2)
								-(IMG_MEM[conv_count+62]>>4)- (IMG_MEM[conv_count+64]>>3)- (IMG_MEM[conv_count+65]>>4)- 13'b0000000001100;
		end
		else if(conv_count==4031)begin
			L0_MEM[conv_count]<=-(IMG_MEM[conv_count-130]>>4)- (IMG_MEM[conv_count-128]>>3)- (IMG_MEM[conv_count-128]>>4)
								-(IMG_MEM[conv_count-2]>>2)+ IMG_MEM[conv_count]- (IMG_MEM[conv_count]>>2)
								-(IMG_MEM[conv_count+62]>>4)- (IMG_MEM[conv_count+64]>>3)- (IMG_MEM[conv_count+64]>>4)- 13'b0000000001100;
		end



		//上
		else if(conv_count>=2&&conv_count<=61)begin
			L0_MEM[conv_count]<=-(IMG_MEM[conv_count-2]>>4)- (IMG_MEM[conv_count]>>3)- (IMG_MEM[conv_count+2]>>4)
								-(IMG_MEM[conv_count-2]>>2)+ IMG_MEM[conv_count]- (IMG_MEM[conv_count+2]>>2)
								-(IMG_MEM[conv_count+126]>>4)- (IMG_MEM[conv_count+128]>>3)- (IMG_MEM[conv_count+130]>>4)- 13'b0000000001100;
		end
		else if(conv_count>=66&&conv_count<=125)begin
			L0_MEM[conv_count]<=-(IMG_MEM[conv_count-66]>>4)- (IMG_MEM[conv_count-64]>>3)- (IMG_MEM[conv_count-62]>>4)
								-(IMG_MEM[conv_count-2]>>2)+ IMG_MEM[conv_count]- (IMG_MEM[conv_count+2]>>2)
								-(IMG_MEM[conv_count+126]>>4)- (IMG_MEM[conv_count+128]>>3)- (IMG_MEM[conv_count+130]>>4)- 13'b0000000001100;
		end		
		//下
		else if(conv_count>=4034&&conv_count<=4093)begin
			L0_MEM[conv_count]<=-(IMG_MEM[conv_count-130]>>4)- (IMG_MEM[conv_count-128]>>3)- (IMG_MEM[conv_count-126]>>4)
								-(IMG_MEM[conv_count-2]>>2)+ IMG_MEM[conv_count]- (IMG_MEM[conv_count+2]>>2)
								-(IMG_MEM[conv_count-2]>>4)- (IMG_MEM[conv_count]>>3)- (IMG_MEM[conv_count+2]>>4)- 13'b0000000001100;
		end
		else if(conv_count>=3970&&conv_count<=4029)begin
			L0_MEM[conv_count]<=-(IMG_MEM[conv_count-130]>>4)- (IMG_MEM[conv_count-128]>>3)- (IMG_MEM[conv_count-126]>>4)
								-(IMG_MEM[conv_count-2]>>2)+ IMG_MEM[conv_count]- (IMG_MEM[conv_count+2]>>2)
								-(IMG_MEM[conv_count+62]>>4)- (IMG_MEM[conv_count+64]>>3)- (IMG_MEM[conv_count+66]>>4)- 13'b0000000001100;
		end	
		//左
		else if(conv_count>=2*64&&conv_count<=61*64&&conv_count%64==0)begin
			L0_MEM[conv_count]<=-(IMG_MEM[conv_count-128]>>4)- (IMG_MEM[conv_count-128]>>3)- (IMG_MEM[conv_count-126]>>4)
								-(IMG_MEM[conv_count]>>2)+ IMG_MEM[conv_count]- (IMG_MEM[conv_count+2]>>2)
								-(IMG_MEM[conv_count+128]>>4)- (IMG_MEM[conv_count+128]>>3)- (IMG_MEM[conv_count+130]>>4)- 13'b0000000001100;
		end	
		else if(conv_count>=2*64+1&&conv_count<=61*64+1&&conv_count%64==1)begin
			L0_MEM[conv_count]<=-(IMG_MEM[conv_count-129]>>4)- (IMG_MEM[conv_count-128]>>3)- (IMG_MEM[conv_count-126]>>4)
								-(IMG_MEM[conv_count-1]>>2)+ IMG_MEM[conv_count]- (IMG_MEM[conv_count+2]>>2)
								-(IMG_MEM[conv_count+127]>>4)- (IMG_MEM[conv_count+128]>>3)- (IMG_MEM[conv_count+130]>>4)- 13'b0000000001100;
		end			
		//右
		else if(conv_count>=2*64+62&&conv_count<=61*64+62&&conv_count%64==62)begin
			L0_MEM[conv_count]<=-(IMG_MEM[conv_count-130]>>4)- (IMG_MEM[conv_count-128]>>3)- (IMG_MEM[conv_count-127]>>4)
								-(IMG_MEM[conv_count-2]>>2)+ IMG_MEM[conv_count]- (IMG_MEM[conv_count+1]>>2)
								-(IMG_MEM[conv_count+126]>>4)- (IMG_MEM[conv_count+128]>>3)- (IMG_MEM[conv_count+129]>>4)- 13'b0000000001100;
		end		
		else if(conv_count>=2*64+63&&conv_count<=61*64+63&&conv_count%64==63)begin
			L0_MEM[conv_count]<=-(IMG_MEM[conv_count-130]>>4)- (IMG_MEM[conv_count-128]>>3)- (IMG_MEM[conv_count-128]>>4)
								-(IMG_MEM[conv_count-2]>>2)+ IMG_MEM[conv_count]- (IMG_MEM[conv_count]>>2)
								-(IMG_MEM[conv_count+126]>>4)- (IMG_MEM[conv_count+128]>>3)- (IMG_MEM[conv_count+128]>>4)- 13'b0000000001100;
		end
		//中間
		else begin
			L0_MEM[conv_count]<=-(IMG_MEM[conv_count-130]>>4)- (IMG_MEM[conv_count-128]>>3)- (IMG_MEM[conv_count-126]>>4)
								-(IMG_MEM[conv_count-2]>>2)+ IMG_MEM[conv_count]- (IMG_MEM[conv_count+2]>>2)
								-(IMG_MEM[conv_count+126]>>4)- (IMG_MEM[conv_count+128]>>3)- (IMG_MEM[conv_count+130]>>4)- 13'b0000000001100;
		end


	end

	RELU:begin
		if(L0_MEM[relu_count]<=0) L0_MEM[relu_count]<=0;
		else L0_MEM[relu_count]<=L0_MEM[relu_count];
		relu_count<=relu_count+1;
		if(relu_count==4095)begin
			cwr<=1;
			csel<=0;
		end
	end
	WRITEL0:begin
		cwr<=1;
		csel<=0;

		if(cwr==1&&csel==0)begin
			caddr_wr<=L0write_count;
			cdata_wr<=L0_MEM[L0write_count];
			L0write_count<=L0write_count+1;
		end

	end
	MAXP:begin
		cwr<=0;
		busy<=0;
	end
	endcase
	end
end


always@(*)begin
	case(state)
	READY:begin
		if(reset) nextstate=READY;
		else begin
			// if(ready) nextstate=INPUT;
			// else nextstate=READY;
			nextstate=INPUT;
		end
	end
	INPUT:begin
		if(iaddr==4095) nextstate=CONV;
		else nextstate=INPUT;
	end
	CONV:begin
		if(conv_count==4095) nextstate=RELU;
		else nextstate=CONV;
	end
	RELU:begin
		if(relu_count==4095) nextstate=WRITEL0;
		else nextstate=RELU;
	end
	WRITEL0:begin
		if(L0write_count==4095) nextstate=MAXP;
		else nextstate=WRITEL0;
	end
	MAXP:begin
		nextstate=READY;
	end
	endcase
end


endmodule