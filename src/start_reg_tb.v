`timescale 1ns/1ps

module tb_start_reg;
    reg clk;
    reg rst;
    reg start;
    wire out;

    // Instantiate the DUT
    start_reg uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .out(out)
    );

    // Clock generation: 10ns period
    always #5 clk = ~clk;

    initial begin
        $display("Time\tRST\tSTART\tOUT");

        // Initialize
        clk = 0;
        rst = 0;
        start = 0;

        // Apply reset
        #2 rst = 1;
        #10 rst = 0;

        // Wait a bit
        #10;

        // Pulse start
        #2 start = 1;
        #10 start = 0;

        // Wait
        #20;

        // Reset again
        #20 rst = 1;
        #10 rst = 0;

        // Final delay
        #10;

        $finish;
    end

    // Print output changes
    initial begin
        $monitor("%4t\t%b\t%b\t%b", $time, rst, start, out);
    end
endmodule
