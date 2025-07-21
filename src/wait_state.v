module WAIT_STATE (
    input  wire        clk,
    input  wire        rst,
    input  wire        en,
    input  wire        colour_in,
    input  wire [1:0]  colour_val,
    input  wire [3:0]  sequence_len,
    output reg         complete_wait,
    output reg [31:0]  sequence_val
);

    reg [3:0] count;

    always @(posedge clk) begin
        if (rst) begin
            count         <= 4'b0;
            sequence_val  <= 32'b0;
            complete_wait <= 1'b0;
        end else if (en && colour_in && !complete_wait) begin
            // Store colour_val into bits [count*2 +: 2]
            sequence_val[count*2 +: 2] <= colour_val;
            count <= count + 1'b1;
            if (count + 1'b1 == sequence_len)
                complete_wait <= 1'b1;
        end
    end

endmodule
