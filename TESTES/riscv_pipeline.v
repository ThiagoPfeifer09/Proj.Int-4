module riscv_pipeline (
    input wire clk,
    input wire rst
);

    // --- Sinais dos Registradores de Pipeline (Wires de Conex�o entre Est�gios) ---

    // Sinais do Registrador IF/ID (Sa�das do if_stage)
    wire [31:0] if_id_pc;        
    wire [31:0] if_id_pc_4;      
    wire [31:0] if_id_instr;     

    // Sinais do Registrador ID/EX (Sa�das do id_stage)
    wire [31:0] id_ex_pc;        
    wire [31:0] id_ex_pc_4;
    wire [31:0] id_ex_rs1_data;  
    wire [31:0] id_ex_rs2_data;  
    wire [4:0]  id_ex_rd;        
    wire [4:0]  id_ex_rs1_addr;  // Endere�o de rs1 (para futuro forwarding)
    wire [4:0]  id_ex_rs2_addr;  // Endere�o de rs2 (para futuro forwarding)
    wire [2:0]  id_ex_funct3;
    wire [6:0]  id_ex_funct7;
    wire [6:0]  id_ex_opcode;
    wire [31:0] id_ex_imm;       

    // Sinais do Registrador EX/MEM (Sa�das do ex_stage)
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

    // Sinais do Registrador MEM/WB (Sa�das do mem_stage)
    wire [31:0] mem_wb_pc_4;         
    wire [31:0] mem_wb_alu_result;   
    wire [31:0] mem_wb_mem_read_data;
    wire [4:0]  mem_wb_rd;           
    wire        mem_wb_reg_write_en;   
    wire [1:0]  mem_wb_mem_to_reg_sel; 

    // Sinais de Write Back para o Banco de Registradores (Sa�das do wb_stage)
    wire        wb_reg_write_en;    
    wire [4:0]  wb_reg_write_addr;  
    wire [31:0] wb_reg_write_data;  

    // Sinais de Controle de Desvio (do EX para o IF)
    wire [31:0] branch_target_ex; 
    wire        branch_taken_ex;  

    // Sinais da Interface de Mem�ria de Dados
    wire [31:0] dm_addr;           
    wire [31:0] dm_write_data;     
    wire        dm_write_byte_en;  
    wire        dm_write_half_en;  
    wire        dm_write_word_en;  
    wire [31:0] dm_read_data;      

    // Sinais da Interface de Mem�ria de Instru��es
    wire [31:0] im_addr;         // Endere�o para a mem�ria de instru��es
    wire [31:0] im_instr_read;   // Instru��o lida da mem�ria de instru��es


    // --- Instancia��o dos Est�gios do Pipeline ---

    // 1. Est�gio IF (Instruction Fetch)
    if_stage u_if_stage (
        .clk             (clk),
        .rst             (rst),
        .branch_target   (branch_target_ex), // Entrada do EX para controle de desvio
        .branch_taken    (branch_taken_ex),  // Entrada do EX para controle de desvio
        .im_instr_in     (im_instr_read),    // Entrada da mem�ria de instru��es
        .im_addr_out     (im_addr),          // Sa�da do PC para a mem�ria de instru��es

        .if_id_pc_out    (if_id_pc),         // Sa�da para o registrador IF/ID (PC)
        .if_id_pc_4_out  (if_id_pc_4),       // Sa�da para o registrador IF/ID (PC + 4)
        .if_id_instr_out (if_id_instr)       // Sa�da para o registrador IF/ID (Instru��o)
    );

    // 2. Est�gio ID (Instruction Decode / Register File Read)
    id_stage u_id_stage (
        .clk             (clk),
        .rst             (rst),
        .instr_in        (if_id_instr),      // Entrada do registrador IF/ID
        .pc_in           (if_id_pc),         // Entrada do registrador IF/ID
        .pc_4_in         (if_id_pc_4),       // Entrada do registrador IF/ID
        
        // Entradas do est�gio WB (para escrita no banco de registradores)
        .reg_write_en    (wb_reg_write_en),
        .reg_write_addr  (wb_reg_write_addr),
        .reg_write_data  (wb_reg_write_data),
        
        // Sa�das para o registrador ID/EX
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

    // 3. Est�gio EX (Execute)
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

        // Sa�das para o registrador EX/MEM
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

        // Sa�das para o est�gio IF (controle de desvio)
        .branch_target   (branch_target_ex),    
        .branch_taken    (branch_taken_ex)      
    );

    // 4. Est�gio MEM (Memory Access)
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

        // Interface com a Mem�ria de Dados
        .mem_addr        (dm_addr),          
        .mem_write_data  (dm_write_data),    
        .mem_write_byte_en (dm_write_byte_en), 
        .mem_write_half_en (dm_write_half_en), 
        .mem_write_word_en (dm_write_word_en), 
        .mem_read_data   (dm_read_data),     // Entrada da Mem�ria de Dados

        // Sa�das para o registrador MEM/WB
        .mem_wb_pc_4     (mem_wb_pc_4),      
        .mem_wb_alu_result (mem_wb_alu_result),
        .mem_wb_mem_read_data (mem_wb_mem_read_data),
        .mem_wb_rd       (mem_wb_rd),
        .mem_wb_reg_write_en (mem_wb_reg_write_en),
        .mem_wb_mem_to_reg_sel (mem_wb_mem_to_reg_sel)
    );

    // 5. Est�gio WB (Write Back)
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

        // Sa�das para o Banco de Registradores (no ID stage)
        .reg_write_en_out  (wb_reg_write_en),   
        .reg_write_addr_out (wb_reg_write_addr), 
        .reg_write_data_out (wb_reg_write_data)  
    );

    // --- Instancia��o das Mem�rias ---

    // Mem�ria de Instru��es
    instr_mem u_imem (
        .addr           (im_addr),         // Endere�o do PC vindo do IF
        .instr          (im_instr_read)    // Instru��o lida
    );
    
    // Mem�ria de Dados
    data_mem u_data_mem (
        .clk            (clk),
        .addr           (dm_addr),          
        .write_data     (dm_write_data),    
        .read_en        (ex_mem_mem_read_en), // Habilita��o de leitura do EX/MEM
        .write_byte_en  (dm_write_byte_en), 
        .write_half_en  (dm_write_half_en), 
        .write_word_en  (dm_write_word_en), 
        .read_data      (dm_read_data)      // Dados lidos
    );

endmodule
