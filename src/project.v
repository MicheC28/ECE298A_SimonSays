`default_nettype none

module tt_um_simonsays (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    // === Control Inputs ===
    wire [1:0] colour_val_WAIT = ui_in[1:0];  // 2-bit color value
    wire       rst_WAIT        = ui_in[2];    // Reset for WAIT_STATE
    wire       en_WAIT         = ui_in[3];    // Enable for WAIT_STATE
    wire       colour_in_WAIT  = ui_in[4];    // Input valid signal
    wire [3:0] seq_len         = ui_in[7:4];  // 4-bit sequence length

    // === WAIT_STATE Outputs ===
    wire [31:0] seq_out_WAIT;
    wire        complete_wait;

    // === Instantiate WAIT_STATE ===
    WAIT_STATE wait_state(
        .clk(clk),
        .rst(rst_WAIT),
        .en(en_WAIT),
        .colour_in(colour_in_WAIT),
        .colour_val(colour_val_WAIT),
        .sequence_len(seq_len),
        .complete_wait(complete_wait),
        .sequence_val(seq_out_WAIT)
    );

    // === Output temp use of WAIT outputs ===
    wire wait_seq_out_xor = ^seq_out_WAIT; // XOR for visibility in debug

    // === Output assignments ===
    assign uo_out   = seq_out_WAIT[7:0];   // Low byte of sequence (debug view)
    assign uio_out  = {4'b0000, complete_wait, wait_seq_out_xor, 2'b00};
    assign uio_oe   = 8'b1111_1111;        // All uio_out bits driven

endmodule
