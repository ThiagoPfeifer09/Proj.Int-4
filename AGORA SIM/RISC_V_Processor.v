module RISC_V_Processor(  
  input clk,
  input reset,
  input wire[63:0] element1, element2, element3, element4, 
  input wire[63:0] element5, element6, element7, element8,
  output wire stall_out,
  output wire flush_out
);
// ======= Declarações =======
wire branch, memread, memtoreg, memwrite, ALUsrc, regwrite;
wire [1:0] ALUop;
wire [63:0] readdata1, readdata2, write_data;
wire [63:0] pc_in, pc_out;
wire [63:0] adderout1, adderout2;
wire [31:0] instruction, inst_ifid_out;

wire [6:0] opcode;
wire [4:0] rd, rs1, rs2;
wire [2:0] funct3;
wire [6:0] funct7;
wire [63:0] imm_data;
wire [63:0] random;

wire [63:0] a1, d, M1, M2;
wire [4:0] RS1, RS2, RD;
wire Branch, Memread, Memtoreg, Memwrite, Regwrite, Alusrc;
wire [1:0] aluop;
wire [3:0] funct4_out;

wire [63:0] threeby1_out1, threeby1_out2, alu_64_b;
wire [63:0] write_Data, exmem_out_adder, exmem_out_result;
wire exmem_out_zero;
wire [4:0] exmemrd;
wire BRANCH,MEMREAD,MEMTOREG,MEMEWRITE,REGWRITE;

wire [63:0] AluResult;
wire zero;
wire [3:0] operation;

wire [63:0] readdata;
wire [63:0] muxin1, muxin2;
wire [4:0] memwbrd;
wire memwb_memtoreg, memwb_regwrite;

wire [1:0] forwardA, forwardB;
wire addermuxselect, branch_final;

// ======= Novos sinais para cache =======
wire [63:0] addr_to_L2_instr;
wire [31:0] instr_from_L2;
wire hit_instr_L2, hit_instr_L1;

wire [63:0] addr_to_mem_instr;
wire [31:0] instr_from_mem;

wire [63:0] addr_to_L2_data;
wire [63:0] data_from_L2;
wire hit_data_L2, hit_data_L1;

wire [63:0] addr_to_mem_data;
wire [63:0] data_from_mem;

// ======= Controle de stall por cache =======
assign stall_out = !(hit_instr_L1 && (hit_data_L1 || !MEMREAD));
assign flush_out = branch_final & BRANCH;

// =========================================================================
pipeline_flush p_flush(.branch(flush_out), .flush(flush_out));

hazard_detection_unit hu(.Memread(Memread), .inst(inst_ifid_out), .Rd(RD), .stall(stall_out));


ForwardingUnit f1(.RS_1(RS1), .RS_2(RS2), .rdMem(exmemrd), .rdWb(memwbrd), 
                  .regWrite_Wb(memwb_regwrite), .regWrite_Mem(REGWRITE),
                  .Forward_A(forwardA), .Forward_B(forwardB));

branching_unit branc(.funct3(funct4_out[2:0]), .readData1(M1), .b(alu_64_b), 
                     .addermuxselect(addermuxselect));

// =========================================================================
program_counter pc(.PC_in(pc_in), .stall(stall_out), .clk(clk), .reset(reset), .PC_out(pc_out));

CacheL1_Instr l1i(.address(pc_out), .instruction(instruction), .hit(hit_instr_L1), .miss(),
                  .addr_to_L2(addr_to_L2_instr), .instruction_from_L2(instr_from_L2),
                  .hit_from_L2(hit_instr_L2));

CacheL2_Instr l2i(.address(addr_to_L2_instr), .instruction(instr_from_L2),
                  .hit(hit_instr_L2), .miss(), .addr_to_mem(addr_to_mem_instr),
                  .instruction_from_mem(instr_from_mem));

instruction_memory imem(.inst_address(addr_to_mem_instr), .instruction(instr_from_mem));

adder adder1(.p(pc_out), .q(64'd4), .out(adderout1));

IF_ID i1(.clk(clk), .reset(reset), .IFIDWrite(stall_out), .instruction(instruction), 
       .A(pc_out), .inst(inst_ifid_out), .a_out(random), .flush(flush_out));


// =========================================================================
Parser ip(.instruction(inst_ifid_out), .opcode(opcode), .rd(rd), .funct3(funct3),
          .rs1(rs1), .rs2(rs2), .funct7(funct7));

CU cu(.opcode(opcode), .branch(branch), .memread(memread), .memtoreg(memtoreg),
       .memwrite(memwrite), .aluSrc(ALUsrc), .regwrite(regwrite), .Aluop(ALUop), 
       .stall(stall_out));

data_extractor immextr(.instruction(inst_ifid_out), .imm_data(imm_data));

registerFile regfile(.clk(clk), .reset(reset), .rs1(rs1), .rs2(rs2), .rd(memwbrd),
                     .writedata(write_data), .reg_write(memwb_regwrite), 
                     .readdata1(readdata1), .readdata2(readdata2),
                     .r8(r8), .r19(r19), .r20(r20), .r21(r21), .r22(r22));

ID_EX i2(.clk(clk), .flush(flush_out), .reset(reset),
         .funct4_in({inst_ifid_out[30],inst_ifid_out[14:12]}),
         .A_in(random), .readdata1_in(readdata1), .readdata2_in(readdata2),
         .imm_data_in(imm_data), .rs1_in(rs1), .rs2_in(rs2), .rd_in(rd),
         .branch_in(branch), .memread_in(memread), .memtoreg_in(memtoreg),
         .memwrite_in(memwrite), .aluSrc_in(ALUsrc), .regwrite_in(regwrite),
         .Aluop_in(ALUop), .a(a1), .rs1(RS1), .rs2(RS2), .rd(RD),
         .imm_data(d), .readdata1(M1), .readdata2(M2), .funct4_out(funct4_out),
         .Branch(Branch), .Memread(Memread), .Memtoreg(Memtoreg), .Memwrite(Memwrite),
         .Regwrite(Regwrite), .Alusrc(Alusrc), .aluop(aluop));

// =========================================================================
adder adder2(.p(a1), .q(d << 1), .out(adderout2));

mux3x1 m1(.a(M1), .b(write_data), .c(exmem_out_result), .sel(forwardA), .out(threeby1_out1));
mux3x1 m2(.a(M2), .b(write_data), .c(exmem_out_result), .sel(forwardB), .out(threeby1_out2));
mux2x1 mux1(.A(threeby1_out2), .B(d), .SEL(Alusrc), .Y(alu_64_b));

alu_control ac(.Aluop(aluop), .funct(funct4_out), .operation(operation));

Alu64 alu(.a(threeby1_out1), .b(alu_64_b), .ALuop(operation), .Result(AluResult), .zero(zero));

EX_MEM i3(
    .clk(clk),
    .reset(reset),
    .Adder_out(adderout2),
    .Result_in_alu(AluResult),
    .Zero_in(zero),
    .flush(flush_out),
    .writedata_in(threeby1_out2),
    .Rd_in(RD),
    .addermuxselect_in(addermuxselect),
    .branch_in(Branch),
    .memread_in(Memread),
    .memtoreg_in(Memtoreg),
    .memwrite_in(Memwrite),
    .regwrite_in(Regwrite),
    .Adderout(exmem_out_adder),
    .zero(exmem_out_zero),
    .result_out_alu(exmem_out_result),
    .writedata_out(write_Data),
    .rd(exmemrd),
    .Branch(BRANCH),
    .Memread(MEMREAD),
    .Memtoreg(MEMTOREG),
    .MemWrite(MEMEWRITE),
    .Regwrite(REGWRITE),
    .addermuxselect(branch_final)
);


// =========================================================================
CacheL1_Data l1d(.clk(clk), .address(exmem_out_result), .read_en(MEMREAD), .write_en(MEMEWRITE),
                 .write_data(write_Data), .read_data(readdata), .hit(hit_data_L1), .miss(),
                 .addr_to_L2(addr_to_L2_data), .data_from_L2(data_from_L2), .hit_from_L2(hit_data_L2));

CacheL2_Data l2d(.clk(clk), .address(addr_to_L2_data), .read_en(MEMREAD), .write_en(MEMEWRITE),
                 .write_data(write_Data), .read_data(data_from_L2), .hit(hit_data_L2), .miss(),
                 .addr_to_mem(addr_to_mem_data), .data_from_mem(data_from_mem));

data_memory datamem(.write_data(write_Data), .address(addr_to_mem_data), 
                    .memorywrite(MEMEWRITE), .clk(clk), .memoryread(MEMREAD),
                    .read_data(data_from_mem), .element1(element1), .element2(element2),
                    .element3(element3), .element4(element4), .element5(element5),
                    .element6(element6), .element7(element7), .element8(element8));

MEM_WB i4(.clk(clk), .reset(reset), .read_data_in(readdata), .result_alu_in(exmem_out_result),
         .Rd_in(exmemrd), .memtoreg_in(MEMTOREG), .regwrite_in(REGWRITE),
         .readdata(muxin1), .result_alu_out(muxin2), .rd(memwbrd), 
         .Memtoreg(memwb_memtoreg), .Regwrite(memwb_regwrite));

twox1Mux mux3(.A(muxin2), .B(muxin1), .SEL(memwb_memtoreg), .Y(write_data));

mux2x1 mux2(.A(adderout1), .B(exmem_out_adder), .SEL(BRANCH & branch_final), .Y(pc_in));

endmodule
