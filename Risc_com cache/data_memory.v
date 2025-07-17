module data_memory (
    input clk,
    input [63:0] address,              // Endereço completo
    input [63:0] write_data,           // Palavra a ser escrita
    input mem_write,                   // Sinal de escrita
    input mem_read,                    // Sinal de leitura
    output reg [127:0] block_read_data // Bloco de 16 bytes (2 palavras de 64 bits)
);

  reg [7:0] mem [0:1023]; // 1KB de memória (ajuste conforme necessário)

  integer i;

  // Escrita de 64 bits (8 bytes) na memória
  always @(posedge clk) begin
    if (mem_write) begin
      mem[address + 0] <= write_data[7:0];
      mem[address + 1] <= write_data[15:8];
      mem[address + 2] <= write_data[23:16];
      mem[address + 3] <= write_data[31:24];
      mem[address + 4] <= write_data[39:32];
      mem[address + 5] <= write_data[47:40];
      mem[address + 6] <= write_data[55:48];
      mem[address + 7] <= write_data[63:56];
    end
  end

  // Leitura de bloco de 16 bytes (128 bits)
  always @(*) begin
    if (mem_read) begin
      block_read_data = {
        mem[address + 15], mem[address + 14], mem[address + 13], mem[address + 12],
        mem[address + 11], mem[address + 10], mem[address + 9],  mem[address + 8],
        mem[address + 7],  mem[address + 6],  mem[address + 5],  mem[address + 4],
        mem[address + 3],  mem[address + 2],  mem[address + 1],  mem[address + 0]
      };
    end else begin
      block_read_data = 128'b0;
    end
  end

endmodule
