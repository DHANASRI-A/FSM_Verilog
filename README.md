
```verilog


`timescale 1ns/1ps

module lift( input clk, rst ,
            input [3:0] floor_request ,
             output reg move_up , move_down , open_door,
            output reg [1:0] floor,            
            output reg [3:0] f_o
             );
reg [2:0] ps,ns;
reg [4:0] timer;
  reg [1:0] f_r;


             
parameter 
        idle        = 3'b000,
        moving_up   = 3'b001,
        moving_down = 3'b010,
        door_open   = 3'b011,
        door_close  = 3'b100;
  always@(*)begin
    case(floor_request)
      4'b0001:
        f_r=2'b00;
      4'b0010:
        f_r=2'b01;
      4'b0100:
        f_r=2'b10;
      4'b1000:
        f_r=2'b11;
      default:
        f_r=2'b00;
    endcase
  end
  always@(*)begin
    case(floor)
      2'b00:
        f_o=4'b0001;
      2'b01:
        f_o=4'b0010;
      2'b10:
        f_o=4'b0100;
      2'b11:
        f_o=4'b1000;
      default:
        f_o=4'b0000;
    endcase
      
  end
  

always@(posedge clk or negedge rst)begin 
    if(!rst)begin 
    ps<=idle;
    ns<=idle;
    move_up<=0;
    move_down<=0;
    open_door<=0;
    timer<=0;
    floor<=2'b00;
    end
    else begin
     ps<=ns;
      if(ps==moving_up&&floor!=2'b11&&floor!=f_r)
        floor<=floor+1;
      else if(ps==moving_down&&floor!=2'b00&&floor!=f_r)
        floor<=floor-1;
        if(open_door)begin
        if(timer==3)
        timer<=0;
        else 
        timer<=timer+1;end
        
    end
        
 end
    
  always@(*)begin 


case(ps)
 idle:begin
     
   if(f_r==floor)
    ns=door_open;
    else if(f_r>floor)
    ns=moving_up;
    else if(f_r<floor)
    ns=moving_down;
    else 
    ns=idle;end
 moving_up:begin
    if(f_r==floor)
    ns=door_open;
    else if(f_r>floor)
    ns=moving_up;
    else 
    ns=idle;end
 moving_down:begin
     if(f_r==floor)
    ns=door_open;
    else if(f_r<floor)
    ns=moving_down;
    else 
    ns=idle;end
  door_open:begin
   if(timer==3)begin
   ns=door_close;end
   else begin
    ns=door_open;end
    end
  door_close:
    ns=idle;
  default: ns=idle;
 endcase
 end
 
 always @(posedge clk or negedge rst)
 begin 
 
 case(ps)
 idle:
    begin 

    move_up<=0;
    move_down<=0;
    open_door<=0;
 end
 moving_up:
    begin

    move_up<=1;
    move_down<=0;
    open_door<=0;
    end
 moving_down:
    begin 

    move_up<=0;
    move_down<=1;
    open_door<=0;
    end
 door_open:
    begin 

    move_up<=0;
    move_down<=0;
    open_door<=1;
    end 
 door_close:
    begin

    move_up<=0;
    move_down<=0;
    open_door<=0;
    end 
 default:begin 

    move_up<=0;
    move_down<=0;
    open_door<=0;
    end
 
 endcase
 end
endmodule              
             
