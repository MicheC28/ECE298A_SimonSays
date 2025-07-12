import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
import pandas as pd

@cocotb.test()
async def test_mem_from_csv(dut):
    """
    Test MEM module loads using vectors from CSV:
    Columns: LFSR_OUT_1,LFSR_OUT_2,LFSR_OUT_3,LFSR_OUT_4,
             LOAD_VAL_1,LOAD_VAL_2,LOAD_VAL_3,LOAD_VAL_4,MEM_OUT
    """

    # Start clock
    cocotb.fork(Clock(dut.clk, 10, units="ns").start())

    # Apply reset
    dut.rst_n <= 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst_n <= 1
    await RisingEdge(dut.clk)

    # Load CSV test vectors
    df = pd.read_csv("mem_test_vectors.csv")

    for idx, row in df.iterrows():
        # Reset before each vector test
        dut.rst_n <= 0
        await RisingEdge(dut.clk)
        dut.rst_n <= 1
        await RisingEdge(dut.clk)

        mem_out_expected = int(row["MEM_OUT"], 2)

        # We will apply 4 sequential loads, one per clock cycle
        for i in range(1, 5):
            # Set MEM_LOAD high for one cycle
            dut.ui_in[0] <= 1  # MEM_LOAD bit
            # Set MEM_IN 8-bit value
            lfsr_out = row[f"LFSR_OUT_{i}"]
            dut.uio_in <= int(lfsr_out, 2)

            # Set MEM_LOAD_VAL 2-bit selector
            load_val = row[f"LOAD_VAL_{i}"]
            # ui_in[2:1] hold MEM_LOAD_VAL bits
            # To set bits 1 and 2, combine carefully:
            # Clear bits 1,2 then set
            current_ui_in = dut.ui_in.value.integer
            # Clear bits 1 and 2:
            current_ui_in &= ~(0b110)
            # Set new load_val shifted to bits 1 and 2
            current_ui_in |= (int(load_val, 2) << 1)
            dut.ui_in <= current_ui_in

            # Wait one clock cycle with MEM_LOAD asserted
            await RisingEdge(dut.clk)

            # De-assert MEM_LOAD for next cycle (except last)
            if i != 4:
                dut.ui_in[0] <= 0
                await RisingEdge(dut.clk)

        # After all 4 loads, MEM_OUT should match expected
        mem_out_actual = dut.MEM_OUT.value.integer

        assert mem_out_actual == mem_out_expected, (
            f"Test vector {idx}: MEM_OUT mismatch\n"
            f"Expected: {row['MEM_OUT']} ({mem_out_expected:#010x})\n"
            f"Actual:   {mem_out_actual:032b} ({mem_out_actual:#010x})"
        )
