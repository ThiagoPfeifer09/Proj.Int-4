// Módulo: branching_unit (Unidade de Desvio)
// Objetivo: Este módulo é responsável por avaliar a condição das instruções de
// desvio condicional (como beq, blt, etc.). Ele compara os dados de dois
// registradores com base no campo 'funct3' da instrução e gera um sinal de
// controle que determina se o desvio deve ou não ser tomado.

module branching_unit (
    // --- Entradas ---
    input [2:0] funct3,         // Campo de 3 bits da instrução que define o tipo de comparação.
                                // 3'b000: beq (Branch if Equal)
                                // 3'b100: blt (Branch if Less Than)
                                // 3'b101: bge (Branch if Greater or Equal)
    input [63:0] readData1,     // Dado do primeiro registrador fonte (rs1)
    input [63:0] b,             // Dado do segundo registrador fonte (rs2)
    
    // --- Saída ---
    output reg addermuxselect   // Sinal de decisão. '1' = Tomar o desvio, '0' = Não tomar o desvio.
                                // Este sinal controla o MUX que seleciona o próximo PC.
);
 
    // ATENÇÃO: Blocos 'initial' NÃO SÃO SINTETIZÁVEIS para hardware (FPGAs/ASICs).
    // Eles são uma construção de SIMULAÇÃO. A inicialização de um estado em hardware
    // deve ser feita através de um sinal de reset síncrono ou com atribuições
    // 'default' em blocos combinacionais para evitar latches.
    initial
    begin
        addermuxselect = 1'b0;
    end
 
    // Bloco combinacional que avalia a condição do desvio.
    always @(*)
    begin
        // O 'case' decodifica o tipo de desvio com base no 'funct3'.
        case (funct3)
            // beq (Branch if Equal)
            3'b000:
            begin
                if (readData1 == b)
                    addermuxselect = 1'b1; // Se forem iguais, tome o desvio.
                else
                    addermuxselect = 1'b0;
            end
            
            // blt (Branch if Less Than)
            3'b100:
            begin
                // NOTA: Esta comparação '<' em Verilog é SEM SINAL por padrão.
                // Para uma instrução 'blt' correta (com sinal), as entradas
                // precisariam ser declaradas como 'signed'.
                if (readData1 < b)
                    addermuxselect = 1'b1; // Se rs1 < rs2, tome o desvio.
                else
                    addermuxselect = 1'b0;
            end
            
            // bge (Branch if Greater or Equal)
            3'b101:
            begin
                // NOTA: O código implementa '>', não '>='. Para 'bge' (maior ou igual),
                // a condição deveria ser 'readData1 >= b'.
                // A comparação também é SEM SINAL.
                if (readData1 > b)
                    addermuxselect = 1'b1; // Se rs1 > rs2, tome o desvio.
                else
                    addermuxselect = 1'b0;
            end
            
            // ATENÇÃO: O 'case' está incompleto (faltam bne, bgeu, etc.).
            // Para um design robusto e para evitar a inferência de latches,
            // um caso 'default' é essencial. Ex: default: addermuxselect = 1'b0;
        endcase
    end
endmodule
