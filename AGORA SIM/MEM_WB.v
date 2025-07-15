// Módulo: MEM_WB
// Objetivo: Este é o último registrador de pipeline, posicionado entre a etapa
// de Acesso à Memória (MEM) e a de Escrita de Retorno (Write-Back, WB).
// Sua função é armazenar o resultado final de uma instrução (seja da ULA ou
// da memória) e os sinais de controle necessários para escrever esse resultado
// de volta no banco de registradores na etapa final.

module MEM_WB(
    // --- Entradas ---
    input clk,                      // Sinal de clock para sincronização
    input reset,                    // Sinal de reset para inicializar o registrador
    
    // Dados vindos da etapa de Acesso à Memória (MEM)
    input [63:0] read_data_in,      // Dado lido da memória de dados (para instruções 'load')
    input [63:0] result_alu_in,     // Resultado da ULA, vindo da etapa EX e passado pela MEM
    input [4:0] Rd_in,              // Endereço do registrador de destino (rd)
    
    // Sinais de controle finais, propagados pelas etapas anteriores
    input memtoreg_in,              // Sinal que seleciona entre o dado da memória ou o resultado da ULA
    input regwrite_in,              // Sinal que habilita a escrita no banco de registradores
    
    // --- Saídas ---
    // Valores registrados que alimentarão diretamente a etapa de Write-Back (WB)
    output reg [63:0] readdata,
    output reg [63:0] result_alu_out,
    output reg [4:0] rd,
    output reg Memtoreg, 
    output reg Regwrite
);
 
    // Bloco síncrono que atualiza os registradores na borda de subida do clock
    always @(posedge clk)
    begin
        // Lógica de reset: Se o processador for resetado, todos os valores são
        // zerados. Note que, geralmente, não há um 'flush' nesta etapa, pois
        // qualquer instrução que precise ser anulada já foi tratada nas etapas
        // anteriores do pipeline.
        if (reset == 1'b1)
        begin
            readdata <= 64'b0;
            result_alu_out <= 64'b0;
            rd <= 5'b0;
            Memtoreg <= 1'b0;
            Regwrite <= 1'b0;
        end
        // Operação normal do pipeline: captura os valores da etapa MEM e os armazena,
        // deixando-os prontos para a etapa de Write-Back no próximo ciclo.
        else
        begin
            readdata <= read_data_in;
            result_alu_out <= result_alu_in;
            rd <= Rd_in;
            Memtoreg <= memtoreg_in;
            Regwrite <= regwrite_in;
        end
    end
endmodule
