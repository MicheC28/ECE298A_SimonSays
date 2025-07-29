# ---------------------------------------------------------------------------
# test_simon.py  –  smoke‑test + CSV‑driven PASS/FAIL vectors
# ---------------------------------------------------------------------------
import os, pathlib, cocotb
from cocotb.triggers import Timer, RisingEdge, ClockCycles
from cocotb.result   import TestFailure

CLK_HALF = 50            # 50 ns → 10 MHz
MAX_WAIT = 50_000        # 5 ms guard‑time per wait_for()

# signals from hierarchy dump
MEM_DATA_SIG = "mem.test_data"     # 32‑bit word to poke
MEM_LOAD_SIG = "mem.test_load"     # 1‑cycle load strobe
MEM_VAL_SIG  = "mem.MEM_LOAD_VAL"  # 2‑bit byte‑enable (write mask)

# ───────── helpers ────────────────────────────────────────────────────────
@cocotb.coroutine
async def clock_gen(clk):
    while True:
        clk.value = 0
        await Timer(CLK_HALF, "ns")
        clk.value = 1
        await Timer(CLK_HALF, "ns")

def resolved(sig):
    """True when a vector contains only ‘0’/‘1’ (no x/z)."""
    return all(ch in "01" for ch in sig.value.binstr.lower())

async def wait_for(dut, cond, msg, cycles=MAX_WAIT):
    """Wait until *cond()* is True or raise after *cycles*."""
    while not cond() and cycles:
        await RisingEdge(dut.clk)
        cycles -= 1
    assert cycles, f"TIME‑OUT waiting for {msg}"

async def press_colour(dut, code, ui_shadow):
    """Pulse one colour button (code 0‑3) on ui_in[3:0] for one clk."""
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
    1) Smoke‑test: make sure one colour appears after START.
    2) Run every row of vectors.csv: load sequence, wait for en_WAIT,
       replay player input, wait complete_wait → complete_check and
       compare sequences_match with the expected outcome.
    """
    cocotb.start_soon(clock_gen(dut.clk))

    # 1 ───────── smoke‑test ───────────────────────────────────────────────
    dut.ena .value = 1
    dut.rst_n.value = 0
    dut.uio_in.value = 0x5A
    await ClockCycles(dut.clk, 3)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    dut.ui_in.value = 0b0010_0000          # START
    await ClockCycles(dut.clk, 4)
    dut.ui_in.value = 0

    await wait_for(dut, lambda: dut.display_state.colour_oe.value == 1,
                   "colour_oe (smoke)")
    await wait_for(dut, lambda: resolved(dut.display_state.colour_bus),
                   "colour_bus resolved (smoke)")

    smoke = []
    while dut.display_state.colour_oe.value == 1:
        smoke.append(int(dut.display_state.colour_bus.value) & 0b11)
        await RisingEdge(dut.clk)
    dut._log.info(f"Smoke‑test colours: {smoke}")
    assert smoke, "Smoke‑test saw no colours"

    # 2 ───────── CSV‑driven vectors ───────────────────────────────────────
    mem_data = dut._id(MEM_DATA_SIG, False)
    mem_load = dut._id(MEM_LOAD_SIG, False)
    mem_val  = dut._id(MEM_VAL_SIG , False)

    vecs = pathlib.Path("vectors.csv").read_text().strip().splitlines()
    if not vecs:
        raise TestFailure("vectors.csv is empty or missing")

    for idx, line in enumerate(vecs, start=1):
        mem_hex, play_hex, expect = [f.strip().lower() for f in line.split(",")]
        mem_word   = int(mem_hex, 16)
        player_pat = int(play_hex, 16)
        want_pass  = expect.startswith("p")

        dut._log.info(f"\nVector {idx}: mem=0x{mem_hex} player=0x{play_hex} "
                      f"expect={'PASS' if want_pass else 'FAIL'}")

        # ─── reset + START ────────────────────────────────────────────────
        dut.rst_n.value = 0
        await ClockCycles(dut.clk, 3)
        dut.rst_n.value = 1
        await RisingEdge(dut.clk)

        dut.ui_in.value = 0b0010_0000
        await ClockCycles(dut.clk, 4)
        dut.ui_in.value = 0

        # ─── wait IDLE done, then load memory word ────────────────────────
        await wait_for(dut, lambda: dut.complete_IDLE.value == 1,
                       "complete_IDLE")

        mem_data.value = mem_word          # data on bus
        await RisingEdge(dut.clk)          # FIX ①: give bus a stable cycle
        mem_val .value = 0b11              # both bytes valid
        mem_load.value = 1                 # strobe
        await RisingEdge(dut.clk)
        mem_load.value = 0
        mem_val .value = 0

        # ─── wait for Display to finish, then for en_WAIT ────────────────
        await wait_for(dut, lambda: dut.display_state.colour_oe.value == 1,
                       "colour_oe")
        while dut.display_state.colour_oe.value == 1:
            await RisingEdge(dut.clk)          # drain Display stream
        await wait_for(dut, lambda: dut.en_WAIT.value == 1,
                       "en_WAIT asserted")      # FIX ②

        # ─── replay player sequence during WAIT state ─────────────────────
        ui_state = 0
        for i in range((player_pat.bit_length() + 1) // 2):
            col = (player_pat >> (2 * i)) & 0b11
            ui_state = await press_colour(dut, col, ui_state)

        # ─── wait complete_wait then complete_check ───────────────────────
        await wait_for(dut, lambda: dut.complete_WAIT.value == 1,
                       "complete_WAIT")        # FIX ③
        await wait_for(dut, lambda: dut.check_state.complete_check.value == 1,
                       "complete_check")

        got_pass = bool(dut.check_state.sequences_match.value)
        assert got_pass == want_pass, (
            f"Vector {idx} FAILED: expected "
            f"{'PASS' if want_pass else 'FAIL'}, got "
            f"{'PASS' if got_pass else 'FAIL'}"
        )

    dut._log.info("✅  All vectors passed")


# optional hierarchy dump
if os.getenv("PRINT_HIER") == "1":
    @cocotb.test()
    async def dump_hierarchy(dut):
        await Timer(1, "ns")
        for c in dut:
            dut._log.info(c._name)
            for g in c:
                dut._log.info(f"  └─ {g._name}")
