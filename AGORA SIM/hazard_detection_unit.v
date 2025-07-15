// Módulo: hazard_detection_unit (Unidade de Detecção de Hazard)
// Objetivo: Este módulo é responsável por detectar um tipo específico de hazard de
// dados que não pode ser resolvido apenas por adiantamento (forwarding): o hazard
// de "load-use". Isso ocorre quando uma instrução tenta usar o resultado de um
// 'load' que está na instrução imediatamente anterior. A unidade força uma
// paralisação (stall) de um ciclo no pipeline para esperar o dado da memória.

module hazard_detection_unit (
    // --- Entradas ---
    // Sinais vindos da etapa ID/EX
    input Memread,          // Sinal 'MemRead' da instrução na etapa EX. Se '1', é um load.
    input [4:0] Rd,         // Endereço do registrador de destino (rd) da instrução na etapa EX.
    
    // Sinal vindo da etapa IF/ID
    input [31:0] inst,      // A instrução completa que está na etapa ID (logo atrás do load).
    
    // --- Saída ---
    output reg stall         // Sinal de controle. '1' = Paralisar o pipeline; '0' = Continuar.
);
 
    // ATENÇÃO: Blocos 'initial' NÃO SÃO SINTETIZÁVEIS para hardware (FPGAs/ASICs).
    // Eles são uma construção de SIMULAÇÃO. A lógica combinacional deve definir
    // a saída para todos os casos possíveis para evitar a inferência de latches.
    initial
    begin
        stall = 1'b0;
    end
 
    // Bloco combinacional que continuamente verifica a condição de hazard.
    always @(*)
    begin
        // A CONDIÇÃO DE HAZARD DE LOAD-USE:
        // 1. A instrução na etapa de Execução (EX) é um 'load' (Memread == 1)?
        // 2. E o registrador de destino (Rd) desse 'load' é um dos registradores
        //    fonte (rs1 ou rs2) da instrução que está na etapa de Decodificação (ID)?
        //    - inst[19:15] é o campo para rs1 na codificação RISC-V.
        //    - inst[24:20] é o campo para rs2 na codificação RISC-V.
        if (Memread == 1'b1 && ((Rd == inst[19:15]) || (Rd == inst[24:20])))
        begin
            // Se a condição for verdadeira, um hazard foi detectado.
            // Ativamos o sinal 'stall' para parar o pipeline por um ciclo.
            stall = 1'b1;
        end
        else
        begin
            // Se não houver hazard de load-use, o pipeline pode prosseguir normalmente.
            stall = 1'b0;
        end
    end
endmodule
