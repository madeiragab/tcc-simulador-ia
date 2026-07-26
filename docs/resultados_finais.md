# Resultados Finais — Benchmark Oficial (Fase 5)

Execução final sobre o banco oficial de 1000 *seeds* de benchmark, sob o conjunto definitivo de regras (percepção por cone de 120°, sensor de proximidade, tiro em linha reta, cobertura direcional, pontuação +3/−1/−3, aprendizado entre partidas). **7.000 partidas** em 7 lotes, todos documentados em `data/runs/`.

Configuração do modelo proposto: λ = 0,005, pesos herdados do aprendizado da campanha (ver `resultados_hibrido.md`).

## 1. Caracterização por autoconfronto

Três instâncias do mesmo modelo por partida. Em condições simétricas, a taxa de vitória converge para ~1/3 em qualquer modelo funcional — o que a comparação revela é **o preço pago por esse desempenho** e a capacidade de decidir a partida.

| Modelo | WinRate (média) | Empates | **Custo médio** |
|---|---|---|---|
| Aleatória | 0,000 | **1000 (100%)** | 2323 |
| Reativa | 0,312 | 65 (6,5%) | 437 |
| Heurística | 0,295 | 116 (11,6%) | 777 |
| **Modelo Proposto** | **0,314** | **57 (5,7%)** | **379** |

Achados:

- **O modelo proposto é o mais econômico entre todos os modelos funcionais**: 379 operações por partida, contra 437 da reativa (−13%) e 777 da heurística (−51%).
- **É também o mais decisivo**: apenas 5,7% de empates, contra 11,6% da heurística — que, sendo mutuamente cautelosa, frequentemente se anula até o limite de turnos.
- Em eficiência estratégica (vitórias por mil operações), a ordem é **modelo proposto 0,829 > reativa 0,714 > heurística 0,380**: o modelo proposto entrega mais de **duas vezes** a eficiência da heurística.
- A IA Aleatória confirma-se como piso absoluto: nenhuma vitória em 1000 partidas, pagando o **maior custo de todos** (2323) — enumera todas as opções e descarta a informação.

## 2. Confronto direto

O modelo avaliado contra oponentes de custo pleno.

### 2.1 Confronto triplo (decisivo)

| | Modelo Proposto | Heurística | Reativa |
|---|---|---|---|
| Pontuação média | −1,44 | −0,75 | −0,81 |
| **WinRate** | 0,225 | **0,339** | 0,330 |
| DamageRatio | 4,23 ± 10,38 | 5,21 ± 10,64 | 5,61 ± 11,07 |
| CoverUsage | **0,096** | 0,095 | 0,074 |
| TurnsToVictory | 44,4 | 39,8 | 39,3 |
| **Custo** | **510** | 719 | 484 |
| Eficiência (vit./1000 ops) | 0,441 | 0,472 | **0,682** |

### 2.2 Contra dois oponentes idênticos

| Confronto | Modelo Proposto | Oponentes |
|---|---|---|
| vs 2 heurísticas | WR 0,232 · custo 492 | WR 0,332 / 0,329 · custo ~700 |
| vs 2 reativas | WR 0,248 · custo 505 | WR 0,332 / 0,329 · custo ~457 |

**Em competição direta o modelo proposto vence menos** (0,225–0,248 contra ~0,33 dos dois baselines), ainda que mantendo o menor custo entre os modelos analíticos e o maior uso de cobertura do confronto triplo.

## 3. Interpretação

Os resultados sustentam três conclusões, e é importante enunciá-las com precisão.

**A hipótese de eficiência confirma-se.** O modelo proposto reduz o custo computacional em 51% em relação à heurística pura e é o modelo funcional mais barato do estudo. Em condições simétricas, entrega desempenho equivalente ou superior aos demais (WinRate 0,314; menor taxa de empates) por uma fração do processamento — mais que o dobro da eficiência estratégica da heurística. A formalização do compromisso entre valor e custo produz, portanto, um agente mensuravelmente mais eficiente.

**A hipótese de superioridade competitiva não se confirma.** Quando enfrenta oponentes que pagam o custo pleno da análise, o modelo proposto vence menos (≈0,23 contra ≈0,33). A economia obtida ao deliberar seletivamente tem preço: nos turnos em que opta pelo regime econômico, o agente ocasionalmente perde a posição que a avaliação completa teria encontrado, e adversários que sempre deliberam exploram essa diferença.

**A IA Reativa revela-se um baseline notavelmente forte.** Com 484 operações e WinRate 0,330 no confronto triplo, apresenta a maior eficiência do confronto direto (0,682 vitórias por mil operações). Este é um resultado relevante em si: em ambientes táticos com percepção limitada e horizonte curto, regras simples e bem escolhidas são difíceis de superar — a sofisticação analítica precisa justificar seu custo, e nem sempre justifica.

### 3.1 Síntese

O trabalho não demonstra que o modelo híbrido é o melhor jogador; demonstra, com evidência quantitativa sobre 7.000 partidas, que **existe um compromisso mensurável e controlável entre qualidade estratégica e custo computacional**, e que o parâmetro λ permite navegá-lo de forma monotônica e previsível (ver curva em `resultados_hibrido.md` §2.2). Para aplicações com orçamento de processamento restrito — jogos comerciais com limite de tempo por quadro, robótica embarcada, simulações em larga escala — o modelo proposto oferece um controle explícito que os modelos de referência não possuem: é possível escolher, por projeto, quanto desempenho se está disposto a trocar por economia.

## 4. Limitação metodológica registrada

O StrategicScore, como definido em `metricas.md`, atribui apenas 10% do peso ao inverso do custo, e com custos da ordem de centenas de operações esse termo contribui com cerca de 0,002 para o escore, enquanto o DamageRatio contribui com valores próximos de 5. A métrica composta é, portanto, praticamente **cega à dimensão que o modelo proposto otimiza**, e por isso os resultados são reportados também em eficiência estratégica (vitórias por mil operações). A revisão dos pesos da fórmula permanece como decisão pendente com a orientação.

## 5. Reprodução

```bash
# Confronto decisivo
godot --headless --path simulator -- batch 1000 benchmark verde=hibrida vermelho=heuristica azul=reativa

# Autoconfrontos
godot --headless --path simulator -- batch 1000 benchmark verde=hibrida vermelho=hibrida azul=hibrida
godot --headless --path simulator -- batch 1000 benchmark verde=heuristica vermelho=heuristica azul=heuristica
godot --headless --path simulator -- batch 1000 benchmark verde=reativa vermelho=reativa azul=reativa
godot --headless --path simulator -- batch 1000 benchmark verde=aleatoria vermelho=aleatoria azul=aleatoria
```

Execuções determinísticas: os mesmos comandos reproduzem os mesmos resultados byte a byte.
