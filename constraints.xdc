create_clock -period 10.000 -name clk -waveform {0.000 5.000} [get_ports clk]
create_generated_clock -name clk_div/led_OBUF -source [get_ports clk] -divide_by 1 [get_pins clk_div/c_out_reg/Q]
set_input_delay -clock [get_clocks clk] -min -add_delay 2.000 [get_ports {floor_request[*]}]
set_input_delay -clock [get_clocks clk] -max -add_delay 2.000 [get_ports {floor_request[*]}]
set_input_delay -clock [get_clocks clk] -min -add_delay 2.000 [get_ports rst]
set_input_delay -clock [get_clocks clk] -max -add_delay 2.000 [get_ports rst]

set_output_delay -clock [get_clocks clk] -min -add_delay 0.000 [get_ports {f_o[*]}]
set_output_delay -clock [get_clocks clk] -max -add_delay 2.000 [get_ports {f_o[*]}]
set_output_delay -clock [get_clocks clk] -min -add_delay 0.000 [get_ports {floor[*]}]
set_output_delay -clock [get_clocks clk] -max -add_delay 2.000 [get_ports {floor[*]}]

set_output_delay -clock [get_clocks clk] -min -add_delay 0.000 [get_ports move_down]
set_output_delay -clock [get_clocks clk] -max -add_delay 2.000 [get_ports move_down]
set_output_delay -clock [get_clocks clk] -min -add_delay 0.000 [get_ports move_up]
set_output_delay -clock [get_clocks clk] -max -add_delay 2.000 [get_ports move_up]
set_output_delay -clock [get_clocks clk] -min -add_delay 0.000 [get_ports open_door]
set_output_delay -clock [get_clocks clk] -max -add_delay 2.000 [get_ports open_door]

set_property IOSTANDARD LVCMOS18 [get_ports led]

set_property IOSTANDARD LVCMOS18 [get_ports {f_o[3]}]
set_property IOSTANDARD LVCMOS18 [get_ports {f_o[2]}]
set_property IOSTANDARD LVCMOS18 [get_ports {f_o[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {f_o[0]}]

set_property IOSTANDARD LVCMOS18 [get_ports {floor[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {floor[0]}]

set_property IOSTANDARD LVCMOS18 [get_ports {floor_request[3]}]
set_property IOSTANDARD LVCMOS18 [get_ports {floor_request[2]}]
set_property IOSTANDARD LVCMOS18 [get_ports {floor_request[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {floor_request[0]}]

set_property IOSTANDARD LVCMOS18 [get_ports clk]
set_property IOSTANDARD LVCMOS18 [get_ports move_down]
set_property IOSTANDARD LVCMOS18 [get_ports move_up]
set_property IOSTANDARD LVCMOS18 [get_ports open_door]
set_property IOSTANDARD LVCMOS18 [get_ports rst]

set_property PACKAGE_PIN Y11 [get_ports {f_o[3]}]
set_property PACKAGE_PIN AA11 [get_ports {f_o[2]}]
set_property PACKAGE_PIN Y19 [get_ports {f_o[1]}]
set_property PACKAGE_PIN AA9 [get_ports {f_o[0]}]

set_property PACKAGE_PIN Y9 [get_ports clk]
set_property PACKAGE_PIN AA8 [get_ports led]
set_property PACKAGE_PIN AB10 [get_ports move_down]
set_property PACKAGE_PIN AB11 [get_ports move_up]
set_property PACKAGE_PIN AB9 [get_ports open_door]
set_property PACKAGE_PIN R18 [get_ports rst]

set_property PACKAGE_PIN H19 [get_ports {floor_request[3]}]
set_property PACKAGE_PIN H18 [get_ports {floor_request[2]}]
set_property PACKAGE_PIN H17 [get_ports {floor_request[1]}]
set_property PACKAGE_PIN M15 [get_ports {floor_request[0]}]

set_property PACKAGE_PIN W12 [get_ports {floor[1]}]
set_property PACKAGE_PIN W11 [get_ports {floor[0]}]
