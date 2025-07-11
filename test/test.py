import cocotb
from cocotb.triggers import RisingEdge, Timer
from cocotb.clock import Clock
import csv
import os

@cocotb.test()
async def test_idle_state_from_csv(dut):
    """Test the IDLE_STATE logic with LFSR output values loaded from CSV."""

    # Start 10ns clock
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

    # Reset DUT
    dut.rst_n.value = 0
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.ena.value = 1
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    # Read CSV file from same directory
    csv_file = os.path.join(os.path.dirname(__file__), "lfsr_outputs.csv")
    with open(csv_file, newline='') as f:
        reader = csv.DictReader(f)
        for row_num, row in enumerate(reader):
            for i in range(1, 5):  # LFSR_OUT_1 to LFSR_OUT_4
                lfsr_bin_str = row[f"LFSR_OUT_{i}"]
                lfsr_val = int(lfsr_bin_str, 2)

                # Set ui_in: en_IDLE=1, rst_IDLE=0, complete_LFSR=1
                dut.ui_in.value = 0b00000101
                dut.uio_in.value = lfsr_val

                # Wait a few clock cycles
                for _ in range(5):
                    await RisingEdge(dut.clk)

                # Extract results
                mem_in = dut.uo_out.value.integer
                out_flags = dut.uio_out.value.integer
                mem_load = (out_flags >> 3) & 0x1
                complete_idle = (out_flags >> 2) & 0x1
                mem_load_val = out_flags & 0x3

                dut._log.info(f"Row {row_num}, Vec {i}: LFSR={lfsr_bin_str}, MEM_IN={mem_in:08b}, MEM_LOAD={mem_load}, COMPLETE_IDLE={complete_idle}, MEM_LOAD_VAL={mem_load_val}")

                assert mem_in == lfsr_val, f"MEM_IN mismatch: expected {lfsr_val:08b}, got {mem_in:08b}"

    # Let IDLE finish after 4 values
    for _ in range(10):
        await RisingEdge(dut.clk)

    final_flags = dut.uio_out.value.integer
    assert (final_flags >> 2) & 0x1 == 1, "complete_IDLE not set after 4 loads"
