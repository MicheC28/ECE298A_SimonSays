import cocotb
from cocotb.triggers import RisingEdge
from cocotb.clock import Clock
import pandas as pd


@cocotb.test()
async def test_wait_state_direct_colour_val(dut):
    """
    Test WAIT_STATE wrapper with direct 2-bit colour_val inputs
    """

    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    df = pd.read_csv("wait_state_test_vectors_direct.csv")

    for idx, row in df.iterrows():
        seq_len = int(row["SEQ_LEN"])

        # Reset
        dut.rst_n.value = 0
        await RisingEdge(dut.clk)
        dut.rst_n.value = 1
        await RisingEdge(dut.clk)

        for i in range(seq_len):
            colour_val_str = row[f"COL_VAL_{i+1}"]
            if pd.isna(colour_val_str):
                continue

            colour_val = int(colour_val_str, 2)

            # Set colour_val directly in lower 2 bits of ui_in
            # Bit 4 = rst_WAIT = 0
            # Bit 5 = en_WAIT = 1
            # Bit 6 = colour_in = 1
            # Upper bits [7:4] carry seq_len
            ui_in_val = (seq_len << 4) | (colour_val) | (1 << 5) | (1 << 6)

            dut.ui_in.value = ui_in_val
            await RisingEdge(dut.clk)

        # Allow state machine to complete
        for _ in range(3):
            await RisingEdge(dut.clk)

        # Read sequence_val
        actual_out = dut.seq_out_WAIT.value.integer
        expected_out = int(row["WAIT_OUT"], 2)

        assert actual_out == expected_out, (
            f"Test case {idx} failed: expected {expected_out:032b}, "
            f"got {actual_out:032b}"
        )
