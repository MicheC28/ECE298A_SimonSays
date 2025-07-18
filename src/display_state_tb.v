`timescale 1ns/1ps
`default_nettype none

module display_state_tb;
    // ─────────── clocks & resets ───────────────────────────────────────
    reg clk = 0;
    always #5 clk = ~clk;           // 100 MHz

    reg rst_display = 0;

    // ─────────── stimulus signals ──────────────────────────────────────
    reg        en_display  = 0;
    reg [31:0] seq_in_display;
    reg [3:0]  round_ctr;

    // ─────────── DUT connection ────────────────────────────────────────
    wire [1:0] colour_bus;
    wire       colour_oe;
    wire       complete_display;

    display_state dut (
        .clk              (clk),
        .rst_display      (rst_display),
        .en_display       (en_display),
        .seq_in_display   (seq_in_display),
        .round_ctr        (round_ctr),
        .colour_bus       (colour_bus),
        .colour_oe        (colour_oe),
        .complete_display (complete_display)
    );

    // ─────────── helpers ───────────────────────────────────────────────
    task automatic reset_dut;
        begin
            @(negedge clk) rst_display = 1;
            @(negedge clk) rst_display = 0;
            $display("[%0t]  RESET done", $time);
        end
    endtask

    // send one start pulse with chosen round count
    task automatic start_round(input [3:0] n);
        begin
            round_ctr = n;
            @(negedge clk) en_display = 1;
            @(negedge clk) en_display = 0;
            $display("[%0t]  Started round %0d (expect %0d colours)",
                     $time, n, n+1);
        end
    endtask

    // initialise the 32-bit sequence  (00 01 10 11 repeating)
    task automatic init_sequence;
        integer i;
        begin
            seq_in_display = 0;
            for (i = 0; i < 16; i = i + 1)
                seq_in_display[i*2 +: 2] = i[1:0];
        end
    endtask

    // ─────────── main pattern ──────────────────────────────────────────
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, display_state_tb);

        init_sequence();
        reset_dut();

        // a few different round lengths to exercise the logic
        start_round(4'd0);   repeat (20) @(posedge clk);
        start_round(4'd1);   repeat (25) @(posedge clk);
        start_round(4'd3);   repeat (40) @(posedge clk);
        start_round(4'd7);   repeat (70) @(posedge clk);
        start_round(4'd15);  repeat (140) @(posedge clk);

        $display("[%0t]  Simulation finished — open wave.vcd in GTKWave!",
                 $time);
        #20 $finish;
    end
endmodule
`default_nettype wire
