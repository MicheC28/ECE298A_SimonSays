// -----------------------------------------------------------------------------
// tb_check_state.v – minimal self-checking test-bench for check_state
// -----------------------------------------------------------------------------
`timescale 1ns/1ps
`default_nettype none          // catch typos that create implicit wires

module check_state_tb;

    // -----------------------------------------------------------------
    // DUT I/O
    // -----------------------------------------------------------------
    reg         clk  = 0;
    reg         rst_check = 0;
    reg         en_check  = 0;
    reg  [31:0] seq_play  = 32'd0;
    reg  [31:0] seq_mem   = 32'd0;
    reg  [3:0]  round_ctr_in = 4'd0;

    wire [3:0]  round_ctr_out;
    wire        complete_check;
    wire        game_complete;
    wire        rst_wait, rst_display, rst_idle, rst_check_out;

    // -----------------------------------------------------------------
    // Instantiate DUT
    // -----------------------------------------------------------------
    check_state dut (
        .clk           (clk),
        .rst_check     (rst_check),
        .en_check      (en_check),
        .seq_in_check  (seq_play),
        .seq_mem       (seq_mem),
        .round_ctr_in  (round_ctr_in),

        .round_ctr_out (round_ctr_out),
        .complete_check(complete_check),
        .game_complete (game_complete)
    );

    // -----------------------------------------------------------------
    // 50 ns half-period clock (10 MHz)
    // -----------------------------------------------------------------
    always #50 clk = ~clk;

    // -----------------------------------------------------------------
    // VCD dump
    // -----------------------------------------------------------------
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, check_state_tb);
    end

    // -----------------------------------------------------------------
    // Utility task to exercise one test vector
    // -----------------------------------------------------------------
    integer errors = 0;

    task automatic run_case;
        input [3:0]  rd_in;
        input [31:0] play_seq;
        input [31:0] mem_seq;
        input        expect_success;
    begin
        round_ctr_in = rd_in;
        seq_play     = play_seq;
        seq_mem      = mem_seq;

        // one-cycle enable pulse
        @(posedge clk) en_check = 1'b1;
        @(posedge clk) en_check = 1'b0;

        // look at outputs one cycle later
        @(posedge clk);

        if (expect_success) begin
            if (!complete_check)            errors = errors + 1;
            if (rd_in != 4'd15 &&
                round_ctr_out != rd_in + 1) errors = errors + 1;
            if (rd_in == 4'd15 && !game_complete)
                                            errors = errors + 1;
        end
        else begin
            if (complete_check)             errors = errors + 1;
            if (round_ctr_out != 4'd0)      errors = errors + 1;
        end
    end
    endtask

    // -----------------------------------------------------------------
    // Test program
    // -----------------------------------------------------------------
    localparam [31:0] GOOD_SEQ = 32'h0A_BC_DE_F0;
    localparam [31:0] BAD_SEQ  = 32'hDEAD_BEEF;

    initial begin
        // synchronous reset
        rst_check = 1'b1;
        @(posedge clk);
        rst_check = 1'b0;

        // 1) Round 0 – expect PASS
        run_case(4'd0 , GOOD_SEQ, GOOD_SEQ, 1'b1);

        // 2) Round 1 – expect FAIL
        run_case(4'd1 , BAD_SEQ , GOOD_SEQ, 1'b0);

        // 3) Round 15 – expect game_complete
        run_case(4'd15, GOOD_SEQ, GOOD_SEQ, 1'b1);

        // Results
        if (errors == 0)
            $display("check_state_tb: *** ALL TESTS PASSED ***");
        else
            $display("check_state_tb: *** FAILED with %0d error(s) ***", errors);

        $finish;
    end
endmodule

`default_nettype wire
