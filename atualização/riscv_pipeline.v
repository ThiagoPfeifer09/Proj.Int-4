// Módulo de topo para o processador RISC-V de 5 estágios
// Versão final com todas as conexões de pipeline e hazard corrigidas.
module riscv_pipeline (
    input wire clk,
    input wire rst
);

    // --- FIOS DE CONEXÃO (WIRES) ---

    // IF/ID
    wire [31:0] if_id_pc;
    wire [31:0] if_id_pc_4;
    wire [31:0] if_id_instr;

    // ID/EX
    wire [31:0] id_ex_pc;
    wire [31:0] id_ex_pc_4;
    wire [31:0] id_ex_rs1_data;
    wire [31:0] id_ex_rs2_data;
    wire [4:0]  id_ex_rd;
    wire [4:0]  id_ex_rs1;
    wire [4:0]  id_ex_rs2;
    wire [2:0]  id_ex_funct3;
    wire [6:0]  id_ex_funct7;
    wire [6:0]  id_ex_opcode;
    wire [31:0] id_ex_imm;

    // EX/MEM
    wire [31:0] ex_mem_pc; // <-- Conexão que estava faltando
    wire [31:0] ex_mem_pc_4;
    wire [31:0] ex_mem_alu_result;
    wire [31:0] ex_mem_rs2_data;
    wire [4:0]  ex_mem_rd;
    wire [2:0]  ex_mem_funct3;
    wire [6:0]  ex_mem_opcode; // <-- Conexão que estava faltando
    wire        ex_mem_mem_write_en;
    wire        ex_mem_mem_read_en;
    wire        ex_mem_reg_write_en;
    wire [1:0]  ex_mem_mem_to_reg_sel;

    // MEM/WB
    wire [31:0] mem_wb_pc_4;
    wire [31:0] mem_wb_alu_result;
    wire [31:0] mem_wb_mem_read_data;
    wire [4:0]  mem_wb_rd;
    wire        mem_wb_reg_write_en;
    wire [1:0]  mem_wb_mem_to_reg_sel;

    // WB -> RegFile
    wire        wb_to_rf_reg_write_en;
    wire [4:0]  wb_to_rf_reg_write_addr;
    wire [31:0] wb_to_rf_reg_write_data;

    // Hazard e Controle
    wire        pc_write_en;
    wire        if_id_write_en;
    wire [31:0] branch_target_from_ex;
    wire        branch_taken_from_ex;

    // Interface com Memória de Dados
    wire [31:0] mem_addr_to_dm;
    wire [31:0] mem_write_data_to_dm;
    wire        mem_write_byte_en_to_dm;
    wire        mem_write_half_en_to_dm;
    wire        mem_write_word_en_to_dm;
    wire [31:0] mem_read_data_from_dm;

    // --- INSTÂNCIA DOS MÓDULOS ---

    if_stage u_if_stage (
        .clk(clk),
        .rst(rst),
        .branch_target(branch_target_from_ex),
        .branch_taken(branch_taken_from_ex),
        .pc_write_en(pc_write_en),
        .if_id_write_en(if_id_write_en),
        .if_id_pc_out(if_id_pc),
        .if_id_pc_4_out(if_id_pc_4),
        .if_id_instr_out(if_id_instr)
    );

    id_stage u_id_stage (
        .clk(clk),
        .rst(rst),
        .instr_in(if_id_instr),
        .pc_in(if_id_pc),
        .pc_4_in(if_id_pc_4),
        .reg_write_en_wb(wb_to_rf_reg_write_en),
        .reg_write_addr_wb(wb_to_rf_reg_write_addr),
        .reg_write_data_wb(wb_to_rf_reg_write_data),
        .ex_mem_mem_read_en(ex_mem_mem_read_en),
        .ex_mem_rd(ex_mem_rd),
        .branch_taken_from_ex(branch_taken_from_ex),
        .pc_write_en(pc_write_en),
        .if_id_write_en(if_id_write_en),
        .id_ex_pc(id_ex_pc),
        .id_ex_pc_4(id_ex_pc_4),
        .id_ex_rs1_data(id_ex_rs1_data),
        .id_ex_rs2_data(id_ex_rs2_data),
        .id_ex_rd(id_ex_rd),
        .id_ex_rs1(id_ex_rs1),
        .id_ex_rs2(id_ex_rs2),
        .id_ex_funct3(id_ex_funct3),
        .id_ex_funct7(id_ex_funct7),
        .id_ex_opcode(id_ex_opcode),
        .id_ex_imm(id_ex_imm)
    );

    ex_stage u_ex_stage (
        .clk(clk),
        .rst(rst),
        .id_ex_pc(id_ex_pc),
        .id_ex_pc_4(id_ex_pc_4),
        .id_ex_rs1_data(id_ex_rs1_data),
        .id_ex_rs2_data(id_ex_rs2_data),
        .id_ex_rd(id_ex_rd),
        .id_ex_rs1(id_ex_rs1),
        .id_ex_rs2(id_ex_rs2),
        .id_ex_funct3(id_ex_funct3),
        .id_ex_funct7(id_ex_funct7),
        .id_ex_opcode(id_ex_opcode),
        .id_ex_imm(id_ex_imm),
        .ex_mem_rd_in(ex_mem_rd),
        .ex_mem_reg_write_en_in(ex_mem_reg_write_en),
        .ex_mem_alu_result_in(ex_mem_alu_result),
        .mem_wb_rd_in(mem_wb_rd),
        .mem_wb_reg_write_en_in(mem_wb_reg_write_en),
        .mem_wb_write_data_in(wb_to_rf_reg_write_data),
        .ex_mem_pc(ex_mem_pc), // <-- Conexão que estava faltando
        .ex_mem_pc_4(ex_mem_pc_4),
        .ex_mem_alu_result(ex_mem_alu_result),
        .ex_mem_rs2_data(ex_mem_rs2_data),
        .ex_mem_rd(ex_mem_rd),
        .ex_mem_funct3(ex_mem_funct3),
        .ex_mem_opcode(ex_mem_opcode),
        .ex_mem_mem_write_en(ex_mem_mem_write_en),
        .ex_mem_mem_read_en(ex_mem_mem_read_en),
        .ex_mem_reg_write_en(ex_mem_reg_write_en),
        .ex_mem_mem_to_reg_sel(ex_mem_mem_to_reg_sel),
        .branch_target(branch_target_from_ex),
        .branch_taken(branch_taken_from_ex)
    );

    mem_stage u_mem_stage (
        .clk(clk),
        .rst(rst),
        .ex_mem_pc(ex_mem_pc), // <-- Conexão que estava faltando
        .ex_mem_pc_4(ex_mem_pc_4),
        .ex_mem_alu_result(ex_mem_alu_result),
        .ex_mem_rs2_data(ex_mem_rs2_data),
        .ex_mem_rd(ex_mem_rd),
        .ex_mem_funct3(ex_mem_funct3),
        .ex_mem_opcode(ex_mem_opcode), // <-- Conexão que estava faltando
        .ex_mem_mem_write_en(ex_mem_mem_write_en),
        .ex_mem_mem_read_en(ex_mem_mem_read_en),
        .ex_mem_reg_write_en(ex_mem_reg_write_en),
        .ex_mem_mem_to_reg_sel(ex_mem_mem_to_reg_sel),
        .mem_addr(mem_addr_to_dm),
        .mem_write_data(mem_write_data_to_dm),
        .mem_write_byte_en(mem_write_byte_en_to_dm),
        .mem_write_half_en(mem_write_half_en_to_dm),
        .mem_write_word_en(mem_write_word_en_to_dm),
        .mem_read_data(mem_read_data_from_dm),
        .mem_wb_pc_4(mem_wb_pc_4),
        .mem_wb_alu_result(mem_wb_alu_result),
        .mem_wb_mem_read_data(mem_wb_mem_read_data),
        .mem_wb_rd(mem_wb_rd),
        .mem_wb_reg_write_en(mem_wb_reg_write_en),
        .mem_wb_mem_to_reg_sel(mem_wb_mem_to_reg_sel)
    );

    wb_stage u_wb_stage (
        .clk(clk),
        .rst(rst),
        .mem_wb_pc_4(mem_wb_pc_4),
        .mem_wb_alu_result(mem_wb_alu_result),
        .mem_wb_mem_read_data(mem_wb_mem_read_data),
        .mem_wb_rd(mem_wb_rd),
        .mem_wb_reg_write_en(mem_wb_reg_write_en),
        .mem_wb_mem_to_reg_sel(mem_wb_mem_to_reg_sel),
        .reg_write_en_out(wb_to_rf_reg_write_en),
        .reg_write_addr_out(wb_to_rf_reg_write_addr),
        .reg_write_data_out(wb_to_rf_reg_write_data)
    );

    data_mem u_data_mem (
        .clk(clk),
        .addr(mem_addr_to_dm),
        .write_data(mem_write_data_to_dm),
        .read_en(ex_mem_mem_read_en), // <-- Conexão que estava faltando
        .write_byte_en(mem_write_byte_en_to_dm),
        .write_half_en(mem_write_half_en_to_dm),
        .write_word_en(mem_write_word_en_to_dm),
        .read_data(mem_read_data_from_dm)
    );

endmodule