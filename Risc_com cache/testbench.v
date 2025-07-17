`timescale 1ns / 1ps

module test_cache;

  reg clk;
  reg reset;
  reg mem_read;
  reg mem_write;
  reg [31:0] address;
  reg [63:0] write_data;
  wire [63:0] read_data;
  wire miss;

  // Interface com a memória principal
  wire [31:0] mem_address;
  wire [63:0] mem_write_data;
  wire [127:0] mem_block_read_data;
  wire mem_ready;
  wire mem_read_out;
  wire mem_write_out;

  // Clock
  always #5 clk = ~clk;

  // Instância da cache
  cache_dados dut (
    .clk(clk),
    .reset(reset),
    .address(address),
    .write_data(write_data),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .read_data(read_data),
    .miss(miss),
    .mem_address(mem_address),
    .mem_write_data(mem_write_data),
    .mem_block_read_data(mem_block_read_data),
    .mem_ready(mem_ready),
    .mem_read_out(mem_read_out),
    .mem_write_out(mem_write_out)
  );

  // Simulação de memória principal com blocos fixos
 assign mem_block_read_data =
       (mem_address[31:4] == 32'h00000000 >> 4) ? 128'hAAAA_BBBB_CCCC_DDDD_EEEE_FFFF_1111_2222 :
       (mem_address[31:4] == 32'h00000040 >> 4) ? 128'h9999_8888_7777_6666_5555_4444_3333_2222 :
                                                 128'hDEAD_BEEF_DEAD_BEEF_DEAD_BEEF_DEAD_BEEF;

  assign mem_ready = mem_read_out; // resposta imediata da "memória" para simular cache funcionando

  initial begin
    $display("==== Iniciando teste da cache com múltiplos blocos ====");
    clk = 0;
    reset = 1;
    mem_read = 0;
    mem_write = 0;
    address = 0;
    write_data = 0;

    #10 reset = 0;

    // Primeiro acesso: MISS (endereço 0x10 ? bloco 0x00)
    address = 32'h00000010;
    mem_read = 1;
    wait (miss);
    $display("1) Bloco 0x00 (MISS): dado lido = %h", read_data);
    mem_read = 0;

    // Segundo acesso: MISS (endereço 0x40 ? bloco 0x40)
    #10 address = 32'h00000040;
    mem_read = 1;
    wait (miss);
    $display("2) Bloco 0x40 (MISS): dado lido = %h", read_data);
    mem_read = 0;

    // Terceiro acesso: HIT (mesmo que o primeiro)
    #10 address = 32'h00000010;
    mem_read = 1;
    wait (miss);
    $display("3) Bloco 0x00 (HIT): dado lido = %h", read_data);
    mem_read = 0;

    #10 $display("==== Fim da simulação ====");
    $finish;
  end

endmodule
