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

3. [State Table](#state-table)
4. [State Transistion Diagram](#state-transistion-diagram)
5. [Hardware Interface and ZedBoard PMOD LED Mapping](#hardware-interface-and-zedboard-pmod-led-mapping)
6. [Resource Utilization](#resource-utilization)
7. [Post-Synthesis RTL Schematic – Elevator Controller](#post-synthesis-rtl-schematic-–-elevator-controller)
8. [Output Video](#output-video)
9. [Future Work](#future-work)
10. [Conclusion](#conclusion)

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

## Finite State Machine (FSM) Design



## Floor Request Processing

The elevator receives floor requests through a 4-bit one-hot encoded input signal `floor_request`. Each bit corresponds to a specific floor:

* `4'b0001` → Floor 0
* `4'b0010` → Floor 1
* `4'b0100` → Floor 2
* `4'b1000` → Floor 3

The system decodes this input to determine the target floor (`f_r`) for the elevator to move to. If the input matches one of the valid one-hot patterns, the corresponding floor is selected. If the input is invalid (e.g., no bits set or multiple bits set), the elevator continues to stay at the current floor.

Below is the core Verilog snippet that handles this decoding:

```verilog
// Decode floor_request to target floor
case (floor_request)
    4'b0001: f_r = 2'b00;  // Request for floor 0
    4'b0010: f_r = 2'b01;  // Request for floor 1
    4'b0100: f_r = 2'b10;  // Request for floor 2
    4'b1000: f_r = 2'b11;  // Request for floor 3
    default: f_r = floor;  // Invalid request - hold current floor
endcase
```

This decoded target floor is then used by the finite state machine (FSM) to decide whether the elevator should move up, move down, or open the door if it is already at the requested floor.

---



### Movement and Door Control Logic

The elevator moves up or down based on the current and target floors, controlled by the FSM states. The door opens when the elevator reaches the target floor and stays open for a fixed time using a timer.

**Key behaviors:**

* Move up: Increment floor until target is reached.
* Move down: Decrement floor until target is reached.
* Door open: Stay open for 3 clock cycles.
* Door close: Transition back to idle.

**Relevant code snippets:**

```verilog
// Floor movement logic
if (ps == moving_up && floor != 2'b11 && floor != f_r)
    floor <= floor + 1;
else if (ps == moving_down && floor != 2'b00 && floor != f_r)
    floor <= floor - 1;

// Timer logic for door open state
if (ps == door_open) begin
    if (timer == 3)
        timer <= 0;
    else
        timer <= timer + 1;
end else
    timer <= 0;

// Output control based on state
case (ps)
    moving_up: begin
        move_up <= 1;
        move_down <= 0;
        open_door <= 0;
    end
    moving_down: begin
        move_up <= 0;
        move_down <= 1;
        open_door <= 0;
    end
    door_open: begin
        move_up <= 0;
        move_down <= 0;
        open_door <= 1;
    end
    default: begin
        move_up <= 0;
        move_down <= 0;
        open_door <= 0;
    end
endcase
```

This logic ensures smooth elevator movement and door timing aligned with the FSM states.

---

### Floor Display Implementation

The elevator’s current floor is shown using a one-hot encoded 4-bit output signal `f_o`. Each bit corresponds to an LED indicator representing a floor:

* `4'b0001` → Floor 0 LED ON
* `4'b0010` → Floor 1 LED ON
* `4'b0100` → Floor 2 LED ON
* `4'b1000` → Floor 3 LED ON

This one-hot encoding simplifies the hardware interface, allowing direct connection to LED indicators.

**Code snippet for floor display decoding:**

```verilog
// Decode current floor to one-hot output for LEDs
case (floor)
    2'b00: f_o = 4'b0001;
    2'b01: f_o = 4'b0010;
    2'b10: f_o = 4'b0100;
    2'b11: f_o = 4'b1000;
    default: f_o = 4'b0000;
endcase
```

This ensures that only the LED corresponding to the current floor is lit at any time, giving clear visual feedback on the elevator’s position.

---

Got it! Let me make it accurate **and** concise, keeping all important details:

---

### Code Explanation and Module Overview

``` verilog
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
```

The elevator controller is implemented in Verilog as a single FSM-based module named `lift`. It handles inputs: a slow clock (`c_out`), reset (`rst`), and a 4-bit one-hot floor request.

The FSM includes five states:

* `idle` — waiting for requests
* `moving_up` — incrementing floors
* `moving_down` — decrementing floors
* `door_open` — door is open with timer
* `door_close` — door closing before idle

Outputs control elevator movement signals (`move_up`, `move_down`), door (`open_door`), current floor (`floor`), and a one-hot floor display (`f_o`).

Key logic blocks include:

* Decoding the one-hot floor request into a target floor register
* Managing floor count during movement
* Timing the door open duration with a timer counter
* Generating the floor display signals for LEDs

A separate clock divider module generates the slower clock `c_out` from the 100 MHz board clock for proper timing.

This integrated design makes the elevator control simple, modular, and easy to extend.

---
## State Table


| **Present State** | **Condition**                          | **Next State** | **Outputs**             |
| ----------------- | -------------------------------------- | -------------- | ----------------------- |
| Idle              | Valid floor request & target > current | Moving Up      | `move_up=1`, others 0   |
| Idle              | Valid floor request & target < current | Moving Down    | `move_down=1`, others 0 |
| Idle              | Valid floor request & target = current | Door Open      | `open_door=1`, others 0 |
| Moving Up         | Target floor = current                 | Door Open      | `open_door=1`, others 0 |
| Moving Up         | Target floor > current                 | Moving Up      | `move_up=1`, others 0   |
| Moving Up         | Target floor < current                 | Moving Down    | `move_down=1`, others 0 |
| Moving Down       | Target floor = current                 | Door Open      | `open_door=1`, others 0 |
| Moving Down       | Target floor < current                 | Moving Down    | `move_down=1`, others 0 |
| Moving Down       | Target floor > current                 | Moving Up      | `move_up=1`, others 0   |
| Door Open         | Timer < 3                              | Door Open      | `open_door=1`, others 0 |
| Door Open         | Timer = 3                              | Door Close     | all outputs 0           |
| Door Close        | Always                                 | Idle           | all outputs 0           |


## State Transistion Diagram 

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


## Hardware Interface and ZedBoard PMOD LED Mapping

The following constraints were applied to interface the design signals properly with the ZedBoard hardware and ensure timing closure.

### Clock Settings

* **System clock (`clk`)** is configured at **100 MHz** with a 10 ns period, matching the ZedBoard onboard clock.
* A generated clock `clk_div/led_OBUF` is defined for internal clock division, currently with divide\_by 1.

### I/O Standards and Timing

* All I/O ports use the **LVCMOS18** standard, compatible with ZedBoard voltage levels (1.8 V).
* Input and output delays are specified with a max delay of 2 ns to assist timing analysis and synthesis.

### Pin Assignments

| Signal             | Pin  | Description                      |
| ------------------ | ---- | -------------------------------- |
| `f_o[3]`           | Y11  | Floor indicator LED bit 3        |
| `f_o[2]`           | AA11 | Floor indicator LED bit 2        |
| `f_o[1]`           | Y19  | Floor indicator LED bit 1        |
| `f_o[0]`           | AA9  | Floor indicator LED bit 0        |
| `clk`              | Y9   | 100 MHz system clock             |
| `led`              | AA8  | General purpose LED              |
| `move_down`        | AB10 | Elevator move down control       |
| `move_up`          | AB11 | Elevator move up control         |
| `open_door`        | AB9  | Elevator door open control       |
| `rst`              | R18  | Reset signal                     |
| `floor_request[3]` | H19  | Floor request input switch bit 3 |
| `floor_request[2]` | H18  | Floor request input switch bit 2 |
| `floor_request[1]` | H17  | Floor request input switch bit 1 |
| `floor_request[0]` | M15  | Floor request input switch bit 0 |
| `floor[1]`         | W12  | Current floor indicator bit 1    |
| `floor[0]`         | W11  | Current floor indicator bit 0    |

### Visual Reference

For detailed pin locations and PMOD connector mapping, please refer to the figure below:

![ZedBoard PMOD Connector LED Pin Mapping](https://github.com/DHANASRI-A/VLSI_Projects/blob/0be46fc324880e7d1bf097e1597ca72ac8274495/Pictures/Pmod.png)


## Output Video

[![Elevator FSM Demo on ZedBoard](https://img.youtube.com/vi/E4Hz2WeLNzQ/0.jpg)](https://youtube.com/shorts/E4Hz2WeLNzQ?feature=share)

---

## Resource Utilization

![image alt](https://github.com/DHANASRI-A/VLSI_Projects/blob/8b240c7f7d10d2fe119c465f001cc209d9c9884c/Pictures/Resource%20Utilization.png)


## **Future Work**

While the current design works well for a basic 4-floor elevator, there’s plenty of room to make it smarter and more versatile. In the future, we’d like to:

* **Add more floors** — Expand beyond the current 4-floor limit so the design can handle taller buildings.
* **Handle multiple requests at once** — Let the elevator store and process several floor calls instead of just one at a time.
* **Make it smarter about movement** — Add logic so it chooses the most efficient path, rather than moving in a fixed order.
* **Improve how we display floors** — Upgrade from simple LEDs to a 7-segment display, LCD screen, or even a serial output with more detailed status.
* **Recover from faults automatically** — Reduce the need for manual resets by adding self-recovery features.

---




