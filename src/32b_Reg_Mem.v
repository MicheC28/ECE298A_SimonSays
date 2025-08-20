// ---------- 32b_Reg_Mem.v ----------------------------------------------
module MEM (
    input  wire        clk,
    input  wire        MEM_LOAD,
    input  wire  [7:0] MEM_IN,
    input  wire        rst_MEM,
    input  wire  [1:0] MEM_LOAD_VAL,
    // >>> TEST BENCH OVERRIDE <<<
    input  wire        test_load,           // NEW
    input  wire [31:0] test_data,           // NEW
    output reg  [31:0] MEM_OUT
);

    always @(posedge clk) begin
        if (rst_MEM)
            MEM_OUT <= 32'd0;

        else if (MEM_LOAD) begin
            case (MEM_LOAD_VAL)
                2'd0: MEM_OUT[ 7:0] <= MEM_IN;
                2'd1: MEM_OUT[15:8] <= MEM_IN;
                2'd2: MEM_OUT[23:16]<= MEM_IN;
                2'd3: MEM_OUT[27:24]<= MEM_IN;
            endcase
        end
    end
endmodule
