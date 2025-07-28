module dff(output reg q, input d, input clk, input en);
    always @(posedge clk) if (en) q <= d;
endmodule

module LFSR(
    input  wire [6:0] LFSR_SEED, // Seed value to load
    input  wire       clk,
    input  wire       rst,
    input  wire       enable,
    output wire [6:0] LFSR_OUT,
    output wire       complete_LFSR
);


wire next_bit = LFSR_OUT[6] ^ LFSR_OUT[5]; // Feedback calculation

wire [6:0] D;
wire [6:0] Q;
wire counter;

wire sel = rst || (Q == 7'b0000000);

t_flip_flop tff(.clk(clk), .reset(rst), .T(1), .Q(counter));

mux2to1 mux_0(sel, next_bit, LFSR_SEED[0], D[0]);
mux2to1 mux_1(sel, Q[0], LFSR_SEED[1], D[1]);
mux2to1 mux_2(sel, Q[1], LFSR_SEED[2], D[2]);
mux2to1 mux_3(sel, Q[2], LFSR_SEED[3], D[3]);
mux2to1 mux_4(sel, Q[3], LFSR_SEED[4], D[4]);
mux2to1 mux_5(sel, Q[4], LFSR_SEED[5], D[5]);
mux2to1 mux_6(sel, Q[5], LFSR_SEED[6], D[6]);

dff dff_0(.q(Q[0]), .d(D[0]), .clk(clk), .en(enable));
dff dff_1(.q(Q[1]), .d(D[1]), .clk(clk), .en(enable));
dff dff_2(.q(Q[2]), .d(D[2]), .clk(clk), .en(enable));
dff dff_3(.q(Q[3]), .d(D[3]), .clk(clk), .en(enable));
dff dff_4(.q(Q[4]), .d(D[4]), .clk(clk), .en(enable));
dff dff_5(.q(Q[5]), .d(D[5]), .clk(clk), .en(enable));
dff dff_6(.q(Q[6]), .d(D[6]), .clk(clk), .en(enable));

assign LFSR_OUT[6:0] = Q[6:0];
assign complete_LFSR = counter == 1? 1'b1 : 1'b0;

endmodule