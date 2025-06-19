// Módulo da Unidade Lógica e Aritmética (ALU)
// Versão corrigida para evitar erros de sintaxe em certas ferramentas.
module alu (
    input wire [31:0] operand_a,
    input wire [31:0] operand_b,
    input wire [3:0]  alu_control,
    output reg [31:0] result
);

    // Variável intermediária para o valor do deslocamento (shift amount)
    reg [4:0] shift_amount;

    always @(*) begin
        // Extrai os 5 bits menos significativos de operand_b para usar nas operações de shift.
        shift_amount = operand_b[4:0];

        case (alu_control)
            4'b0000: result = operand_a + operand_b;                              // ADD, ADDI
            4'b0001: result = operand_a - operand_b;                              // SUB
            // CORREÇÃO: Usa a variável intermediária 'shift_amount'
            4'b0010: result = operand_a << shift_amount;                          // SLL, SLLI
            4'b0011: result = ($signed(operand_a) < $signed(operand_b)) ? 32'd1 : 32'd0; // SLT, SLTI
            4'b0100: result = (operand_a < operand_b) ? 32'd1 : 32'd0;            // SLTU, SLTUI
            4'b0101: result = operand_a ^ operand_b;                              // XOR, XORI
            // CORREÇÃO: Usa a variável intermediária 'shift_amount'
            4'b0110: result = operand_a >> shift_amount;                          // SRL, SRLI
            // CORREÇÃO: Usa a variável intermediária 'shift_amount'
            4'b0111: result = $signed(operand_a) >>> shift_amount;                // SRA, SRAI
            4'b1000: result = operand_a | operand_b;                              // OR, ORI
            4'b1001: result = operand_a & operand_b;                              // AND, ANDI
            default: result = 32'b0;
        endcase
    end

endmodule