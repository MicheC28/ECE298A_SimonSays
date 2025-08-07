// -----------------------------------------------------------------------------
// tb_check_state.v – self-checking test-bench for check_state (round 14 logic)
// -----------------------------------------------------------------------------
`timescale 1ns/1ps
`default_nettype none

module check_state_tb;

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

    check_state dut (
        .clk           (clk),
        .rst_check     (rst_check),
        .en_check      (en_check),
        .seq_in_check  (seq_play),
        .seq_mem       (seq_mem),
        .round_ctr_in  (round_ctr_in),

        .round_ctr_out (round_ctr_out),
        .complete_check(complete_check),
        .game_complete (game_complete),
        .rst_wait      (rst_wait),
        .rst_display   (rst_display),
        .rst_idle      (rst_idle),
        .rst_check_out (rst_check_out)
    );

    always #50 clk = ~clk;

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, check_state_tb);
    end

    integer errors = 0;

    task automatic run_case;
        input [3:0]  rd_in;
        input [31:0] play_seq;
        input [31:0] mem_seq;
        input        expect_success;
        input        expect_game_complete;
    begin
        round_ctr_in = rd_in;
        seq_play     = play_seq;
        seq_mem      = mem_seq;

        @(posedge clk) en_check = 1'b1;
        @(posedge clk) en_check = 1'b0;

        @(posedge clk);

        if (expect_success) begin
            if (!complete_check) begin
                $display("ERROR: Expected complete_check=1 at round %d", rd_in);
                errors = errors + 1;
            end
            // Round increments only if not final round
            if (rd_in != 4'd14 && round_ctr_out != rd_in + 1) begin
                $display("ERROR: Expected round_ctr_out=%d, got %d", rd_in+1, round_ctr_out);
                errors = errors + 1;
            end
            if (expect_game_complete && !game_complete) begin
                $display("ERROR: Expected game_complete=1 at round %d", rd_in);
                errors = errors + 1;
            end
            if (!expect_game_complete && game_complete) begin
                $display("ERROR: Unexpected game_complete=1 at round %d", rd_in);
                errors = errors + 1;
            end
        end
        else begin
            if (round_ctr_out != 4'd0) begin
                $display("ERROR: Expected round_ctr_out=0 on fail, got %d", round_ctr_out);
                errors = errors + 1;
            end
            if (game_complete) begin
                $display("ERROR: game_complete=1 unexpectedly on fail at round %d", rd_in);
                errors = errors + 1;
            end
        end
    end
    endtask

    localparam [31:0] GOOD_SEQ = 32'h0A_BC_DE_F0;
    localparam [31:0] BAD_SEQ  = 32'hDEAD_BEEF;

    initial begin
        rst_check = 1'b1;
        @(posedge clk);
        rst_check = 1'b0;

        // 1) Round 0 – PASS, no game complete
        run_case(4'd0 , GOOD_SEQ, GOOD_SEQ, 1'b1, 1'b0);

        // 2) Round 1 – FAIL
        run_case(4'd1 , BAD_SEQ , GOOD_SEQ, 1'b0, 1'b0);

        // 3) Round 14 – PASS, expect game_complete=1
        run_case(4'd14, GOOD_SEQ, GOOD_SEQ, 1'b1, 1'b1);

        // 4) Round 14 – FAIL, expect game_complete=0
        run_case(4'd14, BAD_SEQ , GOOD_SEQ, 1'b0, 1'b0);

        if (errors == 0)
            $display("check_state_tb: *** ALL TESTS PASSED ***");
        else
            $display("check_state_tb: *** FAILED with %0d error(s) ***", errors);

        $finish;
    end
endmodule

`default_nettype wire
