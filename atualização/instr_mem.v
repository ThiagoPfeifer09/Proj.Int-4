// Módulo de Memória de Instruções - VERSÃO COM PROGRAMA INTERNO (HARCODED)
module instr_mem (
    input  wire [31:0] addr,
    output wire [31:0] instr
);
    reg [31:0] memory [0:255];

    // Carrega o programa de teste diretamente na memória
    initial begin
        memory[0]  = 32'h00000437; // lui  s0, 0
        memory[1]  = 32'h00040413; // addi s0, s0, 0
        memory[2]  = 32'h00042583; // lw   t1, 0(s0)
        memory[3]  = 32'h00442603; // lw   t2, 4(s0)
        memory[4]  = 32'h00c586b3; // add  t3, t1, t2
        memory[5]  = 32'h00442483; // lw   s1, 4(s0)
        memory[6]  = 32'h00148913; // addi s2, s1, 1
        memory[7]  = 32'h00d948e3; // blt  t3, s2, +8 (erro no seu prog, t3 > s2, deveria ser s2,t3) -> Corrigido para s2,t3 no hex
        memory[8]  = 32'h06468693; // addi t3, t3, 100 (esta linha deve ser pulada)
        memory[9]  = 32'h00291993; // slli s3, s2, 2
        memory[10] = 32'h00d9c423; // bge  t3, s3, +16 (não tomado)
        memory[11] = 32'h00d4a423; // sw   t3, 8(s0)
        memory[12] = 32'h00c4a623; // sw   s2, 12(s0)
        memory[13] = 32'h0134a823; // sw   s3, 16(s0)
        memory[14] = 32'h0000006f; // jal  zero, 14 (loop infinito)
    end

    assign instr = memory[addr[9:2]];

endmodule