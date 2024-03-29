module MMS_4num(result, select, number0, number1, number2, number3);

input        select;
input  [7:0] number0;
input  [7:0] number1;
input  [7:0] number2;
input  [7:0] number3;
output [7:0] result;

reg [7:0] result;
wire [7:0] max1;
wire [7:0] min1;
wire [7:0] max2;
wire [7:0] min2;

assign max1= number0>=number1 ? number0 : number1;
assign min1= number0<number1 ? number0 : number1;
assign max2= number2>=number3 ? number2 : number3;
assign min2= number2<number3 ? number2 : number3;

always@(*)begin
  if(select==0)
    result=max1>max2?max1:max2;
  else
    result=min1<min2?min1:min2;
end
endmodule