module start_reg (
    input wire clk,
    input wire rst,       // Active high reset
    input wire start,
    output reg out);        

    always @(posedge clk) begin
        if (rst)
            out <= 1'b0;
        else if (start)
            out <= 1'b1;
    end

endmodule
