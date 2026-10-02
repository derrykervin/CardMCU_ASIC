import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


@cocotb.test()
async def test_cardmcu(dut):
    dut.ena.value = 1
    dut.ui_in.value = 0x00

    # bit0 UART_RX = 1（UART空闲）
    # bit2 SPI_MISO = 1
    dut.uio_in.value = 0b00000101

    cocotb.start_soon(
        Clock(dut.clk, 100, units="ns").start()
    )

    # Reset
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1

    # 等待CPU、UART、SPI运行
    await ClockCycles(dut.clk, 500)

    gpio_out = int(dut.uo_out.value)

    dut._log.info(f"GPIO_OUT = 0x{gpio_out:02X}")
    dut._log.info(f"UIO_OUT  = {dut.uio_out.value}")
    dut._log.info(f"UIO_OE   = {dut.uio_oe.value}")

    assert gpio_out == 0xFF, \
        f"Expected GPIO_OUT=0xFF, got 0x{gpio_out:02X}"

    dut._log.info("CardMCU C0 RTL TEST PASS")
