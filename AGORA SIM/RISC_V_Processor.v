// Módulo: RISC_V_Processor
// Objetivo: Este é o módulo de mais alto nível (top-level) que instancia e
// conecta todos os componentes do processador RISC-V de 5 estágios. Ele
// descreve o caminho de dados completo (datapath) e o caminho de controle,
// unindo as etapas de IF, ID, EX, MEM e WB.

// =========================================================================
// == INCLUDES E DECLARAÇÃO DO MÓDULO
// =========================================================================
`include "2_1mux.sv"
`include "imm_data_extractor.sv"
`include "instruction_parser.sv"
`include "reg_file.sv"
`include "alu_64bit.sv"
`include "data_memory.sv"
`include "instruction_memory.sv"
`include "program_counter.sv"
`include "adder.sv"
`include "control_unit.sv"
`include "alu_control.sv"
`include "pipeline_flush.sv"
`include "hazard_detection_unit.sv"
`include "ThreebyOneMux.sv"
`include "IFID.sv"
`include "IDEX.sv"
`include "EXMEM.sv"
`include "MEMWB.sv"
`include "branching_unit.sv"
`include "ForwardingUnit.sv"

module RISC_V_Processor(
  input clk,
  input reset,
  // As entradas 'element' são para diagnóstico, vindas da memória de dados.
  input wire[63:0] element1, element2, element3, element4, 
  input wire[63:0] element5, element6, element7, element8,
  input stall, flush // Sinais de controle globais (para teste/depuração)
);
  
// =========================================================================
// == SINAIS E FIOS (WIRES)
// =========================================================================
// Esta seção declara todos os fios internos que conectam as saídas de um
// módulo às entradas de outro, formando o datapath e o controlpath.
  // Sinais da Unidade de Controle Principal (CU)
  wire branch, memread, memtoreg, memwrite, ALUsrc, regwrite;
  wire [1:0] ALUop;
  // Sinais do Banco de Registradores (Register File)
  wire [63:0] readdata1, readdata2, write_data;
  // Sinais do Program Counter (PC)
  wire [63:0] pc_in, pc_out;
  // Sinais dos Somadores
  wire [63:0] adderout1, adderout2;
  // Sinais da Memória de Instrução
  wire [31:0] instruction, inst_ifid_out;
  // Sinais do Decodificador de Instrução (Parser)
  wire [6:0] opcode;
  wire [4:0] rd, rs1, rs2;
  wire [2:0] funct3;
  wire [6:0] funct7;
  // Sinais do Extrator de Imediato
  wire [63:0] imm_data;
  // Sinais do registrador IF/ID
  wire [63:0] random;
  // Sinais do registrador ID/EX
  wire [63:0] a1, d, M1, M2;
  wire [4:0] RS1, RS2, RD;
  wire Branch, Memread, Memtoreg, Memwrite, Regwrite, Alusrc;
  wire [1:0] aluop;
  wire [3:0] funct4_out;
  // Sinais dos MUXes da etapa EX
  wire [63:0] threeby1_out1, threeby1_out2, alu_64_b;
  // Sinais do registrador EX/MEM
  wire [63:0] write_Data, exmem_out_adder, exmem_out_result;
  wire exmem_out_zero;
  wire [4:0] exmemrd;
  wire BRANCH,MEMREAD,MEMTOREG,MEMEWRITE,REGWRITE;
  // Sinais da ULA
  wire [63:0] AluResult;
  wire zero;
  // Sinais do Controle da ULA
  wire [3:0] operation;
  // Sinais da Memória de Dados
  wire [63:0] readdata;
  // Sinais do registrador MEM/WB
  wire [63:0] muxin1, muxin2;
  wire [4:0] memwbrd;
  wire memwb_memtoreg, memwb_regwrite;
  // Sinais da Unidade de Adiantamento (Forwarding)
  wire [1:0] forwardA, forwardB;
  // Sinais da Unidade de Desvio (Branching)
  wire addermuxselect, branch_final;

// =========================================================================
// == LÓGICA DE DETECÇÃO DE HAZARDS E ADIANTAMENTO (FORWARDING)
// =========================================================================
// Estes módulos são puramente combinacionais e operam olhando para os
// sinais de diferentes etapas do pipeline para tomar decisões de controle.

  // O pipeline_flush gera um sinal 'flush' para anular instruções incorretas
  // após um desvio ser tomado.
  pipeline_flush p_flush(.branch(branch_final & BRANCH), .flush(flush));
  
  // A Unidade de Detecção de Hazard verifica por hazards do tipo load-use
  // (lw seguido por uma instrução que usa o resultado) e gera o sinal 'stall'.
  hazard_detection_unit hu(.Memread(Memread), .inst(inst_ifid_out), .Rd(RD), .stall(stall));

  // A Unidade de Adiantamento detecta hazards de dados e gera os sinais de
  // controle para os MUXes da ULA, evitando stalls.
  ForwardingUnit f1(.RS_1(RS1), .RS_2(RS2), .rdMem(exmemrd), .rdWb(memwbrd), 
                    .regWrite_Wb(memwb_regwrite), .regWrite_Mem(REGWRITE),
                    .Forward_A(forwardA), .Forward_B(forwardB));
  
  // A Unidade de Desvio avalia a condição de um branch (ex: rs1 == rs2).
  branching_unit branc(.funct3(funct4_out[2:0]), .readData1(M1), .b(alu_64_b), 
                       .addermuxselect(addermuxselect));
                       
// =========================================================================
// == ETAPA 1: BUSCA DA INSTRUÇÃO (INSTRUCTION FETCH - IF)
// =========================================================================

  // O Program Counter armazena o endereço da instrução a ser buscada.
  // Ele é paralisado ('stalled') se o sinal 'stall' da unidade de hazard for ativado.
  program_counter pc(.PC_in(pc_in), .stall(stall), .clk(clk), .reset(reset), .PC_out(pc_out));
  
  // A Memória de Instruções busca a instrução no endereço fornecido pelo PC.
  instruction_memory im(.inst_address(pc_out), .instruction(instruction));
  
  // Somador para calcular PC + 4, o endereço da próxima instrução sequencial.
  adder adder1(.p(pc_out), .q(64'd4), .out(adderout1));
  
  // Registrador de pipeline IF/ID: armazena a instrução buscada e o PC para a próxima etapa.
  // NOTA: A entrada 'A' deveria receber 'adderout1' (PC+4), não 'pc_out'.
  IFID i1(.clk(clk), .reset(reset), .IFIDWrite(stall), .instruction(instruction), 
           .A(pc_out), .inst(inst_ifid_out), .a_out(random), .flush(flush));

// =========================================================================
// == ETAPA 2: DECODIFICAÇÃO E LEITURA DE REGISTRADORES (INSTRUCTION DECODE - ID)
// =========================================================================

  // O Parser quebra a instrução em seus campos (opcode, rd, rs1, etc.).
  Parser ip(.instruction(inst_ifid_out), .opcode(opcode), .rd(rd), .funct3(funct3),
            .rs1(rs1), .rs2(rs2), .funct7(funct7));
  
  // A Unidade de Controle Principal decodifica o opcode e gera os sinais de controle.
  CU cu(.opcode(opcode), .branch(branch), .memread(memread), .memtoreg(memtoreg),
         .memwrite(memwrite), .aluSrc(ALUsrc), .regwrite(regwrite), .Aluop(ALUop), 
         .stall(stall));
  
  // O Extrator de Imediato extrai e estende o sinal do valor imediato da instrução.
  data_extractor immextr(.instruction(inst_ifid_out), .imm_data(imm_data));
  
  // O Banco de Registradores lê os dados dos registradores rs1 e rs2.
  // A escrita ('writedata') é feita na etapa WB.
  registerFile regfile(.clk(clk), .reset(reset), .rs1(rs1), .rs2(rs2), .rd(memwbrd),
                       .writedata(write_data), .reg_write(memwb_regwrite), 
                       .readdata1(readdata1), .readdata2(readdata2),
                       .r8(r8), .r19(r19), .r20(r20), .r21(r21), .r22(r22));
  
  // Registrador de pipeline ID/EX: carrega todos os dados e sinais de controle para a etapa EX.
  IDEX i2(.clk(clk), .flush(flush), .reset(reset), 
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
// == ETAPA 3: EXECUÇÃO (EXECUTE - EX)
// =========================================================================

  // Somador para calcular o endereço de desvio (PC + offset).
  adder adder2(.p(a1), .q(d << 1), .out(adderout2));
  
  // MUXes de adiantamento (Forwarding) para a primeira e segunda entrada da ULA.
  ThreebyOneMux m1(.a(M1), .b(write_data), .c(exmem_out_result), .sel(forwardA), .out(threeby1_out1));
  ThreebyOneMux m2(.a(M2), .b(write_data), .c(exmem_out_result), .sel(forwardB), .out(threeby1_out2));
  
  // MUX (ALUSrc) que seleciona a segunda entrada da ULA: dado do registrador ou imediato.
  twox1Mux mux1(.A(threeby1_out2), .B(d), .SEL(Alusrc), .Y(alu_64_b));
  
  // A Unidade de Controle da ULA gera o código de operação final para a ULA.
  alu_control ac(.Aluop(aluop), .funct(funct4_out), .operation(operation));
  
  // A ULA executa a operação aritmética/lógica.
  Alu64 alu(.a(threeby1_out1), .b(alu_64_b), .ALuop(operation), .Result(AluResult), .zero(zero));
  
  // Registrador de pipeline EX/MEM: armazena os resultados da ULA para a próxima etapa.
  EXMEM i3(.clk(clk), .reset(reset), .Adder_out(adderout2), .Result_in_alu(AluResult),
           .Zero_in(zero), .flush(flush), .writedata_in(threeby1_out2), .Rd_in(RD),
           .addermuxselect_in(addermuxselect), .branch_in(Branch), .memread_in(Memread),
           .memtoreg_in(Memtoreg), .memwrite_in(Memwrite), .regwrite_in(Regwrite),
           .Adderout(exmem_out_adder), .zero(exmem_out_zero), .result_out_alu(exmem_out_result),
           .writedata_out(write_Data), .rd(exmemrd), .Branch(BRANCH), .Memread(MEMREAD),
           .Memtoreg(MEMTOREG), .Memwrite(MEMEWRITE), .Regwrite(REGWRITE),
           .addermuxselect(branch_final));

// =========================================================================
// == ETAPA 4: ACESSO À MEMÓRIA (MEMORY ACCESS - MEM)
// =========================================================================

  // A Memória de Dados realiza a leitura ou escrita.
  // O endereço vem do resultado da ULA. O dado a ser escrito vem do registrador rs2.
  data_memory datamem(.write_data(write_Data), .address(exmem_out_result), 
                      .memorywrite(MEMEWRITE), .clk(clk), .memoryread(MEMREAD),
                      .read_data(readdata), .element1(element1), .element2(element2),
                      .element3(element3), .element4(element4), .element5(element5),
                      .element6(element6), .element7(element7), .element8(element8));
  
  // Registrador de pipeline MEM/WB: armazena o dado lido da memória e o resultado
  // da ULA para a etapa final de escrita.
  MEMWB i4(.clk(clk), .reset(reset), .read_data_in(readdata), .result_alu_in(exmem_out_result),
           .Rd_in(exmemrd), .memtoreg_in(MEMTOREG), .regwrite_in(REGWRITE),
           .readdata(muxin1), .result_alu_out(muxin2), .rd(memwbrd), 
           .Memtoreg(memwb_memtoreg), .Regwrite(memwb_regwrite));
           
// =========================================================================
// == ETAPA 5: ESCRITA DE RETORNO (WRITE-BACK - WB)
// =========================================================================

  // MUX (MemtoReg) que seleciona o dado a ser escrito no banco de registradores:
  // ou o resultado da ULA, ou o dado vindo da memória.
  twox1Mux mux3(.A(muxin2), .B(muxin1), .SEL(memwb_memtoreg), .Y(write_data));

// =========================================================================
// == LÓGICA DE ATUALIZAÇÃO DO PROGRAM COUNTER (PC)
// =========================================================================
  // MUX que seleciona o próximo valor do PC.
  // Se o desvio for tomado, seleciona o endereço de desvio calculado (adderout2).
  // Caso contrário, seleciona PC+4 (adderout1).
  // A decisão é tomada na etapa MEM, pois usa 'BRANCH' (sinal do registrador EX/MEM).
  twox1Mux mux2(.A(adderout1), .B(exmem_out_adder), .SEL(BRANCH & branch_final), .Y(pc_in));
        
endmodule
