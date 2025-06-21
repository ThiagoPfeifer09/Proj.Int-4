// Módulo da Unidade de Forwarding - VERSÃO FINAL E CORRIGIDA
module forwarding_unit (
    input wire [4:0]  id_ex_rs1,
    input wire [4:0]  id_ex_rs2,
    input wire [4:0]  ex_mem_rd_in,
    input wire        ex_mem_reg_write_en_in,
    input wire [4:0]  mem_wb_rd_in,
    input wire        mem_wb_reg_write_en_in,
    output reg [1:0]  forward_a,
    output reg [1:0]  forward_b
);

    // Lógica de Forwarding:
    // 00: Sem forwarding
    // 01: Forward do estágio MEM (saída do EX/MEM)
    // 10: Forward do estágio WB (saída do MEM/WB)
    always @(*) begin
        // --- Forwarding para o Operando A (fonte rs1) ---
        // O hazard mais recente (estágio MEM) tem prioridade.
        if (ex_mem_reg_write_en_in && (ex_mem_rd_in != 5'b0) && (ex_mem_rd_in == id_ex_rs1)) begin
            forward_a = 2'b01;
        end
        // Se não houver hazard com MEM, verifica o estágio WB.
        else if (mem_wb_reg_write_en_in && (mem_wb_rd_in != 5'b0) && (mem_wb_rd_in == id_ex_rs1)) begin
            forward_a = 2'b10;
        end
        else begin
            forward_a = 2'b00;
        end

        // --- Forwarding para o Operando B (fonte rs2) ---
        // A lógica é idêntica, mas para o segundo operando.
        if (ex_mem_reg_write_en_in && (ex_mem_rd_in != 5'b0) && (ex_mem_rd_in == id_ex_rs2)) begin
            forward_b = 2'b01;
        end
        else if (mem_wb_reg_write_en_in && (mem_wb_rd_in != 5'b0) && (mem_wb_rd_in == id_ex_rs2)) begin
            forward_b = 2'b10;
        end
        else begin
            forward_b = 2'b00;
        end
    end
endmodule