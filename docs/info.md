## How it works

CardMCU C0 is an 8-bit microcontroller prototype implemented for Tiny Tapeout SKY130.

It contains:
- an 8-bit CPU
- 8-bit GPIO input and output
- UART transmit and receive
- SPI master interface
- a 32-bit free-running timer
- internal program ROM and data RAM

The CPU accesses peripherals through a memory-mapped I/O interface.

GPIO input is connected to `ui_in[7:0]` and GPIO output is connected to `uo_out[7:0]`.

The bidirectional pins are used as:
- `uio[0]`: UART RX
- `uio[1]`: UART TX
- `uio[2]`: SPI MISO
- `uio[3]`: SPI SCLK
- `uio[4]`: SPI MOSI
- `uio[5]`: SPI CS_N
- `uio[6:7]`: unused

The design is intended to run at 10 MHz.

## How to test

Apply a clock to `clk` and hold `rst_n` low to reset the design.

Release `rst_n` and allow the internal program ROM to execute.

For the current CardMCU C0 demonstration firmware, `uo_out[7:0]` should eventually become `0xFF`.

UART RX should idle high on `uio[0]`.

UART TX output is available on `uio[1]`.

SPI signals are available on:
- MISO: `uio[2]`
- SCLK: `uio[3]`
- MOSI: `uio[4]`
- CS_N: `uio[5]`

The current automated Cocotb test runs the design with a 10 MHz clock and verifies that the GPIO output reaches `0xFF`.

## External hardware

No external hardware is required for the basic GPIO test.

A USB-to-UART adapter can be connected to the UART pins for serial testing.

An SPI peripheral may be connected to the SPI pins for SPI testing.
