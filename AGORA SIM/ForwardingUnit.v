// Módulo: ForwardingUnit
// Objetivo: Este módulo implementa a lógica de adiantamento (forwarding) para
// resolver hazards de dados. É um circuito puramente combinacional que detecta
// quando uma instrução na etapa de Execução (EX) precisa de um resultado que
// ainda não foi escrito no banco de registradores, mas que está disponível nas
// etapas de Memória (MEM) ou Write-Back (WB). Ele gera sinais de controle para
// multiplexadores na entrada da ULA, criando um "atalho" para os dados.

module ForwardingUnit(
    // --- Entradas ---
    // Endereços dos registradores fonte (rs1, rs2) da instrução na etapa ID/EX.
    // Esta é a instrução que PODE PRECISAR de um dado adiantado.
    input [4:0] RS_1, // ID/EX.RegisterRs1
    input [4:0] RS_2, // ID/EX.RegisterRs2
    
    // Endereço do registrador de destino (rd) da instrução na etapa EX/MEM.
    // Esta é uma POTENCIAL FONTE de dados adiantados.
    input [4:0] rdMem, // EX/MEM.RegisterRd
    
    // Endereço do registrador de destino (rd) da instrução na etapa MEM/WB.
    // Esta é outra POTENCIAL FONTE de dados adiantados.
    input [4:0] rdWb, // MEM/WB.RegisterRd
    
    // Sinais de controle 'RegWrite' das etapas futuras. São essenciais para
    // garantir que só adiantamos o resultado de instruções que de fato
    // irão escrever em um registrador (ex: R-Type, lw), e não de instruções
    // como 'sw' (store word).
    input regWrite_Wb, // MEM/WB.RegWrite
    input regWrite_Mem, // EX/MEM.RegWrite
    
    // --- Saídas ---
    // Sinais de controle para os multiplexadores da entrada da ULA.
    // '00': Sem adiantamento (usa valor do banco de registradores).
    // '10': Adiantar da etapa MEM (resultado da ULA da instrução anterior).
    // '01': Adiantar da etapa WB (resultado da instrução de duas posições atrás).
    output reg [1:0] Forward_A, // Controle para o primeiro operando da ULA (origem rs1)
    output reg [1:0] Forward_B  // Controle para o segundo operando da ULA (origem rs2)
);

    // Bloco combinacional: as saídas são atualizadas imediatamente quando qualquer entrada muda.
    always @(*)
    begin
        // --- LÓGICA PARA O OPERANDO A (RS1) ---
        
        // HAZARD EX/MEM: O perigo mais iminente é com a instrução imediatamente anterior,
        // que agora está na etapa MEM. Esta verificação tem a MAIOR PRIORIDADE.
        // Condições:
        // 1. O destino da instrução em MEM (rdMem) é a fonte da instrução em EX (RS_1)?
        // 2. A instrução em MEM realmente vai escrever em um registrador (regWrite_Mem)?
        // 3. O registrador de destino não é x0 (que é sempre zero e não pode ser escrito)?
        if ( (rdMem == RS_1) && (regWrite_Mem != 0) && (rdMem != 0) )
        begin
            Forward_A = 2'b10; // Adiantar o resultado da ULA vindo da etapa EX/MEM.
        end
        // HAZARD MEM/WB: Se não há hazard com a etapa MEM, verificamos a etapa WB.
        // Condições:
        // 1. O destino da instrução em WB (rdWb) é a fonte da instrução em EX (RS_1)?
        // 2. A instrução em WB realmente vai escrever em um registrador (regWrite_Wb)?
        // 3. O registrador de destino não é x0?
        // 4. E, crucialmente, NÃO HÁ um hazard EX/MEM para o mesmo registrador (isso garante a prioridade do hazard EX/MEM, que fornece o dado mais recente).
        else if ( (rdWb == RS_1) && (regWrite_Wb != 0) && (rdWb != 0) && !((rdMem == RS_1) && (regWrite_Mem != 0) && (rdMem != 0)) )
        begin
            Forward_A = 2'b01; // Adiantar o resultado vindo da etapa MEM/WB.
        end
        else
        begin
            Forward_A = 2'b00; // Nenhum hazard de dados para RS_1. Usar o valor do banco de registradores.
        end
        
        // --- LÓGICA PARA O OPERANDO B (RS2) ---
        // A lógica é idêntica à do Operando A, mas agora comparamos com RS_2.
        
        // HAZARD EX/MEM para RS2.
        if ( (rdMem == RS_2) && (regWrite_Mem != 0) && (rdMem != 0) )
        begin
            Forward_B = 2'b10; // Adiantar o resultado da ULA vindo da etapa EX/MEM.
        end
        // HAZARD MEM/WB para RS2.
        else if ( (rdWb == RS_2) && (regWrite_Wb != 0) && (rdWb != 0) && !((rdMem == RS_2) && (regWrite_Mem != 0) && (rdMem != 0)) )
        begin
            Forward_B = 2'b01; // Adiantar o resultado vindo da etapa MEM/WB.
        end
        else
        begin
            Forward_B = 2'b00; // Nenhum hazard de dados para RS_2. Usar o valor do banco de registradores.
        end
    end
endmodule
