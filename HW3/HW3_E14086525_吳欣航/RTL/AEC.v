module AEC(clk, rst, ascii_in, ready, valid, result);

// Input signal
input clk;
input rst;
input ready;
input [7:0] ascii_in;

// Output signal
output reg valid;
output reg [6:0] result;

reg [2:0] state, nextstate;
localparam DATAIN = 3'b000;
localparam POSTFIX = 3'b001;
localparam CALCULATE = 3'b010;
localparam OUT = 3'b011;
localparam WAIT = 3'b100;

reg [7:0] data_in;

//out array
reg [7:0] out [0:15];//255
//pointer of out array
reg [4:0] outp, outp1;

//stack array
reg [7:0] stack [0:15];//255
reg [7:0] stack1 [0:15];//255
reg [4:0] sp, sp1;//1;

//data array
reg [7:0] arraydata [0:15];
reg [4:0] ap;

reg [4:0] stack_bracket_count;//1

integer i;//0


always@(posedge clk or posedge rst)begin
if(rst)begin
    
    valid=0;
    result=0;
    outp=1;
    outp1=1;
    sp=1;
    sp1=1;
    ap=0;
    stack_bracket_count=1;
    for(i=0;i<16;i=i+1)begin
        out[i]<=255;
        stack[i]<=255;
        stack1[i]<=255;
        arraydata[i]<=255;
    end

end
else begin
    case(state)
    DATAIN:begin
        if(ascii_in)begin
            if(data_in=="=")begin
                ap<=0;
            end
            else begin
                arraydata[ap]<=data_in;
                ap<=ap+1;
            end
        end
    end
    POSTFIX:begin
        case(arraydata[ap])
        1,2,3,4,5,6,7,8,9,0,10,11,12,13,14,15:begin  //maybe could improve
            out[outp]<=arraydata[ap];
            outp<=outp+1;
            ap<=ap+1;
        end
        "*":begin
            if(stack[sp-1]=="*")begin
                out[outp]<=stack[sp-1];
                outp<=outp+1;
                
                stack[sp-1]<=arraydata[ap];
                ap<=ap+1;

            end
            else begin
                stack[sp]<=arraydata[ap];
                sp<=sp+1;
                ap<=ap+1;                
            end
        end
        "+","-":begin
            if(stack[sp-1]=="+"||stack[sp-1]=="-"||stack[sp-1]=="*")begin
                out[outp]<=stack[sp-1];
                outp<=outp+1;
                sp<=sp-1;
            end
            else begin
                stack[sp]<=arraydata[ap];
                sp<=sp+1;
                ap<=ap+1;
            end
        end
        "(":begin
            stack[sp]<=arraydata[ap];
            sp<=sp+1;
            ap<=ap+1;            
        end
        ")":begin
            if(stack[sp-1]!="(")begin
                out[outp]<=stack[sp-1];
                outp<=outp+1;
                sp<=sp-1;
            end
            else begin
                sp<=sp-1;
                ap<=ap+1;
            end
        end
        255:begin
            if(sp!=0)begin                
                out[outp]<=stack[sp-1];
                outp<=outp+1;
                sp<=sp-1;
                
            end
        end
        endcase

        
    end
    CALCULATE:begin
        case(out[outp1])
        1,2,3,4,5,6,7,8,9,0,10,11,12,13,14,15:begin
            stack1[sp1]<=out[outp1];
            sp1<=sp1+1;
            outp1<=outp1+1;
        end
        "*":begin
            if(out[outp1+1]==255) sp1<=0;
            else sp1<=sp1-1;
            stack1[sp1-2]<=stack1[sp1-1]*stack1[sp1-2];
            outp1<=outp1+1;          
            
        end
        "+":begin
            if(out[outp1+1]==255) sp1<=0;
            else sp1<=sp1-1;
            stack1[sp1-2]<=stack1[sp1-1]+stack1[sp1-2];
            outp1<=outp1+1;
        end
        "-":begin
            if(out[outp1+1]==255) sp1<=0;
            else sp1<=sp1-1;
            stack1[sp1-2]<=stack1[sp1-2]-stack1[sp1-1];
            outp1<=outp1+1;
        end
        endcase
    end
    OUT:begin
        valid<=1;
        result<=stack1[1];
    end
    WAIT:begin
        valid=0;
        result=0;
        outp=0;
        outp1=0;
        sp=1;
        sp1=1;
        ap=0;
        stack_bracket_count=1;
        for(i=0;i<16;i=i+1)begin
            out[i]<=255;
            stack[i]<=255;
            stack1[i]<=255;
            arraydata[i]<=255;
        end
    end
    endcase
end
end

//data pass a ASCII converter first
always@(*)begin
    case(ascii_in)
        10'd48: data_in = 0;
        10'd49: data_in = 1;
        10'd50: data_in = 2;
        10'd51: data_in = 3;
        10'd52: data_in = 4;
        10'd53: data_in = 5;
        10'd54: data_in = 6;
        10'd55: data_in = 7;
        10'd56: data_in = 8;
        10'd57: data_in = 9;
        10'd97: data_in = 10;
        10'd98: data_in = 11;
        10'd99: data_in = 12;
        10'd100: data_in = 13;
        10'd101: data_in = 14;
        10'd102: data_in = 15;
        10'd40: data_in = "(";
        10'd41: data_in = ")";
        10'd42: data_in = "*";
        10'd43: data_in = "+";
        10'd45: data_in = "-";
        10'd61: data_in = "=";
    endcase
end


always@(posedge clk or posedge rst)begin
    if(rst) state=DATAIN;
    else state=nextstate;
end

always@(*)begin
    case(state)
    DATAIN:begin
        if(data_in=="=") nextstate=POSTFIX;
        else nextstate=DATAIN;
    end
    POSTFIX:begin
        if(sp==0) nextstate=CALCULATE;
        else nextstate=POSTFIX;
    end
    CALCULATE:begin
        if(sp1!=0) nextstate=CALCULATE;
        else nextstate=OUT;
    end
    OUT:begin
        nextstate<=WAIT;
    end
    WAIT:begin
        nextstate<=DATAIN;
    end
    default:begin
        nextstate<=DATAIN;
    end
    endcase
end

endmodule