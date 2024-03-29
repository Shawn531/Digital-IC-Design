module rails(clk, reset, data, valid, result);
  input        clk;
  input        reset;
  input  [3:0] data;
  output       valid;
  output       result;
  reg result;
  reg valid;

  reg [3:0] data_array [0:11];
  reg [3:0] stack_array [0:11];
  reg [3:0] rail_counter=1; //(1,2,3,,4...)
  reg [3:0] sp=0; //stack pointer
  reg [3:0] dp=1; //data pointer
  reg [3:0] check=0; //check the number of array
  integer i=0;

  //give the value
  always@(posedge clk or negedge reset) begin
    if (data) begin
      data_array[i] <= data ;
      i <= i+1;
      valid <= 0;
    end
  else
    i <= 0;
  end
  
  //stack implement and result determination
  always@(posedge clk && !data ) begin
    //pop out from stack array
    if (stack_array[sp]==data_array[dp]) begin 
      sp <= sp-1;
      dp <= dp+1;
      check <= check+1;
    end
    //push into stack array
    else if (rail_counter<=data_array[dp])begin 
      stack_array[sp+1] <= rail_counter ;
      sp <= sp+1;
      rail_counter=rail_counter+1;
    end
    //continue to determine
    else 
      valid = 0;

    //true
    if (check==data_array[0]) begin
      result <= 1;
      valid <= 1;
      //initailize
      rail_counter <= 1;
      sp <= 0;
      dp <= 1;
      check <= 0;
    end
    //false
    else if ( stack_array[sp] > data_array[dp]) begin
      valid <= 1;
      result <= 0;
      //initailize  
      rail_counter <= 1;
      sp <= 0;
      dp <= 1;
      check <= 0;
    end
    //continue to determine
    else 
      valid = 0;
  end
endmodule