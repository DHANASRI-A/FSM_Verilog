# State Transistion Diagram 

                   +-------+
                   |  idle |
                   +-------+
                   
                     ^  | valid req
                     |  |
                     |  v
     +-------------+      +-------------+
     | moving_down |<---->|  moving_up  |
     +-------------+      +-------------+
                      |
                      | arrived floor
                      v        
                 +------------+
                 | door_open  |
                 +------------+
                      |
                      | timer done
                      v
                 +------------+
                 | door_close |
                 +------------+
                      |
                      |
                      v
                   +-------+
                   | idle  |
                   +-------+




```verilog
`timescale 1ns/1ps


// Top Module

module top(
    input clk, rst,
    input [3:0] floor_request,
    output move_up, move_down, open_door,
    output [1:0] floor,
    output [3:0] f_o,
    output led
);
    wire c_out;
    assign led = c_out;
 
    clockdivider clk_div(
        .c_out(c_out),
        .clk(clk),
        .rst(rst)
    );
                     
    lift elevator(
        .c_out(c_out),
        .rst(rst),
        .floor_request(floor_request), 
        .move_up(move_up), 
        .move_down(move_down), 
        .open_door(open_door),
        .floor(floor),
        .f_o(f_o)
    );
endmodule

module lift(
    input c_out, 
    input rst,
    input [3:0] floor_request,
    output reg move_up, move_down, open_door,
    output reg [1:0] floor,
    output reg [3:0] f_o
);
             
reg [2:0] ps, ns;
reg [4:0] timer;
reg [1:0] f_r;
reg invalid;

// State encoding
parameter 
    idle        = 3'b000,
    moving_up   = 3'b001,
    moving_down = 3'b010,
    door_open   = 3'b011,
    door_close  = 3'b100;

//combinational block

always @(*) begin

    // Default values to avoid latches

    ns      = ps;
    f_r     = floor;
    invalid = 1'b1;
    f_o     = 4'b0000;

    // Decode floor_request to target floor

    case (floor_request)
        4'b0001: begin f_r = 2'b00; invalid = 1'b0; end
        4'b0010: begin f_r = 2'b01; invalid = 1'b0; end
        4'b0100: begin f_r = 2'b10; invalid = 1'b0; end
        4'b1000: begin f_r = 2'b11; invalid = 1'b0; end
        default: begin f_r = floor; invalid = 1'b1; end
    endcase

    // Decode current floor to one-hot signal

    case (floor)
        2'b00: f_o = 4'b0001;
        2'b01: f_o = 4'b0010;
        2'b10: f_o = 4'b0100;
        2'b11: f_o = 4'b1000;
        default: f_o = 4'b0000;
    endcase

    // Next state (ns) logic

    case (ps)
        idle: begin
            if (!invalid) begin
                if (f_r == floor)
                    ns = door_open;
                else if (f_r > floor)
                    ns = moving_up;
                else if (f_r < floor)
                    ns = moving_down;
            end
        end

        moving_up: begin
            if (f_r == floor)
                ns = door_open;
            else if (f_r > floor)
                ns = moving_up;
            else if (f_r < floor)
                ns = moving_down; 
        end

        moving_down: begin
            if (f_r == floor)
                ns = door_open;
            else if (f_r < floor)
                ns = moving_down;
            else if (f_r > floor)
                ns = moving_up; 
        end

        door_open: begin
            if (timer == 3)
                ns = door_close;
            else
                ns = door_open;
        end

        door_close: ns = idle;

        default: ns = idle;
    endcase
end

// Sequential logic

always @(posedge c_out or posedge rst) begin
    if (rst) begin
        ps        <= idle;
        move_up   <= 0;
        move_down <= 0;
        open_door <= 0;
        timer     <= 0;
        floor     <= 2'b00;
    end
    else begin
        ps <= ns;

        // Floor movement logic

        if (ps == moving_up && floor != 2'b11 && floor != f_r)
            floor <= floor + 1;
        else if (ps == moving_down && floor != 2'b00 && floor != f_r)
            floor <= floor - 1;

        // Timer logic

        if (ps == door_open) begin
            if (timer == 3)
                timer <= 0;
            else
                timer <= timer + 1;
        end
        else
            timer <= 0;

        // Output logic based on present state (ps)

        case (ps)
            idle: begin
                move_up   <= 0;
                move_down <= 0;
                open_door <= 0;
            end
            moving_up: begin
                move_up   <= 1;
                move_down <= 0;
                open_door <= 0;
            end
            moving_down: begin
                move_up   <= 0;
                move_down <= 1;
                open_door <= 0;
            end
            door_open: begin
                move_up   <= 0;
                move_down <= 0;
                open_door <= 1;
            end
            door_close: begin
                move_up   <= 0;
                move_down <= 0;
                open_door <= 0;
            end
            default: begin
                move_up   <= 0;
                move_down <= 0;
                open_door <= 0;
            end
        endcase
    end
end

endmodule


// Clock Divider module

module clockdivider(
    output reg c_out,
    input clk, rst
);
    reg [27:0] count;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            c_out <= 0;
            count <= 0;
        end
        else if (count == 25000000) begin
            count <= 0;
            c_out <= ~c_out;
        end
        else begin
            count <= count + 1;
        end 
    end
endmodule


