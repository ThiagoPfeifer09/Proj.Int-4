module id_stage (
	input wire        clk,
	input wire        rst,
	input wire [31:0] instr_in,    // vindo do IF/ID
	input wire [31:0] pc_in,       
	input wire [31:0] pc_4_in,     // vindo do IF/ID
	
	// para escrita no banco de registradores (vindo da WB)
	input wire        reg_write_en,
	input wire [4:0]  reg_write_addr,
	input wire [31:0] reg_write_data,
	
	// saídas para o próximo estágio (ID/EX)
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

	// extração dos campos da instrução
	wire [4:0] rs1    = instr_in[19:15];
	wire [4:0] rs2    = instr_in[24:20];
	wire [4:0] rd     = instr_in[11:7];
	wire [2:0] funct3 = instr_in[14:12];
	wire [6:0] funct7 = instr_in[31:25];
	wire [6:0] opcode = instr_in[6:0];
	
	// decodificação de imediato para diferentes tipos de instrução
	wire [31:0] imm_i = {{20{instr_in[31]}}, instr_in[31:20]}; // I-type (load, jalr, imm arithmetic)
	wire [31:0] imm_s = {{20{instr_in[31]}}, instr_in[31:25], instr_in[11:7]}; // S-type (store)
	// Para o tipo B, o bit de sinal é instr_in[31], os bits de 1 a 4 são instr_in[11:8], o bit 11 é instr_in[7], e os bits 5 a 10 são instr_in[30:25].
	// O bit 0 é sempre 0.
	wire [31:0] imm_b = {{20{instr_in[31]}}, instr_in[7], instr_in[30:25], instr_in[11:8], 1'b0}; // B-type (branches)
	wire [31:0] imm_u = {instr_in[31:12], {12{1'b0}}}; // U-type (lui, auipc)
	// Para o tipo J, o bit de sinal é instr_in[31], os bits de 1 a 10 são instr_in[30:21], o bit 11 é instr_in[20], e os bits de 12 a 19 são instr_in[19:12].
	// O bit 0 é sempre 0.
	wire [31:0] imm_j = {{12{instr_in[31]}}, instr_in[19:12], instr_in[20], instr_in[30:21], 1'b0}; // J-type (jal)

	// Seleção do imediato baseado no opcode
	wire [31:0] decoded_imm;
	always @(*) begin
		case (opcode)
			7'b0010011: decoded_imm = imm_i; // I-type: ADDI, SLTI, SLTUI, XORI, ORI, ANDI, SLLI, SRLI, SRAI
			7'b0000011: decoded_imm = imm_i; // I-type: LB, LH, LW, LBU, LHU
			7'b1100111: decoded_imm = imm_i; // I-type: JALR
			7'b0100011: decoded_imm = imm_s; // S-type: SB, SH, SW
			7'b1100011: decoded_imm = imm_b; // B-type: BEQ, BNE, BLT, BGE, BLTU, BGEU
			7'b0110111: decoded_imm = imm_u; // U-type: LUI
			7'b0010111: decoded_imm = imm_u; // U-type: AUIPC
			7'b1101111: decoded_imm = imm_j; // J-type: JAL
			default:    decoded_imm = 32'b0; // Valor padrão para opcodes não reconhecidos
		endcase
	end
	
	// banco de registradores
	wire [31:0] rs1_data, rs2_data;
	
	reg_file u_reg_file (
		.clk       (clk),
		.we        (reg_write_en),
		.rs1_addr  (rs1),
		.rs2_addr  (rs2),
		.rd_addr   (reg_write_addr),
		.rd_data   (reg_write_data),
		.rs1_data  (rs1_data),
		.rs2_data  (rs2_data)
	);
	
	// registradores de pipeline ID/EX
	always @(posedge clk) begin
		if (rst) begin
			id_ex_pc       <= 0;   
			id_ex_pc_4     <= 0;
			id_ex_rs1_data <= 0;
			id_ex_rs2_data <= 0;
			id_ex_rd       <= 0;
			id_ex_rs1      <= 0;
			id_ex_rs2      <= 0;
			id_ex_funct3   <= 0;
			id_ex_funct7   <= 0;
			id_ex_opcode   <= 0;
			id_ex_imm      <= 0;
		end else begin
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
			id_ex_imm      <= decoded_imm; // Agora usa o imediato decodificado
		end
	end

endmodule