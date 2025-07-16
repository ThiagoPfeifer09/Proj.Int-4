// Módulo: pipeline_flush (Anulação do Pipeline)
// Objetivo: Este módulo gera o sinal de 'flush' (anulação) para o pipeline.
// Um flush é necessário para descartar as instruções que foram buscadas
// especulativamente após uma instrução de desvio (branch), quando se descobre
// que o desvio deve ser tomado.

module pipeline_flush(
    // --- Entrada ---
    input branch,       // Sinal de entrada que é ativado ('1') quando um desvio é tomado.
    
    // --- Saída ---
    // A saída agora é um 'wire' (padrão), pois é dirigida por um 'assign'.
    output flush        // Sinal de saída 'flush'.
);
 
    // A lógica foi simplificada para uma única atribuição contínua.
    // Isso é mais eficiente e claro para um circuito que funciona como um fio.
    assign flush = branch;
 
endmodule
