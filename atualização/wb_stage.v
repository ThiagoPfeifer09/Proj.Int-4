module wb_stage (
    input wire clk, rst,
    input wire [31:0] mem_wb_pc_4, mem_wb_alu_result, mem_wb_mem_read_data,
    input wire [4:0]  mem_wb_rd,
    input wire mem_wb_reg_write_en,
    input wire [1:0]  mem_wb_mem_to_reg_sel,
    output wire reg_write_en_out,
    output wire [4:0]  reg_write_addr_out,
    output wire [31:0] reg_write_data_out
);
    reg [31:0] write_data_mux_out;
    always @(*) begin
        case (mem_wb_mem_to_reg_sel)
            2'b00: write_data_mux_out = mem_wb_alu_result;
            2'b01: write_data_mux_out = mem_wb_mem_read_data;
            2'b10: write_data_mux_out = mem_wb_pc_4;
            default: write_data_mux_out = 32'b0;
        endcase
    end
    assign reg_write_en_out   = mem_wb_reg_write_en;
    assign reg_write_addr_out = mem_wb_rd;
    assign reg_write_data_out = write_data_mux_out;
endmodule