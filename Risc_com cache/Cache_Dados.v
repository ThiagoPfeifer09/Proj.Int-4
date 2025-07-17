module cache_dados (
    input clk,
    input reset,
    input [63:0] address,       // endereço do dado (byte)
    input [63:0] write_data,    // dado a ser escrito
    input mem_write,
    input mem_read,
    output reg [63:0] read_data,
    output reg miss             // sinal de cache miss
);

  // Parâmetros da cache simples
  parameter BLOCK_SIZE = 16;  // bytes por bloco (16 bytes = 4 words de 32 bits)
  parameter CACHE_LINES = 16; // número de linhas na cache (pode ajustar)

  // Definição da memória principal simulada (1024 bytes)
  reg [7:0] memory_main [0:1023];

  // Cache estrutura: tag, valid bit, bloco de dados
  reg valid [0:CACHE_LINES-1];
  reg [47:0] tag_array [0:CACHE_LINES-1]; // 48 bits da tag (64-4 bits índice e offset)
  reg [7:0] data_array [0:CACHE_LINES-1][0:BLOCK_SIZE-1]; // bloco de 16 bytes por linha

  // Divisão do endereço
  wire [3:0] offset = address[3:0];  // 16 bytes offset (4 bits)
  wire [3:0] index = address[7:4];   // 16 linhas (4 bits)
  wire [47:0] tag = address[63:16];  // resto é tag

  integer i, j;

  // Inicialização
  initial begin
    for (i = 0; i < CACHE_LINES; i = i + 1) begin
      valid[i] = 0;
      tag_array[i] = 0;
      for (j = 0; j < BLOCK_SIZE; j = j + 1) begin
        data_array[i][j] = 0;
      end
    end

    // Inicializar memória principal com alguns dados (exemplo)
    for (i = 0; i < 1024; i = i + 1)
      memory_main[i] = 8'd0;
  end

  // Variáveis auxiliares
  reg hit;
  reg [7:0] read_block [0:BLOCK_SIZE-1];

  // Lógica de leitura e escrita na cache
  always @(posedge clk) begin
    if (reset) begin
      // Resetar valid bits
      for (i = 0; i < CACHE_LINES; i = i + 1)
        valid[i] <= 0;
      miss <= 0;
    end else begin
      miss <= 0;
      // Leitura
      if (mem_read) begin
        if (valid[index] && tag_array[index] == tag) begin
          // Cache hit
          hit = 1;
          // Monta read_data dos 8 bytes do offset zero do bloco
          read_data <= {
            data_array[index][7], data_array[index][6], data_array[index][5], data_array[index][4],
            data_array[index][3], data_array[index][2], data_array[index][1], data_array[index][0]
          };
        end else begin
          // Cache miss
          hit = 0;
          miss <= 1;

          // Carrega bloco da memória principal na cache
          for (j = 0; j < BLOCK_SIZE; j = j + 1) begin
            data_array[index][j] <= memory_main[{address[63:4],4'd0} + j];
          end
          valid[index] <= 1;
          tag_array[index] <= tag;

          // Sinaliza para o processador aguardar (stall)

          // read_data ainda não válido neste ciclo
          read_data <= 64'b0;
        end
      end

      // Escrita (write-through)
      if (mem_write) begin
        if (valid[index] && tag_array[index] == tag) begin
          // Atualiza a cache no bloco correto (offset 0 assumed)
          for (j = 0; j < 8; j = j + 1) begin
            data_array[index][j] <= write_data[j*8 +: 8];
          end
        end

        // Atualiza a memória principal sempre (write-through)
        for (j = 0; j < 8; j = j + 1) begin
          memory_main[address + j] <= write_data[j*8 +: 8];
        end
      end
    end
  end

endmodule
