# VHDL Controller for ILI9341 with 8080-I Style MCU Interface

## Hardware

This project is compiled for a Digilent BASYS-3 board, (Xilinx Artix-7 35T)

## Status

This project currently successfully resets and powers up the ILI9341. Using a separate framebuffer in the FPGA BRAM, it copies data from this onto the ILI9341 GRAM to be displayed on the screen. This framebuffer is 240x320 pixels with 8 bits per pixel (GGGRRRBB). When each pixel is read, the colour data is upscaled to 18-bit 6-6-6 RGB and sent to the ILI9341 Display RAM (GRAM).

At current clock frequency of 25MHz, we get framerates of 46 FPS. This figure is from copying the entire contents of the BRAM over, and is constant. Measures to improve the framerate are discussed below:

## Future Work

 - Investigate FMAX of the ILI9341 in 8-bit parallel MCU mode 8080-I. This is more of a curiosity, as clock-domain crossing is handled by the dual-clock BRAM framebuffer and by switching to 16-bit colour gets us to 60FPS.

 - Change from 18-bit colour to 16-bit colour to reduce transfers per pixel from 3 to 2, increasing our framerate @ 25MHz to 65FPS. It does make the simulation waveforms harder to read when debugging, however.

 - Add framerate control using FMARK (TE) or VSYNC to remove screen tearing. FMARK (if enabled) is sent from the ILI9341 with vsync information. VSYNC is sent to the ILI9341 to manage the screen refresh cycles



