# Modelos de Referência (Baseline)

## 1. Objetivo

Definir modelos de IA com diferentes níveis de complexidade para comparação experimental com o modelo proposto.

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

Representar um agente funcional básico.

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
- Decisão estritamente local focada em ganho tático puramente abstrato (ValorEstratégico puro), em contrapartida ao Modelo Proposto, que restringe essas mesmas escolhas à penalidade de recursos computacionais
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
- Ambiente fixo
- Condições iniciais controladas

---

## 5. Métricas Coletadas

- WinRate
- Damage Ratio
- Cover Usage
- Turns to Victory
- Tempo de Decisão

---

## 6. Análise

Os resultados permitirão:

- comparar diferentes níveis de inteligência
- avaliar eficiência estratégica
- analisar custo computacional

---

## 7. Relação com o Modelo Proposto

O modelo híbrido será comparado com os modelos baseline para verificar:

- ganhos de desempenho
- eficiência computacional
- qualidade das decisões

A comparação com MCTS será feita de forma conceitual, utilizando-o como referência de desempenho ideal.