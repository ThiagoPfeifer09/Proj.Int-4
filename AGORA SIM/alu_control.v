// Módulo: alu_control (Unidade de Controle da ULA)
// Objetivo: Este módulo atua como um decodificador secundário. Ele recebe um sinal
// genérico de 2 bits da Unidade de Controle principal (Aluop) e os campos de
// função da instrução (funct) para gerar o código de operação específico de 4 bits
// que a ULA principal irá executar. Isso simplifica a Unidade de Controle principal.

module alu_control(
    // --- Entradas ---
    input [1:0] Aluop,      // Sinal de 2 bits da Unidade de Controle principal.
                            // Define o tipo geral da operação:
                            // 2'b00: lw/sw (precisa de uma soma para o endereço)
                            // 2'b01: beq (precisa de uma subtração para comparar)
                            // 2'b10: Instrução Tipo-R (a operação exata depende do funct)
                            
    input [3:0] funct,      // Campo de função da instrução. Para o Tipo-R, ele especifica
                            // a operação exata (add, sub, and, or, etc.).
                            
    // --- Saída ---
    output reg [3:0] operation // Sinal de controle final de 4 bits para a ULA principal.
);
 
    // Bloco combinacional: a saída 'operation' é atualizada imediatamente
    // sempre que 'Aluop' ou 'funct' mudar.
    always @ (*)
    begin
        // NOTA DE IMPLEMENTAÇÃO: O uso de múltiplos 'if's pode ser funcional,
        // mas uma estrutura 'case' ou 'if-else if' é geralmente mais clara e
        // menos propensa a erros como a inferência de latches.
        
        // Caso seja uma instrução de desvio (beq).
        if (Aluop == 2'b01)
        begin
            operation = 4'b0110; // A ULA deve fazer uma SUBTRAÇÃO.
        end
        
        // Caso seja uma instrução de load/store (lw/sw).
        if (Aluop == 2'b00)
        begin
            operation = 4'b0010; // A ULA deve fazer uma SOMA para calcular o endereço.
        end
        
        // Caso seja uma instrução do Tipo-R.
        if (Aluop == 2'b10)
        begin
            // Para o Tipo-R, precisamos "olhar mais a fundo" no campo 'funct'
            // para determinar a operação específica.
            if (funct == 4'b0000)
            begin
                operation = 4'b0010; // add
            end
            if (funct == 4'b0111)
            begin
                operation = 4'b0000; // and
            end
            if (funct == 4'b1000)
            begin
                operation = 4'b0110; // sub
            end
            if (funct == 4'b0110)
            begin
                operation = 4'b0001; // or
            end
            // ATENÇÃO: Se 'Aluop' for 2'b10 mas 'funct' não for um dos valores
            // acima, a 'operation' não é definida, o que pode inferir um latch.
            // É crucial ter um caso 'default' para garantir robustez.
        end
    end
endmodule
