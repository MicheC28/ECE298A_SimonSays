# ---------------------------------------------------------------------------
# test_simon.py – round‑0 debug test for tt_um_simonsays
# ---------------------------------------------------------------------------
import cocotb
from cocotb.triggers import RisingEdge, Timer, ClockCycles

CLK_HALF = 50          # 50 ns  → 10 MHz
MAX_CYC  = 50_000      # 5 ms at 10 MHz


# ========== helpers ========================================================
@cocotb.coroutine
async def clock_gen(clk):
    while True:
        clk.value = 0
        await Timer(CLK_HALF, units="ns")
        clk.value = 1
        await Timer(CLK_HALF, units="ns")


def resolved(sig):
    """True when *sig* (a handle) holds only 0/1 (no x/z)."""
    return all(ch in "01" for ch in sig.value.binstr.lower())


async def wait_assert(dut, cond_fn, desc: str, cycles=MAX_CYC):
    """Wait until cond_fn() is True, else raise with *desc*."""
    while not cond_fn() and cycles:
        await RisingEdge(dut.clk)
        cycles -= 1
    assert cycles, f"TIME‑OUT waiting for «{desc}»"


# ========== main test ======================================================
@cocotb.test()
async def simon_system_test(dut):
    """
    Minimal round‑0 test with explicit stage time‑outs.
    """
    cocotb.start_soon(clock_gen(dut.clk))

    # -- global reset -------------------------------------------------------
    dut.ena.value   = 1
    dut.rst_n.value = 0
    dut.uio_in.value = 0x5A            # resolved 8‑bit seed
    await ClockCycles(dut.clk, 3)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    # -- START pulse --------------------------------------------------------
    dut.ui_in.value = 0b0010_0000
    await ClockCycles(dut.clk, 4)
    dut.ui_in.value = 0

    # ------------------- staged waits --------------------------------------
    await wait_assert(dut,
                      lambda: dut.complete_IDLE.value == 1,
                      "complete_IDLE == 1")

    await wait_assert(dut,
                      lambda: dut.display_state.colour_oe.value == 1,
                      "colour_oe asserted")

    await wait_assert(dut,
                      lambda: resolved(dut.display_state.colour_bus),
                      "resolved colour_bus")

    # ------------------- capture pattern -----------------------------------
    pattern = []
    while dut.display_state.colour_oe.value == 1:
        pattern.append(int(dut.display_state.colour_bus.value) & 0b11)
        await RisingEdge(dut.clk)

    dut._log.info(f"Captured round‑0 colours: {pattern}")
    assert pattern, "colour_oe high but no resolved data captured"
