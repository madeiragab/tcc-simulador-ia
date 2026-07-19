# Resultados das Execuções (Runs)

Cada pasta aqui é uma execução de lote do simulador, **autodocumentada e imutável** — o nome carrega data/hora, banco de seeds e número de partidas (ex.: `2026-07-19_19-16-29_benchmark_1000`).

> Política de versionamento: runs de exploração ficam fora do git (`.gitignore`). Apenas execuções oficiais da pesquisa são commitadas deliberadamente, como artefatos permanentes.

## Como ler uma run (para quem chega de fora)

Todos os arquivos abrem em qualquer planilha (Excel, Google Sheets, LibreOffice) ou pandas.

### 1. `manifest.txt` — comece por aqui
As condições exatas da execução: quando rodou, qual banco de seeds, qual modelo de IA controlava cada jogador, todas as constantes de jogo (dano, coberturas, limite de turnos) e a duração. Garante que você sabe *o que* foi medido antes de olhar números.

### 2. `resumo.csv` — a resposta
Uma linha por jogador com as métricas agregadas do lote: WinRate, DamageRatio (média ± desvio padrão), CoverUsage, TurnsToVictory, Efficiency, custo computacional médio e o **StrategicScore** (métrica composta final — fórmula em `docs/metricas.md`).

### 3. `partidas.csv` — a evidência
Uma linha por jogador por partida (3 linhas por partida). Contém a seed do mapa, quem iniciou a partida, vencedor, turnos, dano causado/recebido, as métricas derivadas (damage_ratio, cover_usage) e o custo computacional total e aberto por tipo de operação (linha de visão, nodos de busca, ações avaliadas). Qualquer número do `resumo.csv` pode ser recalculado a partir daqui.

### 4. `turnos.csv` — o microscópio (opcional)
Presente quando o lote rodou com a flag `turnos`: para cada turno de cada agente, a ação escolhida, posição, se terminou protegido por cobertura e quantos inimigos via. Permite reconstruir uma partida passo a passo.

## Reprodutibilidade

Toda execução é determinística. Para reproduzir uma run, use o mesmo banco e quantidade do `manifest.txt`:

```bash
godot --headless --path simulator -- batch <N> <banco> [turnos]
```

Para reassistir uma partida específica visualmente, abra o projeto no Godot e rode com a seed dela (coluna `seed` do `partidas.csv`):

```bash
godot --path simulator -- <seed>
```

## Runs oficiais commitadas

- **`2026-07-19_19-16-29_benchmark_1000/`** — Validação de neutralidade do ambiente: 3 jogadores com IA Reativa idêntica sobre as 1000 seeds oficiais. WinRates 0.297 / 0.298 / 0.310 (diferenças dentro do ruído estatístico) — análise completa em `docs/resultados_validacao.md`.
