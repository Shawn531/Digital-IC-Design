module demosaic(clk, reset, in_en, data_in, wr_r, addr_r, wdata_r, rdata_r, wr_g, addr_g, wdata_g, rdata_g, wr_b, addr_b, wdata_b, rdata_b, done);
input clk;
input reset;
input in_en;
input [7:0] data_in;
output reg wr_r;
output reg [13:0] addr_r;
output reg [7:0] wdata_r;
input [7:0] rdata_r;
output reg wr_g;
output reg [13:0] addr_g;
output reg [7:0] wdata_g;
input [7:0] rdata_g;
output reg wr_b;
output reg [13:0] addr_b;
output reg [7:0] wdata_b;
input [7:0] rdata_b;
output reg done;

reg [4:0] state, nextstate;
// reg [8:0] x=0 , y=0;
reg [13:0] coordinate=13'd1;
reg [3:0] counter=0;
reg [13:0] addr=0;
reg [9:0] result_b=0;
reg [9:0] result_g=0;
reg [9:0] result_r=0;


//state name
localparam R_DATA=0;
localparam FIND=1;
localparam INTER=2;
localparam WRITE=3;
localparam ENDING=4;
localparam INIT=5;



always@(posedge clk or posedge reset)begin
    if(reset) state<=INIT;
    else state<=nextstate;
end

always@(*)begin
    case(state)
        INIT: nextstate=R_DATA;
        R_DATA: begin
            if(coordinate==16383) nextstate=FIND;
            else nextstate=R_DATA;
        end
        FIND: begin
            if(counter==4) nextstate=INTER;
            else nextstate=FIND;
        end
        INTER: nextstate=WRITE;
        WRITE:begin
            if(coordinate==16383) nextstate=ENDING;
            else nextstate=FIND;
        end
        ENDING: nextstate=INIT;
    endcase
end

always@(posedge clk or posedge reset)begin
    if(reset)begin
        done<=0;
    end
    else begin
        case(state)
            INIT:begin
                if(in_en) done<=0;
            end
            R_DATA:begin //16129 cycles
                //用odd even判斷 需要x y座標 128*y+x
                //if x even and y odd - blue
                if(coordinate[6:0]%2==0 && coordinate[13:7]%2==1)begin
                    wr_r<=0; wr_g<=0; wr_b<=1;
                    addr_b<=coordinate;
                    wdata_b<=data_in;
                end
                //if x odd and y even - red
                else if(coordinate[6:0]%2==1 && coordinate[13:7]%2==0)begin
                    wr_r<=1; wr_g<=0; wr_b<=0;
                    addr_r<=coordinate;
                    wdata_r<=data_in;
                end
                //if x even and y even - green
                //if x odd and y odd - green
                else begin
                    wr_r<=0; wr_g<=1; wr_b<=0;
                    addr_g<=coordinate;
                    wdata_g<=data_in;
                end
                coordinate<=coordinate+1;
            end
            FIND:begin
                wr_r<=0; wr_g<=0; wr_b<=0;
                if(coordinate[6:0]%2==0 && coordinate[13:7]%2==1)begin
                    case(counter)
                        0:begin
                            addr_r<=coordinate-129;
                            addr_g<=coordinate-128;
                        end
                        1:begin
                            addr_r<=coordinate-127;
                            addr_g<=coordinate-1;

                            result_r<=result_r+rdata_r;
                            result_g<=result_g+rdata_g;
                        end
                        2:begin
                            addr_r<=coordinate+127;
                            addr_g<=coordinate+1;

                            result_r<=result_r+rdata_r;
                            result_g<=result_g+rdata_g;
                        end
                        3:begin
                            addr_r<=coordinate+129;
                            addr_g<=coordinate+128;

                            result_r<=result_r+rdata_r;
                            result_g<=result_g+rdata_g;
                        end
                        4:begin
                            result_r<=result_r+rdata_r;
                            result_g<=result_g+rdata_g;
                        end
                    endcase
                end
                //red
                else if(coordinate[6:0]%2==1 && coordinate[13:7]%2==0)begin
                    case(counter)
                        0:begin
                            addr_b<=coordinate-129;
                            addr_g<=coordinate-128;
                        end
                        1:begin
                            addr_b<=coordinate-127;
                            addr_g<=coordinate-1;

                            result_b<=result_b+rdata_b;
                            result_g<=result_g+rdata_g;
                        end
                        2:begin
                            addr_b<=coordinate+127;
                            addr_g<=coordinate+1;

                            result_b<=result_b+rdata_b;
                            result_g<=result_g+rdata_g;
                        end
                        3:begin
                            addr_b<=coordinate+129;
                            addr_g<=coordinate+128;

                            result_b<=result_b+rdata_b;
                            result_g<=result_g+rdata_g;
                        end
                        4:begin
                            result_b<=result_b+rdata_b;
                            result_g<=result_g+rdata_g;
                        end
                    endcase
                end
                //green 1
                else if(coordinate[6:0]%2==1 && coordinate[13:7]%2==1)begin
                    case(counter)
                        0:begin
                            addr_b<=coordinate-1;
                            addr_r<=coordinate-128;
                        end
                        1:begin
                            addr_b<=coordinate+1;
                            addr_r<=coordinate+128;

                            result_b<=result_b+rdata_b;
                            result_r<=result_r+rdata_r;
                        end
                        2:begin
                            result_b<=result_b+rdata_b;
                            result_r<=result_r+rdata_r;
                        end
                        default:begin//do nothing
                            result_b<=result_b;
                        end
                    endcase
                end
                //green 4
                else begin
                    case(counter)
                        0:begin
                            addr_b<=coordinate-128;
                            addr_r<=coordinate-1;
                        end
                        1:begin
                            addr_b<=coordinate+128;
                            addr_r<=coordinate+1;

                            result_b<=result_b+rdata_b;
                            result_r<=result_r+rdata_r;
                        end
                        2:begin
                            result_b<=result_b+rdata_b;
                            result_r<=result_r+rdata_r;
                        end
                        default:begin//do nothing
                            result_b<=result_b;
                        end
                    endcase
                end

                if(counter==4) counter<=0;
                else counter<=counter+1;
            end
            INTER:begin
                //blue
                if(coordinate[6:0]%2==0 && coordinate[13:7]%2==1)begin
                    result_r<=result_r/4;
                    result_g<=result_g/4;
                end
                //red
                else if(coordinate[6:0]%2==1 && coordinate[13:7]%2==0)begin
                    result_b<=result_b/4;
                    result_g<=result_g/4;
                end
                //green
                else begin
                    result_b<=result_b/2;
                    result_r<=result_r/2;
                end
            end
            WRITE:begin
                //blue
                if(coordinate[6:0]%2==0 && coordinate[13:7]%2==1)begin
                    wr_r<=1; wr_g=1; wr_b<=0;
                    addr_r<=coordinate; addr_g<=coordinate;
                    wdata_r<=result_r; wdata_g<=result_g;
                end
                //red
                else if(coordinate[6:0]%2==1 && coordinate[13:7]%2==0)begin
                    wr_r<=0; wr_g=1; wr_b<=1;
                    addr_b<=coordinate; addr_g<=coordinate;
                    wdata_b<=result_b; wdata_g<=result_g;
                end
                else begin
                    wr_r<=1; wr_g=0; wr_b<=1;
                    addr_b<=coordinate; addr_r<=coordinate;
                    wdata_b<=result_b; wdata_r<=result_r;
                end

                coordinate<=coordinate+1;
                result_b<=0;
                result_g<=0;
                result_r<=0;
            end
            ENDING:begin
                done<=1;
            end
        endcase
    end
end


endmodule
