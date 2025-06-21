module id_stage (
    input wire clk, rst,
    input wire [31:0] if_id_pc_in, if_id_pc_4_in, if_id_instr_in,
    input wire ex_mem_mem_read_en_in, input wire [4:0]  ex_mem_rd_in,
    input wire branch_taken_from_ex_in, input wire mem_wb_reg_write_en_in,
    input wire [4:0]  mem_wb_rd_in, input wire [31:0] mem_wb_write_data_in,
    output wire pc_write_en_out, if_id_write_en_out,
    output reg [31:0] id_ex_pc_out, id_ex_pc_4_out, id_ex_rs1_data_out, id_ex_rs2_data_out, id_ex_imm_out,
    output reg [4:0]  id_ex_rd_out, id_ex_rs1_out, id_ex_rs2_out,
    output reg [2:0]  id_ex_funct3_out,
    output reg [6:0]  id_ex_funct7_out, id_ex_opcode_out
);
    wire [4:0] rs1 = if_id_instr_in[19:15]; wire [4:0] rs2 = if_id_instr_in[24:20];
    wire [4:0] rd  = if_id_instr_in[11:7]; wire [2:0] funct3 = if_id_instr_in[14:12];
    wire [6:0] funct7 = if_id_instr_in[31:25]; wire [6:0] opcode = if_id_instr_in[6:0];
    wire load_use_hazard;
    assign load_use_hazard = ex_mem_mem_read_en_in && (ex_mem_rd_in != 0) && ((ex_mem_rd_in == rs1) || (ex_mem_rd_in == rs2));
    assign pc_write_en_out = ~load_use_hazard; assign if_id_write_en_out = ~load_use_hazard;
    reg [31:0] decoded_imm;
    always @(*) begin
        case (opcode)
            7'b0010011, 7'b0000011, 7'b1100111: decoded_imm = {{20{if_id_instr_in[31]}}, if_id_instr_in[31:20]};
            7'b0100011: decoded_imm = {{20{if_id_instr_in[31]}}, if_id_instr_in[31:25], if_id_instr_in[11:7]};
            7'b1100011: decoded_imm = {{20{if_id_instr_in[31]}}, if_id_instr_in[7], if_id_instr_in[30:25], if_id_instr_in[11:8], 1'b0};
            7'b0110111, 7'b0010111: decoded_imm = {if_id_instr_in[31:12], 12'b0};
            7'b1101111: decoded_imm = {{12{if_id_instr_in[31]}}, if_id_instr_in[19:12], if_id_instr_in[20], if_id_instr_in[30:21], 1'b0};
            default:    decoded_imm = 32'b0;
        endcase
    end
    wire [31:0] rs1_data, rs2_data;
    reg_file u_reg_file (.clk(clk), .we(mem_wb_reg_write_en_in), .rs1_addr(rs1), .rs2_addr(rs2), .rd_addr(mem_wb_rd_in), .rd_data(mem_wb_write_data_in), .rs1_data(rs1_data), .rs2_data(rs2_data));
    always @(posedge clk) begin
        if (rst) begin id_ex_pc_out <= 0; id_ex_pc_4_out <= 0; id_ex_rs1_data_out <= 0; id_ex_rs2_data_out <= 0; id_ex_rd_out <= 0; id_ex_rs1_out <= 0; id_ex_rs2_out <= 0; id_ex_funct3_out <= 0; id_ex_funct7_out <= 0; id_ex_opcode_out <= 32'h13; id_ex_imm_out <= 0;
        end else if (load_use_hazard || branch_taken_from_ex_in) begin id_ex_pc_out <= 0; id_ex_pc_4_out <= 0; id_ex_rs1_data_out <= 0; id_ex_rs2_data_out <= 0; id_ex_rd_out <= 0; id_ex_rs1_out <= 0; id_ex_rs2_out <= 0; id_ex_funct3_out <= 0; id_ex_funct7_out <= 0; id_ex_opcode_out <= 32'h13; id_ex_imm_out <= 0;
        end else begin
            id_ex_pc_out <= if_id_pc_in; id_ex_pc_4_out <= if_id_pc_4_in; id_ex_rs1_data_out <= rs1_data; id_ex_rs2_data_out <= rs2_data; id_ex_rd_out <= rd; id_ex_rs1_out <= rs1; id_ex_rs2_out <= rs2; id_ex_funct3_out <= funct3; id_ex_funct7_out <= funct7; id_ex_opcode_out <= opcode; id_ex_imm_out <= decoded_imm;
        end
    end
endmodule