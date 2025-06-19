// Módulo do Estágio de Decodificação (ID)
// Versão final com tratamento de hazards de controle (flush) e de dados (stall).
module id_stage (
    input wire        clk,
    input wire        rst,

    // Entradas do registrador IF/ID
    input wire [31:0] instr_in,
    input wire [31:0] pc_in,
    input wire [31:0] pc_4_in,

    // --- ATUALIZADO: Entradas de Write-Back (vindo do estágio WB) ---
    input wire        reg_write_en_wb,
    input wire [4:0]  reg_write_addr_wb,
    input wire [31:0] reg_write_data_wb,

    // --- ATUALIZADO: Entradas para a Unidade de Detecção de Hazard ---
    input wire        ex_mem_mem_read_en,
    input wire [4:0]  ex_mem_rd,
    input wire        branch_taken_from_ex,

    // --- ATUALIZADO: Saídas de Controle de Hazard ---
    output wire       pc_write_en,
    output wire       if_id_write_en,

    // Saídas para o próximo estágio (ID/EX)
    output reg [31:0] id_ex_pc,
    output reg [31:0] id_ex_pc_4,
    output reg [31:0] id_ex_rs1_data,
    output reg [31:0] id_ex_rs2_data,
    output reg [4:0]  id_ex_rd,
    output reg [4:0]  id_ex_rs1,
    output reg [4:0]  id_ex_rs2,
    output reg [2:0]  id_ex_funct3,
    output reg [6:0]  id_ex_funct7,
    output reg [6:0]  id_ex_opcode,
    output reg [31:0] id_ex_imm
);

    // Extração dos campos da instrução
    wire [4:0] rs1    = instr_in[19:15];
    wire [4:0] rs2    = instr_in[24:20];
    wire [4:0] rd     = instr_in[11:7];
    wire [2:0] funct3 = instr_in[14:12];
    wire [6:0] funct7 = instr_in[31:25];
    wire [6:0] opcode = instr_in[6:0];

    // Unidade de Detecção de Hazard
    wire load_use_hazard;
    assign load_use_hazard = (ex_mem_mem_read_en == 1'b1) &&
                             (ex_mem_rd != 5'b0) &&
                             ((ex_mem_rd == rs1) || (ex_mem_rd == rs2));

    assign pc_write_en    = ~load_use_hazard;
    assign if_id_write_en = ~load_use_hazard;

    // Decodificação de imediato
    wire [31:0] imm_i = {{20{instr_in[31]}}, instr_in[31:20]};
    wire [31:0] imm_s = {{20{instr_in[31]}}, instr_in[31:25], instr_in[11:7]};
    wire [31:0] imm_b = {{20{instr_in[31]}}, instr_in[7], instr_in[30:25], instr_in[11:8], 1'b0};
    wire [31:0] imm_u = {instr_in[31:12], 12'b0};
    wire [31:0] imm_j = {{12{instr_in[31]}}, instr_in[19:12], instr_in[20], instr_in[30:21], 1'b0};

    reg [31:0] decoded_imm; // Alterado para 'reg' para ser usado em 'always'
    always @(*) begin
        case (opcode)
            7'b0010011: decoded_imm = imm_i;
            7'b0000011: decoded_imm = imm_i;
            7'b1100111: decoded_imm = imm_i;
            7'b0100011: decoded_imm = imm_s;
            7'b1100011: decoded_imm = imm_b;
            7'b0110111: decoded_imm = imm_u;
            7'b0010111: decoded_imm = imm_u;
            7'b1101111: decoded_imm = imm_j;
            default:    decoded_imm = 32'b0;
        endcase
    end

    // Banco de Registradores
    wire [31:0] rs1_data, rs2_data;
    reg_file u_reg_file (
        .clk       (clk),
        .we        (reg_write_en_wb),
        .rs1_addr  (rs1),
        .rs2_addr  (rs2),
        .rd_addr   (reg_write_addr_wb),
        .rd_data   (reg_write_data_wb),
        .rs1_data  (rs1_data),
        .rs2_data  (rs2_data)
    );

    // Registradores de Pipeline ID/EX com lógica de Stall/Flush
    always @(posedge clk) begin
        if (rst) begin
            // --- ATUALIZADO: Lógica de reset completa ---
            id_ex_pc       <= 32'b0;
            id_ex_pc_4     <= 32'b0;
            id_ex_rs1_data <= 32'b0;
            id_ex_rs2_data <= 32'b0;
            id_ex_rd       <= 5'b0;
            id_ex_rs1      <= 5'b0;
            id_ex_rs2      <= 5'b0;
            id_ex_funct3   <= 3'b0;
            id_ex_funct7   <= 7'b0;
            id_ex_opcode   <= 7'h13; // NOP
            id_ex_imm      <= 32'b0;
        end
        else if (load_use_hazard) begin
            // Insere uma bolha (NOP) para o stall
            id_ex_pc       <= 32'b0;
            id_ex_pc_4     <= 32'b0;
            id_ex_rs1_data <= 32'b0;
            id_ex_rs2_data <= 32'b0;
            id_ex_rd       <= 5'b0;
            id_ex_rs1      <= 5'b0;
            id_ex_rs2      <= 5'b0;
            id_ex_funct3   <= 3'b0;
            id_ex_funct7   <= 7'b0;
            id_ex_opcode   <= 7'h13; // NOP (addi x0, x0, 0)
            id_ex_imm      <= 32'b0;
        end
        else if (branch_taken_from_ex) begin
             // Insere uma bolha (NOP) para o flush
            id_ex_pc       <= 32'b0;
            id_ex_pc_4     <= 32'b0;
            id_ex_rs1_data <= 32'b0;
            id_ex_rs2_data <= 32'b0;
            id_ex_rd       <= 5'b0;
            id_ex_rs1      <= 5'b0;
            id_ex_rs2      <= 5'b0;
            id_ex_funct3   <= 3'b0;
            id_ex_funct7   <= 7'b0;
            id_ex_opcode   <= 7'h13; // NOP
            id_ex_imm      <= 32'b0;
        end
        else begin
            // Operação Normal
            id_ex_pc       <= pc_in;
            id_ex_pc_4     <= pc_4_in;
            id_ex_rs1_data <= rs1_data;
            id_ex_rs2_data <= rs2_data;
            id_ex_rd       <= rd;
            id_ex_rs1      <= rs1;
            id_ex_rs2      <= rs2;
            id_ex_funct3   <= funct3;
            id_ex_funct7   <= funct7;
            id_ex_opcode   <= opcode;
            id_ex_imm      <= decoded_imm;
        end
    end

endmodule