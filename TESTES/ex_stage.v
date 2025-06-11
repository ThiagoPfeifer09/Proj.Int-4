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

    // Sa�das para o pr�ximo est�gio (EX/MEM)
    output reg [31:0] ex_mem_pc,
    output reg [31:0] ex_mem_pc_4,
    output reg [31:0] ex_mem_alu_result,
    output reg [31:0] ex_mem_rs2_data, // Para opera��es de store
    output reg [4:0]  ex_mem_rd,
    output reg [2:0]  ex_mem_funct3, // Pode ser �til para MEM (load/store byte/halfword)
    output reg [6:0]  ex_mem_opcode,
    
    // Sinais de controle para o est�gio MEM/WB (exemplo: escrita em mem�ria, habilita��o de escrita em registrador)
    output reg        ex_mem_mem_write_en,
    output reg        ex_mem_mem_read_en,
    output reg        ex_mem_reg_write_en,
    output reg [1:0]  ex_mem_mem_to_reg_sel, // Seleciona a origem do dado a ser escrito no registrador

    // Sinais para controle de branch/jump (feedback para o IF)
    output wire [31:0] branch_target,
    output wire        branch_taken
);

    // Sinais internos para a ALU
    wire [31:0] alu_op1;
    wire [31:0] alu_op2;
    wire [3:0]  alu_ctrl_code; // C�digo de controle para a ALU
    wire [31:0] alu_result_wire; // Sa�da da ALU

    // Sinais para branch/jump
    wire        branch_condition;
    wire [31:0] calculated_branch_target;

    // --- Controle da ALU ---
    // Determina qual opera��o a ALU deve realizar com base no opcode e funct3/funct7
    always @(*) begin
        case (id_ex_opcode)
            7'b0110011: begin // Tipo - R
                case (id_ex_funct3)
                    3'b000: alu_ctrl_code = (id_ex_funct7 == 7'b0100000) ? 4'b0001 : 4'b0000; // SUB (0100000) ou ADD (0000000)
                    3'b001: alu_ctrl_code = 4'b0010; // SLL
                    3'b010: alu_ctrl_code = 4'b0011; // SLT
                    3'b011: alu_ctrl_code = 4'b0100; // SLTU
                    3'b100: alu_ctrl_code = 4'b0101; // XOR
                    3'b101: alu_ctrl_code = (id_ex_funct7 == 7'b0100000) ? 4'b0111 : 4'b0110; // SRA (0100000) ou SRL (0000000)
                    3'b110: alu_ctrl_code = 4'b1000; // OR
                    3'b111: alu_ctrl_code = 4'b1001; // AND
                    default: alu_ctrl_code = 4'b0000; // Default para ADD
                endcase
            end
            7'b0010011: begin //  Tipo - I
                case (id_ex_funct3)
                    3'b000: alu_ctrl_code = 4'b0000; // ADDI
                    3'b001: alu_ctrl_code = 4'b0010; // SLLI
                    3'b010: alu_ctrl_code = 4'b0011; // SLTI
                    3'b011: alu_ctrl_code = 4'b0100; // SLTUI
                    3'b100: alu_ctrl_code = 4'b0101; // XORI
                    3'b101: alu_ctrl_code = (id_ex_funct7 == 7'b0100000) ? 4'b0111 : 4'b0110; // SRAI ou SRLI
                    3'b110: alu_ctrl_code = 4'b1000; // ORI
                    3'b111: alu_ctrl_code = 4'b1001; // ANDI
                    default: alu_ctrl_code = 4'b0000;
                endcase
            end
            7'b0000011: alu_ctrl_code = 4'b0000; // I-type (LOAD: LB, LH, LW, LBU, LHU) - Calcula endere�o: rs1_data + imm
            7'b0100011: alu_ctrl_code = 4'b0000; // S-type (STORE: SB, SH, SW) - Calcula endere�o: rs1_data + imm
            7'b1100011: alu_ctrl_code = 4'b0001; // B-type (Branch: BEQ, BNE, BLT, BGE, BLTU, BGEU) - Compara rs1_data e rs2_data (SUB)
            7'b1101111: alu_ctrl_code = 4'b0000; // J-type (JAL) - N�o usa ALU para c�lculo de resultado (PC + imm)
            7'b1100111: alu_ctrl_code = 4'b0000; // I-type (JALR) - N�o usa ALU para c�lculo de resultado (rs1_data + imm)
            7'b0110111: alu_ctrl_code = 4'b0000; // U-type (LUI) - N�o usa ALU para c�lculo de resultado (imm)
            7'b0010111: alu_ctrl_code = 4'b0000; // U-type (AUIPC) - PC + imm
            default:    alu_ctrl_code = 4'b0000; // Default: ADD
        endcase
    end

    // --- Sele��o de Operandos para a ALU ---
    // alu_op1 � sempre o dado de rs1
    assign alu_op1 = id_ex_rs1_data;

    // alu_op2 depende do tipo de instru��o (rs2_data ou imediato)
    always @(*) begin
        case (id_ex_opcode)
            7'b0110011: alu_op2 = id_ex_rs2_data; // R-type: rs2_data
            7'b0010011: alu_op2 = id_ex_imm;      // I-type: imediato
            7'b0000011: alu_op2 = id_ex_imm;      // LOAD: imediato
            7'b0100011: alu_op2 = id_ex_imm;      // STORE: imediato
            7'b1100011: alu_op2 = id_ex_rs2_data; // BRANCH: rs2_data (para compara��o)
            7'b1101111: alu_op2 = id_ex_imm;      // JAL: imediato (para c�lculo de PC_target)
            7'b1100111: alu_op2 = id_ex_imm;      // JALR: imediato (para c�lculo de PC_target)
            7'b0110111: alu_op2 = id_ex_imm;      // LUI: imediato
            7'b0010111: alu_op2 = id_ex_imm;      // AUIPC: imediato
            default:    alu_op2 = 32'b0;
        endcase
    end
    
    // --- Inst�ncia da ALU ---
    // Voc� precisar� criar um m�dulo `alu.v` separadamente
    alu u_alu (
        .operand_a  (alu_op1),
        .operand_b  (alu_op2),
        .alu_control(alu_ctrl_code),
        .result     (alu_result_wire)
    );

    // --- L�gica de Branch/Jump ---
    // C�lculo do endere�o de destino do branch/jump
    assign calculated_branch_target = id_ex_pc + id_ex_imm;

    // Condi��o de branch
    always @(*) begin
        branch_condition = 1'b0; // Default: branch n�o tomado
        case (id_ex_opcode)
            7'b1100011: begin // B-type
                case (id_ex_funct3)
                    3'b000: branch_condition = (alu_result_wire == 32'b0); // BEQ (rs1 == rs2)
                    3'b001: branch_condition = (alu_result_wire != 32'b0); // BNE (rs1 != rs2)
                    3'b100: branch_condition = ($signed(id_ex_rs1_data) < $signed(id_ex_rs2_data)); // BLT (rs1 < rs2, signed)
                    3'b101: branch_condition = ($signed(id_ex_rs1_data) >= $signed(id_ex_rs2_data)); // BGE (rs1 >= rs2, signed)
                    3'b110: branch_condition = (id_ex_rs1_data < id_ex_rs2_data); // BLTU (rs1 < rs2, unsigned)
                    3'b111: branch_condition = (id_ex_rs1_data >= id_ex_rs2_data); // BGEU (rs1 >= rs2, unsigned)
                    default: branch_condition = 1'b0;
                endcase
            end
            default: branch_condition = 1'b0;
        endcase
    end

    // Sinal para o IF de que um branch foi tomado e o target
    assign branch_taken  = branch_condition || (id_ex_opcode == 7'b1101111) || (id_ex_opcode == 7'b1100111); // Branch tomado, JAL ou JALR
    
    // Sele��o do target para JAL e JALR
    assign branch_target = (id_ex_opcode == 7'b1101111) ? calculated_branch_target : // JAL (PC + imm)
                           (id_ex_opcode == 7'b1100111) ? (id_ex_rs1_data + id_ex_imm) & 32'hFFFFFFFE : // JALR (rs1 + imm) & ~1 (garante alinhamento)
                           calculated_branch_target; // Branches (PC + imm)

    // --- Registradores de Pipeline EX/MEM e Sinais de Controle ---
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
            ex_mem_pc           <= id_ex_pc;
            ex_mem_pc_4         <= id_ex_pc_4;
            ex_mem_alu_result   <= alu_result_wire; // Resultado da ALU
            ex_mem_rs2_data     <= id_ex_rs2_data;  // Passa rs2_data para opera��es de store
            ex_mem_rd           <= id_ex_rd;
            ex_mem_funct3       <= id_ex_funct3;    // Passa funct3 para mem�ria (byte, halfword, word)
            ex_mem_opcode       <= id_ex_opcode;

            // L�gica de sinais de controle para o pr�ximo est�gio (MEM e WB)
            case (id_ex_opcode)
                7'b0110011: begin // R-type (ADD, SUB, etc.)
                    ex_mem_mem_write_en <= 1'b0;
                    ex_mem_mem_read_en  <= 1'b0;
                    ex_mem_reg_write_en <= 1'b1; // Escreve no registrador
                    ex_mem_mem_to_reg_sel <= 2'b00; // Resultado da ALU para o registrador
                end
                7'b0010011: begin // I-type (ADDI, etc.)
                    ex_mem_mem_write_en <= 1'b0;
                    ex_mem_mem_read_en  <= 1'b0;
                    ex_mem_reg_write_en <= 1'b1; // Escreve no registrador
                    ex_mem_mem_to_reg_sel <= 2'b00; // Resultado da ALU para o registrador
                end
                7'b0000011: begin // I-type (LOAD)
                    ex_mem_mem_write_en <= 1'b0;
                    ex_mem_mem_read_en  <= 1'b1; // Habilita leitura da mem�ria
                    ex_mem_reg_write_en <= 1'b1; // Escreve no registrador
                    ex_mem_mem_to_reg_sel <= 2'b01; // Resultado da mem�ria para o registrador
                end
                7'b0100011: begin // S-type (STORE)
                    ex_mem_mem_write_en <= 1'b1; // Habilita escrita na mem�ria
                    ex_mem_mem_read_en  <= 1'b0;
                    ex_mem_reg_write_en <= 1'b0; // N�o escreve no registrador
                    ex_mem_mem_to_reg_sel <= 2'b00; // Irrelevante
                end
                7'b1100011: begin // B-type (BRANCH)
                    ex_mem_mem_write_en <= 1'b0;
                    ex_mem_mem_read_en  <= 1'b0;
                    ex_mem_reg_write_en <= 1'b0; // N�o escreve no registrador
                    ex_mem_mem_to_reg_sel <= 2'b00; // Irrelevante
                end
                7'b1101111: begin // J-type (JAL)
                    ex_mem_mem_write_en <= 1'b0;
                    ex_mem_mem_read_en  <= 1'b0;
                    ex_mem_reg_write_en <= 1'b1; // Escreve PC + 4 no rd
                    ex_mem_mem_to_reg_sel <= 2'b10; // PC + 4 para o registrador
                end
                7'b1100111: begin // I-type (JALR)
                    ex_mem_mem_write_en <= 1'b0;
                    ex_mem_mem_read_en  <= 1'b0;
                    ex_mem_reg_write_en <= 1'b1; // Escreve PC + 4 no rd
                    ex_mem_mem_to_reg_sel <= 2'b10; // PC + 4 para o registrador
                end
                7'b0110111: begin // U-type (LUI)
                    ex_mem_mem_write_en <= 1'b0;
                    ex_mem_mem_read_en  <= 1'b0;
                    ex_mem_reg_write_en <= 1'b1; // Escreve no registrador
                    ex_mem_mem_to_reg_sel <= 2'b00; // Resultado da ALU (imm) para o registrador
                end
                7'b0010111: begin // U-type (AUIPC)
                    ex_mem_mem_write_en <= 1'b0;
                    ex_mem_mem_read_en  <= 1'b0;
                    ex_mem_reg_write_en <= 1'b1; // Escreve no registrador
                    ex_mem_mem_to_reg_sel <= 2'b00; // Resultado da ALU (PC + imm) para o registrador
                end
                default: begin
                    ex_mem_mem_write_en <= 1'b0;
                    ex_mem_mem_read_en  <= 1'b0;
                    ex_mem_reg_write_en <= 1'b0;
                    ex_mem_mem_to_reg_sel <= 2'b00;
                end
            endcase
        end
    end

endmodule

// --- M�dulo ALU (alu.v) ---
// Este m�dulo deve ser criado em um arquivo separado chamado `alu.v`
module alu (
    input wire [31:0] operand_a,
    input wire [31:0] operand_b,
    input wire [3:0]  alu_control, // Define a opera��o da ALU
    output reg [31:0] result
);

    always @(*) begin
        case (alu_control)
            4'b0000: result = operand_a + operand_b;       // ADD, ADDI (tamb�m para c�lculo de endere�o)
            4'b0001: result = operand_a - operand_b;       // SUB
            4'b0010: result = operand_a << operand_b[4:0]; // SLL, SLLI (apenas os 5 bits menos significativos para shift amount)
            4'b0011: result = ($signed(operand_a) < $signed(operand_b)) ? 32'd1 : 32'd0; // SLT, SLTI (set if less than, signed)
            4'b0100: result = (operand_a < operand_b) ? 32'd1 : 32'd0; // SLTU, SLTUI (set if less than, unsigned)
            4'b0101: result = operand_a ^ operand_b;       // XOR, XORI
            4'b0110: result = operand_a >> operand_b[4:0]; // SRL, SRLI (shift logical right)
            4'b0111: result = $signed(operand_a) >>> operand_b[4:0]; // SRA, SRAI (shift arithmetic right)
            4'b1000: result = operand_a | operand_b;       // OR, ORI
            4'b1001: result = operand_a & operand_b;       // AND, ANDI
            default: result = 32'b0;
        endcase
    end

endmodule