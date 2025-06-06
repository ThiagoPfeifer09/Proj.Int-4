module id_stage {
	input wire        clk,
	input wire        rst,
	input wire [31:0] instr_in,    //vindo do if_id_instr
	input wire [31:0] pc_4_in,     //vindo do if_id_pc_4
	
	//para a escrita no banco de registradores (vindo da WB)
	input wire        reg_write_en,
	input wire [4:0]  reg_write_addr,
	input wire [31:0] reg_write_data,
	
	//saidas para o próximo estagio (ID/EX)
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

	//extração dos campos
	wire [4:0] rs1    = instr_in[19:15];
	wire [4:0] rs2    = instr_in[24:20];
	wire [4:0] rd     = instr_in[11:7];
	wire [2:0] funct3 = instr_in[14:12];
	wire [6:0] funct7 = instr_in[31:25];
	wire [6:0] opcode = instr_in[6:0];
	
	//decodifica imediato (só para tipo I por enquanto)
	wire [31:0] imm_i = {{20{instr_in[31]}}, instr_in[31:20]}; //sinal extendido
	
	//banco de registradores
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
	
	//registradores de pipeline ID/EX
	always @(posedge clk) begin
		if (rst) begin
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
			id_ex_pc_4     <= pc_4_in;
            id_ex_rs1_data <= rs1_data;
            id_ex_rs2_data <= rs2_data;
            id_ex_rd       <= rd;
            id_ex_rs1      <= rs1;
            id_ex_rs2      <= rs2;
            id_ex_funct3   <= funct3;
            id_ex_funct7   <= funct7
            id_ex_opcode   <= opcode;
            id_ex_imm      <= imm_i //por enquanto só tipo I
		end
	end
endmodule