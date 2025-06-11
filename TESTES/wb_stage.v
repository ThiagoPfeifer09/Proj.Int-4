module wb_stage (
    input wire        clk,
    input wire        rst,

    // Entradas do registrador MEM/WB
    input wire [31:0] mem_wb_pc_4,          // PC + 4 (para JAL/JALR)
    input wire [31:0] mem_wb_alu_result,    // Resultado da ALU (R-type, I-type arith, AUIPC, LUI, endere�o p/ Load)
    input wire [31:0] mem_wb_mem_read_data, // Dados lidos da mem�ria (para Load)
    input wire [4:0]  mem_wb_rd,            // Registrador de destino
    
    // Sinais de controle do est�gio MEM
    input wire        mem_wb_reg_write_en,    // Habilita escrita no registrador
    input wire [1:0]  mem_wb_mem_to_reg_sel,  // Seleciona a origem do dado a ser escrito

    // Sa�das para o banco de registradores (reg_file)
    output wire        reg_write_en_out,     // Habilita��o final de escrita
    output wire [4:0]  reg_write_addr_out,   // Endere�o do registrador para escrita
    output wire [31:0] reg_write_data_out    // Dados a serem escritos
);

    // Vari�vel interna para o dado selecionado a ser escrito
    wire [31:0] write_data_mux_out;

    // --- Multiplexador de Sele��o de Dados para Escrita ---
    // Este multiplexador escolhe qual valor ser� escrito de volta no registrador de destino (rd).
    // mem_to_reg_sel:
    // 2'b00: Resultado da ALU (para R-type, I-type aritm�ticas, LUI, AUIPC)
    // 2'b01: Dado lido da mem�ria (para LOAD)
    // 2'b10: PC + 4 (para JAL, JALR)
    always @(*) begin
        case (mem_wb_mem_to_reg_sel)
            2'b00: write_data_mux_out = mem_wb_alu_result;
            2'b01: write_data_mux_out = mem_wb_mem_read_data;
            2'b10: write_data_mux_out = mem_wb_pc_4;
            default: write_data_mux_out = 32'b0; // Valor padr�o, caso n�o reconhecido
        endcase
    end

    // --- Sa�das Finais para o Banco de Registradores ---
    // Estas sa�das ser�o conectadas diretamente �s entradas correspondentes do m�dulo 'reg_file'.
    assign reg_write_en_out   = mem_wb_reg_write_en; // Passa o sinal de habilita��o
    assign reg_write_addr_out = mem_wb_rd;           // Passa o endere�o do registrador de destino
    assign reg_write_data_out = write_data_mux_out;  // Passa o dado selecionado pelo multiplexador

endmodule