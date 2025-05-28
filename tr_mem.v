module instr_mem (
    input  wire [31:0] addr,       // endereço de instrução (PC)
    output wire [31:0] instr       // instrução lida
);
  // RAM
  reg [31:0] memory [0:255];      

  // carrega o conteudo do arquivo para instr_mem
  initial begin
    $readmemh("program.hex", memory);
  end

  // lê a instrução da memória
  assign instr = memory[addr[9:2]];  
endmodule
