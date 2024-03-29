module GYR(clk, reset, set, stop, jump, gin, yin, rin, gout, yout, rout);
input   clk;
input   reset;
input   set;
input   stop;
input   jump;
input [3:0] gin;
input [3:0] yin;
input [3:0] rin;
output  gout;
output  yout;
output  rout;
reg gout, yout, rout;

reg [2:0] state, nextstate;
localparam GREEN=3'd0;
localparam YELLOW=3'd1;
localparam RED=3'd2;
localparam JUMP=3'd3;
localparam SET=3'd4;
localparam STOP=3'd5;
localparam IDLE=3'd6;

reg [3:0] gc, yc, rc;
reg [3:0] tgin, tyin, trin;

always@(posedge clk or negedge reset)begin
    if(reset) state<=IDLE;
    else state<=nextstate;
end

always@(*)begin
    case(state)
        IDLE:begin
            if(set) nextstate<=SET;
            else nextstate<=IDLE;
        end
        SET:begin
            if(jump) nextstate=JUMP;
            else nextstate<=GREEN;
        end
        GREEN:begin
            if(gc==1) nextstate<=YELLOW;
            else if(jump) nextstate<=JUMP;
            else nextstate<=GREEN;
        end
        YELLOW:begin
            if(yc==1) nextstate<=RED;
            else nextstate<=YELLOW;
        end
        RED:begin
            if(rc==1) nextstate<=GREEN;
            else nextstate<=RED;
        end
        JUMP:begin
            nextstate<=RED;
        end
        STOP:begin
            if(stop) nextstate<=STOP;
            else if(gc!=tgin) nextstate<=GREEN;
            else if(yc!=tyin) nextstate<=YELLOW;
            else if(rc!=trin) nextstate<=RED;
        end
    endcase
end

always@(posedge clk or negedge reset)begin
    if(reset)begin
        //initialize
        tgin<=0; tyin<=0; trin<=0;
        gc<=0; yc<=0; rc<=0;
        gout<=0; yout<=0; rout<=0;
    end
    else begin
    case(state)
        IDLE:begin
            tgin<=0; tyin<=0; trin<=0;
            gc<=0; yc<=0; rc<=0;
            gout<=0; yout<=0; rout<=0;       
        end
        SET:begin
            if(set)begin
                //參考值
                tgin<=gin;
                tyin<=yin;
                trin<=rin;
                //counter
                gc<=gin-1;
                yc<=yin;
                rc<=rin;
                //output
                gout<=1;
                yout<=0;
                rout<=0;
            end
        end
        GREEN:begin
            if(gc==1)begin
                gc<=tgin;
                yc<=tyin;
                rc<=trin;
            end
            else begin
                gc<=gc-1;
                gout<=1;
                yout<=0;
                rout<=0;
            end
        end
        YELLOW:begin
            if(yc==1)begin
                gc<=tgin;
                yc<=tyin;
                rc<=trin;
            end
            else begin
                yc<=yc-1;
                gout<=0;
                yout<=1;
                rout<=0;
            end      
        end
        RED:begin
            if(rc==1)begin
                gc<=tgin;
                yc<=tyin;
                rc<=trin;
            end
            else begin
                rc<=rc-1;
                gout<=0;
                yout<=0;
                rout<=1;
            end    
        end
        JUMP:begin
            gout<=0;
            yout<=0;
            rout<=1;
            rc<=rc-1;
        end  
    endcase
    end
end


endmodule