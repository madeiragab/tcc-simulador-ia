# Documentação do Projeto

Este diretório concentra a base teórica, as definições de arquitetura e a configuração metodológica do simulador e dos experimentos de avaliação dos modelos de IA.

## Arquivos e Guias do Sistema

### 1. Sistema e Arquitetura
- **arquitetura.md**: Separação de responsabilidades entre os módulos de Core, Mapa, Agentes, IA, Turnos e Coleta.
- **agentes.md**: Atributos e estado dos agentes (posição, vida, visão, jogador).
- **movimento.md**: Regras de locomoção no *grid* (até 3 células por turno, caminho validado por BFS).
- **geracao_mapas.md**: Geração procedural de mapas por *seed* — divisão em 4 setores, sorteio de spawn dos 3 jogadores, obstáculos e validação de conectividade.
- **regras.md**: Regras do mundo simulado — tipos de célula, cobertura direcional, combate determinístico, condição de vitória.
- **turnos.md**: Ordem de execução dos agentes e rotação de iniciativa entre simulações.

### 2. Metodologia Científica e Analítica
- **problema.md**: Contexto, problema de pesquisa, questão central e hipótese.
- **contribuicao.md**: A contribuição central do trabalho — o modelo híbrido de decisão baseado em equilíbrio entre valor estratégico e custo computacional.
- **metodologia.md**: Configuração experimental padronizada para garantir reprodutibilidade.
- **experiments.md**: Planejamento dos experimentos em lote (1000 *seeds* de benchmark + 200 de validação).
- **coleta_dados.md**: Estrutura de registro dos resultados em `data/` em formato CSV.
- **metricas.md**: Fórmulas das métricas individuais e da métrica composta (*Strategic Score*), com proteções numéricas (ε contra divisão por zero).

### 3. Concepção das Inteligências
- **ia.md**: O paradigma reativo de Utility AI, geração/filtragem/avaliação de ações e seleção da melhor.
- **baseline.md**: Modelos de referência para comparação (Aleatória, Reativa, Heurística) e o MCTS como referência teórica.
- **modelo_proposto.md**: Especificação do modelo híbrido proposto (valor estratégico − λ × custo computacional).

### 4. Planejamento de Desenvolvimento
- **roadmap_implementacao.md**: Cronograma em 5 fases, das mecânicas elementares ao *benchmark* final, com status de progresso.
