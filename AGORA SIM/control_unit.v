// Módulo: control_unit (Unidade de Controle Principal)
// Objetivo: Este é o centro de comando do processador. É um circuito puramente
// combinacional que recebe o opcode da instrução e gera todos os sinais de
// controle principais que orquestram a operação do datapath. Ele dita o que
// cada etapa do pipeline deve fazer para uma determinada instrução.

module control_unit(
    // --- Entradas ---
    input [6:0] opcode,     // O campo de opcode de 7 bits da instrução. É a entrada principal
                            // para a decodificação.
    input stall,            // Sinal vindo da Unidade de Detecção de Hazard. Se '1', força
                            // a inserção de uma bolha (stall) no pipeline.
    
    // --- Saídas (Sinais de Controle) ---
    output reg branch,      // Habilita a lógica de desvio?
    output reg memread,     // Habilita a leitura da memória de dados?
    output reg memtoreg,    // Seleciona o dado da memória para escrita no registrador (vs. resultado da ULA)?
    output reg memwrite,    // Habilita a escrita na memória de dados?
    output reg aluSrc,      // Seleciona a segunda entrada da ULA (registrador vs. imediato)?
    output reg regwrite,    // Habilita a escrita no banco de registradores?
    output reg [1:0] Aluop  // Sinal de 2 bits para a Unidade de Controle da ULA.
);
 
    // Bloco combinacional que decodifica o opcode para gerar os sinais.
    always @(*)
    begin
     
        // A lógica if-else if decodifica o opcode e define os sinais de controle
        // para cada tipo de instrução principal.
        
        // Decodificação para instruções de LOAD (ex: lw, ld)
        if (opcode == 7'b0000011)
        begin
            aluSrc = 1'b1;       // ULA usa o imediato (para calcular endereço)
            memtoreg = 1'b1;     // O dado da memória vai para o registrador
            regwrite = 1'b1;     // Habilita escrita no registrador
            memread = 1'b1;      // Habilita leitura da memória
            memwrite = 1'b0;     // Não escreve na memória
            branch = 1'b0;       // Não é um desvio
            Aluop = 2'b00;       // ULA deve fazer uma SOMA
        end
     
        // Decodificação para instruções de STORE (ex: sw, sd)
        else if (opcode == 7'b0100011)
        begin
            aluSrc = 1'b1;       // ULA usa o imediato (para calcular endereço)
            memtoreg = 1'bx;     // Não importa (don't care), pois RegWrite é 0
            regwrite = 1'b0;     // Não escreve no registrador
            memread = 1'b0;      // Não lê da memória
            memwrite = 1'b1;     // Habilita escrita na memória
            branch = 1'b0;       // Não é um desvio
            Aluop = 2'b00;       // ULA deve fazer uma SOMA
        end
     
        // Decodificação para instruções do Tipo-R (ex: add, sub, and, or)
        else if (opcode == 7'b0110011)
        begin
            aluSrc = 1'b0;       // ULA usa o segundo registrador (rs2)
            memtoreg = 1'b0;     // O resultado da ULA vai para o registrador
            regwrite = 1'b1;     // Habilita escrita no registrador
            memread = 1'b0;      // Sem acesso à memória
            memwrite = 1'b0;
            branch = 1'b0;       // Não é um desvio
            Aluop = 2'b10;       // ULA deve olhar o 'funct' para a operação específica
        end
     
        // Decodificação para instruções do Tipo-B (desvios condicionais, ex: beq)
        else if (opcode == 7'b1100011)
        begin
            aluSrc = 1'b0;       // ULA usa dois registradores (para comparar)
            memtoreg = 1'bx;     // Não importa (don't care)
            regwrite = 1'b0;     // Não escreve no registrador
            memread = 1'b0;      // Sem acesso à memória
            memwrite = 1'b0;
            branch = 1'b1;       // É um desvio
            Aluop = 2'b01;       // ULA deve fazer uma SUBTRAÇÃO (para comparar)
        end

        // Decodificação para instruções do Tipo-I (aritmética com imediato, ex: addi)
        else if (opcode == 7'b0010011)
        begin
            aluSrc = 1'b1;       // ULA usa o imediato
            memtoreg = 1'b0;     // O resultado da ULA vai para o registrador
            regwrite = 1'b1;     // Habilita escrita no registrador
            memread = 1'b0;      // Sem acesso à memória
            memwrite = 1'b0;
            branch = 1'b0;       // Não é um desvio
            Aluop = 2'b00;       // ULA deve fazer uma SOMA
        end
     
        // Caso Padrão (Default): Para qualquer opcode não reconhecido.
        // Isso torna o design mais seguro, gerando sinais para uma operação NOP.
        else
        begin
            aluSrc = 1'b0;
            memtoreg = 1'b0;
            regwrite = 1'b0;
            memread = 1'b0;
            memwrite = 1'b0;
            branch = 1'b0;
            Aluop = 2'b00;
        end
     
        // Lógica de STALL (Paralisação/Bolha)
        // Esta lógica SOBRESCREVE todas as outras. Se um stall for necessário,
        // todos os sinais de controle são forçados a 0, transformando
        // a instrução em um NOP antes que ela avance no pipeline.
        if (stall == 1'b1)
        begin
            aluSrc = 1'b0;
            memtoreg = 1'b0;
            regwrite = 1'b0;
            memread = 1'b0;
            memwrite = 1'b0;
            branch = 1'b0;
            Aluop = 2'b00;
        end
 
    end
endmodule
