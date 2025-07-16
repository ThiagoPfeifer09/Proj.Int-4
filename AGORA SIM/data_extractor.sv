// Módulo: data_extractor (Extrator de Dados Imediatos) - Versão Verilog-2001 Aprimorada
// Objetivo: Este módulo é responsável por uma tarefa crucial na etapa de Decodificação:
// extrair os bits do valor imediato da instrução, montá-los na ordem correta
// de acordo com o formato da instrução (I, S, B, etc.), e então estender o sinal
// desse valor para 64 bits, para que ele possa ser usado pela ULA.

module data_extractor (
    // --- Entrada ---
    input [31:0] instruction,   // A instrução completa de 32 bits vinda da etapa IF.
    
    // --- Saída ---
    output reg [63:0] imm_data  // O valor imediato final, com sinal estendido para 64 bits.
);
 
    // Registrador temporário para armazenar o imediato de 12 bits já montado.
    // Isso evita dependências lógicas complexas e torna o código mais seguro para a síntese.
    reg [11:0] imm_12bit;

    always @(*)
    begin
        // O 'case' seleciona a lógica de extração do imediato e a armazena
        // no registrador temporário 'imm_12bit'.
        // ATENÇÃO: Usar 'instruction[6:5]' como seletor é uma simplificação que pode
        // não funcionar para um conjunto de instruções RISC-V completo.
        case (instruction[6:5])
            // Formatos I-type (ex: addi, lw).
            2'b00:
                imm_12bit = instruction[31:20];
            
            // Formatos S-type (ex: sw).
            2'b01:
                imm_12bit = {instruction[31:25], instruction[11:7]};
            
            // Formatos B-type (ex: beq).
            2'b11:
                imm_12bit = {instruction[31], instruction[7], instruction[30:25], instruction[11:8]};

            // O default garante que não haverá latch se um formato desconhecido for recebido.
            default:
                imm_12bit = 12'hxxx; // 'x' = don't care
        endcase
        
        // Extensão de Sinal para 64 bits a partir do valor de 12 bits já montado.
        // Pega o bit de sinal (imm_12bit[11]) e o replica nas 52 posições superiores.
        imm_data = {{52{imm_12bit[11]}}, {imm_12bit}};
    end
endmodule
