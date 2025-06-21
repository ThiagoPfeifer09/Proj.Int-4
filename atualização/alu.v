module alu (
    input wire [31:0] operand_a, operand_b,
    input wire [3:0]  alu_control,
    output reg [31:0] result
);
    reg [4:0] shift_amount;
    always @(*) begin
        shift_amount = operand_b[4:0];
        case (alu_control)
            4'b0000: result = operand_a + operand_b;
            4'b0001: result = operand_a - operand_b;
            4'b0010: result = operand_a << shift_amount;
            4'b0011: result = ($signed(operand_a) < $signed(operand_b)) ? 1 : 0;
            4'b0100: result = (operand_a < operand_b) ? 1 : 0;
            4'b0101: result = operand_a ^ operand_b;
            4'b0110: result = operand_a >> shift_amount;
            4'b0111: result = $signed(operand_a) >>> shift_amount;
            4'b1000: result = operand_a | operand_b;
            4'b1001: result = operand_a & operand_b;
            default: result = 32'b0;
        endcase
    end
endmodule