# ---------------------------------------------------------------------------
# test_simon.py  –  vector-driven system test for tt_um_simonsays
# ---------------------------------------------------------------------------
import pathlib, cocotb, os
from cocotb.triggers import Timer, RisingEdge, ClockCycles

CLK_HALF = 50          # 50 ns → 10 MHz
MAX_WAIT = 50_000      # 5 ms  guard-time per stage

# fixed DUT TB pins
MEM_DATA_SIG = "mem.test_data"   # 32-bit sequence register
MEM_LOAD_SIG = "mem.test_load"   # 1-cycle load pulse

# ───────── helpers ─────────────────────────────────────────────────────────
@cocotb.coroutine
async def clock_gen(clk):
    while True:
        clk.value = 0
        await Timer(CLK_HALF, units="ns")
        clk.value = 1
        await Timer(CLK_HALF, units="ns")


def resolved(sig):
    return all(ch in "01" for ch in sig.value.binstr.lower())


async def wait_for(dut, cond, msg, cycles=MAX_WAIT):
    while not cond() and cycles:
        await RisingEdge(dut.clk)
        cycles -= 1
    assert cycles, f"TIME-OUT waiting for {msg}"


async def press_colour(dut, code, ui_shadow):
    """press & release one colour button (00-red 01-blue 10-yellow 11-green)"""
    ui_shadow = (ui_shadow & 0xF0) | (1 << code)
    dut.ui_in.value = ui_shadow
    await RisingEdge(dut.clk)
    ui_shadow &= 0xF0
    dut.ui_in.value = ui_shadow
    await RisingEdge(dut.clk)
    return ui_shadow


# ───────── main test ───────────────────────────────────────────────────────
@cocotb.test()
async def simon_system_test(dut):
    """
    Iterate every row of **vectors.csv**

        mem_hex , player_hex , expect(pass|fail)
    """
    cocotb.start_soon(clock_gen(dut.clk))

    seq_data = dut._id(MEM_DATA_SIG, False)
    seq_load = dut._id(MEM_LOAD_SIG, False)

    vectors = pathlib.Path("vectors.csv").read_text().strip().splitlines()

    for idx, row in enumerate(vectors, start=1):
        mem_hex, play_hex, expect = [f.strip().lower() for f in row.split(",")]
        seq_word   = int(mem_hex, 16)
        player_pat = int(play_hex, 16)
        exp_pass   = expect.startswith("p")

        dut._log.info(
            f"\nVector {idx}: mem=0x{mem_hex}  player=0x{play_hex}  "
            f"expect={'PASS' if exp_pass else 'FAIL'}"
        )

        # ---- reset & seed --------------------------------------------------
        dut.ena.value, dut.rst_n.value = 1, 0
        dut.uio_in.value = 0xA5                 # LFSR seed
        await ClockCycles(dut.clk, 3)
        dut.rst_n.value = 1
        await RisingEdge(dut.clk)

        # ---- START pulse ---------------------------------------------------
        dut.ui_in.value = 0b0010_0000
        await ClockCycles(dut.clk, 4)
        dut.ui_in.value = 0

        # ---- wait for Idle, then load sequence -----------------------------
        await wait_for(dut,
                       lambda: dut.complete_IDLE.value == 1,
                       "complete_IDLE==1")

        seq_data.value = seq_word
        seq_load.value = 1
        await RisingEdge(dut.clk)
        seq_load.value = 0

        # ---- wait for Display ---------------------------------------------
        await wait_for(dut,
                       lambda: dut.display_state.colour_oe.value == 1,
                       "colour_oe asserted")

        captured = []
        while dut.display_state.colour_oe.value == 1:
            if resolved(dut.display_state.colour_bus):
                captured.append(int(dut.display_state.colour_bus.value) & 0b11)
            await RisingEdge(dut.clk)
        dut._log.info(f"   Display stream: {captured}")

        # ---- replay player pattern ----------------------------------------
        ui_state = 0
        for i in range(len(captured)):
            colour = (player_pat >> (2 * i)) & 0b11
            ui_state = await press_colour(dut, colour, ui_state)

        # ---- wait until CHECK finishes then read result --------------------
        await wait_for(dut,
                       lambda: dut.check_state.complete_check.value == 1,
                       "complete_check==1")

        got_pass = bool(dut.check_state.sequences_match.value)
        assert got_pass == exp_pass, (
            f"Vector {idx} FAILED: wanted "
            f"{'PASS' if exp_pass else 'FAIL'}, got "
            f"{'PASS' if got_pass else 'FAIL'}"
        )

    dut._log.info("✅  All vectors passed")


# ───────── optional hierarchy dump (PRINT_HIER=1 make) ─────────────────────
if os.getenv("PRINT_HIER") == "1":
    @cocotb.test()
    async def dump_hierarchy(dut):
        await Timer(1, units="ns")
        for child in dut:
            dut._log.info(f"{child._name} ({type(child).__name__})")
            for grand in child:
                dut._log.info(f"  └─ {grand._name} ({type(grand).__name__})")
