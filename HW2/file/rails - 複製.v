module rails(clk, reset, data, valid, result);
input        clk;
input        reset;
input  [3:0] data;
output       valid;
output       result;
reg result;
reg valid=0;

localparam NUMBER_IN = 3'd0;
localparam DATA_IN = 3'd1;
localparam STATION_POP = 3'd3;
localparam STATION_PUSH = 3'd2;
localparam OUT = 3'd4;
localparam WAIT = 3'd5;

//define state(current) and nextstate
reg  [2:0] state, nextstate;
//other para
reg [3:0] num=0;
//counter
reg  [3:0] data_counter=0; 
reg  [3:0] train_counter=1;
//stack and data array
reg [3:0] stack [0:10];
reg [3:0] indata [0:10];
reg [3:0] sp, dp;
integer i;//reg to integer

//current state, condition attention!!
always@(posedge clk)begin
    if(reset)
        state <= NUMBER_IN;
    else
        //初始化?
        state <= nextstate;
end
//next state, condition attention!!
//都要有else, if else順序搞清楚
always@(*)begin
    case(state)
        NUMBER_IN:begin
            nextstate <= DATA_IN;
        end
        DATA_IN:begin
            if(data_counter == num)//build a counter data_counter to count how many data in
                nextstate <= STATION_PUSH;
            else
                nextstate <= DATA_IN;
        end
        STATION_PUSH:begin// !!!IF ELSE的順序!!!
            if(stack[sp]==indata[dp])
                nextstate <= STATION_POP;
            else if(stack[sp]!=indata[dp])
                nextstate <= STATION_PUSH;
            else
                nextstate <= OUT; //if跑不完，有可能是state跳不出去
        end
        STATION_POP:begin//not sure
            if(stack[sp]!=indata[dp])
                nextstate<=STATION_PUSH;
            else if(stack[sp]==indata[dp])//可以試著把OUT放在ELSE
                nextstate<=STATION_POP;
            else
                nextstate<=OUT;
        end
        OUT:begin
            nextstate <= WAIT;
        end
        WAIT:begin
            nextstate <= NUMBER_IN;
        end
    endcase
end

//output state, condition attention!!
always@(posedge clk)begin

if(reset)begin//!!!initialize!!!沒有加這個會錯
    valid <= 0;
    num <= 0;
    data_counter <= 0;
    train_counter <= 1;
    sp <= 0;
    dp <= 0;
    for (i=0;i<11;i=i+1)begin
        stack[i]<=0;
        indata[i]<=0;
    end
end
else begin
    case(state)
        NUMBER_IN:begin
            num <= data;
        end
        DATA_IN:begin
            indata[data_counter] <= data;
            data_counter <= data_counter+1;
        end
        STATION_PUSH:begin//consider NULL
            if(stack[sp]!=indata[dp])begin
                stack[sp+1]<=train_counter;
                train_counter<=train_counter+1;
                sp<=sp+1;
            end
        end
        STATION_POP:begin
            if(stack[sp]==indata[dp])begin
                sp<=sp-1;
                dp<=dp+1;
            end
        end
        OUT:begin
            valid <= 1;
            if(dp == num)
                result <= 1;
            else    
                result <= 0;
        end
        WAIT:begin
            valid <= 0;
            num <= 0;
            data_counter <= 0;
            train_counter <= 1;
            sp <= 0;
            dp <= 0;
            for (i=0;i<11;i=i+1)begin
                stack[i]<=0;
                indata[i]<=0;
            end
        end
    endcase
end
end

always@(posedge clk)begin
    
end

endmodule