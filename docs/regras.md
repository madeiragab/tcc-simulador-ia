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
	- Célula transponível (não bloqueia movimento nem linha de visão)
	- Reduz o dano recebido quando está entre o defensor e o atacante (cobertura direcional)

- Cobertura pesada:
	- Célula transponível (não bloqueia movimento nem linha de visão)
	- Reduz significativamente o dano recebido, sob a mesma regra direcional

---

## 2. Agentes

A partida é disputada por 3 agentes independentes (todos contra todos), identificados por cor: verde, vermelho e azul. Cada agente possui os seguintes atributos:

- Posição (x, y)
- Vida (HP)
- Alcance de visão (também define o alcance de ataque)
- Estado (vivo ou morto)
- Identificador do jogador (cor)

### Estado Tático

- Proteção por cobertura: avaliada por confronto — o agente está protegido de um atacante quando existe célula de cobertura adjacente a ele na direção desse atacante
- Tipo de cobertura: leve ou pesada (prevalece a maior proteção)

### Percepção (Campo de Visão)

Os agentes **não são oniscientes**. Um agente só conhece a posição de um inimigo quando ele está dentro do seu campo de visão:

- Distância até o alcance de visão (Chebyshev)
- Linha de visão desobstruída: **paredes bloqueiam a visão; coberturas não**

Sem nenhum inimigo à vista, o agente age com base em memória e busca:

- **Memória tática**: guarda a última posição onde viu cada inimigo e caça a mais próxima; ao chegar lá e não encontrar nada, esquece
- **Exploração**: sem memória alguma, percorre destinos sorteados do mapa (RNG semeado pela *seed* da partida — o comportamento permanece determinístico e reprodutível)

---

## 3. Ações

Em cada turno, o agente pode:

1. Mover-se até 3 células (caminho validado por busca em largura, 4 direções, respeitando paredes)
2. Executar uma ação:
	 - Atacar um inimigo
	 - Permanecer na posição atual

A proteção de cobertura é direcional e automática: aplica-se quando há célula de cobertura adjacente ao agente na direção do atacante.

---

## 4. Sistema de Turnos

- O sistema é baseado em turnos sequenciais
- Cada agente realiza suas ações individualmente
- Um turno completo ocorre quando todos os agentes executam suas ações

---

## 4.1 Condição de Vitória

- A simulação encerra quando ocorre uma dentre duas condições: resta apenas um agente vivo, ou o limite fixo de 100 turnos é atingido.
- O último agente vivo é o vencedor.
- Se o limite de 100 turnos for atingido com dois ou mais agentes vivos, a partida termina em empate (*draw*), independentemente dos HPs restantes.

---

## 5. Combate

### Linha de Visão (LOS)

- Um agente só pode atacar se houver linha de visão direta
- Paredes bloqueiam completamente a visão

### Alcance e Linha de Tiro

- O alcance de ataque é igual ao alcance de visão do agente (distância de Chebyshev)
- **O tiro só é permitido em linha reta**: horizontal, vertical ou diagonal perfeita. Sem essa restrição, ataques em ângulos arbitrários contornariam a cobertura direcional, tornando as defesas irrelevantes

### Dano (Determinístico)

O dano é calculado de forma determinística:

Dano = ValorBase − Redução por Cobertura

A redução só se aplica se houver célula de cobertura adjacente ao alvo na direção do atacante (cobertura direcional).

Valores:
- Dano base: 30
- Cobertura leve: reduz 10
- Cobertura pesada: reduz 20

---

## 6. Métricas

As métricas de avaliação (WinRate, Damage Ratio, Cover Usage, Turns to Victory, Custo Computacional Médio) e a métrica composta *Strategic Score* estão definidas em `metricas.md`, que é a fonte única das fórmulas.

---

## 7. Contribuição Proposta (Modelo Híbrido)

O trabalho propõe um modelo de tomada de decisão que equilibra valor estratégico e custo computacional. A especificação completa está em `modelo_proposto.md` e `contribuicao.md`.
