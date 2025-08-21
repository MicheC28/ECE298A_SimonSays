module parameterized_buffer #(
    parameter WIDTH = 1,
    parameter BUFFER_STAGES = 3
) (
    input  wire [WIDTH-1:0] data_in,
    output wire [WIDTH-1:0] data_out
);

    // Generate buffer stages
    genvar i, j;
    wire [WIDTH-1:0] buffer_chain [BUFFER_STAGES:0];
    
    // Input to first buffer stage
    assign buffer_chain[0] = data_in;
    
    // Generate buffer stages
    generate
        for (j = 0; j < BUFFER_STAGES; j = j + 1) begin : buffer_stage
            for (i = 0; i < WIDTH; i = i + 1) begin : bit_buffer
                sky130_fd_sc_hd__buf_1 buf_inst (
                    .X(buffer_chain[j+1][i]),
                    .A(buffer_chain[j][i])
                );
            end
        end
    endgenerate
    
    // Output from last buffer stage
    assign data_out = buffer_chain[BUFFER_STAGES];

endmodule
