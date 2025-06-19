// forwarding_unit.v
module forwarding_unit (
    // Endereços dos registradores de origem no estágio ID/EX
    input wire [4:0]  id_ex_rs1,
    input wire [4:0]  id_ex_rs2,

    // Registrador de destino no estágio EX/MEM
    input wire [4:0]  ex_mem_rd,
    input wire        ex_mem_reg_write_en,

    // Registrador de destino no estágio MEM/WB
    input wire [4:0]  mem_wb_rd,
    input wire        mem_wb_reg_write_en,

    // Sinais de controle de saída para os multiplexadores no estágio EX
    output reg [1:0]  forward_a,
    output reg [1:0]  forward_b
);

    // Lógica de Forwarding:
    // 00: Sem forwarding (usa valor do reg_file)
    // 01: Forward do estágio EX/MEM (resultado da ALU)
    // 10: Forward do estágio MEM/WB (resultado da MEM ou ALU)

    always @(*) begin
        // --- Forwarding para o operando A (rs1) ---
        // Prioridade para o hazard mais recente (EX/MEM)
        if (ex_mem_reg_write_en && ex_mem_rd != 5'b0 && ex_mem_rd == id_ex_rs1) begin
            forward_a = 2'b01; // Forward do resultado da ALU
        end
        // Se não houver hazard EX/MEM, verifica o MEM/WB
        else if (mem_wb_reg_write_en && mem_wb_rd != 5'b0 && mem_wb_rd == id_ex_rs1) begin
            forward_a = 2'b10; // Forward do estágio WB
        end
        else begin
            forward_a = 2'b00; // Sem forwarding
        end

        // --- Forwarding para o operando B (rs2) ---
        // Prioridade para o hazard mais recente (EX/MEM)
        if (ex_mem_reg_write_en && ex_mem_rd != 5'b0 && ex_mem_rd == id_ex_rs2) begin
            forward_b = 2'b01; // Forward do resultado da ALU
        end
        // Se não houver hazard EX/MEM, verifica o MEM/WB
        else if (mem_wb_reg_write_en && mem_wb_rd != 5'b0 && mem_wb_rd == id_ex_rs2) begin
            forward_b = 2'b10; // Forward do estágio WB
        end
        else begin
            forward_b = 2'b00; // Sem forwarding
        end
    end
endmodule