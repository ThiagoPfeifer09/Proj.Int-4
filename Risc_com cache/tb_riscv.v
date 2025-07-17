`timescale 1ns / 1ps

module tb_riscv;

    // Sinais para conectar ao processador (DUT - Device Under Test)
    reg clk;
    reg reset;
    reg stall;
    reg flush;
    
    // Entradas não utilizadas no nosso teste, mas precisam ser conectadas
    reg [63:0] element1, element2, element3, element4, element5, element6, element7, element8;

    // --- Instanciação do seu Processador RISC-V ---
    RISC_V_Processor dut (
        .clk(clk),
        .reset(reset),
        .stall(stall),
        .flush(flush),
        .element1(element1), .element2(element2), .element3(element3), .element4(element4),
        .element5(element5), .element6(element6), .element7(element7), .element8(element8)
    );

    // --- Geração de Clock ---
    parameter CLK_PERIOD = 10; // Usamos 'parameter' em vez de 'localparam' para maior compatibilidade
    always #(CLK_PERIOD / 2) clk = ~clk;

    // --- Tarefas para Imprimir a Memória ---
    // Em Verilog padrão, não podemos passar strings como argumentos para tarefas.
    // Por isso, criamos duas tarefas separadas.

    // Tarefa para imprimir o estado INICIAL da memória
    task print_initial_memory;
        integer i; // O contador do loop deve ser declarado como 'integer' aqui
        reg [63:0] value;
        begin
            $display("\nEstado Inicial da Memória (Antes da Ordenação):");
            $display("------------------------------------");
            for (i = 0; i < 8; i = i + 1) begin
                // Reconstitui o valor de 64 bits a partir dos 8 bytes da memória
                value = {
                    dut.datamem.mem[(i*8)+7], dut.datamem.mem[(i*8)+6],
                    dut.datamem.mem[(i*8)+5], dut.datamem.mem[(i*8)+4],
                    dut.datamem.mem[(i*8)+3], dut.datamem.mem[(i*8)+2],
                    dut.datamem.mem[(i*8)+1], dut.datamem.mem[(i*8)+0]
                };
                $display("Memoria[ %0d ] = %0d", i, value);
            end
            $display("------------------------------------");
        end
    endtask

    // Tarefa para imprimir o estado FINAL da memória
    task print_final_memory;
        integer i; // O contador do loop deve ser declarado como 'integer' aqui
        reg [63:0] value;
        begin
            $display("\nEstado Final da Memória (Após a Ordenação):");
            $display("------------------------------------");
            for (i = 0; i < 8; i = i + 1) begin
                value = {
                    dut.datamem.mem[(i*8)+7], dut.datamem.mem[(i*8)+6],
                    dut.datamem.mem[(i*8)+5], dut.datamem.mem[(i*8)+4],
                    dut.datamem.mem[(i*8)+3], dut.datamem.mem[(i*8)+2],
                    dut.datamem.mem[(i*8)+1], dut.datamem.mem[(i*8)+0]
                };
                $display("Memoria[ %0d ] = %0d", i, value);
            end
            $display("------------------------------------");
        end
    endtask

    // --- Sequência Principal de Teste ---
    initial begin
        // 1. Inicialização
        clk   = 0;
        reset = 1;
        stall = 0;
        flush = 0;
        
        // 2. Libera o Reset e Inicia a Execução
        #(CLK_PERIOD * 2);
        reset = 0;
        // Verilog padrão não tem o formato %t para tempo, usamos %0d ou %g.
        $display("[%0d ns] Reset liberado. Iniciando a execução do programa.", $time);

        // 3. Imprime o estado inicial
        #(5);
        print_initial_memory; // Chama a primeira tarefa

        // 4. Aguarda o Fim do Programa
        wait (dut.if_id_inst.inst_ifid_out == 32'h00100073);
        $display("\n[%0d ns] [TB] Instrução EBREAK detectada no pipeline!", $time);
        
        #(CLK_PERIOD * 5);

        // 5. Imprime o resultado final
        print_final_memory; // Chama a segunda tarefa

        // 6. Encerra a simulação
        $display("\n[%0d ns] Simulação concluída com sucesso.", $time);
        $finish;
    end

endmodule
