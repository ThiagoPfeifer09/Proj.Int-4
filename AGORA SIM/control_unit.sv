// Módulo: control_unit (Unidade de Controle Principal) - Versão Verilog-2001
// Objetivo: Este é o centro de comando do processador. É um circuito puramente
// combinacional que recebe o opcode da instrução e gera todos os sinais de
// controle principais que orquestram a operação do datapath.

module control_unit(
    // --- Entradas ---
    input [6:0] opcode,     // O campo de opcode de 7 bits da instrução.
    input stall,            // Sinal da Unidade de Detecção de Hazard para forçar uma bolha.
    
    // --- Saídas (Sinais de Controle) ---
    output reg branch,
    output reg memread,
    output reg memtoreg,
    output reg memwrite,
    output reg aluSrc,
    output reg regwrite,
    output reg [1:0] Aluop
);
 
    // Bloco combinacional que decodifica o opcode para gerar os sinais.
    always @(*)
    begin
        // A lógica foi reescrita com 'case' para maior clareza.
        // É funcionalmente equivalente à estrutura 'if-else if' original.
        case (opcode)
            // Decodificação para instruções de LOAD (ex: lw, ld)
            7'b0000011: begin
                aluSrc   = 1'b1;
                memtoreg = 1'b1;
                regwrite = 1'b1;
                memread  = 1'b1;
                memwrite = 1'b0;
                branch   = 1'b0;
                Aluop    = 2'b00;
            end
     
            // Decodificação para instruções de STORE (ex: sw, sd)
            7'b0100011: begin
                aluSrc   = 1'b1;
                memtoreg = 1'bx; // "Don't care"
                regwrite = 1'b0;
                memread  = 1'b0;
                memwrite = 1'b1;
                branch   = 1'b0;
                Aluop    = 2'b00;
            end
     
            // Decodificação para instruções do Tipo-R (ex: add, sub)
            7'b0110011: begin
                aluSrc   = 1'b0;
                memtoreg = 1'b0;
                regwrite = 1'b1;
                memread  = 1'b0;
                memwrite = 1'b0;
                branch   = 1'b0;
                Aluop    = 2'b10;
            end
     
            // Decodificação para instruções do Tipo-B (desvios, ex: beq)
            7'b1100011: begin
                aluSrc   = 1'b0;
                memtoreg = 1'bx; // "Don't care"
                regwrite = 1'b0;
                memread  = 1'b0;
                memwrite = 1'b0;
                branch   = 1'b1;
                Aluop    = 2'b01;
            end

            // Decodificação para instruções do Tipo-I (aritmética com imediato, ex: addi)
            7'b0010011: begin
                aluSrc   = 1'b1;
                memtoreg = 1'b0;
                regwrite = 1'b1;
                memread  = 1'b0;
                memwrite = 1'b0;
                branch   = 1'b0;
                Aluop    = 2'b00;
            end
     
            // Caso Padrão (Default): Para qualquer opcode não reconhecido, gera sinais de NOP.
            default: begin
                aluSrc   = 1'b0;
                memtoreg = 1'b0;
                regwrite = 1'b0;
                memread  = 1'b0;
                memwrite = 1'b0;
                branch   = 1'b0;
                Aluop    = 2'b00;
            end
        endcase
     
        // Lógica de STALL (Paralisação/Bolha)
        // Esta lógica SOBRESCREVE todas as outras. Se um stall for necessário,
        // força todos os sinais de controle para 0, transformando a instrução em um NOP.
        if (stall == 1'b1)
        begin
            aluSrc   = 1'b0;
            memtoreg = 1'b0;
            regwrite = 1'b0;
            memread  = 1'b0;
            memwrite = 1'b0;
            branch   = 1'b0;
            Aluop    = 2'b00;
        end
    end
endmodule
