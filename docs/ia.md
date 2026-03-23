# Modelo de Tomada de Decisão da IA

## 1. Visão Geral

A IA é responsável por escolher a melhor ação possível a cada turno, baseada em uma função de avaliação estratégica.

O modelo segue um processo de decisão baseado em avaliação de ações possíveis no estado atual do ambiente.

---

## 2. Geração de Ações

Para cada turno, o agente gera um conjunto de ações possíveis:

- Movimentos para todas as posições alcançáveis (até 3 células)
- Ações de ataque (quando houver linha de visão)

As ações são avaliadas individualmente.

---

## 3. Filtragem de Ações

Para evitar explosão de complexidade, ações irrelevantes são descartadas antes da avaliação:

- posições sem qualquer linha de visão de inimigos
- posições com risco extremamente alto
- posições redundantes (muito próximas ou equivalentes)

---

## 4. Avaliação de Ações

Cada ação recebe um valor estratégico calculado pela função:

ValorEstratégico =
0.3 * vida +
0.3 * cobertura +
0.2 * proximidade +
-0.4 * risco

Onde:

- vida = HP atual normalizado
- cobertura = nível de proteção (0, 1 ou 2)
- proximidade = 1 / distância até o inimigo
- risco = número de inimigos com linha de visão

---

## 5. Seleção da Ação

A IA escolhe a ação com maior valor estratégico.

---

## 6. Extensão do Modelo (Contribuição)

O modelo será estendido para considerar custo computacional:

ScoreFinal = ValorEstratégico − λ × CustoComputacional

Onde:

- CustoComputacional representa o tempo de decisão
- λ controla o equilíbrio entre qualidade e custo

---

## 7. Considerações

- A IA não realiza planejamento de múltiplos turnos (decisão local)
- O modelo considera múltiplos inimigos simultaneamente
- O sistema será ajustado empiricamente com base nos resultados das simulações
