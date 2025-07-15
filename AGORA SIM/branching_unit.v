// Módulo: branching_unit (Unidade de Desvio) - Versão Verilog-2001 Aprimorada
// Objetivo: Este módulo é responsável por avaliar a condição das instruções de
// desvio condicional (como beq, blt, etc.). Ele compara os dados de dois
// registradores com base no campo 'funct3' da instrução e gera um sinal de
// controle que determina se o desvio deve ou não ser tomado.

module branching_unit (
    // --- Entradas ---
    input [2:0] funct3,             // Campo de 3 bits que define o tipo de comparação.
    
    // As entradas de dados são declaradas como 'signed' para que as
    // comparações de 'menor que' (<) e 'maior ou igual' (>=) funcionem
    // corretamente para as instruções blt e bge, que operam com sinal.
    input signed [63:0] readData1,  // Dado do primeiro registrador fonte (rs1).
    input signed [63:0] b,          // Dado do segundo registrador fonte (rs2).
    
    // --- Saída ---
    output reg addermuxselect       // Sinal de decisão. '1' = Tomar o desvio, '0' = Não tomar.
);

    // Bloco combinacional que avalia a condição do desvio.
    always @(*)
    begin
        // O 'case' decodifica o tipo de desvio com base no 'funct3'.
        case (funct3)
            // beq (Branch if Equal)
            3'b000: addermuxselect = (readData1 == b);
            
            // bne (Branch if Not Equal)
            3'b001: addermuxselect = (readData1 != b);

            // blt (Branch if Less Than)
            // A comparação agora é COM SINAL, pois as entradas foram declaradas 'signed'.
            3'b100: addermuxselect = (readData1 < b);

            // bge (Branch if Greater or Equal)
            // A comparação agora é COM SINAL e a lógica foi corrigida para '>='.
            3'b101: addermuxselect = (readData1 >= b);

            // bltu (Branch if Less Than, Unsigned)
            // Usamos $unsigned() para garantir que a comparação seja SEM SINAL.
            3'b110: addermuxselect = ($unsigned(readData1) < $unsigned(b));

            // bgeu (Branch if Greater or Equal, Unsigned)
            // Usamos $unsigned() para garantir que a comparação seja SEM SINAL.
            3'b111: addermuxselect = ($unsigned(readData1) >= $unsigned(b));
            
            // O 'default' garante que, para qualquer outro funct3, o desvio não é tomado.
            // Isso evita a criação de latches e torna o design robusto.
            default: addermuxselect = 1'b0;
        endcase
    end
endmodule
