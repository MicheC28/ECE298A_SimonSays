`default_nettype none

module tt_um_simonsays (
    input  wire [7:0] ui_in,     // Dedicated inputs
    output wire [7:0] uo_out,    // Dedicated outputs
    input  wire [7:0] uio_in,    // IOs: Input path
    output wire [7:0] uio_out,   // IOs: Output path
    output wire [7:0] uio_oe,    // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,       // always 1 when the design is powered, so you can ignore it
    input  wire       clk,       // clock
    input  wire       rst_n      // reset_n - low to reset
);

    // === Local Signals for MEM ===
    wire        MEM_LOAD;
    wire [7:0]  MEM_IN;
    wire [1:0]  MEM_LOAD_VAL;
    wire        rst_MEM;
    wire [31:0] MEM_OUT;

    // === Assign test values for now (replace with real logic) ===
    assign MEM_LOAD      = ui_in[0];           // example input
    assign MEM_IN        = uio_in[7:0];        // example from IO
    assign MEM_LOAD_VAL  = ui_in[2:1];         // 2-bit selector
    assign rst_MEM       = ~rst_n;             // Active-high reset

    // === Instantiate MEM Module ===
    MEM mem(
        .clk(clk),
        .MEM_LOAD(MEM_LOAD),
        .MEM_IN(MEM_IN),
        .rst_MEM(rst_MEM),
        .MEM_LOAD_VAL(MEM_LOAD_VAL),
        .MEM_OUT(MEM_OUT)
    );

    // === Use all signals to avoid optimization ===
    wire mem_out_xor = ^MEM_OUT;


    // === Assign outputs ===
    assign uo_out   = MEM_IN; // or some diagnostic signal
    assign uio_oe   = 8'b1111_1111; // all uio_out are outputs
    assign uio_out  = {7'b0, mem_out_xor};

endmodule
