// Módulo: data_extractor (Extrator de Dados Imediatos)
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
 
    always @(*)
    begin
        // O 'case' seleciona a lógica de extração do imediato.
        // ATENÇÃO: Usar 'instruction[6:5]' como seletor é uma simplificação.
        // Em um processador RISC-V completo, isso não é suficiente para diferenciar
        // todos os formatos (ex: S-type e R-type podem ter os mesmos bits [6:5]).
        // Um design robusto usaria o opcode completo ou sinais da Unidade de Controle.
        case (instruction[6:5])
            // Caso para formatos I-type (ex: addi, lw).
            2'b00:
            begin
                // O imediato de 12 bits está contido nos bits [31:20].
                imm_data[11:0] = instruction[31:20];
            end
            
            // Caso para formatos S-type (ex: sw).
            2'b01:
            begin
                // O imediato de 12 bits é dividido em dois campos.
                // Precisamos concatená-los na ordem correta.
                imm_data[11:0] = {instruction[31:25], instruction[11:7]};
            end
            
            // Caso para formatos B-type (ex: beq).
            2'b11:
            begin
                // O imediato de 12 bits do branch também é dividido e precisa ser
                // remontado na ordem correta.
                imm_data[11:0] = {instruction[31], instruction[7], instruction[30:25], instruction[11:8]};
            end
        endcase
        
        // Extensão de Sinal para 64 bits.
        // Após montar o imediato de 12 bits, pegamos o seu bit mais significativo
        // (o bit de sinal, imm_data[11]) e o replicamos nas 52 posições
        // superiores. Isso garante que o valor do imediato (positivo ou negativo)
        // seja preservado quando ele for estendido para 64 bits.
        imm_data = {{52{imm_data[11]}},{imm_data[11:0]}};
    end
endmodule
