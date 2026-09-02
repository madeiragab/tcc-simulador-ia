> 🇧🇷 **Português** · 🇬🇧 [English](README.en.md)

# Simulador Tático para Avaliação de IA

[![ci](https://github.com/madeiragab/tcc-simulador-ia/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/madeiragab/tcc-simulador-ia/actions/workflows/ci.yml)

[![demo](https://img.shields.io/badge/demo-assista%20uma%20partida-f0a830?style=for-the-badge&logo=godotengine&logoColor=white)](https://madeiragab.github.io/tcc-simulador-ia/)

> Uma partida real rodando no navegador, e os numeros do benchmark ao lado.

Ambiente de simulação tática por turnos construído para **medir a qualidade
estratégica de agentes de IA** — não apenas se ganham, mas quanto processamento
gastam para ganhar.

> Trabalho de Conclusão de Curso — Ciência da Computação, IFSulDeMinas.
> Autor: **Gabriel Madeira**.

## O problema

Comparar modelos de IA em jogos costuma parar no WinRate. Isso esconde duas
coisas: um agente pode vencer por sorte do cenário, e pode vencer gastando um
custo computacional que o tornaria inviável na prática.

Este trabalho constrói um ambiente **neutro, determinístico e reprodutível** onde
eficácia e custo são medidos lado a lado, e usa essa base para investigar um
**modelo híbrido de decisão** que equilibra os dois.

## O ambiente

- Grid 40x40 por turnos, **3 agentes independentes**, limite de 100 turnos.
- Mapas **gerados proceduralmente por seed** (4 setores, spawn sorteado,
  conectividade validada) — bancos fixos de 1000 seeds de benchmark e 200 de
  tuning garantem que todos os modelos enfrentem exatamente os mesmos cenários.
- **Percepção limitada**: cone de visão de 120° barrado por paredes, memória da
  última posição vista, revelação do atirador ao levar dano, e um **sensor de
  proximidade** (inspirado no detector de movimento de *Alien Isolation*) que dá
  direção e faixa de distância do inimigo mais próximo — nunca a posição exata.
- **Cobertura direcional** (só protege na direção do atacante) e **tiro em linha
  reta**, sem os quais a cobertura seria contornável por ângulo.
- Combate **determinístico**: toda a aleatoriedade está confinada à geração do mapa.
- **Rotação de iniciativa**: a partida *i* começa pelo jogador *i* mod 3.
- Execução **headless em lote** com exportação CSV autodocumentada.

Neutralidade validada empiricamente: 1000 partidas com três IAs idênticas
produziram WinRates estatisticamente equivalentes (0,306 / 0,328 / 0,301 —
dentro da flutuação esperada de ±1,5 pp para N=1000).

## Os modelos comparados

| Modelo | Mecanismo |
|---|---|
| **Aleatória** | Sorteia entre as ações válidas — piso absoluto de referência |
| **Reativa** | Regras fixas: atacar se há linha de tiro, senão aproximar ou caçar |
| **Heurística** | Utility AI multicritério + hill-climbing nos pesos entre partidas |
| **Art3miz 0.1** | Modelo proposto — decide *se vale deliberar* antes de deliberar |
| **MCTS** | Busca em árvore Monte Carlo — ancora o extremo de alta qualidade e alto custo |

## O Art3miz 0.1

A formulação de partida penalizava cada ação pelo custo de avaliá-la:

```text
ScoreAção = ValorEstratégico − λ × CustoComputacional
```

**Essa formulação não funciona neste domínio, e o porquê é um dos resultados do
trabalho.** Duas razões medidas: o loop de avaliação responde por apenas 16% do
custo (84% é a busca de caminho, executada todo turno); e como avaliar qualquer
posição custa praticamente o mesmo, o termo vira uma constante somada a todas as
candidatas — formalmente, `argmax[Valor − λk] = argmax[Valor]`. O λ é inerte.

A reformulação aplica o mesmo compromisso um nível acima, na decisão sobre o
próprio procedimento de decisão:

```text
ValorEmJogo − λ × CustoEstimado > 0   →   delibera
```

O agente estima o que está em jogo (inimigos à vista, proximidade, própria
vulnerabilidade) e só paga pela avaliação posicional completa quando compensa.
Com λ = 0 delibera sempre (equivale à heurística); com λ alto, nunca (equivale à
reativa). Fora do regime de deliberação, move-se por passo guloso (~4 operações
em vez de ~25 nós de busca), recorrendo à busca completa apenas ao caçar uma
posição já conhecida.

## Resultados

**Mais de 14.000 partidas** no banco oficial, distribuídas em autoconfrontos,
confrontos diretos, replicação em três escalas de mapa e calibração. Todas as
afirmações comparativas foram submetidas a **teste de significância**
([análise completa](docs/analise_estatistica.md)).

### Autoconfronto — desempenho global

| Modelo | WinRate | Empates | Custo | **StrategicScore** |
|---|---|---|---|---|
| Aleatória | 0,000 | 100% | 2323 | 0,145 |
| Reativa | 0,312 | 6,5% | 437 | 0,473 |
| Heurística | 0,295 | 11,6% | 777 | 0,438 |
| **Art3miz 0.1** | **0,314** | **5,7%** | **379** | **0,497** |

O Art3miz 0.1 obtém **o maior StrategicScore do estudo**, liderando quatro
das cinco dimensões: vence mais, usa mais cobertura, decide as partidas mais
rápido (29 turnos contra 45 da heurística) e gasta **51% menos** que ela.
Em eficiência — vitórias por mil operações — entrega 0,829 contra 0,380 da
heurística: mais que o dobro.

### Confronto direto — o contraponto honesto

| Métrica | Art3miz 0.1 | Heurística | Reativa |
|---|---|---|---|
| WinRate | 0,225 | **0,339** | 0,330 |
| Custo | **510** | 719 | 484 |
| StrategicScore | 0,426 | 0,467 | **0,472** |

Contra adversários que pagam o custo pleno da análise, **o Art3miz 0.1 vence
menos**. A economia tem preço: ao pular a deliberação, o agente às vezes perde a
posição que a avaliação completa encontraria.

### O espectro completo — e o valor marginal da computação

Com o MCTS ancorando o extremo caro, é possível medir quanto custa cada ganho:

| | MCTS | Heurística | Art3miz 0.1 |
|---|---|---|---|
| WinRate | **0,379** | 0,292 | 0,236 |
| Custo | 2794 | 681 | **471** |
| Eficiência (vit./mil ops) | 0,136 | 0,429 | **0,501** |

**Custo por vitória adicional**: ≈ 3.750 operações de Art3miz para Heurística,
≈ 24.300 de Heurística para MCTS. **Retorno fortemente decrescente** — este é o
compromisso central do trabalho, quantificado.

### Generalização — e o limite do modelo

Replicando em três escalas, a economia sobre a heurística **cresce com o
tamanho do mapa**: −16% (25×25), −29% (40×40), **−49%** (60×60). Coerente com o
mecanismo: mapas maiores têm mais turnos sem contato visual, e é aí que a
deliberação é dispensada.

**Mas há um limite honesto**: em mapas 25×25 a IA Reativa é *simultaneamente*
mais barata e mais eficaz que o modelo proposto. Onde toda situação é crítica,
não há o que economizar. O modelo tem [faixa de aplicabilidade](docs/generalizacao.md),
e ela está delimitada.

**Conclusão**: a hipótese de eficiência confirma-se; a de superioridade
competitiva, não. O trabalho demonstra que o compromisso entre qualidade e custo
é mensurável, controlável por λ e explicitável como decisão de projeto — um
controle que os modelos de referência não oferecem.

Dois achados adicionais, ambos com respaldo estatístico: a **IA Reativa é um
baseline notavelmente forte** — a heurística **não vence significativamente
mais** que ela (p = 0,757) embora custe 48% a mais; e a liderança do Art3miz no
escore composto é **robusta à escolha dos pesos** da métrica (lidera em 100% de
10.000 ponderações aleatórias — [análise](docs/sensibilidade_pesos.md)).

Análise completa: [resultados_finais.md](docs/resultados_finais.md).

## Como executar

Requer [Godot 4](https://godotengine.org/).

Modo visual (assistir partidas em loop):

```bash
godot --path simulator
```

Modo headless em lote (coleta de dados):

```bash
godot --headless --path simulator -- batch 1000 benchmark verde=art3miz vermelho=heuristica azul=reativa
```

Argumentos: `batch <N> <banco>` onde `banco` é `benchmark` (1000 seeds) ou
`tuning` (200 seeds), seguido da escalação `<cor>=<modelo>` para `verde`,
`vermelho` e `azul`. Modelos: `aleatoria`, `reativa`, `heuristica`, `art3miz`, `mcts`.
Opcionais: `turnos` (log turno a turno), `mapa=<n>` (tamanho do grid),
`lambda=<v>` e `budget=<n>` (calibração
do modelo híbrido).

Cada execução grava uma pasta em `data/runs/<timestamp>_<banco>_<N>/` com
`partidas.csv` (uma linha por jogador por partida, com métricas brutas,
derivadas e custo aberto por tipo de operação), `resumo.csv` (agregados),
`aprendizado.csv` (evolução dos pesos) e `manifest.txt` (configuração exata).

**As execuções são determinísticas**: os mesmos comandos reproduzem os mesmos
resultados, byte a byte.

## Documentação

A pasta [`docs/`](docs) contém a base teórica e metodológica completa —
[índice comentado aqui](docs/README.md). Os principais:

| Doc | Assunto |
|---|---|
| [fundamentacao_teorica.md](docs/fundamentacao_teorica.md) | **Racionalidade limitada e metarraciocínio** — a base teórica |
| [problema.md](docs/problema.md) | Contexto, questão de pesquisa e hipótese |
| [contribuicao.md](docs/contribuicao.md) | A contribuição central do trabalho |
| [arquitetura.md](docs/arquitetura.md) | Separação entre Core, Mapa, Agentes, IA, Turnos e Coleta |
| [regras.md](docs/regras.md) | Regras do mundo simulado |
| [geracao_mapas.md](docs/geracao_mapas.md) | Geração procedural por seed |
| [ia.md](docs/ia.md) | Utility AI e aprendizado entre partidas |
| [modelo_proposto.md](docs/modelo_proposto.md) | Especificação do modelo híbrido |
| [metricas.md](docs/metricas.md) | Métricas e o StrategicScore normalizado |
| [metodologia.md](docs/metodologia.md) | Configuração experimental |
| [resultados_hibrido.md](docs/resultados_hibrido.md) | Calibração do λ e o resultado negativo da formulação direta |
| [resultados_finais.md](docs/resultados_finais.md) | **Benchmark oficial e conclusões** |
| [analise_estatistica.md](docs/analise_estatistica.md) | Testes de significância sobre os dados brutos |
| [sensibilidade_pesos.md](docs/sensibilidade_pesos.md) | Robustez do ranking à escolha dos pesos da métrica |
| [generalizacao.md](docs/generalizacao.md) | Replicação em três escalas de mapa |
| [roadmap_implementacao.md](docs/roadmap_implementacao.md) | Fases e status |

## Estrutura do repositório

```text
/
├─ simulator/               → projeto Godot 4
│  ├─ core/                 → simulação, turnos, lote, métricas, custo
│  ├─ ai/                   → ai_base, ai_random, ai_reactive, ai_heuristic, ai_hybrid
│  ├─ agents/               → estado e atributos dos agentes
│  ├─ map/                  → grid e geração procedural
│  └─ tools/                → geradores auxiliares e recálculo de resumos
├─ docs/                    → base teórica, metodologia e resultados
├─ diagrams/                → arquitetura, fluxo, decisão e métricas
├─ experiments/             → bancos de seeds (benchmark e tuning)
├─ data/runs/               → execuções oficiais (CSV + manifest)
├─ monografia/              → monografia final (PDF) e referências da banca
└─ presentation/            → apresentação de banca
```

## Status

**Fases 1 a 5 concluídas**: ambiente, infraestrutura experimental, os três
modelos base, o Art3miz 0.1 calibrado e o benchmark oficial de 7.000
partidas, com resultados analisados. Detalhes em
[roadmap_implementacao.md](docs/roadmap_implementacao.md).

## Tecnologias

- **Godot 4** / GDScript — simulação, execução headless em lote e geração de documentos
- CSV como formato de intercâmbio, aberto a qualquer ferramenta de análise
