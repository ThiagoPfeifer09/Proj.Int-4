// Módulo do Estágio de Busca (IF)
// Modificado para suportar o stall do pipeline através das entradas
// pc_write_en e if_id_write_en.
module if_stage (
    input  wire        clk,
    input  wire        rst,

    // Sinais de controle de desvio vindos do estágio EX
    input  wire [31:0] branch_target,
    input  wire        branch_taken,

    // Sinais de controle de hazard vindos do estágio ID
    input  wire        pc_write_en,
    input  wire        if_id_write_en,

    // Saídas para o estágio ID (registradores de pipeline)
    output reg  [31:0] if_id_pc_out,
    output reg  [31:0] if_id_pc_4_out,
    output reg  [31:0] if_id_instr_out
);

    // Fios internos para o fluxo de dados do estágio IF
    wire [31:0] pc_current;
    wire [31:0] pc_next;
    wire [31:0] pc_plus_4;
    wire [31:0] instruction;

    // Lógica para determinar o próximo PC
    assign pc_plus_4 = pc_current + 4;
    assign pc_next = branch_taken ? branch_target : pc_plus_4;

    // --- Instância dos Módulos Internos ---

    // PC (Program Counter) com habilitação de escrita
    pc u_pc (
        .clk      (clk),
        .rst      (rst),
        .next_pc  (pc_next),
        .we       (pc_write_en), // Conecta o sinal de stall ao PC
        .pc_out   (pc_current)
    );

    // Memória de Instruções
    instr_mem u_imem (
        .addr  (pc_current),
        .instr (instruction)
    );

    // --- Registrador de Pipeline IF/ID com habilitação de escrita ---
    always @(posedge clk) begin
        if (rst) begin
            if_id_pc_out      <= 32'b0;
            if_id_pc_4_out    <= 32'b0;
            if_id_instr_out   <= 32'b0; // NOP
        end else if (if_id_write_en) begin // Só atualiza o registrador se não houver stall
            if_id_pc_out      <= pc_current;
            if_id_pc_4_out    <= pc_plus_4;
            if_id_instr_out   <= instruction;
        end
        // Se if_id_write_en for falso, o registrador mantém seu valor anterior,
        // "congelando" a instrução para o estágio ID.
    end

endmodule