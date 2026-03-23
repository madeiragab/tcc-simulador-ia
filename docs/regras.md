# Regras do Simulador Tático

## 1. Ambiente

O ambiente é representado por um grid bidimensional de tamanho NxN (padrão 40x40), onde cada célula possui um tipo específico.

### Tipos de Célula

- Vazio:
	- Permite movimentação
	- Não fornece bônus defensivo

- Parede:
	- Bloqueia movimentação
	- Bloqueia linha de visão

- Cobertura leve:
	- Permite movimentação adjacente
	- Reduz dano recebido

- Cobertura pesada:
	- Permite movimentação adjacente
	- Reduz significativamente o dano recebido

---

## 2. Agentes

Cada agente possui os seguintes atributos:

- Posição (x, y)
- Vida (HP)
- Alcance de visão
- Estado (vivo ou morto)

### Estado Tático

- Em cobertura: definido automaticamente com base na posição
- Tipo de cobertura: leve ou pesada

---

## 3. Ações

Em cada turno, o agente pode:

1. Mover-se até 3 células (utilizando pathfinding)
2. Executar uma ação:
	 - Atacar um inimigo
	 - Permanecer na posição atual

A cobertura é aplicada automaticamente quando o agente está posicionado próximo a elementos de cobertura.

---

## 4. Sistema de Turnos

- O sistema é baseado em turnos sequenciais
- Cada agente realiza suas ações individualmente
- Um turno completo ocorre quando todos os agentes executam suas ações

---

## 5. Combate

### Linha de Visão (LOS)

- Um agente só pode atacar se houver linha de visão direta
- Paredes bloqueiam completamente a visão

### Alcance

- Ataques possuem alcance fixo (definido no sistema)

### Dano (Determinístico)

O dano é calculado de forma determinística:

Dano = ValorBase − Redução por Cobertura

Exemplo:
- Dano base: 30
- Cobertura leve: reduz 10
- Cobertura pesada: reduz 20

---

## 6. Métricas

As seguintes métricas serão utilizadas para avaliação:

- WinRate:
	- Percentual de vitórias em múltiplas simulações

- Damage Ratio:
	- Dano causado / dano recebido

- Cover Usage:
	- Percentual de turnos em cobertura

- Turns to Victory:
	- Número médio de turnos para vencer

- Tempo de Decisão:
	- Tempo médio para escolha de ação por agente

---

## 7. Strategic Score

Será definida uma métrica agregada para avaliação estratégica:

StrategicScore =
0.3 * WinRate +
0.2 * DamageRatio +
0.2 * CoverUsage +
0.2 * Efficiency +
0.1 * (1 / TempoDecisão)

Onde:
- Efficiency = 1 / TurnsToVictory

---

## 8. Contribuição Proposta

O trabalho propõe o desenvolvimento de um modelo de tomada de decisão baseado no equilíbrio entre valor estratégico e custo computacional.

ScoreAção = ValorEstratégico − λ × CustoComputacional

Onde:
- ValorEstratégico considera fatores como posição, cobertura e dano esperado
- CustoComputacional representa o tempo necessário para avaliar a ação
- λ é um parâmetro de ajuste do equilíbrio

O objetivo é encontrar decisões que sejam estrategicamente eficientes sem custo computacional excessivo.
