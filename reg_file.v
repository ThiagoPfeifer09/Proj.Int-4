module reg_file (
	input wire         clk,
	input wire         we, //write enable
	input wire  [4:0]  rs1_addr,
	input wire  [4:0]  rs2_addr,
	input wire  [4:0]  rd_addr,
	input wire  [31:0] rd_data,
	output wire [31:0] rs1_data,
	output wire [31:0] rs2_data
);

	reg [31:0] regs [0:31];
	
	//leitura combinacional
	assign rs1_data = (rs1_addr != 0) ? regs[rs1_addr] : 32'b0;
	assign rs2_data = (rs2_addr != 0) ? regs[rs2_addr] : 32'b0;
	
	//escrita síncrona
	always @(posedge clk) begin 
		if (we && rd_addr != 0)
			regs[rd_addr] <= rd_data;
	end
endmodule
