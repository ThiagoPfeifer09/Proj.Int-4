module ex_stage (
    input wire        clk,
    input wire        rst,

    // Entradas do registrador ID/EX
    input wire [31:0] id_ex_pc,
    input wire [31:0] id_ex_pc_4,
    input wire [31:0] id_ex_rs1_data,
    input wire [31:0] id_ex_rs2_data,
    input wire [4:0]  id_ex_rd,
    input wire [4:0]  id_ex_rs1,
    input wire [4:0]  id_ex_rs2,
    input wire [2:0]  id_ex_funct3,
    input wire [6:0]  id_ex_funct7,
    input wire [6:0]  id_ex_opcode,
    input wire [31:0] id_ex_imm,

    // Entradas para Forwarding (feedback dos estágios futuros)
    input wire [4:0]  ex_mem_rd_in,
    input wire        ex_mem_reg_write_en_in,
    input wire [31:0] ex_mem_alu_result_in,
    input wire [4:0]  mem_wb_rd_in,
    input wire        mem_wb_reg_write_en_in,
    input wire [31:0] mem_wb_write_data_in,

    // Saídas para o próximo estágio (EX/MEM)
    output reg [31:0] ex_mem_pc,
    output reg [31:0] ex_mem_pc_4,
    output reg [31:0] ex_mem_alu_result,
    output reg [31:0] ex_mem_rs2_data,
    output reg [4:0]  ex_mem_rd,
    output reg [2:0]  ex_mem_funct3,
    output reg [6:0]  ex_mem_opcode,
    output reg        ex_mem_mem_write_en,
    output reg        ex_mem_mem_read_en,
    output reg        ex_mem_reg_write_en,
    output reg [1:0]  ex_mem_mem_to_reg_sel,

    // Saídas de controle de branch/jump
    output wire [31:0] branch_target,
    output wire        branch_taken
);

   // Sinais internos combinacionais (devem ser 'reg' se atribuídos em 'always')
    reg  [3:0]  alu_ctrl_code;
    reg         branch_condition;
    reg  [31:0] alu_op1_forwarded;
    reg  [31:0] alu_op2_forwarded;
    reg  [31:0] alu_op2_original;
    
    // Fios para saídas de módulos e lógica 'assign'
    wire [31:0] alu_result_wire;
    wire [31:0] calculated_branch_target;
    wire [1:0]  forward_a_ctrl;
    wire [1:0]  forward_b_ctrl;
    wire        current_reg_write_en;

    // Instância da Unidade de Forwarding
    forwarding_unit u_forwarding (
        .id_ex_rs1(id_ex_rs1),
        .id_ex_rs2(id_ex_rs2),
        .ex_mem_rd(ex_mem_rd_in),                 // Conexão corrigida
        .ex_mem_reg_write_en(ex_mem_reg_write_en_in), // Conexão corrigida
        .mem_wb_rd(mem_wb_rd_in),
        .mem_wb_reg_write_en(mem_wb_reg_write_en_in),
        .forward_a(forward_a_ctrl),
        .forward_b(forward_b_ctrl)
    );

    // Seleção de Operandos para a ALU com Forwarding (sem loop combinacional)
    always @(*) begin
        case (forward_a_ctrl)
            2'b00: alu_op1_forwarded = id_ex_rs1_data;
            2'b01: alu_op1_forwarded = ex_mem_alu_result_in;
            2'b10: alu_op1_forwarded = mem_wb_write_data_in;
            default: alu_op1_forwarded = 32'b0;
        endcase
    end
	always @(*) begin
        case (id_ex_opcode)
            7'b0110011: alu_op2_original = id_ex_rs2_data;
            7'b1100011: alu_op2_original = id_ex_rs2_data;
            default:    alu_op2_original = id_ex_imm;
        endcase
    end

    always @(*) begin
        case (forward_b_ctrl)
            2'b00: alu_op2_forwarded = alu_op2_original;
            2'b01: alu_op2_forwarded = ex_mem_alu_result_in;
            2'b10: alu_op2_forwarded = mem_wb_write_data_in;
            default: alu_op2_forwarded = 32'b0;
        endcase
    end

    // Controle da ALU
    always @(*) begin
        case (id_ex_opcode)
            7'b0110011: begin // Tipo - R
                case (id_ex_funct3)
                    3'b000: alu_ctrl_code = (id_ex_funct7 == 7'b0100000) ? 4'b0001 : 4'b0000;
                    3'b001: alu_ctrl_code = 4'b0010;
                    3'b010: alu_ctrl_code = 4'b0011;
                    3'b011: alu_ctrl_code = 4'b0100;
                    3'b100: alu_ctrl_code = 4'b0101;
                    3'b101: alu_ctrl_code = (id_ex_funct7 == 7'b0100000) ? 4'b0111 : 4'b0110;
                    3'b110: alu_ctrl_code = 4'b1000;
                    3'b111: alu_ctrl_code = 4'b1001;
                    default: alu_ctrl_code = 4'b0000;
                endcase
            end
            7'b0010011: begin //  Tipo - I
                case (id_ex_funct3)
                    3'b000: alu_ctrl_code = 4'b0000;
                    3'b001: alu_ctrl_code = 4'b0010;
                    3'b010: alu_ctrl_code = 4'b0011;
                    3'b011: alu_ctrl_code = 4'b0100;
                    3'b100: alu_ctrl_code = 4'b0101;
                    3'b101: alu_ctrl_code = (id_ex_funct7 == 7'b0100000) ? 4'b0111 : 4'b0110;
                    3'b110: alu_ctrl_code = 4'b1000;
                    3'b111: alu_ctrl_code = 4'b1001;
                    default: alu_ctrl_code = 4'b0000;
                endcase
            end
            7'b0000011: alu_ctrl_code = 4'b0000; // LOAD
            7'b0100011: alu_ctrl_code = 4'b0000; // STORE
            7'b1100011: alu_ctrl_code = 4'b0001; // B-type
            7'b1101111: alu_ctrl_code = 4'b0000; // JAL
            7'b1100111: alu_ctrl_code = 4'b0000; // JALR
            7'b0110111: alu_ctrl_code = 4'b0000; // LUI
            7'b0010111: alu_ctrl_code = 4'b0000; // AUIPC
            default:    alu_ctrl_code = 4'b0000;
        endcase
    end

   // Instância da ALU
    alu u_alu (
        .operand_a  (alu_op1_forwarded),
        .operand_b  (alu_op2_forwarded),
        .alu_control(alu_ctrl_code),
        .result     (alu_result_wire)
    );

    // Lógica de Branch/Jump
   assign calculated_branch_target = id_ex_pc + id_ex_imm;
    always @(*) begin
        branch_condition = 1'b0;
        case (id_ex_opcode)
            7'b1100011: begin // B-type
                case (id_ex_funct3)
                    3'b000: branch_condition = (alu_result_wire == 32'b0);
                    3'b001: branch_condition = (alu_result_wire != 32'b0);
                    3'b100: branch_condition = ($signed(id_ex_rs1_data) < $signed(id_ex_rs2_data));
                    3'b101: branch_condition = ($signed(id_ex_rs1_data) >= $signed(id_ex_rs2_data));
                    3'b110: branch_condition = (id_ex_rs1_data < id_ex_rs2_data);
                    3'b111: branch_condition = (id_ex_rs1_data >= id_ex_rs2_data);
                    default: branch_condition = 1'b0;
                endcase
            end
            default: branch_condition = 1'b0;
        endcase
    end
    assign branch_taken  = branch_condition || (id_ex_opcode == 7'b1101111) || (id_ex_opcode == 7'b1100111);
    assign branch_target = (id_ex_opcode == 7'b1101111) ? calculated_branch_target :
                           (id_ex_opcode == 7'b1100111) ? (id_ex_rs1_data + id_ex_imm) & 32'hFFFFFFFE :
                           calculated_branch_target;

   // Geração combinacional dos sinais de controle para o próximo estágio
    reg        mem_write_en_next;
    reg        mem_read_en_next;
    reg        reg_write_en_next;
    reg [1:0]  mem_to_reg_sel_next;
    assign current_reg_write_en = reg_write_en_next;
    always @(*) begin
        // Valores padrão
        mem_write_en_next   = 1'b0;
        mem_read_en_next    = 1'b0;
        reg_write_en_next   = 1'b0;
        mem_to_reg_sel_next = 2'b00;

        case (id_ex_opcode)
            7'b0110011: begin reg_write_en_next = 1'b1; mem_to_reg_sel_next = 2'b00; end // R-type
            7'b0010011: begin reg_write_en_next = 1'b1; mem_to_reg_sel_next = 2'b00; end // I-type (ADDI, etc.)
            7'b0000011: begin mem_read_en_next = 1'b1; reg_write_en_next = 1'b1; mem_to_reg_sel_next = 2'b01; end // I-type (LOAD)
            7'b0100011: begin mem_write_en_next = 1'b1; end // S-type (STORE)
            7'b1100011: begin end // B-type (BRANCH)
            7'b1101111: begin reg_write_en_next = 1'b1; mem_to_reg_sel_next = 2'b10; end // J-type (JAL)
            7'b1100111: begin reg_write_en_next = 1'b1; mem_to_reg_sel_next = 2'b10; end // I-type (JALR)
            7'b0110111: begin reg_write_en_next = 1'b1; mem_to_reg_sel_next = 2'b00; end // U-type (LUI)
            7'b0010111: begin reg_write_en_next = 1'b1; mem_to_reg_sel_next = 2'b00; end // U-type (AUIPC)
        endcase
    end

    // Registradores de Pipeline EX/MEM
    always @(posedge clk) begin
        if (rst) begin
            ex_mem_pc           <= 0;
            ex_mem_pc_4         <= 0;
            ex_mem_alu_result   <= 0;
            ex_mem_rs2_data     <= 0;
            ex_mem_rd           <= 0;
            ex_mem_funct3       <= 0;
            ex_mem_opcode       <= 0;
            ex_mem_mem_write_en <= 1'b0;
            ex_mem_mem_read_en  <= 1'b0;
            ex_mem_reg_write_en <= 1'b0;
            ex_mem_mem_to_reg_sel <= 2'b00;
		end else begin
            // Lógica síncrona completa e
            ex_mem_pc           <= id_ex_pc;
            ex_mem_pc_4         <= id_ex_pc_4;
            ex_mem_alu_result   <= alu_result_wire;
            ex_mem_rs2_data     <= id_ex_rs2_data;
            ex_mem_rd           <= id_ex_rd;
            ex_mem_funct3       <= id_ex_funct3;
            ex_mem_opcode       <= id_ex_opcode;
            ex_mem_mem_write_en <= mem_write_en_next;
            ex_mem_mem_read_en  <= mem_read_en_next;
            ex_mem_reg_write_en <= reg_write_en_next;
            ex_mem_mem_to_reg_sel <= mem_to_reg_sel_next;
        end
    end

endmodule