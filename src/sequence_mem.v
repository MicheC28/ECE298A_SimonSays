module SEQUENCE_MEM (
    input  wire       clk,
    input  wire       rst,         // Synchronous reset
    input  wire       load,        // Load signal
    input  wire [3:0] data_in,     // Data to load
    output reg  [3:0] data_out     // Always reflects current count value
);

    always @(posedge clk) begin
        if (rst)
            data_out <= 4'b0000;
        else if (load)
            data_out <= data_in;
       
    end

endmodule