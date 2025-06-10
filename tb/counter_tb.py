import cocotb
from cocotb.triggers import RisingEdge
from cocotb.clock import Clock


@cocotb.test()
async def test_counter_incrementing(dut):

    async def wait_clocks(number_of_clocks):
        for _ in range(number_of_clocks):
            await RisingEdge(dut.clk_i)

    """Check that counter increments properly when enabled."""
    cocotb.start_soon(Clock(dut.clk_i, 1, units="ns").start())

    dut.rst_i.value = 1
    dut.en_i.value = 0
    await wait_clocks(2)
    dut.rst_i.value = 0
    await wait_clocks(2)

    dut.en_i.value = 1
    await RisingEdge(dut.clk_i)
    val = dut.count_o.value.integer

    await wait_clocks(5)

    new_val = dut.count_o.value.integer
    assert new_val != val, "Error: Counter did not increment while enabled"

    await wait_clocks(2)


@cocotb.test()
async def test_counter_disable(dut):

    async def wait_clocks(number_of_clocks):
        for _ in range(number_of_clocks):
            await RisingEdge(dut.clk_i)

    """Check that counter stops incrementing when disabled."""
    cocotb.start_soon(Clock(dut.clk_i, 1, units="ns").start())

    dut.rst_i.value = 1
    dut.en_i.value = 0
    await wait_clocks(2)
    dut.rst_i.value = 0
    await wait_clocks(2)

    dut.en_i.value = 1

    await wait_clocks(3)

    dut.en_i.value = 0
    await wait_clocks(1)

    val = dut.count_o.value.integer

    await wait_clocks(5)

    assert dut.count_o.value.integer == val, "Error: Counter changed value while disabled"

    await wait_clocks(2)
