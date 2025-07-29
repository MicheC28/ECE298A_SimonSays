module check_state (
    input  wire        clk,
    input  wire        rst_check,      // synchronous reset (active-high)
    input  wire        en_check,       // start comparison this cycle
    input  wire [31:0] seq_in_check,   // player's sequence (LSB = first colour)
    input  wire [31:0] seq_mem,        // golden sequence  (LSB = first colour)
    input  wire [3:0]  round_ctr_in,   // current round counter (0-15)

    output reg  [3:0]  round_ctr_out,  // updated round counter
    output reg         complete_check, // 1-cycle pulse on success
    output reg         game_complete,  // high after final round clears

    output reg         rst_wait,       // asserted 1 clk on success
    output reg         rst_display,
    output reg         rst_idle,
    output reg         rst_check_out   // self-reset line
);

    // -------------------------------------------------------------------------
    // Helper: mask covering exactly the active bits for this round
    //   round N  ⇒  need (N+1)*2 bits
    //   Example: N=1 → mask = 0b0000_0000_0000_0000_0000_0000_1111 (4 bits)
    // -------------------------------------------------------------------------
    wire [5:0] active_bits = { round_ctr_in, 1'b0 } + 1'b1;  // (N<<1)+2
    wire [31:0] cmp_mask   = (active_bits >= 32) ? 32'hFFFF_FFFF: (32'h1 << active_bits) - 1;

    wire sequences_match = ((seq_in_check ^ seq_mem) & cmp_mask) == 32'b0;

    always @(posedge clk) begin
        if (rst_check) begin
            round_ctr_out  <= 4'd0;
            complete_check <= 1'b0;
            game_complete  <= 1'b0;
            rst_wait       <= 1'b0;
            rst_display    <= 1'b0;
            rst_idle       <= 1'b0;
            rst_check_out  <= 1'b0;
        end
        else begin
            // defaults (1-cycle pulses) ---------------------------------------
            complete_check <= 1'b0;
            rst_wait       <= 1'b0;
            rst_display    <= 1'b0;
            rst_idle       <= 1'b0;
            rst_check_out  <= 1'b0;

            // ----------------------------------------------------------------
            // Triggered once per round when en_check goes high
            // ----------------------------------------------------------------
            if (en_check) begin
                if (sequences_match) begin
                    // === SUCCESS ============================================
                    complete_check <= 1'b1;

                    // Increment round unless already at maximum (15)
                    if (round_ctr_in != 4'd15)
                        round_ctr_out <= round_ctr_in + 1'b1;
                    else
                        round_ctr_out <= round_ctr_in;  // stay at 15

                    // Assert resets for all other blocks for one clock
                    rst_wait      <= 1'b1;
                    rst_display   <= 1'b1;
                    rst_idle      <= 1'b1;
                    rst_check_out <= 1'b1;  // self-reset (optional)

                    // Signal overall game completion on last round
                    if (round_ctr_in == 4'd15)
                        game_complete <= 1'b1;
                end
                else begin
                    // === FAILURE / WRONG SEQUENCE ===========================
                    round_ctr_out <= 4'd0;   // back to round 0
                    game_complete <= 1'b0;   // ensure not set
                    // (no resets asserted; FSM may show "Game Over" state)
                end
            end
            else begin
                // hold current round counter otherwise
                round_ctr_out <= round_ctr_in;
            end
        end
    end
endmodule
