// Módulo: alu_control (Unidade de Controle da ULA) - Versão Verilog-2001 Aprimorada
// Objetivo: Este módulo atua como um decodificador secundário. Ele recebe um sinal
// genérico de 2 bits da Unidade de Controle principal (Aluop) e os campos de
// função da instrução (funct) para gerar o código de operação específico de 4 bits
// que a ULA principal irá executar. Isso simplifica a Unidade de Controle principal.

module alu_control(
    // --- Entradas ---
    input [1:0] Aluop,      // Sinal de 2 bits da Unidade de Controle principal.
    input [3:0] funct,      // Campo de função da instrução para decodificar o Tipo-R.
    
    // --- Saída ---
    output reg [3:0] operation // Sinal de controle final de 4 bits para a ULA principal.
);
 
    // Bloco combinacional: a saída 'operation' é atualizada imediatamente
    // sempre que 'Aluop' ou 'funct' mudar.
    always @ (*)
    begin
        // A lógica foi reescrita com 'case' para maior clareza, segurança e
        // para evitar a criação de latches.
        case (Aluop)
            // Caso para load/store (lw/sw)
            2'b00: begin
                operation = 4'b0010; // A ULA deve fazer uma SOMA para calcular o endereço.
            end
            
            // Caso para desvio (beq)
            2'b01: begin
                operation = 4'b0110; // A ULA deve fazer uma SUBTRAÇÃO para comparar.
            end

            // Caso para instruções Tipo-R
            2'b10: begin
                // Para o Tipo-R, decodificamos o campo 'funct' em um case aninhado.
                case (funct)
                    4'b0000: operation = 4'b0010; // add
                    4'b0111: operation = 4'b0000; // and
                    4'b1000: operation = 4'b0110; // sub
                    4'b0110: operation = 4'b0001; // or
                    default: operation = 4'bxxxx; // Operação indefinida para funct não reconhecido
                endcase
            end

            // Caso padrão para qualquer Aluop não reconhecido.
            default: begin
                operation = 4'bxxxx; // 'x' indica "don't care", ajuda na otimização.
            end
        endcase
    end
endmodule
