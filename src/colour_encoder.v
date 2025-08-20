// uo[0] = red, uo[1] = blue, uo[2] = yellow, uo[3] = green
// colour_enc_in[1:0] mapping: 00 = red, 01 = blue, 10 = yellow, 11 = green

module colour_encoder (
    input  wire       clk,    // clock input
    input  wire       reset,  // reset input
    input  wire       oe,     // active high enable
    input  wire [1:0] colour_enc_in, 
    output  wire [3:0] uo   
);

    // Add output registers for proper timing
    reg [3:0] uo_reg;
    
    always @(posedge clk) begin
        if (oe) begin
            // Set outputs based on input encoding
            uo_reg[0] <= ~colour_enc_in[0] & ~colour_enc_in[1]; // red
            uo_reg[1] <=  colour_enc_in[0] & ~colour_enc_in[1]; // blue
            uo_reg[2] <= ~colour_enc_in[0] &  colour_enc_in[1]; // yellow
            uo_reg[3] <=  colour_enc_in[0] &  colour_enc_in[1]; // green
        end else begin
            // Disable outputs when not enabled
            uo_reg <= 4'b0000;
        end
    end
    
    assign uo = uo_reg;

endmodule