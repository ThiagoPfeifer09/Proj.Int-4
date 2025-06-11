`timescale 1ns / 1ps // Define a escala de tempo para a simulação

module riscv_pipeline_tb;

    // Sinais do Testbench para Clock e Reset
    reg clk;
    reg rst;

    // Instancia o módulo top-level do pipeline RISC-V
    riscv_pipeline u_riscv_pipeline (
        .clk(clk),
        .rst(rst)
    );

    // Geração do Clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // Clock de 100 MHz (período de 10 ns)
    end

    // Sequência de Teste
    initial begin
        // Configura o dump de ondas (para visualização no Gtkwave, por exemplo)
        $dumpfile("riscv_pipeline.vcd");
        $dumpvars(0, riscv_pipeline_tb); // Dumps all variables in the testbench scope

        // Aplica o Reset
        rst = 1;
        #20; // Mantém o reset por 20ns (duas bordas de clock)
        rst = 0;
        #10; // Libera o reset e espera um ciclo para o primeiro fetch

        // Executa por um número de ciclos para o programa terminar
        // Ajuste este valor conforme a complexidade e comprimento do seu programa.
        // Um programa de 8 instruções (~8 * 5 = 40 ciclos para atravessar o pipeline)
        // Mais alguns ciclos para ver o efeito do JAL x0, 0x0
        #200; // Simula por 200ns (20 ciclos de clock completos)

        $display("Simulação Concluída!");
        $finish; // Termina a simulação
    end

    // Monitoramento de Sinais Chave (para depuração no console)
    initial begin
        $monitor("Time: %0t | PC: %h | Instr(IF): %h | Reg[5]: %h | Reg[6]: %h | Reg[7]: %h | Reg[8]: %h | Reg[9]: %h | Reg[10]: %h | Reg[20]: %h | Mem[15]: %h",
                 $time, 
                 u_riscv_pipeline.if_id_pc, // PC atual
                 u_riscv_pipeline.if_id_instr, // Instrução sendo processada
                 u_riscv_pipeline.u_id_stage.u_reg_file.regs[5],  // Valor do Registrador x5
                 u_riscv_pipeline.u_id_stage.u_reg_file.regs[6],  // Valor do Registrador x6
                 u_riscv_pipeline.u_id_stage.u_reg_file.regs[7],  // Valor do Registrador x7
                 u_riscv_pipeline.u_id_stage.u_reg_file.regs[8],  // Valor do Registrador x8
                 u_riscv_pipeline.u_id_stage.u_reg_file.regs[9],  // Valor do Registrador x9
                 u_riscv_pipeline.u_id_stage.u_reg_file.regs[10], // Valor do Registrador x10
                 u_riscv_pipeline.u_id_stage.u_reg_file.regs[20], // Valor do Registrador x20
                 u_riscv_pipeline.u_data_mem.memory[15]           // Valor na posição 15 da memória de dados
                );
    end

endmodule
