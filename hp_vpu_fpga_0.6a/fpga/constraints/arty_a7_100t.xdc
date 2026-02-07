## Arty A7-100T Constraints for VPU Self-Checking Test
## Target: xc7a100tcsg324-1

## Clock - 100 MHz oscillator, but constrain to 50 MHz for VPU timing
set_property -dict { PACKAGE_PIN E3 IOSTANDARD LVCMOS33 } [get_ports { clk_100mhz }]
create_clock -period 20.000 -name sys_clk [get_ports clk_100mhz]

## Reset - BTN0 (directly active high from BTN0)
set_property -dict { PACKAGE_PIN D9 IOSTANDARD LVCMOS33 } [get_ports { btn0 }]

## LEDs
set_property -dict { PACKAGE_PIN H5  IOSTANDARD LVCMOS33 } [get_ports { led[0] }]  ;# LD4 - PASS
set_property -dict { PACKAGE_PIN J5  IOSTANDARD LVCMOS33 } [get_ports { led[1] }]  ;# LD5 - FAIL
set_property -dict { PACKAGE_PIN T9  IOSTANDARD LVCMOS33 } [get_ports { led[2] }]  ;# LD6 - BUSY
set_property -dict { PACKAGE_PIN T10 IOSTANDARD LVCMOS33 } [get_ports { led[3] }]  ;# LD7 - RUNNING

## Configuration
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
