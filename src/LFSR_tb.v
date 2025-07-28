module test;

// Signals for LFSR
reg rst = 0;
reg enable = 1;
reg [7:0] LFSR_SEED = 8'b11010011; // Example 8-bit seed
wire [7:0] LFSR_OUT;
wire complete_LFSR;

// Internal signal to observe feedback calculation
wire feedback;
assign feedback = LFSR_OUT[7] ^ LFSR_OUT[5] ^ LFSR_OUT[4] ^ LFSR_OUT[3];

// Instantiate the LFSR module
LFSR uut (
    .LFSR_SEED(LFSR_SEED),
    .clk(clk),
    .rst(rst),
    .enable(enable),
    .LFSR_OUT(LFSR_OUT),
    .complete_LFSR(complete_LFSR)
);

// Clock generation
reg clk = 0;
always #1 clk = ~clk;

// Test sequence
initial begin
    $dumpfile("LFSR_test.vcd");
    $dumpvars(0, test);

    #1 enable = 1;
    #10 rst = 1; // Reset the LFSR
    #2 rst = 0;

    #40 rst = 1;
    #2 rst = 0;

    // Run with enable high for 20 cycles
    #40 enable = 0;
    // Hold for 10 cycles
    #20 enable = 1;
    // Run for 40 more cycles
    #80 $finish;
end

// Monitor outputs and XOR feedback
always @(posedge clk) begin
    $display("At time %t, LFSR_OUT = %b, feedback (LFSR_OUT[7]^LFSR_OUT[5]^LFSR_OUT[4]^LFSR_OUT[3]) = %b, complete_LFSR = %b", 
        $time, LFSR_OUT, feedback, complete_LFSR);
end

endmodule //test