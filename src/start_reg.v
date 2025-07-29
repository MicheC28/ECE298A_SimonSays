// ------------------------------------------------------------------
// start_reg.v  –  latch "start" push‑button until game is done
// ------------------------------------------------------------------
module start_reg (
    input  wire clk,
    input  wire rst,        // synchronous, active‑high
    input  wire start,      // push‑button (ui_in[5])
    input  wire done,       // de‑assert when game_complete
    output reg  out         // stays 1 once latched
);

always @(posedge clk) begin
    if (rst)
        out <= 1'b0;
    else if (start)         // latch first rising edge
        out <= 1'b1;
    else if (done)          // clear when whole game is over
        out <= 1'b0;
end
endmodule
