# ---------------------------------------------------------------------------
# test_display_state.py  –  cocotb testbench for display_state
# ---------------------------------------------------------------------------
import os
import csv
from pathlib import Path

import cocotb
from cocotb.triggers import RisingEdge, Timer

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
CLK_HALF = 50_000          # 50 ns → 10 MHz clock
CSV_PATH = Path(__file__).with_name("vectors.csv")   # default location

# You may also override the CSV file via environment variable:
#   make CSV=/full/path/to/other_vectors.csv
CSV_PATH = Path(os.getenv("CSV", CSV_PATH))

# ---------------------------------------------------------------------------
# Clock generator coroutine
# ---------------------------------------------------------------------------
@cocotb.coroutine
async def clock_gen(clk):
    while True:
        clk.value = 0
        await Timer(CLK_HALF, units="ns")
        clk.value = 1
        await Timer(CLK_HALF, units="ns")

# ---------------------------------------------------------------------------
# Helper: apply one test‑vector row
# ---------------------------------------------------------------------------
async def apply_round(dut, pattern_int: int, n_round: int, idle_cycles=2):
    """
    pattern_int : 32‑bit integer, colours packed LSB‑first
    n_round     : current round counter to drive
    idle_cycles : extra clocks to observe tri‑state bus after the round
    """
    dut.seq_in_display.value = pattern_int
    dut.round_ctr.value      = n_round

    # --- one‑cycle enable pulse -------------------------------------------
    dut.en_display.value = 1
    await RisingEdge(dut.clk)          # DUT samples enable=1
    dut.en_display.value = 0

    # first valid colour appears ONE clock later
    await RisingEdge(dut.clk)

    for i in range(n_round + 1):
        exp = (pattern_int >> (2 * i)) & 0b11
        await RisingEdge(dut.clk)      # sample after NBA updates

        # Check OE and colour value
        assert dut.colour_oe.value == 1,          f"OE low at colour {i}"
        assert int(dut.colour_bus.value) == exp, (
            f"colour {i}: exp {exp:01x} got {int(dut.colour_bus.value):01x}"
        )

        # complete_display only on last colour
        if i == n_round:
            assert dut.complete_display.value == 1, "complete_display not asserted"
        else:
            assert dut.complete_display.value == 0, f"premature complete_display @ {i}"

    # Next edge → pulse should be cleared
    await RisingEdge(dut.clk)
    assert dut.complete_display.value == 0,        "complete_display stuck high"

    # --- idle bus tri‑state check -----------------------------------------
    for _ in range(idle_cycles):
        await RisingEdge(dut.clk)
        assert dut.colour_oe.value == 0,           "OE high in idle"
        assert not dut.colour_bus.value.is_resolvable, "bus not tri‑stated in idle"

# ---------------------------------------------------------------------------
# Top‑level cocotb test
# ---------------------------------------------------------------------------
@cocotb.test()
async def display_state_basic(dut):
    """Run all vectors from vectors.csv."""
    cocotb.start_soon(clock_gen(dut.clk))

    # synchronous reset
    dut.rst_display.value = 1
    await RisingEdge(dut.clk)
    dut.rst_display.value = 0
    await RisingEdge(dut.clk)

    # --- iterate over CSV rows --------------------------------------------
    if not CSV_PATH.exists():
        raise FileNotFoundError(f"CSV file not found: {CSV_PATH}")

    with CSV_PATH.open(newline="") as f:
        rdr = csv.reader(row for row in f if not row.lstrip().startswith("#"))
        for line_num, row in enumerate(rdr, start=1):
            if len(row) < 2:
                cocotb.log.warning(f"Skipping malformed row {line_num}: {row}")
                continue

            pattern_hex, round_str, *rest = row
            try:
                pattern_int = int(pattern_hex, 16)
                round_ctr   = int(round_str,   0)
                idle        = int(rest[0],     0) if rest else 2
            except ValueError as e:
                cocotb.log.warning(f"Bad data on line {line_num}: {row} ({e})")
                continue

            cocotb.log.info(f"Vector {line_num}: pattern=0x{pattern_int:08X} "
                            f"round={round_ctr} idle={idle}")
            await apply_round(dut, pattern_int, round_ctr, idle)

    cocotb.log.info("All CSV vectors passed.")
