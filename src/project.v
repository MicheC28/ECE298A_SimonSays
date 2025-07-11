
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
    //IDLE 
    wire en_IDLE; // temp
    wire rst_IDLE; // temp
    wire complete_IDLE; // temp
    wire LFSR_out[7:0];
    wire en_LFSR;
    wire MEM_IN[7:0];
    wire MEM_LOAD;
    wire complete_IDLE;
    wire MEM_LOAD_VAL[1:0];

    assign en_IDLE = ui_in[0];
    assign rst_IDLE = ui_in[1];
    assign complete_LFSR = ui_in[2];
    assign LFSR_out = uio_in;


    
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

    
    // All output pins must be assigned. If not used, assign to 0.
    assign uo_out  = MEM_IN;
    assign uio_oe  = 8'b1111_1111; // All uio_out pins are outputs
    assign uio_out = {4'b0, MEM_LOAD, complete_IDLE, MEM_LOAD_VAL};
    
endmodule