module data_memory (
    input clk,
    input [63:0] address,           // Endereço completo
    input [63:0] write_data,        // Palavra a ser escrita
    input mem_write,                // Sinal de escrita
    input mem_read,                 // Sinal de leitura
    output reg [127:0] block_read_data // Bloco de 16 bytes (2 palavras de 64 bits)
);

    reg [7:0] mem [0:1023]; // 1KB de memória

    // Bloco de inicialização para carregar o array a ser ordenado
    initial begin
        // Array inicial: {50, 21, 88, 1, 99, 4, 15, 42}
        // Assumimos que o endereço base 0x10010000 do programa mapeia para o índice 0 da memória.

        // Carrega 64'd50 no endereço 0x10010000 (índices 0-7)
        {mem[7], mem[6], mem[5], mem[4], mem[3], mem[2], mem[1], mem[0]} = 64'd50;
        
        // Carrega 64'd21 no endereço 0x10010008 (índices 8-15)
        {mem[15], mem[14], mem[13], mem[12], mem[11], mem[10], mem[9], mem[8]} = 64'd21;
        
        // Carrega 64'd88 no endereço 0x10010010 (índices 16-23)
        {mem[23], mem[22], mem[21], mem[20], mem[19], mem[18], mem[17], mem[16]} = 64'd88;
        
        // Carrega 64'd1 no endereço 0x10010018 (índices 24-31)
        {mem[31], mem[30], mem[29], mem[28], mem[27], mem[26], mem[25], mem[24]} = 64'd1;
        
        // Carrega 64'd99 no endereço 0x10010020 (índices 32-39)
        {mem[39], mem[38], mem[37], mem[36], mem[35], mem[34], mem[33], mem[32]} = 64'd99;
        
        // Carrega 64'd4 no endereço 0x10010028 (índices 40-47)
        {mem[47], mem[46], mem[45], mem[44], mem[43], mem[42], mem[41], mem[40]} = 64'd4;
        
        // Carrega 64'd15 no endereço 0x10010030 (índices 48-55)
        {mem[55], mem[54], mem[53], mem[52], mem[51], mem[50], mem[49], mem[48]} = 64'd15;
        
        // Carrega 64'd42 no endereço 0x10010038 (índices 56-63)
        {mem[63], mem[62], mem[61], mem[60], mem[59], mem[58], mem[57], mem[56]} = 64'd42;
    end

    // Escrita de 64 bits (8 bytes) na memória (sua lógica está correta)
    always @(posedge clk) begin
        // Use os bits menos significativos do endereço como índice para o array de 1KB
        if (mem_write) begin
            mem[address[9:0] + 0] <= write_data[7:0];
            mem[address[9:0] + 1] <= write_data[15:8];
            mem[address[9:0] + 2] <= write_data[23:16];
            mem[address[9:0] + 3] <= write_data[31:24];
            mem[address[9:0] + 4] <= write_data[39:32];
            mem[address[9:0] + 5] <= write_data[47:40];
            mem[address[9:0] + 6] <= write_data[55:48];
            mem[address[9:0] + 7] <= write_data[63:56];
        end
    end

    // Leitura de bloco de 16 bytes (128 bits) (sua lógica está correta)
    always @(*) begin
        if (mem_read) begin
            block_read_data = {
                mem[address[9:0] + 15], mem[address[9:0] + 14], mem[address[9:0] + 13], mem[address[9:0] + 12],
                mem[address[9:0] + 11], mem[address[9:0] + 10], mem[address[9:0] + 9],  mem[address[9:0] + 8],
                mem[address[9:0] + 7],  mem[address[9:0] + 6],  mem[address[9:0] + 5],  mem[address[9:0] + 4],
                mem[address[9:0] + 3],  mem[address[9:0] + 2],  mem[address[9:0] + 1],  mem[address[9:0] + 0]
            };
        end else begin
            block_read_data = 128'b0;
        end
    end

endmodule
