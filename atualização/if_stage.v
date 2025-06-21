module if_stage (
    input  wire        clk, rst,
    input  wire [31:0] branch_target_in,
    input  wire        branch_taken_in,
    input  wire        pc_write_en_in,
    input  wire        if_id_write_en_in,
    output reg  [31:0] if_id_pc_out,
    output reg  [31:0] if_id_pc_4_out,
    output reg  [31:0] if_id_instr_out
);
    wire [31:0] pc_current, pc_next, pc_plus_4, instruction;
    assign pc_plus_4 = pc_current + 4;
    assign pc_next = branch_taken_in ? branch_target_in : pc_plus_4;
    pc u_pc (.clk(clk), .rst(rst), .next_pc(pc_next), .we(pc_write_en_in), .pc_out(pc_current));
    instr_mem u_imem (.addr(pc_current), .instr(instruction));
    always @(posedge clk) begin
        if (rst) begin
            if_id_pc_out <= 0; if_id_pc_4_out <= 0; if_id_instr_out <= 32'h13;
        end else if (if_id_write_en_in) begin
            if_id_pc_out <= pc_current; if_id_pc_4_out <= pc_plus_4; if_id_instr_out <= instruction;
        end
    end
endmodule