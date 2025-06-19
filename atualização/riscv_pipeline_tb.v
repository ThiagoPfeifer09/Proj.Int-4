`timescale 1ns / 1ps

module riscv_pipeline_tb;

    reg clk;
    reg rst;

    // Instancia o processador
    riscv_pipeline u_riscv_pipeline (
        .clk(clk),
        .rst(rst)
    );

    // Geração de Clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Sequência de Teste Principal
    initial begin
        $dumpfile("riscv_pipeline.vcd");
        $dumpvars(0, riscv_pipeline_tb);

        rst = 1;
        #20;
        rst = 0;

        #20000; // Aumentado para 2000 ciclos para garantir a finalização

        $display("Simulação Concluída!");
        $finish;
    end

    // --- NOVO: Monitor Avançado de Depuração ---
    initial begin
        // Espera o reset
        #21;

        // Este monitor mostra o estado das variáveis chave do algoritmo Insertion Sort
        // e também a interface com a memória de dados.
        $monitor("Time:%4t | PC:%h | i(t2):%d, j(t5):%d | key(s1):%d, arr[j](s3):%d | Mem wr_en:%b, addr:%h, data:%h | Array: [ %d, %d, %d, %d, %d ]",
                  $time,
                  // Sinais de controle de fluxo
                  u_riscv_pipeline.u_if_stage.pc_current,
                  // Registradores chave do algoritmo
                  u_riscv_pipeline.u_id_stage.u_reg_file.regs[7],  // i (t2)
                  u_riscv_pipeline.u_id_stage.u_reg_file.regs[30], // j (t5)
                  u_riscv_pipeline.u_id_stage.u_reg_file.regs[9],  // key (s1)
                  u_riscv_pipeline.u_id_stage.u_reg_file.regs[19], // array[j] (s3)
                  // Interface com a memória de dados (mostra quando uma escrita ocorre)
                  u_riscv_pipeline.mem_write_word_en_to_dm,
                  u_riscv_pipeline.mem_addr_to_dm,
                  u_riscv_pipeline.mem_write_data_to_dm,
                  // O array de memória
                  {u_riscv_pipeline.u_data_mem.memory[3], u_riscv_pipeline.u_data_mem.memory[2], u_riscv_pipeline.u_data_mem.memory[1], u_riscv_pipeline.u_data_mem.memory[0]},
                  {u_riscv_pipeline.u_data_mem.memory[7], u_riscv_pipeline.u_data_mem.memory[6], u_riscv_pipeline.u_data_mem.memory[5], u_riscv_pipeline.u_data_mem.memory[4]},
                  {u_riscv_pipeline.u_data_mem.memory[11], u_riscv_pipeline.u_data_mem.memory[10], u_riscv_pipeline.u_data_mem.memory[9], u_riscv_pipeline.u_data_mem.memory[8]},
                  {u_riscv_pipeline.u_data_mem.memory[15], u_riscv_pipeline.u_data_mem.memory[14], u_riscv_pipeline.u_data_mem.memory[13], u_riscv_pipeline.u_data_mem.memory[12]},
                  {u_riscv_pipeline.u_data_mem.memory[19], u_riscv_pipeline.u_data_mem.memory[18], u_riscv_pipeline.u_data_mem.memory[17], u_riscv_pipeline.u_data_mem.memory[16]}
                 );
    end

endmodule