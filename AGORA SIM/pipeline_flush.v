// Módulo: pipeline_flush
// Objetivo: Este módulo gera o sinal de 'flush' (anulação) para o pipeline.
// Um flush é necessário para descartar as instruções que foram buscadas
// especulativamente após uma instrução de desvio (branch), quando se descobre
// que o desvio deve ser tomado. Ele anula essas instruções para garantir que
// o fluxo de execução correto seja seguido.

module pipeline_flush(
    // --- Entrada ---
    input branch,       // Sinal de entrada que é ativado ('1') quando um desvio é tomado.
    
    // --- Saída ---
    output reg flush    // Sinal de saída 'flush'. Quando '1', os estágios iniciais
                        // do pipeline (IF/ID, ID/EX) devem anular suas instruções.
);
 
    // ATENÇÃO: Blocos 'initial' NÃO SÃO SINTETIZÁVEIS para hardware (FPGAs/ASICs).
    // Eles são uma construção de SIMULAÇÃO. A lógica combinacional deve definir
    // a saída para todos os casos possíveis.
    initial
    begin
        flush = 1'b0;
    end
 
    // Bloco combinacional que gera o sinal de flush.
    always @(*)
    begin
        // A lógica é direta: se um desvio for tomado, ative o flush.
        if (branch == 1'b1)
            flush = 1'b1;
        else
            flush = 1'b0;
        // NOTA: Este bloco 'if-else' inteiro pode ser simplificado para uma única
        // linha, pois a saída é funcionalmente idêntica à entrada:
        // assign flush = branch;
    end
 
endmodule
