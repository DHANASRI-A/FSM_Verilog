# Project Overview


| Aspect                        | Details                                                                         |
| ----------------------------- | ------------------------------------------------------------------------------- |
| Objective                     | Implementation of a finite state machine (FSM) in Verilog for elevator control. |
| Floors Supported              | 4                                                                               |
| Floor Request Handling        | One-hot encoded signal (single request at a time).                              |
| Door Operation Logic          | Door open for \~3 clock cycles at 2 Hz frequency.                               |
| Display Output                | LED indicators via PMOD interface.                                              |
| Target Hardware               | ZedBoard FPGA.                                                                  |
| Hardware Description Language | Verilog.                                                                        |
| Key Components                | Clock divider module, FSM design.                                               |
| Limitations                   | Only single floor request accepted; no multiple concurrent requests supported.  |


---



## Table of Contents

1. [Introduction](#introduction)
2. [Design and Implementation Details](#design-and-implementation-details)
   
   - [Clock Divider and Timing Control](#clock-divider-and-timing-control)
   - [Finite State Machine (FSM) Design](#finite-state-machine-fsm-design)
   - [Floor Request Processing](#floor-request-processing)
   - [Movement and Door Control Logic](#movement-and-door-control-logic)
   - [Floor Display Implementation](#floor-display-implementation)
   - [Code Explanation and Module Overview](#code-explanation-and-module-overview)

3. [Operation Walkthrough](#operation-walkthrough)
4. [Hardware Interface and ZedBoard PMOD LED Mapping](#hardware-interface-and-zedboard-pmod-led-mapping)
5. [Testing and Verification](#testing-and-verification)
6. [Limitations and Future Enhancements](#limitations-and-future-enhancements)
7. [Conclusion](#conclusion)

---


## Introduction

This project implements a finite state machine (FSM) in Verilog to control a digital elevator system. It covers essential functions such as floor request handling, movement control, door timing, and floor display on an FPGA platform. The design serves as a practical example of hardware description and digital system design.

---
## Design and Implementation Details

### Clock Divider and Timing Control

```verilog

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
``` 

The ZedBoard provides a 100 MHz input clock (`clk`), which is too fast for timing elevator operations like door opening or floor transitions. To make these actions human-perceivable, we divide the clock down to 2 Hz.

**How 2 Hz is generated:**

* The module uses a 28-bit counter that increments every 10 ns (1 / 100 MHz).
* When the counter reaches 25,000,000, it resets and toggles the output clock `c_out`.
* Since toggling happens every 25 million cycles, one full cycle of `c_out` takes 50 million clock cycles (two toggles per cycle).

Calculating output frequency:

$$
f_{out} = \frac{f_{in}}{2 \times \text{terminal count}} = \frac{100,000,000}{2 \times 25,000,000} = 2 \text{ Hz}
$$

So, the output `c_out` toggles at 2 Hz, perfectly pacing the FSM operations for visible elevator behavior.

The asynchronous reset (`rst`) initializes the counter and output to zero for a clean start.

---





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


