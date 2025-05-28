module if_stage (
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] branch_target,
    input  wire        branch_taken,
    output wire [31:0] pc_plus4,
    output wire [31:0] instr,
    output reg  [31:0] if_id_pc_plus4,
    output reg  [31:0] if_id_instr
);
  wire [31:0] pc_current, pc_next;

  // 1) PC + 4
  assign pc_plus4 = pc_current + 4;

  // 2) Sele��o de pr�ximo PC (branch ou sequ�ncia)
  assign pc_next = branch_taken ? branch_target : pc_plus4;

  // Inst�ncia do PC
  pc u_pc (
    .clk      (clk),
    .rst      (rst),
    .next_pc  (pc_next),
    .pc_out   (pc_current)
  );

  // Inst�ncia da mem�ria de instru��es
  instr_mem u_imem (
    .addr  (pc_current),
    .instr (instr)
  );

  // Escritura no registrador IF/ID
  always @(posedge clk) begin
    if (rst) begin
      if_id_pc_plus4 <= 32'b0;
      if_id_instr    <= 32'b0;
    end else begin
      if_id_pc_plus4 <= pc_plus4;
      if_id_instr    <= instr;
    end
  end

endmodule
