module IDLE_STATE(
    input wire clk,
    input wire en_IDLE,
    input wire rst_IDLE,
    input wire complete_LFSR,
    input wire [7:0] LFSR_output,
    output reg en_LFSR,
    output reg [7:0] MEM_IN,
    output reg MEM_LOAD,
    output reg complete_IDLE,
    output reg [1:0]MEM_LOAD_VAL
);

reg [1:0] count;

always @(posedge clk) begin
    if (rst_IDLE) begin
        en_LFSR <= 1'b0;
        MEM_IN <= 8'b0;
        MEM_LOAD <= 1'b0;
        complete_IDLE <= 1'b0;
        count <= 2'b00;
    end else if (en_IDLE) begin
        if (complete_LFSR && ~MEM_LOAD) begin
            en_LFSR <= 1'b0;
            MEM_IN <= LFSR_output;
            MEM_LOAD_VAL <= count;
            MEM_LOAD <= 1'b1;
        end else if (MEM_LOAD) begin
            en_LFSR <= 1'b1;
            MEM_LOAD <= 1'b0;

            if (count == 2'b00) count <= 2'b01;
            else if (count == 2'b01) count <= 2'b10;
            else if (count == 2'b10) count <= 2'b11;
            else if (count == 2'b11) begin
                complete_IDLE <= 1'b1;
                count <= 2'b00;
            end else begin
                complete_IDLE <= 1'b0;
            end // <- missing END added here!
        end else begin
            en_LFSR <= 1'b1;
        end
    end
end

endmodule
