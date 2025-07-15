// Módulo: tb_risc_v
// Objetivo: Testbench para o processador RISC-V completo.
// Este testbench inicializa o processador, fornece um sinal de clock,
// aplica um pulso de reset e deixa o processador executar o programa
// pré-carregado na memória de instruções.

`timescale 1ns / 1ps // Define as unidades de tempo para a simulação

module tb_risc_v;

    // =========================================================================
    // == 1. DECLARAÇÃO DE SINAIS
    // =========================================================================
    // Sinais do tipo 'reg' são usados para aplicar estímulos ao DUT.
    reg clk;
    reg reset;

    // Sinais do tipo 'wire' são usados para conectar às saídas do DUT.
    // (As saídas de diagnóstico da memória de dados)
    wire [63:0] element1, element2, element3, element4;
    wire [63:0] element5, element6, element7, element8;

    // =========================================================================
    // == 2. INSTANCIAÇÃO DO DUT (Device Under Test)
    // =========================================================================
    // Aqui nós criamos uma instância do seu processador e conectamos os
    // sinais do testbench às suas portas.
    RISC_V_Processor dut (
        .clk(clk),
        .reset(reset),
        
        // Conectando as saídas de diagnóstico da memória
        .element1(element1),
        .element2(element2),
        .element3(element3),
        .element4(element4),
        .element5(element5),
        .element6(element6),
        .element7(element7),
        .element8(element8),

        // Sinais de teste globais que não usaremos neste teste básico.
        // Os conectamos a um valor fixo de 0.
        .stall(1'b0),
        .flush(1'b0)
    );

    // =========================================================================
    // == 3. GERAÇÃO DE CLOCK
    // =========================================================================
    // Este bloco 'always' gera um sinal de clock contínuo com um período
    // de 10ns (frequência de 100MHz).
    initial begin
        clk = 0;
    end
    
    always begin
        #5 clk = ~clk; // A cada 5ns, o clock inverte. (Período = 10ns)
    end

    // =========================================================================
    // == 4. GERAÇÃO DE WAVEFORM (VCD) E ESTÍMULO
    // =========================================================================
    // Este bloco 'initial' controla a sequência de teste.
    initial begin
        // --- Geração do arquivo VCD para visualização das ondas ---
        // Isso cria o arquivo 'dump.vcd' que você pode abrir no GTKWave.
        $dumpfile("dump.vcd");
        // O '0' indica para capturar todos os sinais em todos os níveis
        // de hierarquia a partir do 'dut'.
        $dumpvars(0, dut);

        // --- Sequência de Reset e Execução ---
        // 1. Começa com o processador em estado de reset.
        reset = 1'b1;
        $display("T=%0t ns: Sistema em RESET.", $time);
        
        // 2. Mantém o reset por 20ns (2 ciclos de clock) para estabilizar.
        #20;
        
        // 3. Libera o reset. O processador começará a buscar a primeira instrução (em PC=0).
        reset = 1'b0;
        $display("T=%0t ns: Reset liberado. Iniciando execução do programa.", $time);
        
        // 4. Deixa a simulação rodar por 500ns.
        // Este tempo deve ser suficiente para o seu programa executar uma quantidade
        // significativa de instruções. Ajuste se necessário.
        #500;
        
        // --- Verificação Final e Encerramento ---
        $display("\n----------------------------------------------------");
        $display("T=%0t ns: Simulação finalizada. Verificando estado final.", $time);
        
        // Usando referências hierárquicas para ler o valor final de alguns registradores.
        // Isso permite "olhar dentro" do seu design sem precisar criar saídas para tudo.
        // NOTA: Os nomes dos registradores (s0, t0, etc.) são baseados na ABI do RISC-V.
        $display("  - Valor final em x8 (s0): %d", dut.regfile.registers[8]);
        $display("  - Valor final em x9 (s1): %d", dut.regfile.registers[9]);
        $display("  - Valor final em x10 (a0): %d", dut.regfile.registers[10]);
        $display("  - Valor final em x11 (a1): %d", dut.regfile.registers[11]);
        $display("----------------------------------------------------");
        
        // 5. Encerra a simulação.
        $finish;
    end

endmodule
