# Hardware Implementation of I2C (and Pong) with FPGA

This repository contains Verilog source files for a partial hardware implementation of I2C (write transaction only), and other logic required to play a basic Pong game using the DE0-Nano FPGA on a ST7567S 128x64 LCD display.

For more info, see [this blogpost](https://insertnewline.com/blog/hardware-i2c-and-pong-with-fpga/).

## Usage

Any of the GPIOs listed below can be changed in `DE0_Nano.v`.

### LCD connections
- GND → LCD GND
- 3.3V → LCD VCC
- GPIO0_24 → LCD SCL
- GPIO0_26 → LCD SDA (with 4.7k pull-up resistor)

### Pushbutton connections
These connections are for the pushbuttons used to move the Pong paddles. Note that each pushbutton requires a pull-down resistor.
- GPIO1_33 → Pushbutton for Paddle Left Up
- GPIO1_31 → Pushbutton for Paddle Left Down
- GPIO1_29 → Pushbutton for Paddle Right Up
- GPIO1_27 → Pushbutton for Paddle Right Down
