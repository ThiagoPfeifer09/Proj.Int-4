// Módulo do Estágio de Acesso à Memória (MEM)
// Versão corrigida para compatibilidade com Verilog mais antigo.
module mem_stage (
    input wire        clk,
    input wire        rst,

    // Entradas do registrador EX/MEM
    input wire [31:0] ex_mem_pc,
    input wire [31:0] ex_mem_pc_4,
    input wire [31:0] ex_mem_alu_result,
    input wire [31:0] ex_mem_rs2_data,
    input wire [4:0]  ex_mem_rd,
    input wire [2:0]  ex_mem_funct3,
    input wire [6:0]  ex_mem_opcode,

    // Sinais de controle do estágio EX
    input wire        ex_mem_mem_write_en,
    input wire        ex_mem_mem_read_en,
    input wire        ex_mem_reg_write_en,
    input wire [1:0]  ex_mem_mem_to_reg_sel,

    // Interface com a memória de dados (Data Memory)
    output wire [31:0] mem_addr,
    output wire [31:0] mem_write_data,
    output wire        mem_write_byte_en,
    output wire        mem_write_half_en,
    output wire        mem_write_word_en,
    input wire [31:0]  mem_read_data,

    // Saídas para o próximo estágio (MEM/WB)
    output reg [31:0] mem_wb_pc_4,
    output reg [31:0] mem_wb_alu_result,
    output reg [31:0] mem_wb_mem_read_data,
    output reg [4:0]  mem_wb_rd,
    
    // Sinais de controle para o estágio WB
    output reg        mem_wb_reg_write_en,
    output reg [1:0]  mem_wb_mem_to_reg_sel
);
    // --- Interface com a Memória de Dados ---
    assign mem_addr = ex_mem_alu_result;
    assign mem_write_data = ex_mem_rs2_data;
    assign mem_write_byte_en  = (ex_mem_mem_write_en && ex_mem_funct3 == 3'b000); // SB
    assign mem_write_half_en  = (ex_mem_mem_write_en && ex_mem_funct3 == 3'b001); // SH
    assign mem_write_word_en  = (ex_mem_mem_write_en && ex_mem_funct3 == 3'b010); // SW

    // --- Registradores de Pipeline MEM/WB ---
    always @(posedge clk) begin
        if (rst) begin
            mem_wb_pc_4         <= 0;
            mem_wb_alu_result   <= 0;
            mem_wb_mem_read_data <= 0;
            mem_wb_rd           <= 0;
            mem_wb_reg_write_en <= 1'b0;
            mem_wb_mem_to_reg_sel <= 2'b00;
        end else begin
            mem_wb_pc_4         <= ex_mem_pc_4;
            mem_wb_alu_result   <= ex_mem_alu_result;
            mem_wb_rd           <= ex_mem_rd;
            
            if (ex_mem_mem_read_en) begin
                case (ex_mem_funct3)
                    3'b000: mem_wb_mem_read_data <= {{24{mem_read_data[7]}}, mem_read_data[7:0]};     // LB
                    3'b001: mem_wb_mem_read_data <= {{16{mem_read_data[15]}}, mem_read_data[15:0]};  // LH
                    3'b010: mem_wb_mem_read_data <= mem_read_data;                                  // LW
                    3'b100: mem_wb_mem_read_data <= {{24{1'b0}}, mem_read_data[7:0]};                // LBU
                    3'b101: mem_wb_mem_read_data <= {{16{1'b0}}, mem_read_data[15:0]};               // LHU
                    default: mem_wb_mem_read_data <= mem_read_data;
                endcase
            end else begin
                mem_wb_mem_read_data <= 0;
            end
            
            mem_wb_reg_write_en   <= ex_mem_reg_write_en;
            mem_wb_mem_to_reg_sel <= ex_mem_mem_to_reg_sel;
        end
    end

endmodule