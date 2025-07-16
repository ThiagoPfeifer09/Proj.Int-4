// Módulo: reg_file (Banco de Registradores)
module reg_file(
    input clk,
    input reset,
    input [4:0] rs1,
    input [4:0] rs2,
    input [4:0] rd,
    input [63:0] writedata,
    input reg_write,
    output [63:0] readdata1,
    output [63:0] readdata2,
    // Saídas de diagnóstico (opcionais)
    output [63:0] r8, r19, r20, r21, r22
);
    reg [63:0] registers [31:0];
    integer i;

    assign r8  = registers[8];
    assign r19 = registers[19];
    assign r20 = registers[20];
    assign r21 = registers[26];
    assign r22 = registers[27];

    // Leitura combinacional, tratando o caso especial do registrador x0
    assign readdata1 = (rs1 == 5'b0) ? 64'd0 : registers[rs1];
    assign readdata2 = (rs2 == 5'b0) ? 64'd0 : registers[rs2];
    
    // Escrita síncrona na borda de subida do clock
    always @(posedge clk)
    begin
        if (reset) begin
            for (i=0; i<32; i=i+1) begin
                registers[i] <= 64'd0;
            end
        end
        else begin
            // A escrita só ocorre se habilitada E o destino não for x0
            if (reg_write && rd != 5'b0) begin
                registers[rd] <= writedata;
            end
        end
    end
endmodule