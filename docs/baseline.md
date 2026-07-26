# Modelos de Referência (Baseline)

## 1. Objetivo

Definir modelos de IA com diferentes níveis de complexidade para comparação experimental com o Art3miz 0.1.

Os modelos permitem analisar o impacto da estratégia e do custo computacional no desempenho.

---

## 2. Modelos Definidos

### 2.1 IA Aleatória (Baseline Inferior)

#### Descrição

Seleciona uma ação aleatoriamente entre as possíveis.

#### Características

- Nenhuma estratégia
- Baixo custo computacional
- Alto nível de inconsistência

#### Objetivo

Servir como limite inferior de desempenho.

---

### 2.2 IA Reativa (Atacar ou Aproximar)

#### Descrição

Modelo baseado em regras simples:

- Se houver inimigo visível → atacar
- Caso contrário → mover em direção ao inimigo mais próximo

#### Características

- Decisão imediata
- Sem avaliação estratégica
- Baixa complexidade

#### Objetivo

Representar um agente funcional básico. É também o modelo que controla os dois agentes adversários em todas as avaliações, garantindo oposição idêntica entre os modelos comparados.

---

### 2.3 IA Heurística (Avaliação Local)

#### Descrição

Utiliza uma função de avaliação para selecionar ações com base em múltiplos fatores:

- vida
- cobertura
- proximidade
- risco

A ação com maior valor é escolhida.

#### Características

- Considera múltiplos critérios de cenário (vida, posicionamento, distância)
- Decisão estritamente local focada em ganho tático puramente abstrato (ValorEstratégico puro), em contrapartida ao Art3miz 0.1, que restringe essas mesmas escolhas à penalidade de recursos computacionais
- Complexidade moderada

#### Objetivo

Representar um agente com comportamento estratégico básico.

---

## 3. Modelo Avançado (Referência Teórica)

### 3.1 Monte Carlo Tree Search (MCTS)

#### Descrição

O MCTS é um algoritmo de busca baseado em simulação que avalia ações explorando múltiplos cenários futuros, equilibrando exploração e aproveitamento (BROWNE et al., 2012). Implementação: `simulator/ai/ai_mcts.gd`.

#### Papel no estudo

**Ancora o extremo superior do espectro de compromisso.** Assim como a IA Aleatória estabelece o piso de desempenho, o MCTS estabelece a referência do que se obtém quando a qualidade da decisão é buscada sem restrição de processamento. Sem esse ponto, a curva de compromisso entre qualidade e custo ficaria aberta em uma das pontas.

#### Implementação

Quatro fases padrão — seleção por UCT (constante √2), expansão, simulação e retropropagação — com 60 simulações por decisão e profundidade de 6 turnos por *rollout*.

Duas adaptações ao domínio merecem registro:

- **Opera sobre o modelo de mundo percebido**, não sobre o estado real. Como a percepção é limitada, a busca considera apenas os inimigos que o agente enxerga — do contrário, o MCTS seria onisciente e a comparação, injusta.
- **Cada operação da busca é contabilizada** pelo mesmo medidor de custo dos demais modelos, nos mesmos termos.

#### Características observadas

- Considera múltiplos turnos futuros
- Maior taxa de vitória entre os modelos avaliados
- **Custo computacional muito superior** — cerca de seis vezes o do Art3miz 0.1

Resultados quantitativos em `resultados_finais.md`.

---

## 4. Execução Experimental

Todos os modelos implementados serão avaliados sob as mesmas condições.

### Configuração

- 1000 simulações por modelo
- Mesmo banco de *seeds* para todos (mapas e posições de nascimento idênticos entre modelos)
- Rotação uniforme da ordem inicial de jogo
- O modelo avaliado controla um agente; os outros dois executam a IA Reativa como adversário padrão

---

## 5. Métricas Coletadas

- WinRate
- Damage Ratio
- Cover Usage
- Turns to Victory
- Custo Computacional Médio

---

## 6. Análise

Os resultados permitirão:

- comparar diferentes níveis de inteligência
- avaliar eficiência estratégica
- analisar custo computacional

---

## 7. Relação com o Art3miz 0.1

O modelo híbrido foi comparado com os modelos baseline (ver `resultados_finais.md`) para verificar:

- ganhos de desempenho
- eficiência computacional
- qualidade das decisões

A comparação com MCTS será feita de forma conceitual, utilizando-o como referência de desempenho ideal.