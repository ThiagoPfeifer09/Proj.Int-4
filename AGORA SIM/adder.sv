// Módulo: adder (Somador)
// Objetivo: Este módulo implementa um somador combinacional genérico de 64 bits.
// Ele recebe dois operandos de 64 bits e produz a soma como saída. Este é
// um dos blocos de construção mais fundamentais em um processador.

module adder(
    // --- Entradas ---
    input [63:0] p,     // Primeiro operando de 64 bits para a soma
    input [63:0] q,     // Segundo operando de 64 bits para a soma
    
    // --- Saída ---
    output [63:0] out   // Saída de 64 bits contendo o resultado da soma (p + q)
);
 
    // A instrução 'assign' descreve uma atribuição contínua, o que cria um
    // circuito puramente combinacional. O operador '+' é interpretado pela
    // ferramenta de síntese para gerar um circuito somador em hardware
    // (ex: ripple-carry, carry-lookahead, etc.).
    assign out = p + q;
    
endmodule
