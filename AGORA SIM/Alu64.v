// Módulo: Alu64 (Unidade Lógica e Aritmética de 64 bits)
// Objetivo: Este módulo é o "cérebro matemático" do processador. Ele executa
// operações aritméticas (soma, subtração) e lógicas (AND, OR, NOR) em dois
// operandos de 64 bits. A operação a ser executada é determinada por um sinal
// de controle de 4 bits (ALUop). Também gera um sinal 'zero' para desvios.

module Alu64 (
    // --- Entradas ---
    input [63:0] a, b,      // Os dois operandos de 64 bits para a operação.
    input [3:0] ALuop,      // Sinal de controle de 4 bits que define a operação a ser realizada.
    
    // --- Saídas ---
    output reg [63:0] Result, // Saída de 64 bits que contém o resultado da operação.
    output reg zero           // Flag de 1 bit. É '1' se o resultado for zero, '0' caso contrário.
);
 
    // Bloco combinacional: as saídas 'Result' e 'zero' são atualizadas
    // imediatamente sempre que qualquer uma das entradas (a, b, ALuop) mudar.
    always @(*)
    begin
        // A instrução 'case' seleciona a operação a ser realizada com base no
        // valor do sinal de controle 'ALuop'.
        case (ALuop)
            4'b0000: Result = a & b;     // Operação AND bit a bit
            4'b0001: Result = a | b;     // Operação OR bit a bit
            4'b0010: Result = a + b;     // Operação de Soma
            4'b0110: Result = a - b;     // Operação de Subtração
            4'b1100: Result = ~(a | b);  // Operação NOR bit a bit
            
            // ATENÇÃO: A instrução 'case' está incompleta. Um seletor de 4 bits
            // tem 16 combinações possíveis, mas apenas 5 estão definidas.
            // Para evitar a inferência de latches indesejados, é uma boa prática
            // adicionar uma cláusula 'default' para cobrir os casos restantes.
            // Exemplo: default: Result = 64'b0;
        endcase
        
        // Lógica para o flag 'zero'. Após qualquer operação, verificamos se o
        // resultado é zero. Este sinal é fundamental para o funcionamento de
        // instruções de desvio condicional como 'beq' e 'bne'.
        if (Result == 64'b0)
            zero = 1'b1; // Se o resultado for 0, o flag 'zero' é ativado.
        else
            zero = 1'b0; // Caso contrário, o flag 'zero' é desativado.
    end
endmodule
