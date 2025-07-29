// uo[0] = red, uo[1] = blue, uo[2] = yellow, uo[3] = green
// colour_enc_in[1:0] mapping: 00 = red, 01 = blue, 10 = yellow, 11 = green

module colour_encoder (
    input  wire       oe, //active high enable
    input wire [1:0] colour_enc_in, 
    output  reg [3:0] uo   
);

    always @(*) begin
        if (oe) begin
            // Set outputs based on input encoding
            uo[0] = ~colour_enc_in[0] & ~colour_enc_in[1]; // red
            uo[1] =  colour_enc_in[0] & ~colour_enc_in[1]; // blue
            uo[2] = ~colour_enc_in[0] &  colour_enc_in[1]; // yellow
            uo[3] =  colour_enc_in[0] &  colour_enc_in[1]; // green
        end else begin
            // High-impedance when output is disabled
            uo <= 4'b0000;
        end
    end

endmodule