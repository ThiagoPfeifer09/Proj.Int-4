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
 
    // Bloco sensível à borda de subida do clock (operação síncrona)
    // e à borda de subida do reset (reset assíncrono).
    always @(posedge clk or posedge reset)
    begin
        // Lógica de reset assíncrono: se 'reset' for ativado, o PC é
        // imediatamente forçado para o endereço 0, o ponto de partida padrão.
        if (reset == 1'b1)
        begin
            PC_out <= 64'd0;
        end
        // Operação síncrona normal (sem stall).
        // Se não houver reset e o pipeline não estiver paralisado ('stall' == 0),
        // o PC é atualizado com o próximo valor na borda de subida do clock.
        else if (stall == 1'b0)
        begin
            PC_out <= PC_in;
        end
        // STALL (PARALISAÇÃO) IMPLÍCITO: Note que não há um 'else' final.
        // Se 'stall' for '1', nenhuma das condições do 'if/else if' é satisfeita.
        // Portanto, o registrador 'PC_out' mantém seu valor anterior.
        // É assim que o PC é "congelado" durante um stall, impedindo que novas
        // instruções sejam buscadas.
    end
endmodule
