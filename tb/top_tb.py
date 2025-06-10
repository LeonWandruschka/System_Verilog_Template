import cocotb
from cocotb.triggers import RisingEdge
from cocotb.clock import Clock


async def wait_clocks(signal, n):
    """Wait for n rising clock edges."""
    for _ in range(n):
        await RisingEdge(signal)


@cocotb.test()
async def test_reset_behavior(dut):
    """Check that toggle output is 0 after reset."""
    cocotb.start_soon(Clock(dut.clk_i, 1, units="ns").start())

    dut.rst_i.value = 1
    await wait_clocks(dut.clk_i, 2)

    dut.rst_i.value = 0
    await wait_clocks(dut.clk_i, 1)

    assert dut.count_toggle_o.value == 0, "Error: Toggle output is not 0 after reset"


@cocotb.test()
async def test_toggle_on_overflow(dut):
    """Check that toggle output inverts on overflow."""
    cocotb.start_soon(Clock(dut.clk_i, 1, units="ns").start())

    dut.rst_i.value = 1
    await wait_clocks(dut.clk_i, 2)
    dut.rst_i.value = 0

    prev_toggle = dut.count_toggle_o.value.integer

    await wait_clocks(dut.clk_i, 257)  # 256 cycles + 1 to check the new state

    new_toggle = dut.count_toggle_o.value.integer
    cocotb.log.info(f"Toggle before overflow: {prev_toggle}, after overflow: {new_toggle}")

    assert new_toggle != prev_toggle, "Error: Toggle output did not change after overflow"


@cocotb.test()
async def test_toggle_stable_until_next_overflow(dut):
    """Check that toggle output remains stable until the next overflow."""
    cocotb.start_soon(Clock(dut.clk_i, 1, units="ns").start())

    dut.rst_i.value = 1
    await wait_clocks(dut.clk_i, 2)
    dut.rst_i.value = 0

    await wait_clocks(dut.clk_i, 257)  # First overflow
    prev_toggle = dut.count_toggle_o.value.integer

    await wait_clocks(dut.clk_i, 255)  # Almost another full cycle
    new_toggle = dut.count_toggle_o.value.integer

    cocotb.log.info(f"Toggle after 1st overflow: {prev_toggle}, after 255 more cycles: {new_toggle}")
    assert new_toggle == prev_toggle, "Error: Toggle output changed too early"

