module riscv_pipeline (
    input wire clk,
    input wire rst
);

    // --- Sinais dos Registradores de Pipeline (Wires de Conexão entre Estágios) ---

    // Sinais do Registrador IF/ID (Saídas do if_stage)
    wire [31:0] if_id_pc;        
    wire [31:0] if_id_pc_4;      
    wire [31:0] if_id_instr;     

    // Sinais do Registrador ID/EX (Saídas do id_stage)
    wire [31:0] id_ex_pc;        
    wire [31:0] id_ex_pc_4;
    wire [31:0] id_ex_rs1_data;  
    wire [31:0] id_ex_rs2_data;  
    wire [4:0]  id_ex_rd;        
    wire [4:0]  id_ex_rs1_addr;  // Endereço de rs1 (para futuro forwarding)
    wire [4:0]  id_ex_rs2_addr;  // Endereço de rs2 (para futuro forwarding)
    wire [2:0]  id_ex_funct3;
    wire [6:0]  id_ex_funct7;
    wire [6:0]  id_ex_opcode;
    wire [31:0] id_ex_imm;       

    // Sinais do Registrador EX/MEM (Saídas do ex_stage)
    wire [31:0] ex_mem_pc;           
    wire [31:0] ex_mem_pc_4;         
    wire [31:0] ex_mem_alu_result;   
    wire [31:0] ex_mem_rs2_data;     
    wire [4:0]  ex_mem_rd;           
    wire [2:0]  ex_mem_funct3;       
    wire [6:0]  ex_mem_opcode;       
    wire        ex_mem_mem_write_en; 
    wire        ex_mem_mem_read_en;  
    wire        ex_mem_reg_write_en; 
    wire [1:0]  ex_mem_mem_to_reg_sel; 

    // Sinais do Registrador MEM/WB (Saídas do mem_stage)
    wire [31:0] mem_wb_pc_4;         
    wire [31:0] mem_wb_alu_result;   
    wire [31:0] mem_wb_mem_read_data;
    wire [4:0]  mem_wb_rd;           
    wire        mem_wb_reg_write_en;   
    wire [1:0]  mem_wb_mem_to_reg_sel; 

    // Sinais de Write Back para o Banco de Registradores (Saídas do wb_stage)
    wire        wb_reg_write_en;    
    wire [4:0]  wb_reg_write_addr;  
    wire [31:0] wb_reg_write_data;  

    // Sinais de Controle de Desvio (do EX para o IF)
    wire [31:0] branch_target_ex; 
    wire        branch_taken_ex;  

    // Sinais da Interface de Memória de Dados
    wire [31:0] dm_addr;           
    wire [31:0] dm_write_data;     
    wire        dm_write_byte_en;  
    wire        dm_write_half_en;  
    wire        dm_write_word_en;  
    wire [31:0] dm_read_data;      

    // Sinais da Interface de Memória de Instruções
    wire [31:0] im_addr;         // Endereço para a memória de instruções
    wire [31:0] im_instr_read;   // Instrução lida da memória de instruções


    // --- Instanciação dos Estágios do Pipeline ---

    // 1. Estágio IF (Instruction Fetch)
    if_stage u_if_stage (
        .clk             (clk),
        .rst             (rst),
        .branch_target   (branch_target_ex), // Entrada do EX para controle de desvio
        .branch_taken    (branch_taken_ex),  // Entrada do EX para controle de desvio
        .im_instr_in     (im_instr_read),    // Entrada da memória de instruções
        .im_addr_out     (im_addr),          // Saída do PC para a memória de instruções

        .if_id_pc_out    (if_id_pc),         // Saída para o registrador IF/ID (PC)
        .if_id_pc_4_out  (if_id_pc_4),       // Saída para o registrador IF/ID (PC + 4)
        .if_id_instr_out (if_id_instr)       // Saída para o registrador IF/ID (Instrução)
    );

    // 2. Estágio ID (Instruction Decode / Register File Read)
    id_stage u_id_stage (
        .clk             (clk),
        .rst             (rst),
        .instr_in        (if_id_instr),      // Entrada do registrador IF/ID
        .pc_in           (if_id_pc),         // Entrada do registrador IF/ID
        .pc_4_in         (if_id_pc_4),       // Entrada do registrador IF/ID
        
        // Entradas do estágio WB (para escrita no banco de registradores)
        .reg_write_en    (wb_reg_write_en),
        .reg_write_addr  (wb_reg_write_addr),
        .reg_write_data  (wb_reg_write_data),
        
        // Saídas para o registrador ID/EX
        .id_ex_pc        (id_ex_pc),        
        .id_ex_pc_4      (id_ex_pc_4),
        .id_ex_rs1_data  (id_ex_rs1_data),  
        .id_ex_rs2_data  (id_ex_rs2_data),  
        .id_ex_rd        (id_ex_rd),        
        .id_ex_rs1       (id_ex_rs1_addr),  
        .id_ex_rs2       (id_ex_rs2_addr),  
        .id_ex_funct3    (id_ex_funct3),
        .id_ex_funct7    (id_ex_funct7),
        .id_ex_opcode    (id_ex_opcode),
        .id_ex_imm       (id_ex_imm)       
    );

    // 3. Estágio EX (Execute)
    ex_stage u_ex_stage (
        .clk             (clk),
        .rst             (rst),
        // Entradas do registrador ID/EX
        .id_ex_pc        (id_ex_pc),         
        .id_ex_pc_4      (id_ex_pc_4),       
        .id_ex_rs1_data  (id_ex_rs1_data),   
        .id_ex_rs2_data  (id_ex_rs2_data),   
        .id_ex_rd        (id_ex_rd),         
        .id_ex_rs1       (id_ex_rs1_addr),   
        .id_ex_rs2       (id_ex_rs2_addr),   
        .id_ex_funct3    (id_ex_funct3),     
        .id_ex_funct7    (id_ex_funct7),     
        .id_ex_opcode    (id_ex_opcode),     
        .id_ex_imm       (id_ex_imm),        

        // Saídas para o registrador EX/MEM
        .ex_mem_pc       (ex_mem_pc),        
        .ex_mem_pc_4     (ex_mem_pc_4),
        .ex_mem_alu_result (ex_mem_alu_result),
        .ex_mem_rs2_data (ex_mem_rs2_data),
        .ex_mem_rd       (ex_mem_rd),
        .ex_mem_funct3   (ex_mem_funct3),
        .ex_mem_opcode   (ex_mem_opcode),
        .ex_mem_mem_write_en (ex_mem_mem_write_en),
        .ex_mem_mem_read_en (ex_mem_mem_read_en), 
        .ex_mem_reg_write_en (ex_mem_reg_write_en),
        .ex_mem_mem_to_reg_sel (ex_mem_mem_to_reg_sel),

        // Saídas para o estágio IF (controle de desvio)
        .branch_target   (branch_target_ex),    
        .branch_taken    (branch_taken_ex)      
    );

    // 4. Estágio MEM (Memory Access)
    mem_stage u_mem_stage (
        .clk             (clk),
        .rst             (rst),
        // Entradas do registrador EX/MEM
        .ex_mem_pc       (ex_mem_pc),        
        .ex_mem_pc_4     (ex_mem_pc_4),      
        .ex_mem_alu_result (ex_mem_alu_result),
        .ex_mem_rs2_data (ex_mem_rs2_data),  
        .ex_mem_rd       (ex_mem_rd),        
        .ex_mem_funct3   (ex_mem_funct3),    
        .ex_mem_opcode   (ex_mem_opcode),    
        .ex_mem_mem_write_en (ex_mem_mem_write_en),
        .ex_mem_mem_read_en (ex_mem_mem_read_en), 
        .ex_mem_reg_write_en (ex_mem_reg_write_en),
        .ex_mem_mem_to_reg_sel (ex_mem_mem_to_reg_sel),

        // Interface com a Memória de Dados
        .mem_addr        (dm_addr),          
        .mem_write_data  (dm_write_data),    
        .mem_write_byte_en (dm_write_byte_en), 
        .mem_write_half_en (dm_write_half_en), 
        .mem_write_word_en (dm_write_word_en), 
        .mem_read_data   (dm_read_data),     // Entrada da Memória de Dados

        // Saídas para o registrador MEM/WB
        .mem_wb_pc_4     (mem_wb_pc_4),      
        .mem_wb_alu_result (mem_wb_alu_result),
        .mem_wb_mem_read_data (mem_wb_mem_read_data),
        .mem_wb_rd       (mem_wb_rd),
        .mem_wb_reg_write_en (mem_wb_reg_write_en),
        .mem_wb_mem_to_reg_sel (mem_wb_mem_to_reg_sel)
    );

    // 5. Estágio WB (Write Back)
    wb_stage u_wb_stage (
        .clk             (clk),
        .rst             (rst),
        // Entradas do registrador MEM/WB
        .mem_wb_pc_4     (mem_wb_pc_4),        
        .mem_wb_alu_result (mem_wb_alu_result),
        .mem_wb_mem_read_data (mem_wb_mem_read_data),
        .mem_wb_rd       (mem_wb_rd),          
        .mem_wb_reg_write_en (mem_wb_reg_write_en),
        .mem_wb_mem_to_reg_sel (mem_wb_mem_to_reg_sel),

        // Saídas para o Banco de Registradores (no ID stage)
        .reg_write_en_out  (wb_reg_write_en),   
        .reg_write_addr_out (wb_reg_write_addr), 
        .reg_write_data_out (wb_reg_write_data)  
    );

    // --- Instanciação das Memórias ---

    // Memória de Instruções
    instr_mem u_imem (
        .addr           (im_addr),         // Endereço do PC vindo do IF
        .instr          (im_instr_read)    // Instrução lida
    );
    
    // Memória de Dados
    data_mem u_data_mem (
        .clk            (clk),
        .addr           (dm_addr),          
        .write_data     (dm_write_data),    
        .read_en        (ex_mem_mem_read_en), // Habilitação de leitura do EX/MEM
        .write_byte_en  (dm_write_byte_en), 
        .write_half_en  (dm_write_half_en), 
        .write_word_en  (dm_write_word_en), 
        .read_data      (dm_read_data)      // Dados lidos
    );

endmodule
