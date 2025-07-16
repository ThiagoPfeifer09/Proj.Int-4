module cache_dados (
    input wire clock,
    input wire reset,
    input wire MemRead,
    input wire [31:0] endereco,

    output wire [31:0] dado_lido,
    output wire stall_cache_dados,

    // Interface com memória principal
    output reg        mem_read,
    output reg [31:0] mem_address,
    input wire [127:0] mem_block // bloco de 16 bytes (4 words de 32 bits)
);

    // 32 linhas de cache, 128 bits cada (4 words)
    reg [127:0] data_cache_data [0:31];
    reg [22:0]  data_cache_tag [0:31];
    reg         data_cache_valid [0:31];

    // Lógica de endereçamento
    wire [4:0]  cache_index       = endereco[8:4];
    wire [22:0] cache_tag_addr    = endereco[31:9];
    wire [1:0]  seletor_de_palavra = endereco[3:2];

    // Hit se válidos e tags coincidem
    wire cache_hit = data_cache_valid[cache_index] && (data_cache_tag[cache_index] == cache_tag_addr);

    assign stall_cache_dados = MemRead && !cache_hit;

    // Palavra selecionada do bloco
    wire [127:0] bloco = data_cache_data[cache_index];

    assign dado_lido = (seletor_de_palavra == 2'b00) ? bloco[31:0] :
                       (seletor_de_palavra == 2'b01) ? bloco[63:32] :
                       (seletor_de_palavra == 2'b10) ? bloco[95:64] :
                                                      bloco[127:96];

    integer i;

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 32; i = i + 1) begin
                data_cache_valid[i] <= 0;
                data_cache_tag[i]   <= 0;
                data_cache_data[i]  <= 0;
            end
            mem_read <= 0;
        end else begin
            if (MemRead && !cache_hit) begin
                // MISS: solicitamos leitura do bloco
                mem_read <= 1;
                mem_address <= {endereco[31:4], 4'b0000}; // endereço alinhado ao bloco de 16 bytes
            end else begin
                mem_read <= 0;
            end
        end
    end

    // Carregamento do bloco da memória principal
    always @(posedge clock) begin
        if (MemRead && !cache_hit) begin
            // Preenche a cache com o novo bloco após receber da memória
            data_cache_data[cache_index] <= mem_block;
            data_cache_tag[cache_index]  <= cache_tag_addr;
            data_cache_valid[cache_index] <= 1;
        end
    end

endmodule
