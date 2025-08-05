`timescale 1ns/1ps

module tb_32b_Reg_Mem;

    reg clk = 0;
    reg rst_MEM = 0;
    reg MEM_LOAD = 0;
    reg [7:0] MEM_IN = 8'h00;
    reg [1:0] MEM_LOAD_VAL = 2'b00;
    wire [31:0] MEM_OUT;

    // Instantiate the DUT
    MEM dut (
        .clk(clk),
        .MEM_LOAD(MEM_LOAD),
        .MEM_IN(MEM_IN),
        .rst_MEM(rst_MEM),
        .MEM_LOAD_VAL(MEM_LOAD_VAL),
        .MEM_OUT(MEM_OUT)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        $dumpfile("tb_32b_Reg_Mem.vcd");
        $dumpvars(0, tb_32b_Reg_Mem);

        // Reset the memory
        rst_MEM = 1;
        MEM_LOAD = 0;
        MEM_IN = 8'h00;
        MEM_LOAD_VAL = 2'b00;
        @(negedge clk);
        rst_MEM = 0;

        // Load 0xAA into byte 0
        MEM_LOAD = 1;
        MEM_IN = 8'hAA;
        MEM_LOAD_VAL = 2'b00;
        @(negedge clk);
        MEM_LOAD = 0;
        @(negedge clk);

        // Load 0xBB into byte 1
        MEM_LOAD = 1;
        MEM_IN = 8'hFF;
        MEM_LOAD_VAL = 2'b01;
        @(negedge clk);
        MEM_LOAD = 0;
        @(negedge clk);

        // Load 0xCC into byte 2
        MEM_LOAD = 1;
        MEM_IN = 8'hCC;
        MEM_LOAD_VAL = 2'b10;
        @(negedge clk);
        MEM_LOAD = 0;
        @(negedge clk);

        // Load 0xDD into byte 3
        MEM_LOAD = 1;
        MEM_IN = 8'hDD;
        MEM_LOAD_VAL = 2'b11;
        @(negedge clk);
        MEM_LOAD = 0;
        @(negedge clk);

        // Display the final memory value
        $display("Final MEM_OUT = %h", MEM_OUT);

        #20;
        $finish;
    end

    // Monitor only the requested signals
    initial begin
        $display("Time\trst_MEM\tMEM_LOAD\tMEM_IN\tMEM_LOAD_VAL");
        $monitor("%0t\t%b\t%b\t%h\t%b",
            $time, rst_MEM, MEM_LOAD, MEM_IN, MEM_LOAD_VAL);
    end

endmodule