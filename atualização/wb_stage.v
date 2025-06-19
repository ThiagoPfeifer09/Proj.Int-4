// Módulo do Estágio de Write-Back (WB)
module wb_stage (
    input wire        clk,
    input wire        rst,

    // Entradas do registrador MEM/WB
    input wire [31:0] mem_wb_pc_4,
    input wire [31:0] mem_wb_alu_result,
    input wire [31:0] mem_wb_mem_read_data,
    input wire [4:0]  mem_wb_rd,
    input wire        mem_wb_reg_write_en,
    input wire [1:0]  mem_wb_mem_to_reg_sel,

    // Saídas para o banco de registradores (reg_file)
    output wire        reg_write_en_out,
    output wire [4:0]  reg_write_addr_out,
    output wire [31:0] reg_write_data_out
);

    // --- CORREÇÃO: Alterado de 'wire' para 'reg' ---
    // A variável que armazena a saída do multiplexador deve ser 'reg'
    // porque ela é atribuída dentro de um bloco 'always'.
    reg [31:0] write_data_mux_out;

    // --- Multiplexador de Seleção de Dados para Escrita ---
    // Este multiplexador escolhe qual valor será escrito de volta no registrador de destino (rd).
    always @(*) begin
        case (mem_wb_mem_to_reg_sel)
            2'b00: write_data_mux_out = mem_wb_alu_result;    // Resultado da ALU
            2'b01: write_data_mux_out = mem_wb_mem_read_data; // Dado lido da memória
            2'b10: write_data_mux_out = mem_wb_pc_4;          // PC + 4 (para JAL/JALR)
            default: write_data_mux_out = 32'b0;          // Valor padrão
        endcase
    end

    // --- Saídas Finais para o Banco de Registradores ---
    // Estas saídas serão conectadas diretamente às entradas correspondentes do módulo 'reg_file'.
    assign reg_write_en_out   = mem_wb_reg_write_en;   // Passa o sinal de habilitação
    assign reg_write_addr_out = mem_wb_rd;             // Passa o endereço do registrador de destino
    assign reg_write_data_out = write_data_mux_out;    // Passa o dado selecionado pelo multiplexador

endmodule