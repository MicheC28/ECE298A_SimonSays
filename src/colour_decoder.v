// ui[0] = red, ui[1] = blue, ui[2] = yellow, ui[3] = green
// colour[1:0] mapping: 00 = red, 01 = blue, 10 = yellow, 11 = green

module colour_decoder (
    input  wire [3:0] ui,      
    output wire [1:0] colour_dec_out   
);

    // colour[1] goes high for Yellow or Green
    assign colour_dec_out[1] = ui[2] | ui[3];

    // colour[0] goes high for Blue or Green
    assign colour_dec_out[0] = ui[1] | ui[3];

endmodule