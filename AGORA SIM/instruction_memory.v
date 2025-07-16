// Memória de Instruções com programa de teste abrangente
module instruction_memory(
    input [63:0] inst_address,
    output reg [31:0] instruction
);
    reg [7:0] inst_mem[127:0]; // Memória para o programa de teste

    initial begin
        // Programa de teste em hexadecimal.
        // Endereço |  Instrução Assembly
        {inst_mem[3], inst_mem[2], inst_mem[1], inst_mem[0]}     = 32'h00A00093; // 00: addi x1, x0, 10
        {inst_mem[7], inst_mem[6], inst_mem[5], inst_mem[4]}     = 32'h01400113; // 04: addi x2, x0, 20
        {inst_mem[11], inst_mem[10], inst_mem[9], inst_mem[8]}   = 32'h002081B3; // 08: add x3, x1, x2
        {inst_mem[15], inst_mem[14], inst_mem[13], inst_mem[12]} = 32'h40208233; // 0C: sub x4, x1, x2
        {inst_mem[19], inst_mem[18], inst_mem[17], inst_mem[16]} = 32'h0041E2B3; // 10: or x5, x3, x4
        {inst_mem[23], inst_mem[22], inst_mem[21], inst_mem[20]} = 32'h0041F333; // 14: and x6, x3, x4
        {inst_mem[27], inst_mem[26], inst_mem[25], inst_mem[24]} = 32'h00538393; // 18: addi x7, x7, 5 (forwarding test)
        {inst_mem[31], inst_mem[30], inst_mem[29], inst_mem[28]} = 32'h06400E93; // 1C: addi x29, x0, 100 (endereço base)
        {inst_mem[35], inst_mem[34], inst_mem[33], inst_mem[32]} = 32'h007eB023; // 20: sd x7, 0(x29) (store test)
        {inst_mem[39], inst_mem[38], inst_mem[37], inst_mem[36]} = 32'h000eB503; // 24: ld x10, 0(x29) (load test)
        {inst_mem[43], inst_mem[42], inst_mem[41], inst_mem[40]} = 32'h00150613; // 28: addi x12, x10, 1 (load-use hazard test)
        {inst_mem[47], inst_mem[46], inst_mem[45], inst_mem[44]} = 32'h00100863; // 2C: beq x0, x1, 16 (branch not taken)
        {inst_mem[51], inst_mem[50], inst_mem[49], inst_mem[48]} = 32'h00C50863; // 30: beq x10, x12, 12 (branch taken)
        {inst_mem[55], inst_mem[54], inst_mem[53], inst_mem[52]} = 32'h3E700893; // 34: addi x17, x0, 999 (should be flushed)
        {inst_mem[59], inst_mem[58], inst_mem[57], inst_mem[56]} = 32'h00000000; // 38: NOP (espaçamento)
        {inst_mem[63], inst_mem[62], inst_mem[61], inst_mem[60]} = 32'h00000000; // 3C: NOP (espaçamento)
        {inst_mem[67], inst_mem[66], inst_mem[65], inst_mem[64]} = 32'h06F00913; // 40: addi x18, x0, 111 (branch target)
        {inst_mem[71], inst_mem[70], inst_mem[69], inst_mem[68]} = 40000000;     // 44: addi x0, x0, 50 (teste de escrita no x0)
        {inst_mem[75], inst_mem[74], inst_mem[73], inst_mem[72]} = 32'h00000A33; // 48: add x20, x0, x0 (teste de leitura do x0)
        {inst_mem[79], inst_mem[78], inst_mem[77], inst_mem[76]} = 32'h0000006F; // 4C: jal x0, 0 (fim do programa, loop infinito)
    end
    
    always @ (inst_address) begin
        instruction = {inst_mem[inst_address+3], inst_mem[inst_address+2],
                       inst_mem[inst_address+1], inst_mem[inst_address+0]};
    end
endmodule