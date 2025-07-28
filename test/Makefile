TOPLEVEL      := tt_um_simonsays
MODULE        := test_simon
TOPLEVEL_LANG := verilog
SIM           := icarus
IVERILOG_ARGS += -g2012      # compile‑time flag only
WAVES         := 1
WAVE_FORMAT:= vcd

# pull in every RTL file but skip *_tb.v
VERILOG_SOURCES := $(shell find ../src -type f -name "*.v" ! -name "*_tb.v")

include $(shell cocotb-config --makefiles)/Makefile.sim
