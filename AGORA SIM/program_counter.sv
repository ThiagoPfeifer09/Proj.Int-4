// Módulo: program_counter (Contador de Programa - PC)
// Objetivo: Este módulo implementa o Contador de Programa (PC). O PC é um
// registrador fundamental que armazena o endereço da próxima instrução a ser
// buscada da memória. Ele é o motor que impulsiona o fluxo de execução do
// processador.

module program_counter(
    // --- Entradas ---
    input [63:0] PC_in,     // O valor do PRÓXIMO PC, vindo do MUX que escolhe entre PC+4 e o endereço de desvio.
    input clk,            // O sinal de clock do sistema.
    input reset,          // Sinal de reset (nesse caso, assíncrono) para iniciar o PC em 0.
    input stall,          // Sinal de controle vindo da Unidade de Detecção de Hazard. Se '1', o PC não é atualizado.
    
    // --- Saída ---
    output reg [63:0] PC_out // O valor ATUAL do PC, enviado para a Memória de Instruções.
);
 
   // Bloco síncrono. O reset agora também é síncrono ao clock.
    always @(posedge clk)
    begin
        // A lógica de reset agora está DENTRO do bloco sensível ao clock.
        // O PC irá para 0 na primeira borda de subida do clock em que o reset estiver ativo.
        if (reset == 1'b1)
        begin
            PC_out <= 64'd0;
        end
        // Se não houver reset, verificamos o stall.
        else if (stall == 1'b0) 
        begin
            PC_out <= PC_in;
        end
        // Se stall for '1', o PC mantém o valor (hold implícito).
    end
        // STALL (PARALISAÇÃO) IMPLÍCITO: Note que não há um 'else' final.
        // Se 'stall' for '1', nenhuma das condições do 'if/else if' é satisfeita.
        // Portanto, o registrador 'PC_out' mantém seu valor anterior.
        // É assim que o PC é "congelado" durante um stall, impedindo que novas
        // instruções sejam buscadas.
endmodule
