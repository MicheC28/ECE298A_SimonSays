`timescale 1ns/1ps

module wait_state_tb;

    reg clk = 0;
    reg rst = 0;
    reg en = 0;
    reg colour_in = 0;
    reg [1:0] colour_val = 0;
    reg [3:0] sequence_len = 0;
    wire complete_wait;
    wire [31:0] sequence;

    // Instantiate the wait_state module
    WAIT_STATE uut (
        .clk(clk),
        .rst(rst),
        .en(en),
        .colour_in(colour_in),
        .colour_val(colour_val),
        .sequence_len(sequence_len),
        .complete_wait(complete_wait),
        .sequence_val(sequence)
    );

    // Clock generation
    always #5 clk = ~clk;

    task send_colour(input [1:0] val);
        begin
            @(negedge clk);
            colour_val = val;
            colour_in = 1;
            @(negedge clk);
            colour_in = 0;
        end
    endtask

    initial begin
    $dumpfile("wait_state_tb.vcd");
    $dumpvars(0, wait_state_tb);

    // Initial state
    rst = 1;
    en = 0;
    colour_in = 0;
    colour_val = 0;
    sequence_len = 4;

    #10;
    @(negedge clk); rst = 0; // Release reset
    @(negedge clk); en = 1;  // Enable module

    // Send 4 colours: 01, 10, 11, 11
    send_colour(2'b11);
    send_colour(2'b10);
    send_colour(2'b11);
    send_colour(2'b11);

    // Wait for complete_wait
    wait (complete_wait == 1);

    $display("Final sequence (binary): %032b", sequence);

    #10;
    $finish;
end

initial begin
    $monitor("T=%0t rst=%b en=%b colour_in=%b colour_val=%b count=%0d sequence=%032b complete_wait=%b",
             $time, rst, en, colour_in, colour_val, uut.count, sequence, complete_wait);
end


endmodule
