
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
    //Input
    wire [3:0] colour_dec_in = ui_in[3:0];                // 4-bit input for colour decoding
    wire reset = ui_in[4];                             // Reset signal
    wire start = ui_in[5];                                // Start signal
    wire [7:0] LFSR_SEED = uio_in[7:0];

    //LFSR
    wire [7:0] LFSR_out;
    wire complete_LFSR;                                      // LFSR completion signal
    wire en_LFSR;

    //IDLE 
    wire en_IDLE; // temp
    wire rst_IDLE; // temp
    wire complete_IDLE; // temp

    //32bMEM
    wire MEM_LOAD;
    wire [7:0]MEM_IN; // load 8 bits at a time
    wire [1:0]MEM_LOAD_VAL;
    wire rst_MEM;
    wire [31:0]MEM_OUT;

    //WAIT
    wire en_WAIT;
    wire rst_WAIT;
    wire [31:0] seq_out_WAIT;
    wire [3:0] seq_len;
    wire [1:0] colour_val_WAIT;
    wire colour_in_WAIT;
    wire complete_wait;
    



    LFSR lfsr(
        .LFSR_SEED(LFSR_SEED),      // Use the first 7 bits of ui_in as the seed
        .clk(clk),
        .rst(~rst_n),                // Active low reset
        .enable(ena),                // Enable signal
        .LFSR_OUT(LFSR_out),     // Output the LFSR value to uio_out[6:0]
        .complete_LFSR(complete_LFSR)   // Indicate completion in the last bit of uio_out
    );

    IDLE_STATE idle(
        .clk(clk),
        .en_IDLE(en_IDLE),
        .rst_IDLE(rst_IDLE),
        .complete_LFSR(complete_LFSR),
        .LFSR_output(LFSR_out), // Use the first 7 bits of LFSR output
        .en_LFSR(en_LFSR),
        .MEM_IN(MEM_IN), // Load the LFSR output into memory
        .MEM_LOAD(MEM_LOAD),
        .complete_IDLE(complete_IDLE),
        .MEM_LOAD_VAL(MEM_LOAD_VAL)
    );

    MEM mem(
        .clk(clk),
        .MEM_LOAD(MEM_LOAD),
        .MEM_IN(MEM_IN),
        .rst_MEM(rst_MEM),
        .MEM_LOAD_VAL(MEM_LOAD_VAL),
        .MEM_OUT(MEM_OUT)
    );

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

    assign en_IDLE = start; // Enable IDLE state when start is pressed
    assign rst_IDLE = reset; // Reset IDLE state when reset is pressed
    assign rst_MEM = reset;
    assign en_WAIT = start;
    assign rst_WAIT = reset;
    assign colour_in_WAIT = {reset};
    assign colour_val_WAIT= {start, start};
    assign seq_len = {start, start, start, start};

    //temp to make sure wait seq out used 
    wire wait_seq_out_xor;
    assign wait_seq_out_xor = ^ seq_out_WAIT; 


    //temp to make sure mem out signals are used
    wire mem_out_xor;
    assign mem_out_xor = ^MEM_OUT; // Reduction XOR operator


    // All output pins must be assigned. If not used, assign to 0.
    assign uo_out  = MEM_IN;
    assign uio_oe  = 8'b1111_1111; // All uio_out pins are outputs
    assign uio_out = {5'b0, wait_seq_out_xor, mem_out_xor, complete_IDLE};
endmodule