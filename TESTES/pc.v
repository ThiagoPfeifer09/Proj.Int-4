module pc (
    input  wire       clk,
    input  wire       rst,         // reset síncrono
    input  wire [31:0] next_pc,    // PC + 4 ou target de branch
    output reg  [31:0] pc_out      // valor atual do PC
);
  always @(posedge clk) begin
    if (rst)
      pc_out <= 32'b0;
    else
      pc_out <= next_pc;
  end
endmodule
