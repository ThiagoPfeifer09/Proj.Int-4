// Módulo: EX_MEM
// Objetivo: Este módulo implementa o registrador de pipeline entre as etapas
// de Execução (EX) e Acesso à Memória (MEM). Sua função principal é armazenar
// os resultados e sinais de controle gerados na etapa EX e passá-los para
// a etapa MEM no próximo ciclo de clock, mantendo a sincronia do pipeline.

module EX_MEM(
  // --- Entradas ---
  input clk,                      // Sinal de clock para sincronização
  input reset,                    // Sinal de reset para inicializar o registrador
  
  // Dados vindos da etapa de Execução (EX)
  input [63:0] Adder_out,         // Resultado do somador que calcula o endereço de desvio (branch)
  input [63:0] Result_in_alu,     // Resultado da Unidade Lógica e Aritmética (ULA)
  input Zero_in,                  // Flag 'Zero' da ULA (indica se o resultado foi zero)
  input [63:0] writedata_in,      // Dado a ser escrito na memória (vindo do registrador rs2)
  input [4:0] Rd_in,              // Endereço do registrador de destino (rd)
  
  // Sinais de controle que são propagados pelo pipeline
  input branch_in,                // Sinal de controle para desvio condicional
  input memread_in,               // Sinal de controle para leitura da memória (instrução lw)
  input memtoreg_in,              // Sinal de controle que define se o dado para o registrador vem da memória ou da ULA
  input memwrite_in,              // Sinal de controle para escrita na memória (instrução sw)
  input regwrite_in,              // Sinal de controle para habilitar a escrita no banco de registradores
  
  // Sinal para anular a instrução (inserir bolha)
  input flush,                    // Sinal que invalida a instrução presente no registrador, geralmente por um desvio tomado
  
  // Sinal de controle para um MUX propagado pelo pipeline
  input addermuxselect_in,
  
  // --- Saídas ---
  // As saídas são versões registradas (atrasadas em um ciclo) das entradas,
  // que serão usadas pela etapa de Acesso à Memória (MEM).
  output reg [63:0] Adderout,
  output reg zero,
  output reg [63:0] result_out_alu,
  output reg [63:0] writedata_out,
  output reg [4:0] rd,
  output reg Branch, 
  output reg Memread, 
  output reg Memtoreg, 
  output reg MemWrite, 
  output reg Regwrite,
  output reg addermuxselect
);

  // Bloco síncrono que atualiza os registradores na borda de subida do clock
  always @ (posedge clk)
  begin
    // Lógica de reset ou flush: se o processador for resetado ou se um flush for
    // solicitado (ex: devido a um desvio condicional tomado), todos os valores e
    // sinais de controle são zerados. Isso transforma a instrução em uma operação
    // nula (NOP), prevenindo ações incorretas nas etapas seguintes.
    if (reset == 1'b1 || flush == 1'b1)
    begin
      Adderout <= 64'b0;
      zero <= 1'b0;
      result_out_alu <= 64'b0; // Usar 64'b0 para consistência de largura de barramento
      writedata_out <= 64'b0;
      rd <= 5'b0;
      Branch <= 1'b0;
      Memread <= 1'b0;
      Memtoreg <= 1'b0;
      MemWrite <= 1'b0;
      Regwrite <= 1'b0;
      addermuxselect <= 1'b0;
    end
    // Operação normal do pipeline: se não houver reset ou flush, os valores
    // das entradas (vindas da etapa EX) são capturados e armazenados nos
    // registradores internos deste módulo.
    else
    begin
      Adderout <= Adder_out;
      zero <= Zero_in;
      result_out_alu <= Result_in_alu;
      writedata_out <= writedata_in;
      rd <= Rd_in;
      Branch <= branch_in;
      Memread <= memread_in;
      Memtoreg <= memtoreg_in;
      MemWrite <= memwrite_in;
      Regwrite <= regwrite_in;
      addermuxselect <= addermuxselect_in;
    end
  end
endmodule
