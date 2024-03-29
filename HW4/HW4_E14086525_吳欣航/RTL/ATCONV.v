`timescale 1ns/10ps
module  ATCONV(
 input  clk,
 input  reset,
 output reg busy, 
 input  ready, 
   
 output reg [11:0] iaddr,
 input signed [12:0] idata,
 
 output reg  cwr,
 output  reg [11:0] caddr_wr,
 output reg  [12:0]  cdata_wr,
 
 output reg  crd,
 output reg [11:0]  caddr_rd,
 input  [12:0]  cdata_rd,
 
 output reg  csel
 );

reg signed[12:0]k1=0;
reg signed[12:0]k2=0;
reg signed[12:0]k3=0;
reg signed[12:0]k4=0;
reg signed[12:0]k5=0;
reg signed[12:0]k6=0;
reg signed[12:0]k7=0;
reg signed[12:0]k8=0;
reg signed[12:0]k9=0;
reg signed[12:0]temp=0;
reg signed[12:0]temp1=0;


reg [10:0]L1_count=0;

reg[4:0]kernel_count=0;
reg[3:0]mp_count=0;

reg [3:0] state, nextstate;
localparam READY = 4'd0;
localparam INPUT = 4'd1;
localparam CONV = 4'd3;
localparam WRITEL0 = 4'd5;
localparam MAXP = 4'd6;
localparam READL0 = 4'd7;
localparam WRITEL1 = 4'd8;
localparam ENDING = 4'd9;

integer i=0,j=0,r=0,c=0,kc=0,kr=0;

always@(posedge clk or posedge reset)begin
 if(reset) state<=READY;
 else state<=nextstate;
end

always@(posedge clk or posedge reset)begin
 if(reset) begin
  busy<=0;
  mp_count=0;
 end
 else begin
 case(state)
 READY:begin
  if(ready)begin
   busy<=1;
  end
 end
 INPUT:begin
  cwr<=0;
  //左上
  if(kernel_count!=9)begin
   i<=i+2;
   if(i==4)begin
    j<=j+2;
    i<=0;
    if(j==4) j<=0;
   end
  end
  if(r+i-2<0) kr=0;
  else if (r+i-2>63) kr=63;
  else kr=r+i-2;

  if(c+j-2<0) kc=0;
  else if(c+j-2>63) kc=63;
  else kc=c+j-2;
 
  
 // end

 // ADD:begin
  case(kernel_count)
  0:begin
   iaddr=64*kc+kr;
  end
  1:begin
   iaddr=64*kc+kr;
   k1=idata;
  end
  2:begin
   iaddr=64*kc+kr;
   k2=idata;
  end
  3:begin
   iaddr=64*kc+kr;
   k3=idata;
  end
  4:begin
   iaddr=64*kc+kr;
   k4=idata;
  end
  5:begin
   iaddr=64*kc+kr;
   k5=idata;
  end
  6:begin
   iaddr=64*kc+kr;
   k6=idata;
  end
  7:begin
   iaddr=64*kc+kr;
   k7=idata;
  end
  8:begin
   iaddr=64*kc+kr;
   k8=idata;
  end
  9:begin
   k9=idata;
  end
  endcase
  if(kernel_count==9) kernel_count<=0;
  else   kernel_count<=kernel_count+1;
 end

 CONV:begin
  cwr<=1; csel<=0;
  caddr_wr<=64*c+r;
  temp<=k5-((k1>>4)+(k2>>3)+(k3>>4)+(k4>>2)+(k6>>2)+(k7>>4)+(k8>>3)+(k9>>4)+13'b0000000001100);
  r<=r+1;
  if(r==63)begin
   c<=c+1;
   r<=0;
  end

 end
 WRITEL0:begin
  if(temp>0) cdata_wr<=temp;
  else cdata_wr<=0;
 end
 READL0:begin
  cwr<=0;
  
  case(mp_count)
  1:begin
   crd<=1;
   caddr_rd<=64*i+j;
  end
  2:begin
   crd<=1;
   caddr_rd<=64*i+j+1;
   if(cdata_rd>temp1) temp1<=cdata_rd;
   else temp1<=temp1;
  end
  3:begin
   crd<=1;
   caddr_rd<=64*i+j+64;
   if(cdata_rd>temp1) temp1<=cdata_rd;
   else temp1<=temp1;
  end
  4:begin
   crd<=1;
   caddr_rd<=64*i+j+65;
   if(cdata_rd>temp1) temp1<=cdata_rd;
   else temp1<=temp1;
  end
  5:begin
   crd<=0;
   if(cdata_rd>temp1) temp1<=cdata_rd;
   else temp1<=temp1;
  end
  endcase
  
  // if(cdata_rd>temp1) temp1<=cdata_rd;
  // else temp1<=temp1;
  mp_count<=mp_count+1;
  // if(mp_count==4)begin
  //  cwr<=1; csel<=1;
  // end
 end
 MAXP:begin

  //進位
  if(temp1%(5'b10000)==0) cdata_wr<=temp1;
  else cdata_wr<=((temp1>>4)+1)<<4;


  // cdata_wr<=((temp1>>4)+1)<<4;
  cwr<=1; csel<=1;
  caddr_wr=L1_count;
  mp_count<=0;

  

  j<=j+2;
  if(j==62)begin
   j<=0;
   i<=i+2;
  end
  L1_count<=L1_count+1;
 end
 WRITEL1:begin
  //進位
  
  csel<=0;
  temp1<=0;
  cwr<=0;
 end
 ENDING:begin
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
 // INPUT:begin
 //  nextstate=ADD;
 // end
 INPUT:begin
  if(kernel_count==9) nextstate=CONV;
  else nextstate=INPUT;
 end
 CONV:begin
  nextstate<=WRITEL0;
 end
 WRITEL0:begin
  if(64*c+r>4095) nextstate=READL0;
  else nextstate=INPUT;
 end
 READL0:begin
  if(mp_count==5) nextstate=MAXP;
  else nextstate=READL0;
 end
 MAXP:begin
  nextstate=WRITEL1;
 end
 WRITEL1:begin
  if(L1_count>1023) nextstate=ENDING;
  else nextstate=READL0;
 end
 ENDING:begin
  nextstate=READY;
 end
 endcase
end


endmodule