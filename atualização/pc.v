module pc (
    input  wire       clk,
    input  wire       rst,
    input  wire [31:0] next_pc,
    input  wire       we,          // Nova entrada para habilitar/desabilitar a escrita
    output reg  [31:0] pc_out
);

    // Lógica síncrona do PC
    always @(posedge clk) begin
        if (rst)
            pc_out <= 32'b0;
        else if (we) // Só atualiza o PC se a habilitação de escrita estiver ativa
            pc_out <= next_pc;
    end

endmodule