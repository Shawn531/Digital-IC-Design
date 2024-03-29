module rails(clk, reset, data, valid, result);
input        clk;
input        reset;
input  [3:0] data;
output       valid;
output       result;
reg result;
reg valid=0;

reg [3:0] stack [0:11];
reg [3:0] indata [0:11];
reg [3:0] sp=0;
reg [3:0] dp=1;
reg [3:0] dc=0;
reg [3:0] tc=1;//1 2 3 4 5
integer i=0;

always @(posedge clk or posedge reset)begin
  if(reset)begin //reset
    valid=0;sp<=0;dp<=0;
    for(i=0;i<12;i=i+1)begin
      stack[i]<=0;
      indata[i]<=0;
    end
  end
  else begin //feed data
    if(data)
      indata[dc]<=data;
  end
end

always @ (posedge clk && !data)begin
  if(indata[dp]!=stack[sp])begin
    stack[sp+1]<=tc;
    sp<=sp+1;
    tc<=tc+1;
  end
  else if(indata[dp]==stack[sp]) begin
    sp<=sp-1;
    dp<=dp+1;
  end

end

always @ (posedge clk && !data)begin
  if(dp==indata[0]+1)begin
    valid<=1;
    result<=1;
    sp<=0;dp<=0;
    for(i=0;i<12;i=i+1)begin
      stack[i]<=0;
      indata[i]<=0;
    end
  end
  else if (tc==indata[0]+1 && sp!=0)begin
    valid<=1;
    result<=0;
    sp<=0;dp<=0;
    for(i=0;i<12;i=i+1)begin
      stack[i]<=0;
      indata[i]<=0;
    end
  end
  else
    valid<=0;  
end

endmodule