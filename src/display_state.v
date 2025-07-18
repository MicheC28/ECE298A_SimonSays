module display_state (
    input  wire        clk,
    input  wire        rst_display,      // sync reset, active-high
    input  wire        en_display,       // assert to start / keep sending
    input  wire [31:0] seq_in_display,   // 16 colours packed LSB-first
    input  wire [3:0]  round_ctr,        // N ⇒ show N+1 colours

    output reg  [1:0]  colour_bus,       // drives only while OE=1
    output reg         colour_oe,        // 1 = bus valid, 0 = Hi-Z
    output reg         complete_display  // 1-cycle “done” pulse
);
    // ───────────────── internal state ─────────────────────────────
    reg [3:0] pos;     // which 2-bit pair we’re on
    reg       active;  // high while inside a round

    // ───────────────── sequential logic ──────────────────────────
    always @(posedge clk) begin
        // ---------- synchronous reset ----------------------------
        if (rst_display) begin
            pos              <= 4'd0;
            active           <= 1'b0;
            colour_bus       <= 2'bzz;   // Hi-Z inside, OE=0 outside
            colour_oe        <= 1'b0;
            complete_display <= 1'b0;
        end
        else begin
            complete_display <= 1'b0;    // default (1-cycle pulse)

            // ---------- start of a new round ----------------------
            if (en_display && !active) begin
                pos    <= 4'd0;
                active <= 1'b1;
            end

            // ---------- active colour streaming ------------------
            if (active) begin
                colour_bus <= seq_in_display[(pos << 1) +: 2];
                colour_oe  <= 1'b1;      // drive bus

                if (pos == round_ctr) begin
                    complete_display <= 1'b1;  // last colour
                    active           <= 1'b0;  // leave round
                end
                else begin
                    pos <= pos + 1'b1;
                end
            end
            else begin
                // ---------- idle state ---------------------------
                colour_bus <= 2'bzz;      // internal Hi-Z
                colour_oe  <= 1'b0;       // inform wrapper to tri-state pads
            end
        end
    end
endmodule