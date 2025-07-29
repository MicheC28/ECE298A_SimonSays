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

        // test‑bench write has higher priority
        // else if (test_load)
            // MEM_OUT <= test_data;

        else if (MEM_LOAD) begin
            case (MEM_LOAD_VAL)
                2'd0: MEM_OUT[ 7:0] <= MEM_IN;
                2'd1: MEM_OUT[15:8] <= MEM_IN;
                2'd2: MEM_OUT[23:16]<= MEM_IN;
                2'd3: MEM_OUT[31:24]<= MEM_IN;
            endcase
        end
    end
endmodule
// -----------------------------------------------------------------------



// // 32-bit Register Memory w/ async reset signal.
// module MEM(
//     input wire clk,
//     input wire MEM_LOAD,
//     input wire [7:0] MEM_IN,
//     input wire rst_MEM,
//     input wire [1:0] MEM_LOAD_VAL, // which bits to load.
//     output reg[31:0] MEM_OUT
// );

// always @(posedge clk)begin
//     if(rst_MEM)begin
//         MEM_OUT  <= 32'b00000000000000000000000000000000;
//     end else if(MEM_LOAD_VAL == 2'b00 && MEM_LOAD) begin
//         MEM_OUT <= {MEM_OUT[31:8], MEM_IN[7:0]};
//     end else if(MEM_LOAD_VAL == 2'b01 && MEM_LOAD) begin
//         MEM_OUT <= {MEM_OUT[31:16], MEM_IN[7:0], MEM_OUT[7:0]};
//     end else if(MEM_LOAD_VAL == 2'b10 && MEM_LOAD) begin
//         MEM_OUT <= {MEM_OUT[31:24], MEM_IN[7:0], MEM_OUT[15:0]};
//     end else if(MEM_LOAD_VAL == 2'b11 && MEM_LOAD)begin
//         MEM_OUT <= {MEM_IN[7:0], MEM_OUT[23:0]};
//     end 
//     end
// endmodule