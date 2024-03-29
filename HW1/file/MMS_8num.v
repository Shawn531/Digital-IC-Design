`include "MMS_4num.v"

module MMS_8num(result, select, number0, number1, number2, number3, number4, number5, number6, number7);

input        select;
input  [7:0] number0;
input  [7:0] number1;
input  [7:0] number2;
input  [7:0] number3;
input  [7:0] number4;
input  [7:0] number5;
input  [7:0] number6;
input  [7:0] number7;
output [7:0] result; 

wire [7:0] result1;
wire [7:0] result2;
wire [7:0] max;
wire [7:0] min;

MMS_4num MMS_4num(result1, select, number0, number1, number2, number3);
MMS_4num MMS_4num2(result2, select, number4, number5, number6, number7);

assign max=result1>=result2?result1:result2;
assign min=result1<result2?result1:result2;

assign result=select?min:max;



endmodule