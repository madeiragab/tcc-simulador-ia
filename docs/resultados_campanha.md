# Resultados da Campanha de Coleta (Etapas 1 e 2)

> **Documento histórico.** Esta campanha foi executada antes da introdução do
> sensor de proximidade e da correção da normalização do StrategicScore. Os
> valores de escore aqui reportados seguem a fórmula antiga (não normalizada) e
> não são comparáveis aos de `resultados_finais.md`, que é o documento de
> referência dos resultados do trabalho. Mantido pelo valor metodológico da
> análise de decomposição de custo (seção 2.1), que orientou o desenho do
> Art3miz 0.1.

Campanha executada em 21/07/2026 sobre o banco oficial de 1000 *seeds* de benchmark, sob o conjunto final de regras (percepção por cone de 120°, tiro em linha reta, cobertura direcional, pontuação +3/−1/−3, aprendizado entre partidas). 4 lotes × 1000 partidas × 3 agentes = 12.000 registros por jogador. Runs completas em `data/runs/`:

| Campanha | Escalação | Pasta |
|---|---|---|
| 1 | 3x Aleatória | `2026-07-21_17-34-46_benchmark_1000` |
| 2 | 3x Reativa | `2026-07-21_19-33-37_benchmark_1000` |
| 3 | 3x Heurística | `2026-07-21_20-06-42_benchmark_1000` |
| 4 | Misto (aleatória × reativa × heurística) | `2026-07-21_20-46-32_benchmark_1000` |

## 1. Etapa 1 — Autoconfrontos (caracterização isolada)

### 1.1 Neutralidade re-validada sob as regras finais

No autoconfronto reativo, os WinRates foram **0,231 / 0,232 / 0,225** (diferença máxima de 0,7 ponto percentual, dentro do ruído esperado de ±1,5 pp) — a neutralidade do ambiente, já demonstrada na versão inicial das mecânicas, permanece válida sob percepção limitada, tiro reto e demais regras definitivas. O autoconfronto heurístico repete o padrão (0,191 / 0,216 / 0,203).

### 1.2 Assinatura comportamental de cada modelo

| Métrica (média por jogador) | 3x Aleatória | 3x Reativa | 3x Heurística |
|---|---|---|---|
| Pontuação média | −1,00 | −1,00 | −1,00 |
| WinRate | 0,000 | 0,229 | 0,203 |
| Empates | **100%** | 31,2% | 39,0% |
| TurnsToVictory | 100 | 74,1 | 79,9 |
| CoverUsage | 0,051 | 0,051 | **0,078** |
| Custo computacional | 2322 | 880 | 1243 |

Achados:

- **Aleatória define o piso absoluto**: 1000 partidas, 1000 empates, nenhuma vitória. Três agentes aleatórios não se matam em 100 turnos. A pontuação de partida (−1 por empate) captura corretamente essa inação como comportamento ruim — sem ela, o modelo pareceria "neutro".
- **O custo da aleatória (2322) é o maior de todos os autoconfrontos** — ela enumera todas as opções a cada turno e joga fora a informação. Custo sem benefício: pagou mais que a reativa (880) para ganhar nada.
- **Espelhos empatam por construção** (pontuação média ≈ −1,00 em todos): em jogo simétrico de soma negativa com empate penalizado, o self-play não diferencia modelos — ele serve para caracterizar comportamento (empates, duração, cobertura, custo), não eficácia. A diferenciação vem do confronto misto.
- **A heurística joga "mais posicional" contra si mesma**: mais cobertura (+53%), partidas mais longas (79,9 vs 74,1) e mais empates (39% vs 31%) — heurísticas mutuamente cautelosas se anulam.

## 2. Etapa 2 — Confronto misto (o gradiente de inteligência)

Uma IA de cada na mesma arena, 1000 partidas (633 empates):

| Métrica | Aleatória | Reativa | Heurística |
|---|---|---|---|
| **Pontuação média** | −1,57 | −0,83 | **−0,59** |
| WinRate | 0,027 | 0,150 | **0,190** |
| DamageRatio | 0,11 | 11,17 | **13,08** |
| CoverUsage | 0,047 | 0,060 | **0,072** |
| TurnsToVictory | 97,8 | 90,8 | **88,3** |
| Custo computacional | 1520 | 1358 | 1811 |
| StrategicScore | 0,04 | 2,29 | **2,69** |

O gradiente de inteligência aparece em **todas** as métricas de eficácia, na ordem esperada: heurística > reativa > aleatória. A heurística vence 27% mais que a reativa (0,190 vs 0,150), converte muito melhor a pontuação (−0,59 vs −0,83) e domina o StrategicScore — ao custo de **33% mais operações** (1811 vs 1358).

### 2.1 Decomposição do custo (para onde vai o processamento)

| Componente (média/partida) | Aleatória | Reativa | Heurística |
|---|---|---|---|
| Linha de visão (LOS) | 9 | 12 | **180** |
| Nós de busca (BFS) | 1511 | 1346 | 1462 |
| Ações avaliadas | ~0 | 0 | **169** |

A base de custo de todos os modelos é a busca de caminho (perseguição/exploração sob percepção limitada). O *diferencial* da heurística — os +453 ops sobre a reativa — está concentrado no **loop de avaliação posicional** (LOS de risco por célula candidata + ações pontuadas). É exatamente esse loop que o modelo híbrido deve disciplinar.

### 2.2 O aprendizado funcionou no misto

No autoconfronto (espelho), o hill-climbing quase não adotou perturbações (13 de 120 janelas) — os pesos iniciais já eram um ótimo local contra oponente idêntico. No misto, contra oponentes reais, o aprendizado **melhorou mensuravelmente**: a janela 1 rendeu −0,44 de média; a janela 3 adotou uma configuração com **+0,04**; a janela 40 fechou adotando **+0,20** — pontuação positiva sustentada. A melhor configuração adotada foi:

`w_vida = 0,092 | w_cobertura = 0,307 | w_proximidade = 0,495 | w_risco = −0,228`

(evolução completa em `aprendizado.csv` de cada run). A direção do ajuste — menos peso em vida, mais aversão a risco — é um resultado empírico que informa os pesos de partida do modelo híbrido.

## 3. Implicações para o Modelo Híbrido (Etapa 4)

Os dados da campanha fundamentam a especificação:

1. **O que penalizar**: o custo marginal da heurística está no loop de avaliação (LOS + ações). A leitura natural do termo `CustoComputacional` no `ScoreAção = ValorEstratégico − λ×Custo` é o **custo de avaliar a própria ação** (delta do medidor durante a avaliação da candidata) — penaliza avaliações caras, preservando as baratas.
2. **Pesos de partida**: usar a configuração aprendida no misto (acima), não os valores de projeto.
3. **Faixa de λ**: o custo por ação avaliada é da ordem de 3–10 operações e o ValorEstratégico é da ordem de 0,1–0,7; λ na faixa 0,005–0,05 coloca a penalidade na mesma escala do valor. Varredura em {0,005; 0,01; 0,02; 0,05} no banco de tuning (200 seeds).
4. **Meta quantitativa do híbrido** (critério de sucesso da hipótese): pontuação média ≥ −0,59 (heurística) com custo < 1811, idealmente aproximando-se do patamar da reativa (~1360).

## 4. Reprodução

```bash
godot --headless --path simulator -- batch 1000 benchmark verde=aleatoria vermelho=aleatoria azul=aleatoria
godot --headless --path simulator -- batch 1000 benchmark verde=reativa vermelho=reativa azul=reativa
godot --headless --path simulator -- batch 1000 benchmark verde=heuristica vermelho=heuristica azul=heuristica
godot --headless --path simulator -- batch 1000 benchmark verde=aleatoria vermelho=reativa azul=heuristica
```

Execuções determinísticas: os mesmos comandos reproduzem os mesmos resultados byte a byte.
