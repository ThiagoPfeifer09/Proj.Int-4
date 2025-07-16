// Módulo: Parser (Analisador/Decodificador de Instrução)
// Objetivo: Este módulo tem uma função estrutural simples, mas muito importante.
// Ele recebe a palavra de instrução de 32 bits e a "fatia" em seus campos
// constituintes, como opcode, rd, rs1, etc., de acordo com o formato padrão
// do conjunto de instruções RISC-V. Isso torna o resto do design mais limpo
// e legível, pois outros módulos podem se conectar a estes fios nomeados em vez
// de fatiar o barramento de instrução repetidamente.

module Parser(
    // --- Entrada ---
    input [31:0] instruction,   // A palavra de instrução de 32 bits, vinda do registrador IF/ID.
    
    // --- Saídas ---
    // Os campos da instrução, agora separados e nomeados.
    output [6:0] opcode,        // Campo Opcode (bits 6:0) - Define o tipo da instrução.
    output [4:0] rd,            // Endereço do registrador de destino (bits 11:7).
    output [2:0] funct3,        // Campo de função de 3 bits (bits 14:12) - Especializa o opcode.
    output [4:0] rs1,           // Endereço do primeiro registrador fonte (bits 19:15).
    output [4:0] rs2,           // Endereço do segundo registrador fonte (bits 24:20).
    output [6:0] funct7         // Campo de função de 7 bits (bits 31:25) - Especializa ainda mais.
);
 
    // As atribuições contínuas 'assign' simplesmente conectam fatias do barramento
    // de entrada 'instruction' às portas de saída. Não há lógica complexa aqui,
    // apenas uma reorganização estrutural dos fios para dar nomes significativos
    // a cada campo da instrução.
    
    assign opcode = instruction[6:0];
    assign rd     = instruction[11:7];
    assign funct3 = instruction[14:12];
    assign rs1    = instruction[19:15];
    assign rs2    = instruction[24:20];
    assign funct7 = instruction[31:25];
 
endmodule
