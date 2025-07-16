// =============================
// Cache L1 para Instruções (Somente Leitura)
// =============================
module CacheL1_Instr #(parameter BLOCKS = 8) (
    input [63:0] address,
    output reg [31:0] instruction,
    output reg hit,
    output reg miss,

    // Interface com Cache L2
    output reg [63:0] addr_to_L2,
    input [31:0] instruction_from_L2,
    input hit_from_L2
);
    reg [63:0] tags [0:BLOCKS-1];
    reg [31:0] instrs [0:BLOCKS-1];
    reg valid [0:BLOCKS-1];

    integer i;
    initial begin
        for (i = 0; i < BLOCKS; i = i + 1) begin
            valid[i] = 0;
            tags[i] = 0;
            instrs[i] = 0;
        end
    end

    always @(*) begin
        hit = 0;
        miss = 1;
        instruction = 32'd0;
        for (i = 0; i < BLOCKS; i = i + 1) begin
            if (valid[i] && tags[i] == address) begin
                hit = 1;
                miss = 0;
                instruction = instrs[i];
            end
        end
        if (miss)
            addr_to_L2 = address;
    end

    always @(*) begin
        if (hit_from_L2) begin
            instrs[0] = instruction_from_L2;
            tags[0] = address;
            valid[0] = 1;
        end
    end
endmodule

// =============================
// Cache L2 para Instruções (Somente Leitura)
// =============================
module CacheL2_Instr #(parameter BLOCKS = 16) (
    input [63:0] address,
    output reg [31:0] instruction,
    output reg hit,
    output reg miss,

    // Interface com memória
    output reg [63:0] addr_to_mem,
    input [31:0] instruction_from_mem
);
    reg [63:0] tags [0:BLOCKS-1];
    reg [31:0] instrs [0:BLOCKS-1];
    reg valid [0:BLOCKS-1];

    integer i;
    initial begin
        for (i = 0; i < BLOCKS; i = i + 1) begin
            valid[i] = 0;
            tags[i] = 0;
            instrs[i] = 0;
        end
    end

    always @(*) begin
        hit = 0;
        miss = 1;
        instruction = 32'd0;
        for (i = 0; i < BLOCKS; i = i + 1) begin
            if (valid[i] && tags[i] == address) begin
                hit = 1;
                miss = 0;
                instruction = instrs[i];
            end
        end

        if (miss)
            addr_to_mem = address;
    end

    always @(*) begin
        if (miss) begin
            instrs[0] = instruction_from_mem;
            tags[0] = address;
            valid[0] = 1;
        end
    end
endmodule

// =============================
// Cache L1 para Dados (Leitura Assíncrona, Escrita Síncrona)
// =============================
module CacheL1_Data #(parameter BLOCKS = 8) (
    input clk,
    input [63:0] address,
    input read_en,
    input write_en,
    input [63:0] write_data,
    output reg [63:0] read_data,
    output reg hit,
    output reg miss,

    // Interface com Cache L2
    output reg [63:0] addr_to_L2,
    input [63:0] data_from_L2,
    input hit_from_L2
);
    reg [63:0] tags [0:BLOCKS-1];
    reg [63:0] datas [0:BLOCKS-1];
    reg valid [0:BLOCKS-1];

    integer i;
    initial begin
        for (i = 0; i < BLOCKS; i = i + 1) begin
            valid[i] = 0;
            tags[i] = 0;
            datas[i] = 0;
        end
    end

    always @(*) begin
        hit = 0;
        miss = 1;
        read_data = 64'd0;
        for (i = 0; i < BLOCKS; i = i + 1) begin
            if (valid[i] && tags[i] == address) begin
                hit = 1;
                miss = 0;
                read_data = datas[i];
            end
        end

        if (miss)
            addr_to_L2 = address;
    end

    always @(posedge clk) begin
        if (hit && write_en) begin
            for (i = 0; i < BLOCKS; i = i + 1) begin
                if (tags[i] == address) begin
                    datas[i] <= write_data;
                end
            end
        end else if (hit_from_L2) begin
            datas[0] <= data_from_L2;
            tags[0] <= address;
            valid[0] <= 1;
        end
    end
endmodule

// =============================
// Cache L2 para Dados (Leitura Assíncrona, Escrita Síncrona)
// =============================
module CacheL2_Data #(parameter BLOCKS = 16) (
    input clk,
    input [63:0] address,
    input read_en,
    input write_en,
    input [63:0] write_data,
    output reg [63:0] read_data,
    output reg hit,
    output reg miss,

    // Interface com Memória Principal
    output reg [63:0] addr_to_mem,
    input [63:0] data_from_mem
);
    reg [63:0] tags [0:BLOCKS-1];
    reg [63:0] datas [0:BLOCKS-1];
    reg valid [0:BLOCKS-1];

    integer i;
    initial begin
        for (i = 0; i < BLOCKS; i = i + 1) begin
            valid[i] = 0;
            tags[i] = 0;
            datas[i] = 0;
        end
    end

    always @(*) begin
        hit = 0;
        miss = 1;
        read_data = 64'd0;
        for (i = 0; i < BLOCKS; i = i + 1) begin
            if (valid[i] && tags[i] == address) begin
                hit = 1;
                miss = 0;
                read_data = datas[i];
            end
        end

        if (miss)
            addr_to_mem = address;
    end

    always @(posedge clk) begin
        if (hit && write_en) begin
            for (i = 0; i < BLOCKS; i = i + 1) begin
                if (tags[i] == address) begin
                    datas[i] <= write_data;
                end
            end
        end else if (miss) begin
            datas[0] <= data_from_mem;
            tags[0] <= address;
            valid[0] <= 1;
        end
    end
endmodule
