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
    reg       delay_complete;  // new register for 1-cycle delay

    always @(posedge clk) begin
        if (rst) begin
            count           <= 4'b0;
            sequence_val    <= 32'b0;
            complete_wait   <= 1'b0;
            delay_complete  <= 1'b0;
        end else if (!complete_wait) begin
            
            if (delay_complete) begin
                complete_wait  <= 1'b1;
                delay_complete <= 1'b0;
            end
            
            
            if (en && colour_in) begin
                sequence_val[count*2 +: 2] <= colour_val;
                count <= count + 1'b1;

                if (count + 1 == sequence_len)
                    delay_complete <= 1'b1;
            end

            
        end
    end

endmodule
