// M�dulo de Mem�ria de Dados
// Armazena e recupera os dados para as instru��es LOAD e STORE.
// Baseado no c�digo contido em: mem_stage.txt
module data_mem (
    input  wire        clk,
    input  wire [31:0] addr,
    input  wire [31:0] write_data,
    input  wire        read_en,           // Habilita leitura (n�o usado na l�gica de leitura combinacional)
    input  wire        write_byte_en,     // Habilita escrita de byte
    input  wire        write_half_en,     // Habilita escrita de halfword
    input  wire        write_word_en,     // Habilita escrita de word
    output wire [31:0] read_data
);

    // Mem�ria de dados de 1KB (1024 bytes)
    reg [7:0] memory [0:1023];

    // --- IMPORTANTE: Inicializa��o da Mem�ria ---
    // Para testar seu programa Insertion Sort, voc� DEVE carregar o arquivo data.hex.
    initial begin
        // Descomente a linha abaixo e comente ou remova o la�o 'for'.
        $readmemh("data.hex", memory);

        /* Comente ou remova este la�o para usar o arquivo .hex
        for (integer i = 0; i < 1024; i = i + 1) begin
            memory[i] = 8'h00; // Limpa a mem�ria no in�cio
        end
        */
    end

    // L�gica de leitura (combinacional)
    // L� uma palavra de 32 bits (4 bytes) em formato little-endian.
    assign read_data = {memory[addr+3], memory[addr+2], memory[addr+1], memory[addr]};

    // L�gica de escrita (s�ncrona)
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