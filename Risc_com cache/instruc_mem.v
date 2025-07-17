module instruc_mem(
    input [63:0] inst_address,
    output reg [31:0] instruction
);

    // Memória para 88 bytes (suficiente para as 22 instruções do nosso programa)
    reg [7:0] inst_mem[87:0];

    // Carrega o programa Insertion Sort na memória ao iniciar a simulação
    initial begin
        // Endereço 0x00: lui  x5, 0x10010
        {inst_mem[3], inst_mem[2], inst_mem[1], inst_mem[0]} = 32'h100102b7;
        // Endereço 0x04: li   x6, 8
        {inst_mem[7], inst_mem[6], inst_mem[5], inst_mem[4]} = 32'h00800313;
        // Endereço 0x08: li   x7, 1
        {inst_mem[11], inst_mem[10], inst_mem[9], inst_mem[8]} = 32'h00100393;
        // Endereço 0x0c: bge  x7, x6, end_sort
        {inst_mem[15], inst_mem[14], inst_mem[13], inst_mem[12]} = 32'h0263d663;
        // Endereço 0x10: slli x12, x7, 3
        {inst_mem[19], inst_mem[18], inst_mem[17], inst_mem[16]} = 32'h00339e13;
        // Endereço 0x14: add  x12, x5, x12
        {inst_mem[23], inst_mem[22], inst_mem[21], inst_mem[20]} = 32'h00ce0e33;
        // Endereço 0x18: ld   x10, 0(x12)
        {inst_mem[27], inst_mem[26], inst_mem[25], inst_mem[24]} = 32'h000e3503;
        // Endereço 0x1c: addi x11, x7, -1
        {inst_mem[31], inst_mem[30], inst_mem[29], inst_mem[28]} = 32'hfff38593;
        // Endereço 0x20: bltz x11, inner_loop_exit
        {inst_mem[35], inst_mem[34], inst_mem[33], inst_mem[32]} = 32'h0005d863;
        // Endereço 0x24: slli x12, x11, 3
        {inst_mem[39], inst_mem[38], inst_mem[37], inst_mem[36]} = 32'h00359e13;
        // Endereço 0x28: add  x12, x5, x12
        {inst_mem[43], inst_mem[42], inst_mem[41], inst_mem[40]} = 32'h00ce0e33;
        // Endereço 0x2c: ld   x13, 0(x12)
        {inst_mem[47], inst_mem[46], inst_mem[45], inst_mem[44]} = 32'h000e3683;
        // Endereço 0x30: ble  x13, x10, inner_loop_exit
        {inst_mem[51], inst_mem[50], inst_mem[49], inst_mem[48]} = 32'h00a6d463;
        // Endereço 0x34: sd   x13, 8(x12)
        {inst_mem[55], inst_mem[54], inst_mem[53], inst_mem[52]} = 32'h00dca423;
        // Endereço 0x38: addi x11, x11, -1
        {inst_mem[59], inst_mem[58], inst_mem[57], inst_mem[56]} = 32'hfff58593;
        // Endereço 0x3c: j    inner_loop_condition
        {inst_mem[63], inst_mem[62], inst_mem[61], inst_mem[60]} = 32'hfe5ff06f;
        // Endereço 0x40: slli x12, x11, 3
        {inst_mem[67], inst_mem[66], inst_mem[65], inst_mem[64]} = 32'h00359e13;
        // Endereço 0x44: add  x12, x5, x12
        {inst_mem[71], inst_mem[70], inst_mem[69], inst_mem[68]} = 32'h00ce0e33;
        // Endereço 0x48: sd   x10, 8(x12)
        {inst_mem[75], inst_mem[74], inst_mem[73], inst_mem[72]} = 32'h00acb423;
        // Endereço 0x4c: addi x7, x7, 1
        {inst_mem[79], inst_mem[78], inst_mem[77], inst_mem[76]} = 32'h00138393;
        // Endereço 0x50: j    outer_loop_start
        {inst_mem[83], inst_mem[82], inst_mem[81], inst_mem[80]} = 32'hfbdff06f;
        // Endereço 0x54: ebreak
        {inst_mem[87], inst_mem[86], inst_mem[85], inst_mem[84]} = 32'h00100073;
    end

    // Lógica de leitura (a sua já estava correta)
    // Monta a instrução de 32 bits a partir de 4 bytes da memória.
    always @ (inst_address) begin
        instruction[7:0]   = inst_mem[inst_address + 0];
        instruction[15:8]  = inst_mem[inst_address + 1];
        instruction[23:16] = inst_mem[inst_address + 2];
        instruction[31:24] = inst_mem[inst_address + 3];
    end

endmodule
