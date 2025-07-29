module SEQUENCE_MEM (
    input  wire       clk,
    input  wire       rst,         // Synchronous reset
    input  wire       load,        // Load signal
    input  wire [3:0] data_in,     // Data to load
    output reg  [3:0] data_out     // Always reflects current count value
);

always @(posedge clk) begin
    // --- synchronous reset ---
    if (rst) begin
        data_out <= 4'b1110;      // counter starts at 0 after power‑on
    end
    // --- normal load on successful round ---
    else if (load) begin
        // data_out <= data_in;   // next round value from check_state
    end
end

endmodule