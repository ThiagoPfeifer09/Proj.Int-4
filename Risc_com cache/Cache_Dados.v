module cache_dados (
    input logic clk,
    input logic reset,

    input logic [31:0] address,
    input logic [63:0] write_data,
    input logic mem_read,
    input logic mem_write,

    output logic [63:0] read_data,
    output logic miss,

    // interface com a memória principal
    output logic [31:0] mem_address,
    output logic [63:0] mem_write_data,
    input logic [127:0] mem_block_read_data,
    input logic mem_ready,
    output logic mem_read_out,
    output logic mem_write_out
);

// Parâmetros
parameter BLOCK_SIZE = 16;
parameter CACHE_LINES = 4;

// Estado
typedef enum logic [1:0] {IDLE, MISS} state_t;
state_t state;

// Linha da cache
typedef struct packed {
    logic valid;
    logic [24:0] tag;
    logic [127:0] data;
} cache_line_t;

cache_line_t cache [CACHE_LINES-1:0];

// Sinais auxiliares
logic [1:0] index;
logic [24:0] tag;
logic [3:0] offset;

assign index = address[3:2];
assign tag = address[31:7];
assign offset = address[6:3];

// Inicialização
integer i;
initial begin
    for (i = 0; i < CACHE_LINES; i++) begin
        cache[i].valid = 0;
        cache[i].tag = 0;
        cache[i].data = 0;
    end
    state = IDLE;
    read_data = 0;
    miss = 0;
    mem_read_out = 0;
    mem_write_out = 0;
end
always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
        state <= IDLE;
        miss <= 0;
        read_data <= 0;
        mem_read_out <= 0;
        mem_write_out <= 0;
        for (i = 0; i < CACHE_LINES; i++) begin
            cache[i].valid <= 0;
            cache[i].tag <= 0;
            cache[i].data <= 0;
        end
    end else begin
        case (state)
            IDLE: begin
                miss <= 0;
                mem_read_out <= 0;
                mem_write_out <= 0;

                if (mem_read && !mem_write) begin
                    if (cache[index].valid && cache[index].tag == tag) begin
                        // Cache HIT - leitura
                        case (offset[3])
                            1'b0: read_data <= cache[index].data[63:0];
                            1'b1: read_data <= cache[index].data[127:64];
                        endcase
                        miss <= 1;
                    end else begin
                        // Cache MISS - requisita da memória
                        mem_address <= {address[31:4], 4'b0000};
                        mem_read_out <= 1;
                        state <= MISS;
                        miss <= 1;
                    end
                end else if (mem_write) begin
                    // Escrita write-through
                    mem_address <= address;
                    mem_write_data <= write_data;
                    mem_write_out <= 1;

                    // Atualiza a cache se HIT
                    if (cache[index].valid && cache[index].tag == tag) begin
                        if (offset[3] == 1'b0) begin
                            cache[index].data[63:0] <= write_data;
                            read_data <= write_data;
                        end else begin
                            cache[index].data[127:64] <= write_data;
                            read_data <= write_data;
                        end
                    end
                    miss <= 1;
                end
            end

            MISS: begin
                if (mem_ready) begin
                    // Cache refill
                    cache[index].valid <= 1;
                    cache[index].tag <= tag;
                    cache[index].data <= mem_block_read_data;

                    // Retorna leitura ao processador
                    case (offset[3])
                        1'b0: read_data <= mem_block_read_data[63:0];
                        1'b1: read_data <= mem_block_read_data[127:64];
                    endcase

                    miss <= 1;
                    state <= IDLE;
                end
            end
        endcase
    end
end

endmodule
