module ex_stage (
    input wire clk, rst,
    input wire [31:0] id_ex_pc, id_ex_pc_4, id_ex_rs1_data, id_ex_rs2_data, id_ex_imm,
    input wire [4:0]  id_ex_rd, id_ex_rs1, id_ex_rs2,
    input wire [2:0]  id_ex_funct3,
    input wire [6:0]  id_ex_funct7, id_ex_opcode,
    input wire [4:0]  ex_mem_rd_in, input wire [31:0] ex_mem_alu_result_in,
    input wire        ex_mem_reg_write_en_in,
    input wire [4:0]  mem_wb_rd_in, input wire        mem_wb_reg_write_en_in,
    input wire [31:0] mem_wb_write_data_in,
    output reg [31:0] ex_mem_pc, ex_mem_pc_4, ex_mem_alu_result, ex_mem_rs2_data,
    output reg [4:0]  ex_mem_rd,
    output reg [2:0]  ex_mem_funct3,
    output reg [6:0]  ex_mem_opcode,
    output reg        ex_mem_mem_write_en, ex_mem_mem_read_en, ex_mem_reg_write_en,
    output reg [1:0]  ex_mem_mem_to_reg_sel,
    output wire [31:0] branch_target,
    output wire        branch_taken
);
    reg [3:0] alu_ctrl_code; reg branch_condition;
    reg [31:0] alu_op1_forwarded, alu_op2_forwarded, alu_op2_original;
    wire [31:0] alu_result_wire, calculated_branch_target;
    wire [1:0] forward_a_ctrl, forward_b_ctrl;
    wire current_reg_write_en;
    forwarding_unit u_forwarding ( .id_ex_rs1(id_ex_rs1), .id_ex_rs2(id_ex_rs2), .ex_mem_rd_in(ex_mem_rd_in), .ex_mem_reg_write_en_in(ex_mem_reg_write_en_in), .mem_wb_rd_in(mem_wb_rd_in), .mem_wb_reg_write_en_in(mem_wb_reg_write_en_in), .forward_a(forward_a_ctrl), .forward_b(forward_b_ctrl) );
    always @(*) begin
        case (forward_a_ctrl) 2'b00: alu_op1_forwarded = id_ex_rs1_data; 2'b01: alu_op1_forwarded = ex_mem_alu_result_in; 2'b10: alu_op1_forwarded = mem_wb_write_data_in; default: alu_op1_forwarded = 32'b0; endcase
    end
    always @(*) begin
        case (id_ex_opcode) 7'b0110011, 7'b1100011: alu_op2_original = id_ex_rs2_data; default: alu_op2_original = id_ex_imm; endcase
    end
    always @(*) begin
        case (forward_b_ctrl) 2'b00: alu_op2_forwarded = alu_op2_original; 2'b01: alu_op2_forwarded = ex_mem_alu_result_in; 2'b10: alu_op2_forwarded = mem_wb_write_data_in; default: alu_op2_forwarded = 32'b0; endcase
    end
    always @(*) begin
        case (id_ex_opcode)
            7'b0110011: case (id_ex_funct3) 3'b000: alu_ctrl_code=(id_ex_funct7==7'b0100000)?4'b0001:4'b0000; 3'b001: alu_ctrl_code=4'b0010; 3'b010: alu_ctrl_code=4'b0011; 3'b011: alu_ctrl_code=4'b0100; 3'b100: alu_ctrl_code=4'b0101; 3'b101: alu_ctrl_code=(id_ex_funct7==7'b0100000)?4'b0111:4'b0110; 3'b110: alu_ctrl_code=4'b1000; 3'b111: alu_ctrl_code=4'b1001; default: alu_ctrl_code=4'b0; endcase
            7'b0010011: case (id_ex_funct3) 3'b000: alu_ctrl_code=4'b0; 3'b001: alu_ctrl_code=4'b0010; 3'b010: alu_ctrl_code=4'b0011; 3'b011: alu_ctrl_code=4'b0100; 3'b100: alu_ctrl_code=4'b0101; 3'b101: alu_ctrl_code=(id_ex_funct7==7'b0100000)?4'b0111:4'b0110; 3'b110: alu_ctrl_code=4'b1000; 3'b111: alu_ctrl_code=4'b1001; default: alu_ctrl_code=4'b0; endcase
            7'b0000011, 7'b0100011, 7'b1101111, 7'b1100111, 7'b0110111, 7'b0010111: alu_ctrl_code=4'b0;
            7'b1100011: alu_ctrl_code = 4'b0001; default: alu_ctrl_code = 4'b0;
        endcase
    end
    alu u_alu ( .operand_a(alu_op1_forwarded), .operand_b(alu_op2_forwarded), .alu_control(alu_ctrl_code), .result(alu_result_wire) );
    assign calculated_branch_target = id_ex_pc + id_ex_imm;
    always @(*) begin
        branch_condition = 1'b0;
        if (id_ex_opcode == 7'b1100011) case (id_ex_funct3) 3'b000: branch_condition=(alu_result_wire==0); 3'b001: branch_condition=(alu_result_wire!=0); 3'b100: branch_condition=($signed(id_ex_rs1_data) < $signed(id_ex_rs2_data)); 3'b101: branch_condition=($signed(id_ex_rs1_data) >= $signed(id_ex_rs2_data)); 3'b110: branch_condition=(id_ex_rs1_data < id_ex_rs2_data); 3'b111: branch_condition=(id_ex_rs1_data >= id_ex_rs2_data); default: branch_condition=0; endcase
    end
    assign branch_taken  = branch_condition || id_ex_opcode == 7'b1101111 || id_ex_opcode == 7'b1100111;
    assign branch_target = (id_ex_opcode == 7'b1100111) ? ((id_ex_rs1_data + id_ex_imm) & 32'hFFFFFFFE) : calculated_branch_target;
    reg mem_write_en_next, mem_read_en_next, reg_write_en_next; reg [1:0] mem_to_reg_sel_next;
    assign current_reg_write_en = reg_write_en_next;
    always @(*) begin
        mem_write_en_next=0; mem_read_en_next=0; reg_write_en_next=0; mem_to_reg_sel_next=0;
        case (id_ex_opcode) 7'b0110011, 7'b0010011, 7'b0110111, 7'b0010111: begin reg_write_en_next=1; mem_to_reg_sel_next=0; end
            7'b0000011: begin mem_read_en_next=1; reg_write_en_next=1; mem_to_reg_sel_next=1; end
            7'b0100011: mem_write_en_next=1;
            7'b1101111, 7'b1100111: begin reg_write_en_next=1; mem_to_reg_sel_next=2; end
        endcase
    end
    always @(posedge clk) begin
        if (rst) begin ex_mem_pc<=0; ex_mem_pc_4<=0; ex_mem_alu_result<=0; ex_mem_rs2_data<=0; ex_mem_rd<=0; ex_mem_funct3<=0; ex_mem_opcode<=0; ex_mem_mem_write_en<=0; ex_mem_mem_read_en<=0; ex_mem_reg_write_en<=0; ex_mem_mem_to_reg_sel<=0;
        end else begin
            ex_mem_pc<=id_ex_pc; ex_mem_pc_4<=id_ex_pc_4; ex_mem_alu_result<=alu_result_wire; ex_mem_rs2_data<=id_ex_rs2_data; ex_mem_rd<=id_ex_rd; ex_mem_funct3<=id_ex_funct3; ex_mem_opcode<=id_ex_opcode;
            ex_mem_mem_write_en<=mem_write_en_next; ex_mem_mem_read_en<=mem_read_en_next; ex_mem_reg_write_en<=reg_write_en_next; ex_mem_mem_to_reg_sel<=mem_to_reg_sel_next;
        end
    end
endmodule