module RISC_V_Processor(
  input clk,
  input reset,
  input wire[63:0] element1,
  input wire[63:0] element2,
  input wire[63:0] element3,
  input wire[63:0] element4,
  input wire[63:0] element5,
  input wire[63:0] element6,
  input wire[63:0] element7,
  input wire[63:0] element8,
  input stall,
  input flush
);

  // Control Unit wires
  wire branch;
  wire memread;
  wire memtoreg;
  wire memwrite;
  wire ALUsrc;
  wire regwrite;
  wire [1:0] ALUop;

  // Regfile wires
  wire regwrite_memwb_out;
  wire [63:0] readdata1, readdata2;
  wire [63:0] r8, r19, r20, r21, r22;
  wire [63:0] write_data;

  // PC wires
  wire [63:0] pc_in;
  wire [63:0] pc_out;

  // Adders
  wire [63:0] adderout1;
  wire [63:0] adderout2;

  // Instruction memory wires
  wire [31:0] instruction;
  wire [31:0] inst_ifid_out;

  // Parser wires
  wire [6:0] opcode;
  wire [4:0] rd, rs1, rs2;
  wire [2:0] funct3;
  wire [6:0] funct7;

  // Immediate Data Extractor
  wire [63:0] imm_data;

  // IFID wires
  wire [63:0] random;

  // IDEX wires
  wire [63:0] a1;
  wire [4:0] RS1;
  wire [4:0] RS2;
  wire [4:0] RD;
  wire [63:0] d, M1, M2;
  wire Branch;
  wire Memread;
  wire Memtoreg;
  wire Memwrite;
  wire Regwrite;
  wire Alusrc;
  wire [1:0] aluop;
  wire [3:0] funct4_out;

  // MUX wires
  wire [63:0] threeby1_out1;
  wire [63:0] threeby1_out2;
  wire [63:0] alu_64_b;

  // EXMEM wires
  wire [63:0] write_Data;
  wire [63:0] exmem_out_adder;
  wire exmem_out_zero;
  wire [63:0] exmem_out_result;
  wire [4:0] exmemrd;
  wire BRANCH, MEMREAD, MEMTOREG, MEMEWRITE, REGWRITE;

  // ALU 64
  wire [63:0] AluResult;
  wire zero;

  // ALU Control
  wire [3:0] operation;

  // MemWB wires
  wire [63:0] muxin1, muxin2;
  wire [4:0] memwbrd;
  wire memwb_memtoreg;
  wire memwb_regwrite;

  // Forwarding Unit wires
  wire [1:0] forwardA;
  wire [1:0] forwardB;

  // Branch
  wire addermuxselect;
  wire branch_final;

  // Memória e cache - sinais adicionais
  wire [63:0] mem_address;
  wire [63:0] mem_write_data;
  wire [127:0] mem_block_read_data;
  wire mem_read_out;
  wire mem_write_out;
  wire [63:0] readdata; // leitura 64 bits da cache para o processador
  wire cache_miss;

  pipeline_flush p_flush (
    .branch(branch_final & BRANCH),
    .flush(flush)
  );

// Hazard unit atualizada
  hazard_detection_unit hu (
    .Memread(Memread),
    .inst(inst_ifid_out),
    .Rd(RD),
    .stall(stall_combined)
  );

   pc pc_inst (
    .PC_in(pc_in),
    .stall(stall_combined),
    .clk(clk),
    .reset(reset),
    .PC_out(pc_out)
  );

  instruc_mem im (
    .inst_address(pc_out),
    .instruction(instruction)
  );

  somador adder1 (
    .p(pc_out),
    .q(64'd4),
    .out(adderout1)
  );

 // IF/ID com stall pela cache
  IF_ID if_id_inst (
    .clk(clk),
    .reset(reset),
    .IFIDWrite(stall_combined),
    .instruction(instruction),
    .A(pc_out),
    .inst(inst_ifid_out),
    .a_out(random),
    .flush(flush)
  );

  Parser ip (
    .instruction(inst_ifid_out),
    .opcode(opcode),
    .rd(rd),
    .funct3(funct3),
    .rs1(rs1),
    .rs2(rs2),
    .funct7(funct7)
  );

  control_unit cu (
    .opcode(opcode),
    .branch(branch),
    .memread(memread),
    .memtoreg(memtoreg),
    .memwrite(memwrite),
    .aluSrc(ALUsrc),
    .regwrite(regwrite),
    .Aluop(ALUop),
    .stall(stall)
  );

  data_extractor immextr (
    .instruction(inst_ifid_out),
    .imm_data(imm_data)
  );

  banco_regs regfile (
    .clk(clk),
    .reset(reset),
    .rs1(rs1),
    .rs2(rs2),
    .rd(memwbrd),
    .writedata(write_data),
    .reg_write(memwb_regwrite),
    .readdata1(readdata1),
    .readdata2(readdata2),
    .r8(r8),
    .r19(r19),
    .r20(r20),
    .r21(r21),
    .r22(r22)
  );

  ID_EX i2 (
    .clk(clk),
    .flush(flush),
    .reset(reset),
    .funct4_in({inst_ifid_out[30], inst_ifid_out[14:12]}),
    .A_in(random),
    .readdata1_in(readdata1),
    .readdata2_in(readdata2),
    .imm_data_in(imm_data),
    .rs1_in(rs1), .rs2_in(rs2), .rd_in(rd),
    .branch_in(branch), .memread_in(memread), .memtoreg_in(memtoreg),
    .memwrite_in(memwrite), .aluSrc_in(ALUsrc), .regwrite_in(regwrite), .Aluop_in(ALUop),
    .a(a1), .rs1(RS1), .rs2(RS2), .rd(RD), .imm_data(d), .readdata1(M1), .readdata2(M2),
    .funct4_out(funct4_out), .Branch(Branch), .Memread(Memread), .Memtoreg(Memtoreg),
    .Memwrite(Memwrite), .Regwrite(Regwrite), .Alusrc(Alusrc), .aluop(aluop)
  );

  somador adder2 (
    .p(a1),
    .q(d << 1),
    .out(adderout2)
  );

  tresx1MUX m1 (
    .a(M1), .b(write_data), .c(exmem_out_result), .sel(forwardA), .out(threeby1_out1)
  );

  tresx1MUX m2 (
    .a(M2), .b(write_data), .c(exmem_out_result), .sel(forwardB), .out(threeby1_out2)
  );

  doisx1Mux mux1 (
    .A(threeby1_out2), .B(d), .SEL(Alusrc), .Y(alu_64_b)
  );

  Alu64 alu (
    .a(threeby1_out1),
    .b(alu_64_b),
    .ALuop(operation),
    .Result(AluResult),
    .zero(zero)
  );

  alu_control ac (
    .Aluop(aluop),
    .funct(funct4_out),
    .operation(operation)
  );

  EX_MEM i3 (
    .clk(clk), .reset(reset), .Adder_out(adderout2), .Result_in_alu(AluResult), .Zero_in(zero), .flush(flush),
    .writedata_in(threeby1_out2), .Rd_in(RD), .addermuxselect_in(addermuxselect),
    .branch_in(Branch), .memread_in(Memread), .memtoreg_in(Memtoreg), .memwrite_in(Memwrite), .regwrite_in(Regwrite),
    .Adderout(exmem_out_adder), .zero(exmem_out_zero), .result_out_alu(exmem_out_result), .writedata_out(write_Data),
    .rd(exmemrd), .Branch(BRANCH), .Memread(MEMREAD), .Memtoreg(MEMTOREG), .Memwrite(MEMEWRITE), .Regwrite(REGWRITE), .addermuxselect(branch_final)
  );

  // CACHE - leitura/escrita pela cache_dados
	// Instancia cache_dados com saída miss
  cache_dados cache_inst (
    .clk(clk),
    .reset(reset),
    .address(exmem_out_result),
    .write_data(write_Data),
    .mem_write(MEMEWRITE),
    .mem_read(MEMREAD),
    .read_data(readdata),
    .miss(cache_miss)
  );

  // Memória de dados real atrás da cache
  data_memory datamem (
    .clk(clk),
    .address(mem_address),
    .write_data(mem_write_data),
    .mem_write(mem_write_out),
    .mem_read(mem_read_out),
    .block_read_data(mem_block_read_data)
  );

  doisx1Mux mux2 (
    .A(adderout1), .B(exmem_out_adder), .SEL(BRANCH & branch_final), .Y(pc_in)
  );

  MEM_WB i4 (
    .clk(clk), .reset(reset), .read_data_in(readdata),
    .result_alu_in(exmem_out_result), .Rd_in(exmemrd), .memtoreg_in(MEMTOREG), .regwrite_in(REGWRITE),
    .readdata(muxin1), .result_alu_out(muxin2), .rd(memwbrd), .Memtoreg(memwb_memtoreg), .Regwrite(memwb_regwrite)
  );

  doisx1Mux mux3 (
    .A(muxin2), .B(muxin1), .SEL(memwb_memtoreg), .Y(write_data)
  );

  ForwardingUnit f1 (
    .RS_1(RS1), .RS_2(RS2), .rdMem(exmemrd),
    .rdWb(memwbrd), .regWrite_Wb(memwb_regwrite),
    .regWrite_Mem(REGWRITE),
    .Forward_A(forwardA), .Forward_B(forwardB)
  );

  branching_unit branc (
    .funct3(funct4_out[2:0]), .readData1(M1), .b(alu_64_b), .addermuxselect(addermuxselect)
  );

endmodule
