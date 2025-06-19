// Módulo de Memória de Dados
// Armazena e recupera os dados para as instruções LOAD e STORE.
// Baseado no código contido em: mem_stage.txt
module data_mem (
    input  wire        clk,
    input  wire [31:0] addr,
    input  wire [31:0] write_data,
    input  wire        read_en,           // Habilita leitura (não usado na lógica de leitura combinacional)
    input  wire        write_byte_en,     // Habilita escrita de byte
    input  wire        write_half_en,     // Habilita escrita de halfword
    input  wire        write_word_en,     // Habilita escrita de word
    output wire [31:0] read_data
);

    // Memória de dados de 1KB (1024 bytes)
    reg [7:0] memory [0:1023];

    // --- IMPORTANTE: Inicialização da Memória ---
    // Para testar seu programa Insertion Sort, você DEVE carregar o arquivo data.hex.
    initial begin
        // Descomente a linha abaixo e comente ou remova o laço 'for'.
        $readmemh("data.hex", memory);

        /* Comente ou remova este laço para usar o arquivo .hex
        for (integer i = 0; i < 1024; i = i + 1) begin
            memory[i] = 8'h00; // Limpa a memória no início
        end
        */
    end

    // Lógica de leitura (combinacional)
    // Lê uma palavra de 32 bits (4 bytes) em formato little-endian.
    assign read_data = {memory[addr+3], memory[addr+2], memory[addr+1], memory[addr]};

    // Lógica de escrita (síncrona)
    always @(posedge clk) begin
        if (write_word_en) begin
            // Escrita de palavra completa
            memory[addr]   <= write_data[7:0];
            memory[addr+1] <= write_data[15:8];
            memory[addr+2] <= write_data[23:16];
            memory[addr+3] <= write_data[31:24];
        end else if (write_half_en) begin
            // Escrita de meia-palavra (16 bits)
            memory[addr]   <= write_data[7:0];
            memory[addr+1] <= write_data[15:8];
        end else if (write_byte_en) begin
            // Escrita de byte
            memory[addr]   <= write_data[7:0];
        end
    end

endmodule