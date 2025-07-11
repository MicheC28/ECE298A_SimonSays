
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

  // Local Signals
    //LFSR
    wire [7:0] LFSR_out;
    wire complete_LFSR;   
    wire LFSR_SEED;                                       
    wire en_LFSR;

    assign LFSR_SEED = uio_in[7:0];

    LFSR lfsr(
        .LFSR_SEED(LFSR_SEED),      // Use the first 7 bits of ui_in as the seed
        .clk(clk),
        .rst(~rst_n),                // Active low reset
        .enable(ena),                // Enable signal
        .LFSR_OUT(LFSR_out),     // Output the LFSR value to uio_out[6:0]
        .complete_LFSR(complete_LFSR)   // Indicate completion in the last bit of uio_out
    );

    
    // All output pins must be assigned. If not used, assign to 0.
    assign uo_out  = LFSR_OUT;
    assign uio_oe  = 8'b1111_1111; // All uio_out pins are outputs
    assign uio_out = {7'b0, complete_LFSR};
endmodule