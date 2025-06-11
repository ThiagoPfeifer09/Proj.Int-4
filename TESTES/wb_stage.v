module wb_stage (
    input wire        clk,
    input wire        rst,

    // Entradas do registrador MEM/WB
    input wire [31:0] mem_wb_pc_4,          // PC + 4 (para JAL/JALR)
    input wire [31:0] mem_wb_alu_result,    // Resultado da ALU (R-type, I-type arith, AUIPC, LUI, endereço p/ Load)
    input wire [31:0] mem_wb_mem_read_data, // Dados lidos da memória (para Load)
    input wire [4:0]  mem_wb_rd,            // Registrador de destino
    
    // Sinais de controle do estágio MEM
    input wire        mem_wb_reg_write_en,    // Habilita escrita no registrador
    input wire [1:0]  mem_wb_mem_to_reg_sel,  // Seleciona a origem do dado a ser escrito

    // Saídas para o banco de registradores (reg_file)
    output wire        reg_write_en_out,     // Habilitação final de escrita
    output wire [4:0]  reg_write_addr_out,   // Endereço do registrador para escrita
    output wire [31:0] reg_write_data_out    // Dados a serem escritos
);

    // Variável interna para o dado selecionado a ser escrito
    wire [31:0] write_data_mux_out;

    // --- Multiplexador de Seleção de Dados para Escrita ---
    // Este multiplexador escolhe qual valor será escrito de volta no registrador de destino (rd).
    // mem_to_reg_sel:
    // 2'b00: Resultado da ALU (para R-type, I-type aritméticas, LUI, AUIPC)
    // 2'b01: Dado lido da memória (para LOAD)
    // 2'b10: PC + 4 (para JAL, JALR)
    always @(*) begin
        case (mem_wb_mem_to_reg_sel)
            2'b00: write_data_mux_out = mem_wb_alu_result;
            2'b01: write_data_mux_out = mem_wb_mem_read_data;
            2'b10: write_data_mux_out = mem_wb_pc_4;
            default: write_data_mux_out = 32'b0; // Valor padrão, caso não reconhecido
        endcase
    end

    // --- Saídas Finais para o Banco de Registradores ---
    // Estas saídas serão conectadas diretamente às entradas correspondentes do módulo 'reg_file'.
    assign reg_write_en_out   = mem_wb_reg_write_en; // Passa o sinal de habilitação
    assign reg_write_addr_out = mem_wb_rd;           // Passa o endereço do registrador de destino
    assign reg_write_data_out = write_data_mux_out;  // Passa o dado selecionado pelo multiplexador

endmodule