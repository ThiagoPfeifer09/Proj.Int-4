// Módulo: instruction_memory (Memória de Instruções)
// Objetivo: Este módulo modela a memória que armazena o programa a ser executado
// pelo processador. Na prática, funciona como uma Memória Apenas de Leitura (ROM).
// Ele recebe um endereço do Program Counter (PC) e retorna a instrução de 32 bits
// armazenada nesse endereço.

module instruction_memory(
    // --- Entrada ---
    input [63:0] inst_address,  // Endereço da instrução a ser buscada, vindo do PC.
    
    // --- Saída ---
    output reg [31:0] instruction // A instrução de 32 bits lida da memória.
);

    // Declaração da memória: um array de 88 posições, onde cada posição armazena 8 bits (1 byte).
    // Isso modela uma memória de 88 bytes, endereçável a byte, capaz de armazenar 22 instruções.
    reg [7:0] inst_mem[87:0];
 
    // Bloco de inicialização que "grava" o programa na memória.
    // NOTA: Este bloco é usado para carregar o programa durante a SIMULAÇÃO.
    // Em uma síntese para hardware, isso instruiria a ferramenta a criar uma ROM
    // com este conteúdo pré-gravado.
    initial
    begin
        // Cada linha atribui uma instrução de 32 bits a 4 bytes consecutivos na memória.
        // Ex: 'addi s2, x0, 0'
        {inst_mem[3], inst_mem[2], inst_mem[1], inst_mem[0]} = 32'h00000913; // 1
        // add s0, x0, x0
        {inst_mem[7], inst_mem[6], inst_mem[5], inst_mem[4]} = 32'h00000433; // 2
        // beq s3, s3, 8
        {inst_mem[11], inst_mem[10], inst_mem[9], inst_mem[8]} = 32'h04b40863; // 3
        // add t3, x0, x8
        {inst_mem[15], inst_mem[14], inst_mem[13], inst_mem[12]} = 32'h00800eb3; // 4
        // add t4, s0, x0
        {inst_mem[19], inst_mem[18], inst_mem[17], inst_mem[16]} = 32'h000409b3; // 5
        // add t4, t3, t3
        {inst_mem[23], inst_mem[22], inst_mem[21], inst_mem[20]} = 32'h013989b3; // 6
        // add t4, t3, t3
        {inst_mem[27], inst_mem[26], inst_mem[25], inst_mem[24]} = 32'h013989b3; // 7
        // add t4, t3, t3
        {inst_mem[31], inst_mem[30], inst_mem[29], inst_mem[28]} = 32'h013989b3; // 8
        // bne t3, t6, 32
        {inst_mem[35], inst_mem[34], inst_mem[33], inst_mem[32]} = 32'h02be8663; // 9
        // addi t3, t3, 1
        {inst_mem[39], inst_mem[38], inst_mem[37], inst_mem[36]} = 32'h001e8e93; // 10
        // addi t4, t3, 8
        {inst_mem[43], inst_mem[42], inst_mem[41], inst_mem[40]} = 32'h00898993; // 11
        // ld t2, 0(t3)
        {inst_mem[47], inst_mem[46], inst_mem[45], inst_mem[44]} = 32'h00093d03; // 12
        // ld t3, 0(t4)
        {inst_mem[51], inst_mem[50], inst_mem[49], inst_mem[48]} = 32'h0009bd83; // 13
        // blt t4, t3, 20
        {inst_mem[55], inst_mem[54], inst_mem[53], inst_mem[52]} = 32'h01bd4463; // 14
        // beq x0, x0, -20
        {inst_mem[59], inst_mem[58], inst_mem[57], inst_mem[56]} = 32'hfe0004e3; // 15
        // add t0, t3, t2
        {inst_mem[63], inst_mem[62], inst_mem[61], inst_mem[60]} = 32'h01a002b3; // 16
        // sd t0, 0(t4)
        {inst_mem[67], inst_mem[66], inst_mem[65], inst_mem[64]} = 32'h01b93023; // 17
        // sd t0, 0(t4)
        {inst_mem[71], inst_mem[70], inst_mem[69], inst_mem[68]} = 32'h0059b023; // 18
        // beq x0, x0, -64
        {inst_mem[75], inst_mem[74], inst_mem[73], inst_mem[72]} = 32'hfc000ce3; // 19
        // addi s0, s0, 1
        {inst_mem[79], inst_mem[78], inst_mem[77], inst_mem[76]} = 32'h00140413; // 20
        // addi t2, t3, 8
        {inst_mem[83], inst_mem[82], inst_mem[81], inst_mem[80]} = 32'h00890913; // 21
        // beq x0, x0, -96
        {inst_mem[87], inst_mem[86], inst_mem[85], inst_mem[84]} = 32'hfa000ae3; // 22
    end
    
    // Lógica de Leitura Combinacional (Assíncrona).
    // O bloco é sensível a mudanças no endereço de entrada.
    always @ (inst_address)
    begin
        // Monta a instrução de 32 bits a partir de 4 bytes consecutivos da memória.
        // A ordem de atribuição (byte 0 para bits 7:0) modela uma arquitetura little-endian,
        // que é o padrão para RISC-V.
        instruction[7:0]   = inst_mem[inst_address+0];
        instruction[15:8]  = inst_mem[inst_address+1];
        instruction[23:16] = inst_mem[inst_address+2];
        instruction[31:24] = inst_mem[inst_address+3];
    end
endmodule
