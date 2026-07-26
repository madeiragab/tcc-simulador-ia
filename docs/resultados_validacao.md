# Resultados Preliminares — Validação do Ambiente

> **Documento histórico.** Primeira validação de neutralidade, executada sobre a
> versão inicial das mecânicas (antes da percepção limitada, do sensor de
> proximidade e do tiro em linha reta). A validação definitiva, sob as regras
> finais, está na seção 5.1 de `resultados_finais.md`. Mantido como registro do
> percurso metodológico.

## Objetivo do experimento

Antes de comparar modelos de IA, é preciso provar que o ambiente de simulação não introduz viés — ou seja, que nenhum jogador vence mais por causa do mapa, do setor de nascimento ou da ordem de turno. Este é o "experimento zero" do trabalho: a validação do instrumento de medição.

**Método**: se os 3 jogadores usam exatamente a mesma IA, qualquer diferença sistemática de desempenho entre eles só pode vir do ambiente. Um ambiente neutro deve produzir taxas de vitória estatisticamente indistinguíveis.

## Configuração

- 1000 partidas sobre o banco oficial de *seeds* de benchmark (`experiments/seeds_benchmark.txt`)
- 3 jogadores independentes (verde, vermelho, azul), todos controlados pela **mesma IA Reativa**
- Mapas gerados proceduralmente por *seed* (4 setores, spawn sorteado — `geracao_mapas.md`)
- Rotação de iniciativa: a partida *i* inicia pelo jogador *i* mod 3
- Combate determinístico, limite de 100 turnos (empate)
- Execução documentada em `data/runs/2026-07-19_19-16-29_benchmark_1000/`

## Resultados

| Jogador | WinRate | DamageRatio | CoverUsage | TurnsToVictory | Custo Médio | StrategicScore |
|---|---|---|---|---|---|---|
| verde | 0.297 | 5.32 ± 12.03 | 0.058 ± 0.152 | 31.8 | 235.9 ± 433.8 | 1.171 |
| vermelho | 0.298 | 6.24 ± 13.38 | 0.055 ± 0.145 | 31.3 | 220.6 ± 399.3 | 1.355 |
| azul | 0.310 | 6.48 ± 13.81 | 0.053 ± 0.147 | 30.3 | 235.5 ± 430.8 | 1.406 |

Empates (limite de 100 turnos): ~9% das partidas.

## Interpretação

### 1. Neutralidade do ambiente confirmada

Com N = 1000 e probabilidade esperada de ~1/3, a flutuação estatística natural do WinRate é de aproximadamente ±1,5 ponto percentual. A maior diferença observada entre jogadores foi de **1,3 ponto** (0.297 vs 0.310) — dentro do ruído esperado. Custo computacional, turnos até a vitória e uso de cobertura também vieram praticamente idênticos.

**Conclusão**: o sorteio de setores de nascimento e a rotação de iniciativa neutralizam com sucesso os vieses de terreno e de primeiro turno. Diferenças de desempenho observadas em experimentos futuros são atribuíveis aos modelos de IA, não ao ambiente.

### 2. A IA Reativa ignora cobertura (CoverUsage ≈ 5%)

Comportamento esperado de um modelo sem avaliação estratégica: a Reativa só persegue e ataca, sem buscar posições protegidas. Essa é exatamente a lacuna que a IA Heurística (que pontua cobertura na função de valor) deve explorar — o experimento estabelece a linha de base contra a qual esse ganho será medido.

### 3. Questão em aberto: escala do DamageRatio no StrategicScore

O DamageRatio apresentou desvio padrão muito superior à média (±12–14 sobre médias de 5–6). Isso ocorre porque, quando um jogador vence sem receber dano, a razão `dano_causado / max(dano_recebido, ε)` assume valores altos (até 200), e o termo `0.2 × DamageRatio` passa a dominar o StrategicScore — os demais termos da fórmula valem no máximo ~1.

A fórmula está implementada literalmente como definida em `metricas.md`. Fica registrada como decisão pendente (a discutir com a orientação) a adoção de um teto ou normalização para o DamageRatio, para que o StrategicScore pondere as dimensões de forma equilibrada.

## Reprodução

```bash
godot --headless --path simulator -- batch 1000 benchmark
```

A execução é determinística: o mesmo comando sobre o mesmo banco de *seeds* reproduz os mesmos resultados, byte a byte.
