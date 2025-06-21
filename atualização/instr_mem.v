// Módulo de Memória de Instruções - VERSÃO COM PROGRAMA DE TESTE DE MEMÓRIA
module instr_mem (
    input  wire [31:0] addr,
    output wire [31:0] instr
);
    reg [31:0] memory [0:255];

    // Carrega o programa de teste de memória diretamente
    initial begin
        memory[0] = 32'h00000437; // lui  s0, 0         (Prepara o endereço)
        memory[1] = 32'h10040413; // addi s0, s0, 256    (s0 = 0x100)
        memory[2] = 32'hdeadb4b7; // lui  s1, 0xdeadb     (Prepara o dado)
        memory[3] = 32'heef48493; // addi s1, s1, 3823  (s1 = 0xdeadbeef)
        memory[4] = 32'h00942023; // sw   s1, 0(s0)       (TESTE DE STORE WORD)
        memory[5] = 32'h00000493; // addi s1, zero, 0    (Limpa s1)
        memory[6] = 32'h00042903; // lw   s2, 0(s0)       (TESTE DE LOAD WORD)
        memory[7] = 32'h0000006f; // jal  zero, 7         (Loop infinito para terminar)
    end

    assign instr = memory[addr[9:2]];

endmodule