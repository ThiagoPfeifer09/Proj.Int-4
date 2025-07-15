// Módulo: mux3x1 (Multiplexador 3 para 1)
// Objetivo: Este módulo implementa um multiplexador combinacional que seleciona
// uma de três entradas de dados de 64 bits (a, b, c) com base em um sinal
// de seleção de 2 bits (sel) e a direciona para a saída.

module mux3x1(
    // --- Entradas ---
    input [63:0] a,         // Primeira entrada de dados
    input [63:0] b,         // Segunda entrada de dados
    input [63:0] c,         // Terceira entrada de dados
    input [1:0]  sel,       // Sinal de seleção de 2 bits
    
    // --- Saída ---
    output reg [63:0] out   // Saída de 64 bits, conterá o valor da entrada selecionada
);

    // Bloco combinacional: a saída 'out' é atualizada imediatamente
    // sempre que qualquer uma das entradas (a, b, c, sel) mudar.
    always @(*)
    begin
        // A instrução 'case' funciona como o centro de decisão do MUX.
        // Ela verifica o valor de 'sel' para determinar qual entrada
        // deve ser passada para a saída.
        case(sel)
            2'b00: out = a; // Se sel = 00, a saída recebe o valor de 'a'.
            2'b01: out = b; // Se sel = 01, a saída recebe o valor de 'b'.
            2'b10: out = c; // Se sel = 10, a saída recebe o valor de 'c'.
            
            // ATENÇÃO: O caso para sel = 2'b11 não está definido. Em hardware,
            // isso pode levar à inferência de um 'latch', o que geralmente
            // é indesejado em um circuito combinacional. Uma boa prática é
            // cobrir todos os casos possíveis usando uma cláusula 'default'.
            // Exemplo: default: out = 64'b0;
        endcase
    end
endmodule
