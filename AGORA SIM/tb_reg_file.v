`timescale 1ns / 1ps

module tb_risc_v;

    reg clk;
    reg reset;
    wire [63:0] element1, element2, element3, element4,
                element5, element6, element7, element8;
    wire stall_out, flush_out;

    // Instancia o processador
    RISC_V_Processor dut (
        .clk(clk), .reset(reset), .element1(element1), .element2(element2),
        .element3(element3), .element4(element4), .element5(element5), 
        .element6(element6), .element7(element7), .element8(element8),
        .stall_out(stall_out), .flush_out(flush_out)
    );

    // Geração de Clock
    initial clk = 0;
    always #5 clk = ~clk;

    // TASK para verificar um registrador
    task check_reg;
        input [4:0] addr;
        input [63:0] expected_value;
        input [255:0] test_name;
        reg [63:0] actual_value;
    begin
        // Usando referência hierárquica para ler o valor direto do banco de registradores
        actual_value = dut.regfile.registers[addr];
        if (actual_value == expected_value)
            $display("  [SUCESSO] %s (x%0d == %0d)", test_name, addr, expected_value);
        else
            $display("  [FALHA]   %s (x%0d era %0d, mas o esperado era %0d)", test_name, addr, actual_value, expected_value);
    end
    endtask

    // Sequência de Teste e Verificação
    initial begin
        $dumpfile("full_test_dump.vcd");
        $dumpvars(0, dut);

        reset = 1'b1;
        #20;
        reset = 1'b0;
        
        $display("\n--- INICIANDO TESTE ABRANGENTE DO PROCESSADOR RISC-V ---");

        // As verificações são feitas após um número de ciclos de clock,
        // tempo suficiente para a instrução passar pelo pipeline e escrever o resultado.
        // Uma instrução leva 5 ciclos para completar (IF, ID, EX, MEM, WB).
        
        @(posedge clk); // Ciclo 1
        @(posedge clk); // Ciclo 2: addi x2...
        @(posedge clk); // Ciclo 3: add x3...
        @(posedge clk); // Ciclo 4: sub x4...
        @(posedge clk); // Ciclo 5: or x5...
        check_reg(1, 10, "Teste I-Type: addi x1");
        
        @(posedge clk); // Ciclo 6: and x6...
        check_reg(2, 20, "Teste I-Type: addi x2");
        
        @(posedge clk); // Ciclo 7: addi x7...
        check_reg(3, 30, "Teste R-Type: add x3");
        
        @(posedge clk); // Ciclo 8: addi x29...
        check_reg(4, -10, "Teste R-Type: sub x4"); // 10-20 = -10
        
        @(posedge clk); // Ciclo 9: sd x7...
        check_reg(5, 30, "Teste R-Type: or x5"); // 30 | -10 (representação binaria) = 30
        
        @(posedge clk); // Ciclo 10: ld x10...
        check_reg(6, 0, "Teste R-Type: and x6"); // 30 & -10 (representação binaria) = 0
        
        @(posedge clk); // Ciclo 11: addi x12...
        check_reg(7, 5, "Teste Forwarding: addi x7");
        
        @(posedge clk); // Ciclo 12: beq (not taken)...
        check_reg(29, 100, "Teste I-Type (endereço): addi x29");
        
        @(posedge clk); // Ciclo 13: beq (taken)...
        // A verificação do store (sd) é implícita no load (ld) a seguir.
        
        @(posedge clk); // Ciclo 14: instrução que deveria ser anulada (flushed)
        check_reg(10, 5, "Teste S-Type/I-Type: sd/ld");
        
        // O load-use stall acontece aqui. A instrução addi x12 precisa de 1 ciclo de bolha.
        // Portanto, seu resultado demora 1 ciclo a mais para aparecer.
        @(posedge clk); // Ciclo 15
        @(posedge clk); // Ciclo 16
        check_reg(12, 6, "Teste Stall (Load-Use): addi x12");
        
        // Agora verificamos os branches
        @(posedge clk); // Ciclo 17
        @(posedge clk); // Ciclo 18
        @(posedge clk); // Ciclo 19
        check_reg(17, 0, "Teste Branch (Not Taken): x17 não deve ser escrito"); // A instrução após o branch não tomado não foi executada

        @(posedge clk); // Ciclo 20
        check_reg(18, 111, "Teste Branch (Taken): alvo do branch x18"); // O alvo do branch foi executado corretamente

        @(posedge clk); // Ciclo 21
        check_reg(17, 0, "Teste Flush: x17 não deve ter sido escrito"); // A instrução após o branch tomado foi anulada

        @(posedge clk); // Ciclo 22
        check_reg(20, 0, "Teste x0: Escrita em x0 ignorada, leitura de x0 é 0");

        $display("\n--- TESTE CONCLUÍDO ---");
        $finish;
    end

endmodule