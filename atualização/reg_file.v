module reg_file (
	input wire clk, we,
	input wire [4:0]  rs1_addr, rs2_addr, rd_addr,
	input wire [31:0] rd_data,
	output wire [31:0] rs1_data, rs2_data
);
	reg [31:0] regs [0:31];
    integer i;
    initial for (i = 0; i < 32; i = i + 1) regs[i] = 0;
	assign rs1_data = (rs1_addr != 0) ? regs[rs1_addr] : 32'b0;
	assign rs2_data = (rs2_addr != 0) ? regs[rs2_addr] : 32'b0;
	always @(posedge clk) if (we && rd_addr != 0) regs[rd_addr] <= rd_data;
endmodule