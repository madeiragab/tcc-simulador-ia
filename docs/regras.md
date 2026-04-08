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

## 4.1 Condição de Vitória

- A simulação de um jogo/cenário é encerrada instantaneamente quando ocorre uma dentre duas condições: eliminação total de uma das partes rivais (*Total Annihilation*), ou atingimento de um limite fixo inflexível de 100 turnos (*Timeout Cap* de segurança procedural).
- A equipe sobrevivente é aclamada vencedora.
- Caso o limite de 100 turnos seja atingido estourando o tempo do jogo, um Empate (*Draw*) será decretado formalmente, independentemente dos HPs das equipes resultantes.

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

- Custo Computacional Médio:
        - Esforço algorítmico numérico (operações de matriz e LOS).

---

## 7. Strategic Score

Será definida uma métrica agregada para avaliação estratégica final com base estritamente formal:

StrategicScore =
0.3 * WinRate +
0.2 * DamageRatio +
0.2 * CoverUsage +
0.2 * Efficiency +
0.1 * (1 / max(CustoComputacionalMedio, ε))

Onde:
- Efficiency = 1 / max(TurnsToVictory, 1)
- $\epsilon = 1$ é uma constante técnica inserida para impedir a divisão por base zero sobre avaliações matemáticas nulas unitárias imediatas.

---

## 8. Contribuição Proposta (Modelo Híbrido)

O trabalho propõe o desenvolvimento de um modelo de tomada de decisão (Híbrido) baseado no equilíbrio entre valor estratégico (*Heurística*)  e custo computacional.

ScoreAção = ValorEstratégico − λ × CustoComputacional

Onde:
- ValorEstratégico considera fatores como posição, cobertura e dano esperado 
- CustoComputacional é o rastreio avaliatório contínuo (processamento via count formal para processamento em loop)
