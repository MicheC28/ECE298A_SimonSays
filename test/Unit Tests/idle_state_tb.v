`timescale 1ns/1ps

module idle_state_tb;

    reg clk = 0;
    reg en_IDLE = 0;
    reg rst_IDLE = 0;
    reg complete_LFSR = 0;
    reg [31:0] lfsr_sequence = 32'hA5B6C7D8; // Example 32-bit value to output 8 bits at a time
    reg [7:0] LFSR_output = 8'h00;

    wire en_LFSR;
    wire [7:0] MEM_IN;
    wire MEM_LOAD;
    wire complete_IDLE;
    wire [1:0] MEM_LOAD_VAL;

    // Instantiate the DUT
    IDLE_STATE dut (
        .clk(clk),
        .en_IDLE(en_IDLE),
        .rst_IDLE(rst_IDLE),
        .complete_LFSR(complete_LFSR),
        .LFSR_output(LFSR_output),
        .en_LFSR(en_LFSR),
        .MEM_IN(MEM_IN),
        .MEM_LOAD(MEM_LOAD),
        .complete_IDLE(complete_IDLE),
        .MEM_LOAD_VAL(MEM_LOAD_VAL)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        $dumpfile("idle_state_tb.vcd");
        $dumpvars(0, idle_state_tb);

        // Initial reset
        rst_IDLE = 1;
        en_IDLE = 0;
        complete_LFSR = 0;
        #12;
        rst_IDLE = 0;
        en_IDLE = 1;

        // Simulate 4 LFSR loads, outputting 8 bits at a time from lfsr_sequence
        repeat (5) begin
            @(negedge clk);
            // Assign the next 8 bits of lfsr_sequence based on MEM_LOAD_VAL
            case (MEM_LOAD_VAL)
                2'b00: LFSR_output = lfsr_sequence[7:0];
                2'b01: LFSR_output = lfsr_sequence[15:8];
                2'b10: LFSR_output = lfsr_sequence[23:16];
                2'b11: LFSR_output = lfsr_sequence[31:24];
                default: LFSR_output = 8'h00;
            endcase
            complete_LFSR = 1;
            @(negedge clk);
            complete_LFSR = 0;
            // Wait for MEM_LOAD to go high and then low
            wait (MEM_LOAD == 1);
            $display("LFSR load output: %h, MEM_IN: %h, LOAD_VAL:%b", LFSR_output, MEM_IN, MEM_LOAD_VAL);
            @(negedge clk);
            wait (MEM_LOAD == 0);
        end

        // Wait for complete_IDLE to go high
        wait (complete_IDLE == 1);
        $display("IDLE state complete!");

        #20;
        $finish;
    end

    // Monitor signals
    initial begin
        $display("Time\tclk\ten_IDLE\trst_IDLE\tcomplete_LFSR\tLFSR_output\tMEM_IN\tMEM_LOAD\tcomplete_IDLE\tMEM_LOAD_VAL\ten_LFSR");
        $monitor("%0t\t%b\t%b\t%b\t%b\t%h\t%h\t%b\t%b\t%b\t%b",
            $time, clk, en_IDLE, rst_IDLE, complete_LFSR, LFSR_output, MEM_IN, MEM_LOAD, complete_IDLE, MEM_LOAD_VAL, en_LFSR);
    end

endmodule