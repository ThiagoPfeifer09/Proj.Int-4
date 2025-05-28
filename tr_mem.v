module instr_mem (
    input  wire [31:0] addr,       // endere�o de instru��o (PC)
    output wire [31:0] instr       // instru��o lida
);
  // RAM
  reg [31:0] memory [0:255];      

  // carrega o conteudo do arquivo para instr_mem
  initial begin
    $readmemh("program.hex", memory);
  end

  // l� a instru��o da mem�ria
  assign instr = memory[addr[9:2]];  
endmodule
