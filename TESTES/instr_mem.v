// instr_mem.v (COM LEITURA SÍNCRONA - CUIDADO, PODE QUEBRAR SEU PIPELINE ATUAL)
module instr_mem_synchronous (
    input  wire        clk,        // Agora depende do clock
    input  wire [31:0] addr,       // Endereço de instrução (PC)
    output reg  [31:0] instr       // Instrução lida (agora um 'reg')
);
  reg [31:0] memory [0:255];      

  // Carrega o conteudo do arquivo para instr_mem
  initial begin
      $readmemh("programa.hex", memory);
  end

  // Lê a instrução da memória de forma SÍNCRONA
  always @(posedge clk) begin
      instr <= memory[addr[9:2]]; // A instrução só estará disponível no próximo ciclo de clock
  end
endmodule
