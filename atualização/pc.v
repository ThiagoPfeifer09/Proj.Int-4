module pc # (parameter BASE_PC = 32'h0) (
    input wire clk, rst, we,
    input wire [31:0] next_pc,
    output reg [31:0] pc_out
);
    always @(posedge clk) begin
        if (rst) pc_out <= BASE_PC;
        else if (we) pc_out <= next_pc;
    end
endmodule