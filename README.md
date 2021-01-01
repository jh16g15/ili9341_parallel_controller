# VHDL Controller for ILI9341 with 8080-I Style MCU Interface

## Hardware

This project is compiled for a Digilent BASYS-3 board, (Xilinx Artix-7 35T)

## Status

This project currently successfully resets and powers up the ILI9341 and writes a small strip of Red, Green and Blue pixels to the top line of the screen.

## Planned Features

- Add a standard BRAM interface to allow the controller to read from an internal FPGA Block RAM framebuffer, as reads from the ILI9341 frame memory are very slow. This decoupling will make it far easier to use, as the user can then interface with a standard BRAM using, for example a Microblaze soft processor to easily update the screen contents, rather than requiring a state machine to initialise the screen contents.
- Colour conversion to allow the internal FPGA framebuffer to use up less memory (16-bit 240x320 framebuffer would require 70% of the 1.8Mb BRAM on the A7-35T, so we can reduce this requirement by switching to 8-bit or 9-bit colour)
