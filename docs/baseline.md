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

O MCTS é um algoritmo de busca baseado em simulação que avalia ações por meio da exploração de múltiplos cenários futuros.

Ele equilibra exploração e exploração para encontrar decisões com melhor valor esperado.

#### Características

- Considera múltiplos turnos futuros
- Alta qualidade estratégica
- Alto custo computacional

#### Observação

O MCTS não será implementado neste trabalho, sendo utilizado apenas como referência teórica de modelos avançados de tomada de decisão.

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