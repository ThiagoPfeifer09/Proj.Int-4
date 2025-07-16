// Módulo: ID_EX
// Objetivo: Este módulo implementa o registrador de pipeline entre as etapas
// de Decodificação de Instrução (ID) e Execução (EX). Sua função é carregar
// todos os dados, endereços e sinais de controle gerados na etapa ID e
// passá-los para a etapa EX no ciclo de clock seguinte. Ele é fundamental para
// o fluxo de informações e para a inserção de bolhas (stalls) no pipeline.

module ID_EX(
  // --- Entradas ---
  input clk,                      // Sinal de clock para sincronização
  input reset,                    // Sinal de reset para inicializar o registrador
  
  // Dados e endereços decodificados na etapa ID
  input [3:0] funct4_in,          // Campo de função da instrução (ex: para controle da ULA)
  input [63:0] A_in,              // Valor do PC + 4 (ou similar), vindo da etapa IF, para cálculo de desvio
  input [63:0] readdata1_in,      // Dado lido do banco de registradores (endereço rs1)
  input [63:0] readdata2_in,      // Dado lido do banco de registradores (endereço rs2)
  input [63:0] imm_data_in,       // Valor imediato extraído da instrução e com sinal estendido
  input [4:0] rs1_in,             // Endereço do primeiro registrador fonte (rs1)
  input [4:0] rs2_in,             // Endereço do segundo registrador fonte (rs2)
  input [4:0] rd_in,              // Endereço do registrador de destino (rd)
  
  // Sinais de controle gerados pela Unidade de Controle na etapa ID
  input branch_in,                // É uma instrução de desvio?
  input memread_in,               // Habilita leitura da memória?
  input memtoreg_in,              // O dado para o registrador vem da memória?
  input memwrite_in,              // Habilita escrita na memória?
  input aluSrc_in,                // A segunda entrada da ULA é um imediato?
  input regwrite_in,              // Habilita escrita no banco de registradores?
  input [1:0] Aluop_in,           // Operação principal da ULA (definida pelo opcode)
  
  // Sinal para anular a instrução (inserir bolha/stall)
  input flush,                    // Sinal que invalida a instrução, geralmente por um hazard de dados (ex: load-use)

  // --- Saídas ---
  // Versões registradas das entradas, que alimentarão a etapa de Execução (EX)
  output reg [63:0] a,
  output reg [4:0] rs1,
  output reg [4:0] rs2,
  output reg [4:0] rd,
  output reg [63:0] imm_data,
  output reg [63:0] readdata1,
  output reg [63:0] readdata2,
  output reg [3:0] funct4_out,
  output reg Branch,
  output reg Memread,
  output reg Memtoreg, 
  output reg Memwrite, 
  output reg Regwrite,
  output reg Alusrc, 
  output reg [1:0] aluop
);
 
  // Bloco síncrono que atualiza os registradores na borda de subida do clock
  always @ (posedge clk)
  begin
    // Lógica de reset ou flush: se o processador for resetado ou um 'flush' for
    // solicitado, o conteúdo do registrador é zerado.
    // O 'flush' aqui é crucial para a inserção de uma bolha (pipeline stall).
    // Isso acontece, por exemplo, em um hazard de load-use, onde a pipeline
    // precisa parar por um ciclo para esperar o dado vir da memória. Zerar os
    // sinais de controle transforma a instrução em um NOP.
    if (reset == 1'b1 || flush == 1'b1)
    begin
      a <= 64'b0;
      rs1 <= 5'b0;
      rs2 <= 5'b0;
      rd <= 5'b0;
      imm_data <= 64'b0;
      readdata1 <= 64'b0;
      readdata2 <= 64'b0;
      funct4_out <= 4'b0;
      Branch <= 1'b0;
      Memread <= 1'b0;
      Memtoreg <= 1'b0;
      Memwrite <= 1'b0;
      Regwrite <= 1'b0;
      Alusrc <= 1'b0;
      aluop <= 2'b0;
    end
    // Operação normal do pipeline: captura todos os valores da etapa ID e os armazena,
    // disponibilizando-os para a etapa EX no próximo ciclo de clock.
    else
    begin
      a <= A_in;
      rs1 <= rs1_in;
      rs2 <= rs2_in;
      rd <= rd_in;
      imm_data <= imm_data_in;
      readdata1 <= readdata1_in;
      readdata2 <= readdata2_in;
      funct4_out <= funct4_in;
      Branch <= branch_in;
      Memread <= memread_in;
      Memtoreg <= memtoreg_in;
      Memwrite <= memwrite_in;
      Regwrite <= regwrite_in;
      Alusrc <= aluSrc_in;
      aluop <= Aluop_in;
    end
  end
endmodule
