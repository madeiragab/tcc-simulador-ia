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

### 0. Fundamentação

- **fundamentacao_teorica.md**: Racionalidade limitada (Simon), metarraciocínio e valor da computação (Russell & Wefald), algoritmos *anytime* (Zilberstein) e racionalidade computacional. Situa o modelo proposto na literatura e mostra que o resultado negativo obtido é corolário do princípio clássico.

### 2. Metodologia Científica e Analítica
- **problema.md**: Contexto, problema de pesquisa, questão central e hipótese.
- **contribuicao.md**: A contribuição central do trabalho — o modelo híbrido de decisão baseado em equilíbrio entre valor estratégico e custo computacional.
- **metodologia.md**: Configuração experimental padronizada para garantir reprodutibilidade.
- **experiments.md**: Planejamento dos experimentos em lote (1000 *seeds* de benchmark + 200 de validação).
- **coleta_dados.md**: Estrutura de registro dos resultados em `data/` em formato CSV.
- **metricas.md**: Fórmulas das métricas individuais e da métrica composta (*Strategic Score*), com proteções numéricas (ε contra divisão por zero).

### 5. Resultados

Os documentos abaixo estão em ordem cronológica; **`resultados_finais.md` é o
documento de referência** — os anteriores registram etapas do percurso e foram
coletados sob versões anteriores das regras.

- **resultados_validacao.md**: Experimento zero — primeira validação da neutralidade do ambiente (versão inicial das mecânicas). Superado pela seção 5.1 de `resultados_finais.md`.
- **resultados_campanha.md**: Campanha de caracterização dos modelos base (etapas 1 e 2 do protocolo), anterior à introdução do sensor de proximidade e à correção da métrica composta. Mantido pelo valor metodológico da análise de decomposição de custo.
- **resultados_hibrido.md**: Calibração do Art3miz 0.1 — inclui o resultado negativo da formulação direta e a varredura do parâmetro λ.
- **resultados_finais.md**: **Benchmark oficial** — 7.000 partidas sob as regras definitivas, com a métrica corrigida e as afirmações submetidas a teste de significância. Documento de referência para os resultados do trabalho.
- **generalizacao.md**: Replicação do confronto em três escalas de mapa (25×25, 40×40, 60×60) — verifica quais achados são propriedade do modelo e quais eram da configuração original.
- **sensibilidade_pesos.md**: Análise de sensibilidade dos pesos do StrategicScore — ponderações alternativas, casos extremos, 10.000 vetores aleatórios e teste de dominância de Pareto. Responde à crítica de arbitrariedade dos pesos.
- **analise_estatistica.md**: Relatório de significância gerado automaticamente a partir dos dados brutos — qui-quadrado, testes binomiais condicionais, testes t pareados por *seed*, intervalos de Wilson e *bootstrap*. Reproduzível por comando.

### 3. Concepção das Inteligências
- **ia.md**: O paradigma reativo de Utility AI, geração/filtragem/avaliação de ações e seleção da melhor.
- **baseline.md**: Modelos de referência para comparação — Aleatória e Reativa (piso e agente funcional), Heurística (Utility AI) e MCTS (ancoragem do extremo de alto custo, implementado).
- **modelo_proposto.md**: Especificação do Art3miz 0.1 — por que a formulação direta é inerte e como a reformulação aplica o compromisso na decisão de deliberar.

### 4. Planejamento de Desenvolvimento
- **roadmap_implementacao.md**: Cronograma em 5 fases, das mecânicas elementares ao *benchmark* final, com status de progresso.
