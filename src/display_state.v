// -----------------------------------------------------------------------------
// Show (round_ctr + 1) colours from seq_in_display, holding each colour
// on colour_bus for HOLD_CYCLES clock ticks so a human can see it clearly.
// -----------------------------------------------------------------------------
module display_state #(
    // How many clk ticks to display one colour.
    //   Example:  10 MHz clk  × 5 000 000 = 0.5 s            (edit as needed)
    parameter integer HOLD_CYCLES = 5_000_000
)(
    input  wire        clk,
    input  wire        rst_display,      // sync reset, active‑high
    input  wire        en_display,       // assert to start / keep sending
    input  wire [31:0] seq_in_display,   // 16 colours packed LSB‑first
    input  wire [3:0]  round_ctr,        // N ⇒ show N+1 colours

    output reg  [1:0]  colour_bus,       // drives only while OE=1
    output reg         colour_oe,        // 1 = bus valid, 0 = Hi‑Z
    output reg         complete_display  // 1‑cycle “done” pulse
);
    // ───────────────── internal state ─────────────────────────────
    reg [3:0]       pos;         // which 2‑bit colour we’re on
    reg             active;      // high while inside a round
    reg [$clog2(HOLD_CYCLES)-1:0] hold_ctr; // ticks spent on current colour

    // ───────────────── sequential logic ──────────────────────────
    always @(posedge clk) begin
        // ---------- synchronous reset ----------------------------
        if (rst_display) begin
            pos              <= 4'd0;
            active           <= 1'b0;
            colour_bus       <= 2'b00;
            colour_oe        <= 1'b0;
            complete_display <= 1'b0;
            hold_ctr         <= {($clog2(HOLD_CYCLES)){1'b0}};
        end else begin
            complete_display <= 1'b0;  // default (pulse only when asserted)

            // ---------- start of a new round ----------------------
            if (en_display && !active) begin
                active    <= 1'b1;
                pos       <= 4'd0;
                hold_ctr  <= {($clog2(HOLD_CYCLES)){1'b0}};
            end

            // ---------- active colour streaming ------------------
            if (active) begin
                colour_bus <= seq_in_display[{1'b0, pos} +: 2];
                colour_oe  <= 1'b1;  // drive bus for entire hold window

                // stay on this colour until hold_ctr reaches limit
                if (hold_ctr == HOLD_CYCLES-1) begin
                    hold_ctr <= {($clog2(HOLD_CYCLES)){1'b0}}; // reset timer

                    if (pos == round_ctr) begin
                        // last colour of round finished displaying
                        complete_display <= 1'b1;
                        active           <= 1'b0;
                        colour_oe        <= 1'b0; // release bus next cycle
                    end else begin
                        pos <= pos + 1'b1;  // advance to next colour
                    end
                end else begin
                    hold_ctr <= hold_ctr + 1'b1;
                end
            end else begin
                // ---------- idle state ---------------------------
                colour_oe <= 1'b0;  // inform wrapper to tri‑state pads
            end
        end
    end
endmodule
