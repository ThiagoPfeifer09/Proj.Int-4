Abaixo está organizado um readme com uma explicação do que é cada módulo, não tive muito tempo de detalhar muito bem, mas foi o que deu :)

---

# Processador RISC-V

Este repositório contém a implementação de um processador RISC-V, seguindo uma arquitetura de pipeline. Abaixo, você encontrará a descrição de cada módulo, suas funcionalidades e como eles interagem para formar o processador completo.

---

## Módulo Principal: `RISC_V_Processor`

Este é o módulo de nível superior que integra todos os outros componentes do processador. Ele gerencia o fluxo de dados e controle entre as diferentes etapas do pipeline.

### Entradas:
* `clk`: Sinal de clock principal.
* `reset`: Sinal de reset para inicializar o processador.
* `element1` a `element8`: Entradas genéricas de 64 bits (usadas somente para uma depuração).
* `stall`: Sinal para pausar o pipeline devido a uma dependência de dados ou miss na cache.
* `flush`: Sinal para limpar o pipeline (usado em desvios e exceções).


### Funcionamento Geral:
O `RISC_V_Processor` orquestra as cinco etapas clássicas de um pipeline (Fetch, Decode, Execute, Memory, Write-back) e lida com os sinais de controle e dados que fluem entre elas, incluindo a detecção e resolução de *hazards* (riscos) e o tratamento de *flushes* de pipeline.

---

## Unidades de Controle e Lógica Auxiliar

### `control_unit`
* **Função:** Gera os sinais de controle para as outras unidades do pipeline com base no `opcode` da instrução.
* **Entradas:** `opcode` (parte da instrução).
* **Saídas:** Sinais como `branch`, `memread`, `memtoreg`, `memwrite`, `ALUsrc`, `regwrite`, `ALUop` (que determinam a operação da ULA, acesso à memória, escrita em registrador, etc.).
* **Detalhes:** Esta unidade é crucial para decodificar a instrução e determinar as ações necessárias em cada estágio do pipeline. O sinal `stall` pode afetar a geração desses sinais.

### `hazard_detection_unit` (unidade de detecção de riscos)
* **Função:** Detecta *hazards* de dados (data hazards) que podem causar leituras incorretas de dados devido à ordem das instruções no pipeline.
* **Entradas:** `Memread` (do estágio ID/EX), `inst` (instrução atual), `Rd` (registrador de destino do estágio ID/EX).
* **Saídas:** `stall_combined` (sinal de stall).
* **Detalhes:** Quando uma instrução `load` está no pipeline e a próxima instrução tenta usar o dado que será carregado, esta unidade gera um sinal de `stall` para pausar o pipeline e garantir a leitura correta dos dados.

### `pipeline_flush`
* **Função:** Gera o sinal de `flush` para limpar o pipeline em caso de desvios tomados (branches) ou exceções.
* **Entradas:** `branch` (sinal indicando um desvio condicional), `flush` (sinal de flush externo/global).
* **Detalhes:** Quando um desvio é previsto incorretamente, ou uma interrupção ocorre, o pipeline precisa ser esvaziado para que as instruções corretas sejam buscadas.

### `data_extractor` (extrator de dados imediatos)
* **Função:** Extrai o valor imediato (literal) de diferentes formatos de instrução.
* **Entradas:** `instruction` (instrução completa).
* **Saídas:** `imm_data` (valor imediato de 64 bits).
* **Detalhes:** As instruções RISC-V utilizam diferentes formatos para constantes. Este módulo decodifica esses formatos para obter o valor imediato correto.

### `alu_control`
* **Função:** Determina a operação específica que a Unidade Lógica Aritmética (ULA) deve executar.
* **Entradas:** `Aluop` (da unidade de controle), `funct` (campos `funct3` e `funct7` da instrução).
* **Saídas:** `operation` (código para a ULA).
* **Detalhes:** Com base no tipo geral de operação (`ALUop`) e nos campos de função da instrução, esta unidade define a operação exata da ULA (soma, subtração, AND, OR, etc.).

### `branching_unit`
* **Função:** Determina se um desvio condicional deve ser tomado.
* **Entradas:** `funct3` (campo da instrução), `readData1`, `b` (operandos para comparação).
* **Saídas:** `addermuxselect` (sinal para o MUX que seleciona o próximo PC).
* **Detalhes:** Compara os operandos com base no tipo de desvio (BEQ, BNE, BLT, etc.) e sinaliza se o desvio deve ocorrer.

### `ForwardingUnit` (Unidade de Encaminhamento)
* **Função:** Resolve *hazards* de dados encaminhando resultados de estágios posteriores do pipeline para estágios anteriores, evitando stalls desnecessários.
* **Entradas:** `RS_1`, `RS_2` (registradores de origem), `rdMem` (registrador de destino do estágio EX/MEM), `rdWb` (registrador de destino do estágio MEM/WB), `regWrite_Wb` (escrita de registrador no estágio MEM/WB), `regWrite_Mem` (escrita de registrador no estágio EX/MEM).
* **Saídas:** `Forward_A`, `Forward_B` (sinais para os MUXes de encaminhamento).
* **Detalhes:** Se uma instrução no estágio EX ou MEM está prestes a escrever em um registrador que será lido por uma instrução anterior no estágio ID, esta unidade detecta isso e direciona o resultado da ULA ou da memória diretamente para a entrada da ULA ou dos registradores, em vez de esperar a escrita no banco de registradores.

---

## Estágios do Pipeline (Registradores de Pipeline)

### `IF_ID` (Instruction Fetch / Instruction Decode Register)
* **Função:** Armazena a instrução e o PC+4 do estágio de *Instruction Fetch* para o estágio de *Instruction Decode*.
* **Entradas:** `clk`, `reset`, `IFIDWrite` (controle de escrita), `instruction`, `A` (PC+4), `flush`.
* **Saídas:** `inst` (instrução para o próximo estágio), `a_out` (PC+4 para o próximo estágio).
* **Detalhes:** É um registrador que "sincroniza" os dados entre os estágios IF e ID. `IFIDWrite` é controlado pelo `stall` (para pausar a escrita quando há um stall).

### `ID_EX` (Instruction Decode / Execute Register)
* **Função:** Armazena os dados e sinais de controle do estágio de *Instruction Decode* para o estágio de *Execute*.
* **Entradas:** `clk`, `reset`, `flush`, `funct4_in`, `A_in` (PC+4), `readdata1_in`, `readdata2_in`, `imm_data_in`, `rs1_in`, `rs2_in`, `rd_in`, e todos os sinais de controle (`branch_in`, `memread_in`, etc.).
* **Saídas:** `a` (PC+4), `rs1`, `rs2`, `rd`, `imm_data`, `readdata1`, `readdata2`, `funct4_out`, e todos os sinais de controle (`Branch`, `Memread`, etc.) para o próximo estágio.
* **Detalhes:** Este registrador transfere os operandos lidos do banco de registradores, o valor imediato, os endereços dos registradores e os sinais de controle relevantes para o estágio de execução.

### `EX_MEM` (Execute / Memory Register)
* **Função:** Armazena os dados e sinais de controle do estágio de *Execute* para o estágio de *Memory Access*.
* **Entradas:** `clk`, `reset`, `flush`, `Adder_out` (endereço do desvio), `Result_in_alu` (resultado da ULA), `Zero_in` (sinal zero da ULA), `writedata_in` (dado a ser escrito na memória), `Rd_in` (registrador de destino), `addermuxselect_in` (sinal de desvio), e sinais de controle (`branch_in`, `memread_in`, etc.).
* **Saídas:** `Adderout` (endereço do desvio), `zero` (sinal zero da ULA), `result_out_alu` (resultado da ULA), `writedata_out` (dado a ser escrito na memória), `rd` (registrador de destino), e sinais de controle (`BRANCH`, `MEMREAD`, etc.).
* **Detalhes:** Este registrador passa o resultado da ULA (para escrita em registrador ou cálculo de endereço de memória), o dado a ser escrito na memória, o registrador de destino e os sinais de controle pertinentes para o estágio de memória.

### `MEM_WB` (Memory / Write-Back Register)
* **Função:** Armazena os dados e sinais de controle do estágio de *Memory Access* para o estágio de *Write-back*.
* **Entradas:** `clk`, `reset`, `read_data_in` (dado lido da memória), `result_alu_in` (resultado da ULA), `Rd_in` (registrador de destino), `memtoreg_in` (controle de mux), `regwrite_in` (controle de escrita de registrador).
* **Saídas:** `readdata` (dado lido da memória), `result_alu_out` (resultado da ULA), `rd` (registrador de destino), `Memtoreg` (controle de mux), `Regwrite` (controle de escrita de registrador).
* **Detalhes:** Este registrador propaga o dado lido da memória (se houver), o resultado final da ULA (para instruções tipo R ou imediatas) e os sinais de controle necessários para o estágio de escrita de volta (Write-back).

---

## Componentes Funcionais

### `pc` (Program Counter)
* **Função:** Armazena o endereço da próxima instrução a ser buscada.
* **Entradas:** `PC_in` (próximo valor do PC), `stall` (para pausar a atualização), `clk`, `reset`.
* **Saídas:** `PC_out` (valor atual do PC).
* **Detalhes:** O PC é atualizado a cada ciclo, geralmente para `PC_out + 4`, a menos que haja um desvio ou salto.

### `instruc_mem` (Memória de Instruções)
* **Função:** Fornece a instrução com base no endereço do PC.
* **Entradas:** `inst_address` (endereço da instrução, do PC).
* **Saídas:** `instruction` (instrução lida).
* **Detalhes:** Simula a memória onde o código do programa é armazenado.

### `somador` (Adder)
* **Função:** Realiza operações de adição de 64 bits.
* **Entradas:** `p`, `q` (operandos).
* **Saídas:** `out` (resultado da adição).
* **Detalhes:** Usado para calcular `PC + 4` e para o cálculo do endereço de desvio (PC + offset).

### `Parser` (Decodificador de Instruções)
* **Função:** Divide a instrução em seus campos constituintes (opcode, registradores, campos de função).
* **Entradas:** `instruction` (instrução de 32 bits).
* **Saídas:** `opcode`, `rd`, `funct3`, `rs1`, `rs2`, `funct7`.
* **Detalhes:** Essencial para que a unidade de controle e outras partes do pipeline saibam o que a instrução representa.

### `banco_regs` (Banco de Registradores)
* **Função:** Armazena os valores dos registradores de uso geral do RISC-V.
* **Entradas:** `clk`, `reset`, `rs1`, `rs2` (endereços de registradores para leitura), `rd` (endereço de registrador para escrita), `writedata` (dado a ser escrito), `reg_write` (sinal para habilitar a escrita).
* **Saídas:** `readdata1`, `readdata2` (dados lidos dos registradores), `r8`, `r19`, `r20`, `r21`, `r22` (registradores específicos, possivelmente para depuração ou observação).
* **Detalhes:** Permite a leitura de dois registradores e a escrita em um registrador em cada ciclo de clock.

### `Alu64` (Unidade Lógica Aritmética de 64 bits)
* **Função:** Executa operações aritméticas e lógicas em dados de 64 bits.
* **Entradas:** `a`, `b` (operandos), `ALuop` (código da operação).
* **Saídas:** `Result` (resultado da operação), `zero` (sinalizador de zero).
* **Detalhes:** A unidade central para a execução de instruções de tipo R e I.

### `cache_dados` (Cache de Dados)
* **Função:** Atua como um buffer de alta velocidade entre o processador e a memória principal de dados.
* **Entradas:** `clk`, `reset`, `address` (endereço de memória), `write_data` (dado a ser escrito), `mem_write` (sinal de escrita), `mem_read` (sinal de leitura).
* **Saídas:** `read_data` (dado lido), `miss` (sinal de cache miss), `mem_address` (endereço para a memória principal), `mem_write_data` (dado para a memória principal), `mem_read_out` (sinal de leitura para a memória principal), `mem_write_out` (sinal de escrita para a memória principal).
* **Detalhes:** A cache tenta servir as requisições de leitura/escrita de forma mais rápida. Em caso de `miss`, ela acessa a `data_memory` e gerencia o bloco de dados.

### `data_memory` (Memória de Dados Principal)
* **Função:** Simula a memória principal de dados, acessada pela cache em caso de `miss`.
* **Entradas:** `clk`, `address` (endereço na memória principal), `write_data` (dado a ser escrito), `mem_write` (sinal de escrita), `mem_read` (sinal de leitura).
* **Saídas:** `block_read_data` (bloco de dados lido).
* **Detalhes:** Esta é a memória de dados de "baixo nível" que armazena os dados do programa.

---

## Multiplexadores (MUXes)

### `doisx1Mux` (MUX 2 para 1)
* **Função:** Seleciona entre duas entradas com base em um sinal de seleção.
* **Entradas:** `A`, `B` (entradas de dados), `SEL` (sinal de seleção).
* **Saídas:** `Y` (saída selecionada).
* **Detalhes:** Usado em vários pontos para selecionar o próximo valor do PC, o segundo operando da ULA, ou o dado a ser escrito no registrador.

### `tresx1MUX` (MUX 3 para 1)
* **Função:** Seleciona entre três entradas com base em um sinal de seleção.
* **Entradas:** `a`, `b`, `c` (entradas de dados), `sel` (sinal de seleção).
* **Saídas:** `out` (saída selecionada).
* **Detalhes:** Usado principalmente na unidade de encaminhamento (`ForwardingUnit`) para selecionar o operando correto para a ULA.

---

## Módulo de Teste: `test_cache`

Este módulo é um *testbench* projetado para verificar o funcionamento da `cache_dados` de forma isolada. Ele simula interações com a cache e uma "memória principal" simplificada para observar seu comportamento (hits e misses).

### Entradas/Saídas de Teste:
* `clk`, `reset`, `mem_read`, `mem_write`, `address`, `write_data`: Sinais de controle e dados para a cache.
* `read_data`, `miss`: Saídas da cache.
* `mem_address`, `mem_write_data`, `mem_block_read_data`, `mem_ready`, `mem_read_out`, `mem_write_out`: Sinais para simular a interface com a memória principal.

### Funcionamento da Simulação:
1.  **Inicialização:** Reseta a cache e os sinais.
2.  **Primeiro Acesso (MISS):** Tenta ler um endereço (ex: `0x00000010`) que não está na cache. A simulação espera por um `miss` e exibe o dado "lido" da memória principal.
3.  **Segundo Acesso (MISS):** Tenta ler outro endereço (ex: `0x00000040`), resultando em outro `miss`.
4.  **Terceiro Acesso (HIT):** Tenta ler o primeiro endereço novamente (`0x00000010`), esperando que desta vez resulte em um `hit` (o dado já está na cache) e que o `miss` não seja ativado.
5.  **Memória Principal Simulada:** Um `assign` direto (`mem_block_read_data`) simula blocos de dados fixos na memória principal. O `mem_ready` é imediatamente ativo (`mem_read_out`) para simplificar a simulação da memória.

---

Espero que esta explicação ajude você a entender um pouco o funcionamento de cada parte do nosso processador RISC-V!
