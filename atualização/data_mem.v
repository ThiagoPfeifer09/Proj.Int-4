module data_mem (
    input  wire clk,
    input  wire [31:0] addr, write_data,
    input  wire read_en, write_byte_en, write_half_en, write_word_en,
    output wire [31:0] read_data
);
    reg [7:0] memory [0:8191];
    integer i;
    initial begin
        for (i = 0; i < 8192; i = i + 1) memory[i] = 8'h00;
        memory[0]=8'h0A; memory[1]=8'h00; memory[2]=8'h00; memory[3]=8'h00;
        memory[4]=8'h03; memory[5]=8'h00; memory[6]=8'h00; memory[7]=8'h00;
    end
    assign read_data = {memory[addr+3], memory[addr+2], memory[addr+1], memory[addr]};
    always @(posedge clk) begin
        if (write_word_en) begin memory[addr]<=write_data[7:0]; memory[addr+1]<=write_data[15:8]; memory[addr+2]<=write_data[23:16]; memory[addr+3]<=write_data[31:24];
        end else if (write_half_en) begin memory[addr]<=write_data[7:0]; memory[addr+1]<=write_data[15:8];
        end else if (write_byte_en) memory[addr]<=write_data[7:0];
    end
endmodule