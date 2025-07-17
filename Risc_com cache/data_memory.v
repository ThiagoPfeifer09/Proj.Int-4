module data_memory (
    input clk,
    input [31:0] address,
    input [63:0] write_data,
    input mem_write,
    input mem_read,
    output reg [127:0] block_read_data,
    output reg mem_ready
);

  reg [7:0] mem [0:1023]; // 1KB de memória
  integer i;

  reg mem_read_prev;

  // Escrita de 64 bits (8 bytes)
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

  // Geração de mem_ready: ativo por 1 ciclo após leitura
  always @(posedge clk) begin
    mem_read_prev <= mem_read;
    mem_ready <= mem_read_prev;
  end

endmodule
