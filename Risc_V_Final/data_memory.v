module data_memory (
    input wire clk,
    input wire reset,

    // Interface de leitura de bloco (128 bits)
    input wire mem_read,
    input wire [31:0] mem_address,          // Alinhado a 16 bytes (últimos 4 bits = 0)
    output reg [127:0] mem_block_out        // Bloco retornado
);

    // Memória byte-endereçável: 256 bytes
    reg [7:0] mem [0:255];

    integer i;

    // Inicialização da memória
    initial begin
        for (i = 0; i < 256; i = i + 1)
            mem[i] = 8'd0;

        // Exemplo: popular alguns valores (1, 2, 3, ..., 8)
        mem[0]  = 8'd1;
        mem[4]  = 8'd2;
        mem[8]  = 8'd3;
        mem[12] = 8'd4;
        mem[16] = 8'd5;
        mem[20] = 8'd6;
        mem[24] = 8'd7;
        mem[28] = 8'd8;
    end

    // Leitura de bloco de 128 bits (16 bytes)
    always @(posedge clk) begin
        if (mem_read) begin
            mem_block_out = {
                mem[mem_address + 15], mem[mem_address + 14],
                mem[mem_address + 13], mem[mem_address + 12],
                mem[mem_address + 11], mem[mem_address + 10],
                mem[mem_address + 9],  mem[mem_address + 8],
                mem[mem_address + 7],  mem[mem_address + 6],
                mem[mem_address + 5],  mem[mem_address + 4],
                mem[mem_address + 3],  mem[mem_address + 2],
                mem[mem_address + 1],  mem[mem_address + 0]
            };
        end
    end

endmodule
