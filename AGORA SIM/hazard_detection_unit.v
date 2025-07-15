// Módulo: hazard_detection_unit (Unidade de Detecção de Hazard) - Versão Verilog-2001 Aprimorada
// Objetivo: Este módulo é responsável por detectar o hazard de "load-use".
// Ele força uma paralisação (stall) de um ciclo no pipeline para esperar o dado da memória.

module hazard_detection_unit (
    // --- Entradas ---
    // Sinais vindos da etapa ID/EX
    input Memread,          // Sinal 'MemRead' da instrução na etapa EX. Se '1', é um load.
    input [4:0] Rd,         // Endereço do registrador de destino (rd) da instrução na etapa EX.
    
    // Sinal vindo da etapa IF/ID
    input [31:0] inst,      // A instrução completa que está na etapa ID.
    
    // --- Saída ---
    // A saída agora é um 'wire' (padrão para output), pois é dirigida por um 'assign'.
    output stall            // Sinal de controle. '1' = Paralisar o pipeline; '0' = Continuar.
);
 
    // A lógica combinacional foi simplificada para uma única atribuição contínua 'assign'.
    // O sinal 'stall' será '1' se e somente se a condição de hazard de load-use for verdadeira:
    // 1. A instrução na etapa EX é um 'load' (Memread == 1)?
    // 2. E o registrador de destino (Rd) desse 'load' é um dos registradores fonte (rs1 ou rs2)
    //    da instrução seguinte (que está na etapa ID)?
    assign stall = (Memread == 1'b1) && 
                   ( (Rd == inst[19:15]) || (Rd == inst[24:20]) );
 
endmodule
