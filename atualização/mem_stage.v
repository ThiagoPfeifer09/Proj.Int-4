module mem_stage (
    input wire clk, rst,
    input wire [31:0] ex_mem_pc, ex_mem_pc_4, ex_mem_alu_result, ex_mem_rs2_data, mem_read_data,
    input wire [4:0]  ex_mem_rd, input wire [2:0]  ex_mem_funct3, input wire [6:0]  ex_mem_opcode,
    input wire ex_mem_mem_write_en, ex_mem_mem_read_en, ex_mem_reg_write_en,
    input wire [1:0]  ex_mem_mem_to_reg_sel,
    output wire [31:0] mem_addr, mem_write_data,
    output wire mem_write_byte_en, mem_write_half_en, mem_write_word_en,
    output reg [31:0] mem_wb_pc_4, mem_wb_alu_result, mem_wb_mem_read_data,
    output reg [4:0]  mem_wb_rd,
    output reg mem_wb_reg_write_en,
    output reg [1:0]  mem_wb_mem_to_reg_sel
);
    assign mem_addr = ex_mem_alu_result; assign mem_write_data = ex_mem_rs2_data;
    assign mem_write_byte_en  = ex_mem_mem_write_en && (ex_mem_funct3 == 3'b0);
    assign mem_write_half_en  = ex_mem_mem_write_en && (ex_mem_funct3 == 3'b1);
    assign mem_write_word_en  = ex_mem_mem_write_en && (ex_mem_funct3 == 3'b10);
    always @(posedge clk) begin
        if (rst) begin mem_wb_pc_4<=0; mem_wb_alu_result<=0; mem_wb_mem_read_data<=0; mem_wb_rd<=0; mem_wb_reg_write_en<=0; mem_wb_mem_to_reg_sel<=0;
        end else begin
            mem_wb_pc_4 <= ex_mem_pc_4; mem_wb_alu_result <= ex_mem_alu_result; mem_wb_rd <= ex_mem_rd;
            if(ex_mem_mem_read_en) case(ex_mem_funct3) 3'b0:mem_wb_mem_read_data<={{24{mem_read_data[7]}},mem_read_data[7:0]}; 3'b1:mem_wb_mem_read_data<={{16{mem_read_data[15]}},mem_read_data[15:0]}; 3'b10:mem_wb_mem_read_data<=mem_read_data; 3'b100:mem_wb_mem_read_data<={{24{1'b0}},mem_read_data[7:0]}; 3'b101:mem_wb_mem_read_data<={{16{1'b0}},mem_read_data[15:0]}; default:mem_wb_mem_read_data<=mem_read_data; endcase
            else mem_wb_mem_read_data <= 32'b0;
            mem_wb_reg_write_en <= ex_mem_reg_write_en; mem_wb_mem_to_reg_sel <= ex_mem_mem_to_reg_sel;
        end
    end
endmodule