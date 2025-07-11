import cocotb
from cocotb.triggers import RisingEdge, FallingEdge, Timer
from cocotb.clock import Clock
import csv
import os

@cocotb.test()
async def test_lfsr_from_csv(dut):
    # Start a clock on clk
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

    # Reset the DUT
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    # Load CSV file
    csv_path = os.path.join(os.path.dirname(__file__), "LFSR_TEST.csv")
    with open(csv_path, newline='') as csvfile:
        reader = csv.DictReader(csvfile)
        for row in reader:
            seed = int(row["LFSR_SEED"])
            dut.uio_in.value = seed
            dut.ena.value = 1

            # Reset LFSR again before each test
            dut.rst_n.value = 0
            await RisingEdge(dut.clk)
            dut.rst_n.value = 1
            await RisingEdge(dut.clk)

            # Apply seed and run LFSR
            for _ in range(20):  # Run enough cycles to trigger 'complete_LFSR'
                await RisingEdge(dut.clk)

            lfsr_out = dut.uo_out.value.integer
            complete = dut.uio_out.value.integer & 0x01

            # Output observed values
            dut._log.info(f"Seed: {seed:08b}, LFSR Output: {lfsr_out:08b}, Complete: {complete}")

            # Basic sanity checks
            assert complete == 1, f"LFSR did not complete for seed {seed:08b}"
            assert lfsr_out != 0, f"LFSR output is zero for seed {seed:08b}"
