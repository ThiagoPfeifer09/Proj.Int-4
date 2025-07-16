// Módulo: IF_ID
// Objetivo: Este é o primeiro registrador do pipeline, localizado entre as etapas
// de Busca de Instrução (IF) e Decodificação (ID). Sua função é armazenar a
// instrução buscada da memória e o endereço da próxima instrução (PC + 4)
// para serem utilizados pela etapa de Decodificação no ciclo de clock seguinte.
// Este registrador também é controlado para permitir stalls (paralisações) e
// flushes (anulações) no pipeline.

module IF_ID(
    // --- Entradas ---
    input clk,                      // Sinal de clock para sincronização
    input reset,                    // Sinal de reset para inicializar o processador
    
    // Dados vindos da etapa de Busca (IF)
    input [31:0] instruction,       // A instrução de 32 bits lida da memória de instruções
    input [63:0] A,                 // O valor do Program Counter incrementado (geralmente PC + 4)
    
    // Sinais de Controle do Pipeline
    input flush,                    // Sinal para anular a instrução buscada (ex: após um desvio tomado)
    input IFIDWrite,                // Sinal de controle para o stall. Lógica invertida:
                                    // '0' = Escreve no registrador (pipeline avança).
                                    // '1' = Não escreve (pipeline para/stalls).
    
    // --- Saídas ---
    // Valores registrados que serão passados para a etapa de Decodificação (ID)
    output reg [31:0] inst,         // Instrução registrada
    output reg [63:0] a_out         // PC + 4 registrado
);

    // Bloco síncrono que atualiza os registradores na borda de subida do clock
    always @(posedge clk)
    begin
        // Lógica de reset ou flush: se o processador for resetado ou se um flush for
        // solicitado (indicando que a instrução buscada é inválida por causa de um
        // desvio), o conteúdo do registrador é zerado, inserindo um NOP na pipeline.
        if (reset == 1'b1 || flush == 1'b1)
        begin
            inst <= 32'b0;
            a_out <= 64'b0;
        end
        // Lógica de escrita (avanço do pipeline): se o sinal de controle 'IFIDWrite'
        // permitir a escrita (estiver em '0'), o registrador captura a nova instrução
        // e o novo valor de PC+4. Este é o funcionamento normal do pipeline.
        else if (IFIDWrite == 1'b0)
        begin
            inst <= instruction;
            a_out <= A;
        end
        // STALL (PARALISAÇÃO) IMPLÍCITO: Note que não há um 'else' final.
        // Em Verilog, se um 'reg' dentro de um bloco 'always' não recebe uma atribuição
        // sob todas as condições, ele mantém seu valor anterior.
        // Portanto, se 'reset' e 'flush' forem 0 e 'IFIDWrite' for 1, nenhuma
        // atribuição é feita, e o registrador 'segura' seus valores, efetivamente
        // paralisando a primeira etapa do pipeline por um ciclo.
    end
endmodule
