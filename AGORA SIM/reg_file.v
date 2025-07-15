// Módulo: reg_file (Banco de Registradores) - Versão Verilog-2001 Corrigida
// Objetivo: Este módulo implementa o banco de registradores do RISC-V. Ele suporta
// duas leituras combinacionais (assíncronas) e uma escrita síncrona.

module reg_file(
    // --- Entradas ---
    input clk,                   // Sinal de clock do sistema.
    input reset,                 // Sinal de reset síncrono.
    input [4:0] rs1,             // Endereço do primeiro registrador a ser lido.
    input [4:0] rs2,             // Endereço do segundo registrador a ser lido.
    input [4:0] rd,              // Endereço do registrador a ser escrito.
    input [63:0] writedata,       // O dado a ser escrito no registrador 'rd'.
    input reg_write,             // Sinal de habilitação de escrita.
    
    // --- Saídas ---
    output [63:0] readdata1,      // Dado lido do registrador no endereço 'rs1'.
    output [63:0] readdata2,      // Dado lido do registrador no endereço 'rs2'.
    
    // Saídas de diagnóstico para observar registradores específicos na simulação.
    output [63:0] r8,
    output [63:0] r19,
    output [63:0] r20,
    output [63:0] r21,
    output [63:0] r22
);
    // Declaração do armazenamento físico: um array de 32 registradores, cada um com 64 bits.
    reg [63:0] registers [31:0];

    // Atribuições para as saídas de diagnóstico.
    assign r8  = registers[8];
    assign r19 = registers[19];
    assign r20 = registers[20];
    assign r21 = registers[26];
    assign r22 = registers[27];

    // Lógica de LEITURA (Read Ports) - Combinacional (Assíncrona).
    // A leitura é direta do array de registradores.
    // O registrador x0 é tratado especialmente para sempre retornar 0.
    assign readdata1 = (rs1 == 5'b0) ? 64'd0 : registers[rs1];
    assign readdata2 = (rs2 == 5'b0) ? 64'd0 : registers[rs2];
    
    // Lógica de ESCRITA (Write Port) - Sequencial (Síncrona).
    // CORREÇÃO: A escrita agora ocorre na borda de SUBIDA do clock (posedge),
    // que é a prática padrão da indústria.
    integer i;
    always @(posedge clk)
    begin
        // Lógica de reset síncrono para inicializar os registradores.
        if (reset) begin
            for (i=0; i<32; i=i+1) begin
                registers[i] <= 64'd0;
            end
        end
        else begin
            // A escrita só ocorre se 'reg_write' estiver ativado E o destino não for x0.
            // CORREÇÃO: Adicionada verificação para impedir a escrita no registrador x0.
            if (reg_write && rd != 5'b0) begin
                registers[rd] <= writedata;
            end
        end
    end
endmodule
