# Banca 5 — Registro do que foi apresentado e erros a corrigir

**Data**: 04/11/2026 · Slides: `Banca_5_Validacao_Experimental_Gabriel_Madeira.pptx` / `.pdf`
Roteiro original: `banca_5_validacao.md`

Este documento existe para que a Banca 6 corrija, **de frente e com explicação**,
o que foi mostrado de forma imprecisa na Banca 5.

---

## 1. De onde vieram os números dos slides

Todos os resultados dos slides 7 a 10 vêm da **campanha de 21/07/2026**:

| Lote | Execução | Escalação |
|---|---|---|
| 1 | `data/runs/2026-07-21_17-34-46_benchmark_1000` | 3× Aleatória |
| 2 | `data/runs/2026-07-21_19-33-37_benchmark_1000` | 3× Reativa |
| 3 | `data/runs/2026-07-21_20-06-42_benchmark_1000` | 3× Heurística |
| 4 | `data/runs/2026-07-21_20-46-32_benchmark_1000` | uma de cada |

Cada lote: 1.000 partidas (1.000 *seeds* distintas), 3 agentes por partida
(3.000 linhas no CSV), no máximo 100 turnos por partida.

---

## 2. Erros e imprecisões

### Erro 1 — Os dados são de antes do sensor de proximidade

A campanha de 21/07 foi rodada **antes** da introdução do sensor de proximidade
(`docs/resultados_campanha.md` declara isso no topo). A Banca 4 já tinha
apresentado o sensor como parte do ambiente. Os resultados da Banca 5, portanto,
**não correspondem ao ambiente apresentado**.

Consequência mais visível — **empates**. Sem o sensor, os agentes não se
reencontram com facilidade e as partidas chegam ao limite de 100 turnos:

| Autoconfronto | Empates sem sensor (21/07) | Empates com sensor (25/07, oficial) |
|---|---|---|
| Aleatória | 100% | 100% |
| Reativa | 31% | **6,5%** |
| Heurística | 39% | **11,6%** |
| Confronto misto (uma de cada) | **63,3%** | *não foi rodado com sensor* |

No confronto misto sem sensor, 633 das 1.000 partidas empataram; em 77% desses
empates uma IA já tinha sido eliminada e as duas restantes não se reencontraram
até o turno 100. A taxa de empate é estável ao longo do lote (não é efeito do
aprendizado).

### Erro 2 — O p-valor do roteiro era de outra execução

O roteiro dizia "heurística × reativa, p = 0,757, não significativo". Esse valor
é da execução `2026-07-25_19-50-46` (Art3miz + Heurística + Reativa, com sensor:
339 × 330 vitórias), **não** da campanha de 21/07 cujas taxas estavam no slide.

Recalculado sobre os dados do slide (binomial condicional, mesmo método de
`docs/analise_estatistica.md`): **190 × 150 vitórias → p = 0,034**. Foi esse o
valor que entrou no slide apresentado: significativo a 5%, mas diferença pequena
(+4 pontos percentuais), com custo 33% maior (p < 0,001).

As duas afirmações são verdadeiras **cada uma no seu ambiente**:
- sem sensor (21/07): a heurística vence um pouco mais (p = 0,034);
- com sensor (25/07, oficial): não vence mais (p = 0,757).

### Erro 3 — Decomposição do custo ("84% na busca de caminho")

O roteiro trazia 1086 / 109 / 103 operações por partida; esses valores **não
foram reproduzidos** em nenhuma execução. Valores medidos para a Heurística:

| Campanha | Busca de caminho | Linha de visão | Ações avaliadas |
|---|---|---|---|
| Lote 3, sem sensor (21/07) | 1039 (84%) | 105 (8%) | 100 (8%) |
| Autoconfronto com sensor (`2026-07-25_22-21-47`) | 591 (**76%**) | 96 (12%) | 91 (12%) |

O slide mostrou só os percentuais 84/8/8 (corretos para o lote 3 sem sensor). No
ambiente oficial o número é **76%** — a conclusão (o custo mora na busca de
caminho, não na avaliação) se mantém.

### Erro 4 — A curva de aprendizado também é sem sensor

O slide 10 usa `aprendizado.csv` do lote 4 de 21/07 (−0,44 → +0,04 → +0,20). Com
sensor, as três heurísticas do autoconfronto de 25/07 têm curvas próprias (por
exemplo, uma delas vai de −1,08 a +0,28).

### O que falta rodar

O confronto **uma de cada** (Aleatória + Reativa + Heurística, sem Art3miz) **com
sensor** nunca foi executado. Se a Banca 6 precisar desse resultado, rodar antes.

---

## 3. Observações da banca

*(preencher depois da apresentação: perguntas feitas, críticas, pedidos)*

-
