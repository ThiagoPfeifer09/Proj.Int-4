// Módulo: mux2x1 (Multiplexador 2 para 1) - Versão Verilog-2001 Aprimorada
// Objetivo: Este módulo implementa um multiplexador combinacional que seleciona
// uma de duas entradas de 64 bits (A ou B) com base no sinal de controle SEL.

module mux2x1(
    // --- Entradas ---
    input [63:0] A, B,
    input SEL,
    
    // --- Saída ---
    // A saída agora é um 'wire' (padrão), pois é dirigida por um 'assign'.
    output [63:0] Y
);
 
    // A lógica foi reescrita com um 'assign' e o operador ternário (?:).
    // Esta é a forma mais comum e concisa de descrever um MUX 2x1 em Verilog.
    // Se SEL for 1, Y recebe B; senão, Y recebe A.
    assign Y = SEL ? B : A;
 
endmodule
