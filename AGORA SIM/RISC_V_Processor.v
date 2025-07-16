// Módulo: RISC_V_Processor (Versão Final e Funcional)

module RISC_V_Processor(
  input clk,
  input reset,
  output wire[63:0] element1, element2, element3, element4, 
  output wire[63:0] element5, element6, element7, element8,
  output wire stall_out,
  output wire flush_out
);

// --- Declaração de Fios ---
// Sinais da Etapa ID
wire [6:0] opcode;
wire [4:0] rd_id, rs1_id, rs2_id;
wire [2:0] funct3;
wire [63:0] imm_data_id;
wire [63:0] readdata1_from_regfile, readdata2_from_regfile;
wire branch_id, memread_id, memtoreg_id, memwrite_id, alusrc_id, regwrite_id;
wire [1:0] aluop_id;

// Sinais da Etapa EX
wire [63:0] pc_plus_4_ex, readdata1_ex, readdata2_ex, imm_data_ex;
wire [4:0] rs1_ex, rs2_ex, rd_ex;
wire [3:0] funct4_ex;
wire branch_ex, memread_ex, memtoreg_ex, memwrite_ex, regwrite_ex, alusrc_ex;
wire [1:0] aluop_ex;
wire [63:0] forwarded_data_A, forwarded_data_B, alu_input_B, alu_result_ex, branch_addr_ex;
wire zero_ex, branch_decision_ex;
wire [3:0] alu_operation_ex;
wire [1:0] forwardA, forwardB;

// Sinais da Etapa MEM
wire [63:0] alu_result_mem, branch_addr_mem, readdata2_mem;
wire [4:0] rd_mem;
wire zero_mem;
wire branch_mem, memread_mem, memtoreg_mem, memwrite_mem, regwrite_mem, branch_taken_mem;

// Sinais da Etapa WB
wire [63:0] alu_result_wb, data_from_mem_wb, data_to_write_back;
wire [4:0] rd_wb;
wire memtoreg_wb, regwrite_wb;

// Sinais Globais
wire [63:0] pc_in, pc_out, pc_plus_4;
wire [31:0] instruction, instruction_id;

// =========================================================================
// == Lógica de Controle de Pipeline
// =========================================================================
assign flush_out = branch_taken_mem;
hazard_detection_unit hu(.Memread(memread_ex), .inst(instruction_id), .Rd(rd_ex), .stall(stall_out));
ForwardingUnit f1(.RS_1(rs1_ex), .RS_2(rs2_ex), .rdMem(rd_mem), .rdWb(rd_wb),
                  .regWrite_Wb(regwrite_wb), .regWrite_Mem(regwrite_mem),
                  .Forward_A(forwardA), .Forward_B(forwardB));

// =========================================================================
// == ETAPA 1: BUSCA DA INSTRUÇÃO (IF)
// =========================================================================
program_counter pc(.PC_in(pc_in), .stall(stall_out), .clk(clk), .reset(reset), .PC_out(pc_out));
adder pc_adder(.p(pc_out), .q(64'd4), .out(pc_plus_4));
instruction_memory imem(.inst_address(pc_out), .instruction(instruction));
IF_ID if_id_reg(.clk(clk), .reset(reset), .IFIDWrite(stall_out), .instruction(instruction), 
                 .A(pc_plus_4), .inst(instruction_id), .a_out(pc_plus_4_ex), .flush(flush_out));

// =========================================================================
// == ETAPA 2: DECODIFICAÇÃO (ID)
// =========================================================================
Parser ip(.instruction(instruction_id), .opcode(opcode), .rd(rd_id), .funct3(funct3),
          .rs1(rs1_id), .rs2(rs2_id), .funct7());
control_unit cu(.opcode(opcode), .branch(branch_id), .memread(memread_id), .memtoreg(memtoreg_id),
                .memwrite(memwrite_id), .aluSrc(alusrc_id), .regwrite(regwrite_id), .Aluop(aluop_id), 
                .stall(stall_out));
data_extractor immextr(.instruction(instruction_id), .imm_data(imm_data_id));
reg_file regfile(.clk(clk), .reset(reset), .rs1(rs1_id), .rs2(rs2_id), .rd(rd_wb),
                 .writedata(data_to_write_back), .reg_write(regwrite_wb), 
                 .readdata1(readdata1_from_regfile), .readdata2(readdata2_from_regfile),
                 .r8(), .r19(), .r20(), .r21(), .r22());
ID_EX id_ex_reg(.clk(clk), .flush(flush_out), .reset(reset),
                .funct4_in({instruction_id[30], instruction_id[14:12]}),
                .A_in(pc_plus_4_ex), .readdata1_in(readdata1_from_regfile), .readdata2_in(readdata2_from_regfile),
                .imm_data_in(imm_data_id), .rs1_in(rs1_id), .rs2_in(rs2_id), .rd_in(rd_id),
                .branch_in(branch_id), .memread_in(memread_id), .memtoreg_in(memtoreg_id),
                .memwrite_in(memwrite_id), .aluSrc_in(alusrc_id), .regwrite_in(regwrite_id),
                .Aluop_in(aluop_id), .a(pc_plus_4_ex), .rs1(rs1_ex), .rs2(rs2_ex), .rd(rd_ex),
                .imm_data(imm_data_ex), .readdata1(readdata1_ex), .readdata2(readdata2_ex), .funct4_out(funct4_ex),
                .Branch(branch_ex), .Memread(memread_ex), .Memtoreg(memtoreg_ex), .Memwrite(memwrite_ex),
                .Regwrite(regwrite_ex), .Alusrc(alusrc_ex), .aluop(aluop_ex));

// =========================================================================
// == ETAPA 3: EXECUÇÃO (EX)
// =========================================================================
mux3x1 forward_mux_A(.a(readdata1_ex), .b(data_to_write_back), .c(alu_result_mem), .sel(forwardA), .out(forwarded_data_A));
mux3x1 forward_mux_B(.a(readdata2_ex), .b(data_to_write_back), .c(alu_result_mem), .sel(forwardB), .out(forwarded_data_B));
mux2x1 alusrc_mux(.A(forwarded_data_B), .B(imm_data_ex), .SEL(alusrc_ex), .Y(alu_input_B));
alu_control ac(.Aluop(aluop_ex), .funct(funct4_ex), .operation(alu_operation_ex));
Alu64 alu(.a(forwarded_data_A), .b(alu_input_B), .ALuop(alu_operation_ex), .Result(alu_result_ex), .zero(zero_ex));
adder branch_adder(.p(pc_plus_4_ex), .q(imm_data_ex << 1), .out(branch_addr_ex));
branching_unit branc(.funct3(funct3), .readData1(forwarded_data_A), .b(forwarded_data_B),
                     .addermuxselect(branch_decision_ex));
EX_MEM ex_mem_reg(.clk(clk), .reset(reset), .Adder_out(branch_addr_ex), .Result_in_alu(alu_result_ex),
                  .Zero_in(zero_ex), .flush(flush_out), .writedata_in(forwarded_data_B), .Rd_in(rd_ex),
                  .addermuxselect_in(branch_decision_ex), .branch_in(branch_ex), .memread_in(memread_ex),
                  .memtoreg_in(memtoreg_ex), .memwrite_in(memwrite_ex), .regwrite_in(regwrite_ex),
                  .Adderout(branch_addr_mem), .zero(zero_mem), .result_out_alu(alu_result_mem),
                  .writedata_out(readdata2_mem), .rd(rd_mem), .Branch(branch_mem), .Memread(memread_mem),
                  .Memtoreg(memtoreg_mem), .MemWrite(memwrite_mem), .Regwrite(regwrite_mem),
                  .addermuxselect(branch_taken_mem));

// =========================================================================
// == ETAPA 4: ACESSO À MEMÓRIA (MEM)
// =========================================================================
data_memory datamem(.write_data(readdata2_mem), .address(alu_result_mem), 
                    .memorywrite(memwrite_mem), .clk(clk), .memoryread(memread_mem),
                    .read_data(data_read_from_mem), .element1(element1), .element2(element2),
                    .element3(element3), .element4(element4), .element5(element5),
                    .element6(element6), .element7(element7), .element8(element8));
MEM_WB mem_wb_reg(.clk(clk), .reset(reset), .read_data_in(data_read_from_mem), .result_alu_in(alu_result_mem),
                  .Rd_in(rd_mem), .memtoreg_in(memtoreg_mem), .regwrite_in(regwrite_mem),
                  .readdata(data_from_mem_wb), .result_alu_out(alu_result_wb), .rd(rd_wb), 
                  .Memtoreg(memtoreg_wb), .Regwrite(regwrite_wb));

// =========================================================================
// == ETAPA 5: ESCRITA DE RETORNO (WB) e LÓGICA DO PC
// =========================================================================
mux2x1 writeback_mux(.A(alu_result_wb), .B(data_from_mem_wb), .SEL(memtoreg_wb), .Y(data_to_write_back));
mux2x1 pc_mux(.A(pc_plus_4), .B(branch_addr_mem), .SEL(branch_taken_mem), .Y(pc_in));

endmodule