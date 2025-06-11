module mem_stage (
    input wire        clk,
    input wire        rst,

    // Entradas do registrador EX/MEM
    input wire [31:0] ex_mem_pc,           // PC da instrução (para debug ou JAL/JALR no WB)
    input wire [31:0] ex_mem_pc_4,         // PC + 4 (para JAL/JALR no WB)
    input wire [31:0] ex_mem_alu_result,   // Endereço para Load/Store ou resultado ALU para R/I-type
    input wire [31:0] ex_mem_rs2_data,     // Dados a serem escritos na memória (para Store)
    input wire [4:0]  ex_mem_rd,           // Registrador de destino
    input wire [2:0]  ex_mem_funct3,       // Para determinar o tamanho do acesso à memória (byte, half, word)
    input wire [6:0]  ex_mem_opcode,       // Opcode para controle

    // Sinais de controle do estágio EX
    input wire        ex_mem_mem_write_en,   // Habilita escrita na memória
    input wire        ex_mem_mem_read_en,    // Habilita leitura da memória
    input wire        ex_mem_reg_write_en,   // Habilita escrita no registrador (passa para WB)
    input wire [1:0]  ex_mem_mem_to_reg_sel, // Seleciona a origem do dado a ser escrito (passa para WB)

    // Interface com a memória de dados (Data Memory)
    output wire [31:0] mem_addr,         // Endereço para a memória
    output wire [31:0] mem_write_data,   // Dados a serem escritos
    output wire        mem_write_byte_en, // Habilita escrita de byte
    output wire        mem_write_half_en, // Habilita escrita de halfword
    output wire        mem_write_word_en, // Habilita escrita de word
    input wire [31:0]  mem_read_data,    // Dados lidos da memória

    // Saídas para o próximo estágio (MEM/WB)
    output reg [31:0] mem_wb_pc_4,         // Passa PC + 4 (para JAL/JALR)
    output reg [31:0] mem_wb_alu_result,   // Passa resultado da ALU (para R/I-type ou endereço de Load/Store)
    output reg [31:0] mem_wb_mem_read_data, // Dados lidos da memória
    output reg [4:0]  mem_wb_rd,           // Registrador de destino
    
    // Sinais de controle para o estágio WB
    output reg        mem_wb_reg_write_en,   // Habilita escrita no registrador
    output reg [1:0]  mem_wb_mem_to_reg_sel  // Seleciona a origem do dado a ser escrito
);

    // --- Interface com a Memória de Dados ---
    assign mem_addr = ex_mem_alu_result; // O resultado da ALU (endereço) é a entrada de endereço para a memória

    // Dados a serem escritos na memória são sempre rs2_data
    assign mem_write_data = ex_mem_rs2_data; 

    // Controle de escrita na memória por byte/halfword/word
    assign mem_write_byte_en  = (ex_mem_mem_write_en && ex_mem_funct3 == 3'b000); // SB
    assign mem_write_half_en  = (ex_mem_mem_write_en && ex_mem_funct3 == 3'b001); // SH
    assign mem_write_word_en  = (ex_mem_mem_write_en && ex_mem_funct3 == 3'b010); // SW

    // --- Registradores de Pipeline MEM/WB ---
    always @(posedge clk) begin
        if (rst) begin
            mem_wb_pc_4         <= 0;
            mem_wb_alu_result   <= 0;
            mem_wb_mem_read_data <= 0;
            mem_wb_rd           <= 0;
            mem_wb_reg_write_en <= 1'b0;
            mem_wb_mem_to_reg_sel <= 2'b00;
        end else begin
            // Passa os dados e sinais de controle adiante, ou lida com o acesso à memória
            mem_wb_pc_4         <= ex_mem_pc_4;
            mem_wb_alu_result   <= ex_mem_alu_result;
            mem_wb_rd           <= ex_mem_rd;
            
            // Se for uma instrução de leitura da memória (LOAD), armazena os dados lidos
            if (ex_mem_mem_read_en) begin
                // Lógica para assinar corretamente os dados lidos, dependendo do funct3
                case (ex_mem_funct3)
                    3'b000: mem_wb_mem_read_data <= {{24{mem_read_data[7]}}, mem_read_data[7:0]}; // LB (signed byte)
                    3'b001: mem_wb_mem_read_data <= {{16{mem_read_data[15]}}, mem_read_data[15:0]}; // LH (signed halfword)
                    3'b010: mem_wb_mem_read_data <= mem_read_data; // LW (word)
                    3'b100: mem_wb_mem_read_data <= {{24{1'b0}}, mem_read_data[7:0]}; // LBU (unsigned byte)
                    3'b101: mem_wb_mem_read_data <= {{16{1'b0}}, mem_read_data[15:0]}; // LHU (unsigned halfword)
                    default: mem_wb_mem_read_data <= mem_read_data; // Default, ou erro
                endcase
            end else begin
                mem_wb_mem_read_data <= 0; // Não é Load, então não há dados lidos da memória
            end

            // Passa os sinais de controle de escrita em registrador para o WB
            mem_wb_reg_write_en   <= ex_mem_reg_write_en;
            mem_wb_mem_to_reg_sel <= ex_mem_mem_to_reg_sel;
        end
    end

endmodule

// --- Módulo de Memória de Dados (data_mem.v) ---
// Este módulo deve ser criado em um arquivo separado chamado `data_mem.v`
// (Simples para demonstração, pode ser mais complexo para um simulador completo)
module data_mem (
    input  wire        clk,
    input  wire [31:0] addr,
    input  wire [31:0] write_data,
    input  wire        read_en,           // Habilita leitura
    input  wire        write_byte_en,     // Habilita escrita de byte
    input  wire        write_half_en,     // Habilita escrita de halfword
    input  wire        write_word_en,     // Habilita escrita de word
    output wire [31:0] read_data
);

    reg [7:0] memory [0:1023]; // Memória de dados de 1KB (1024 bytes)

    // Inicializa a memória (opcional, para testes)
    initial begin
        // $readmemh("data.hex", memory); // Se você tiver um arquivo de dados inicial
        // Exemplo: memory[0] = 8'hAA; memory[1] = 8'hBB; etc.
        for (integer i = 0; i < 1024; i = i + 1) begin
            memory[i] = 8'h00; // Limpa a memória no início
        end
    end

    // Lógica de leitura (combinacional)
    assign read_data = {memory[addr+3], memory[addr+2], memory[addr+1], memory[addr]}; // Leitura de word

    // Lógica de escrita (síncrona)
    always @(posedge clk) begin
        if (write_word_en) begin
            memory[addr]   <= write_data[7:0];
            memory[addr+1] <= write_data[15:8];
            memory[addr+2] <= write_data[23:16];
            memory[addr+3] <= write_data[31:24];
        end else if (write_half_en) begin
            memory[addr]   <= write_data[7:0];
            memory[addr+1] <= write_data[15:8];
        end else if (write_byte_en) begin
            memory[addr]   <= write_data[7:0];
        end
    end

endmodule