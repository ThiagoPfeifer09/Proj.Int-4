// Módulo: reg_file (Banco de Registradores)
// Objetivo: Este módulo implementa o banco de registradores do RISC-V. É uma memória
// pequena e muito rápida que contém os 32 registradores de propósito geral (x0-x31).
// Ele é projetado para suportar duas leituras simultâneas (para rs1 e rs2) e
// uma escrita síncrona (para rd) em cada ciclo de clock.

module reg_file(
    // --- Entradas ---
    input clk,                   // Sinal de clock do sistema.
    input reset,                 // Sinal de reset.
    input [4:0] rs1,             // Endereço de 5 bits do primeiro registrador a ser lido.
    input [4:0] rs2,             // Endereço de 5 bits do segundo registrador a ser lido.
    input [4:0] rd,              // Endereço de 5 bits do registrador a ser escrito.
    input [63:0] writedata,       // O dado de 64 bits a ser escrito no registrador 'rd'.
    input reg_write,             // Sinal de habilitação de escrita. Se '1', a escrita ocorre.
    
    // --- Saídas ---
    output reg [63:0] readdata1,  // Dado lido do registrador no endereço 'rs1'.
    output reg [63:0] readdata2,  // Dado lido do registrador no endereço 'rs2'.
    
    // Saídas de diagnóstico para observar registradores específicos na simulação.
    output [63:0] r8,
    output [63:0] r19,
    output [63:0] r20,
    output [63:0] r21,
    output [63:0] r22
);
    integer i;
    // Declaração do armazenamento físico: um array de 32 registradores, cada um com 64 bits.
    reg [63:0] registers [31:0];

    // Bloco de inicialização para SIMULAÇÃO.
    // ATENÇÃO: Blocos 'initial' NÃO SÃO SINTETIZÁVEIS para hardware.
    // A inicialização dos registradores em um hardware real geralmente é feita
    // por um loop de reset controlado por software.
    initial
    begin
        //... (inicialização dos registradores para simulação)
        registers[0] = 64'd0; registers[1] = 64'd0; //... e assim por diante
        registers[11] = 64'd8; //...
    end

    // Atribuições para as saídas de diagnóstico.
    assign r8 = registers[8];
    assign r19 = registers[19];
    assign r20 = registers[20];
    assign r21 = registers[26];
    assign r22 = registers[27];

    // Lógica de LEITURA (Read Ports) - Combinacional (Assíncrona).
    // O banco de registradores fornece os dados de 'rs1' e 'rs2' imediatamente
    // assim que os endereços são fornecidos.
    always @ (*)
    begin
        // A lógica de reset aqui é pouco convencional para portas de leitura.
        // Normalmente, a leitura é puramente combinacional: readdata1 = registers[rs1].
        if (reset == 1'b1)
        begin
            readdata1 = 64'd0;
            readdata2 = 64'd0;
        end
        else
        begin
            readdata1 = registers[rs1];
            readdata2 = registers[rs2];
        end
    end
    
    // Lógica de ESCRITA (Write Port) - Sequencial (Síncrona).
    // ATENÇÃO 1: Usar a borda de descida do clock ('negedge clk') é altamente
    // incomum e pode causar sérios problemas de temporização em um design real.
    // A prática padrão da indústria é usar 'posedge clk' para toda a lógica síncrona.
    always @(negedge clk)
    begin
        // A escrita só ocorre se o sinal 'reg_write' estiver ativado.
        // ATENÇÃO 2: A arquitetura RISC-V exige que o registrador x0 seja
        // sempre zero. Esta lógica permite que x0 seja sobrescrito. O correto
        // seria: if (reg_write == 1 && rd != 5'b0)
        if (reg_write == 1)
            registers[rd] <= writedata;
    end
endmodule
