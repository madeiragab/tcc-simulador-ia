# Análise de Significância Estatística

Relatório gerado automaticamente por `simulator/tools/analise_estatistica.gd` a partir dos dados brutos das execuções oficiais. Reproduzível com:

```bash
godot --headless --path simulator --script res://tools/analise_estatistica.gd
```

## Delineamento e escolha dos testes

O experimento é **pareado**: todos os modelos enfrentam exatamente as mesmas *seeds*, e no confronto direto disputam a mesma partida. Esse controle da variabilidade do cenário permite testes mais potentes que os de amostras independentes, e determina quais testes são apropriados:

| Comparação | Teste | Justificativa |
|---|---|---|
| Taxas de vitória no confronto direto | Qui-quadrado de aderência (df = 2) | Verifica se as três contagens desviam da distribuição uniforme antes de comparações par a par |
| Par a par no confronto direto | Binomial condicional | Como só um agente vence cada partida, as vitórias são mutuamente excludentes; testa-se a divisão entre as partidas decididas pelos dois |
| Custo computacional | Teste t **pareado** por *seed* | Cada par é o mesmo cenário jogado pelos dois modelos — elimina a variância entre mapas |
| Proporções (intervalo) | Intervalo de Wilson | Mantém cobertura adequada mesmo com proporções distantes de 0,5 |
| StrategicScore | *Bootstrap* percentílico (2000 reamostragens) | O escore combina cinco agregados e não possui forma fechada para o erro-padrão |

Nível de significância adotado: **α = 0,05**. Com N = 1000, a distribuição t (≈999 g.l.) é indistinguível da normal padrão, aproximação usada nos cálculos de p-valor.

---

## 1. Confronto direto — as taxas de vitória diferem?

Execução: `2026-07-25_19-50-46_benchmark_1000` (1000 partidas, um agente de cada modelo).

### 1.1 Taxas de vitória com intervalo de confiança de 95%

| Modelo | Vitórias | Taxa | IC 95% (Wilson) |
|---|---|---|---|
| art3miz_0.1 | 225/1000 | 0.225 | [0.200; 0.252] |
| heuristica | 339/1000 | 0.339 | [0.310; 0.369] |
| reativa | 330/1000 | 0.330 | [0.302; 0.360] |

### 1.2 Teste global (qui-quadrado de aderência)

Hipótese nula: os três modelos têm a mesma probabilidade de vencer.

- χ² = **26.96** (df = 2), p < 0,001
- Frequência esperada sob a hipótese nula: 298.0 vitórias por modelo
- Resultado: **ALTAMENTE SIGNIFICATIVO**

Rejeita-se a hipótese nula: as diferenças entre os modelos **não são atribuíveis ao acaso**. Procede-se às comparações par a par.

### 1.3 Comparações par a par (teste binomial condicional)

Entre as partidas decididas por um dos dois modelos, a divisão é equilibrada?

| Comparação | Divisão | Proporção | IC 95% | p-valor | Conclusão |
|---|---|---|---|---|---|
| art3miz_0.1 vs heuristica | 225–339 | 0.399 | [0.359; 0.440] | p < 0,001 | altamente significativo |
| art3miz_0.1 vs reativa | 225–330 | 0.405 | [0.365; 0.447] | p < 0,001 | altamente significativo |
| heuristica vs reativa | 339–330 | 0.507 | [0.469; 0.544] | p = 0.7571 | NÃO significativo |

### 1.4 Custo computacional (teste t pareado por seed)

Cada par de observações é o **mesmo cenário** enfrentado pelos dois modelos, o que elimina a variância entre mapas.

| Comparação | Diferença média | IC 95% da diferença | t | p-valor | d de Cohen | Efeito |
|---|---|---|---|---|---|---|
| art3miz_0.1 − heuristica | -208.5 ops | [-241.5; -175.4] | -12.35 | p < 0,001 | -0.391 | pequeno |
| art3miz_0.1 − reativa | 26.0 ops | [-3.3; 55.3] | 1.74 | p = 0.0819 | 0.055 | desprezível |
| heuristica − reativa | 234.5 ops | [209.6; 259.3] | 18.49 | p < 0,001 | 0.585 | médio |

---

## 2. Autoconfrontos — comparação de custo entre modelos

Cada modelo joga contra si mesmo nas mesmas 1000 *seeds*. O custo de cada modelo é comparado ao dos demais **pareando por seed**: o mesmo mapa, o mesmo posicionamento inicial, modelos diferentes.

### 2.1 Custo médio por partida

| Modelo | Custo médio | IC 95% da média |
|---|---|---|
| aleatoria | 2322.7 | [2318.8; 2326.5] |
| reativa | 437.2 | [413.4; 461.0] |
| heuristica | 776.9 | [745.3; 808.5] |
| art3miz_0.1 | 378.7 | [362.7; 394.7] |

### 2.2 Comparações par a par (teste t pareado)

| Comparação | Diferença média | IC 95% | p-valor | d de Cohen | Efeito |
|---|---|---|---|---|---|
| aleatoria − reativa | 1885.5 ops | [1861.2; 1909.7] | p < 0,001 | 4.816 | grande |
| aleatoria − heuristica | 1545.7 ops | [1513.8; 1577.7] | p < 0,001 | 2.999 | grande |
| aleatoria − art3miz_0.1 | 1944.0 ops | [1927.3; 1960.6] | p < 0,001 | 7.234 | grande |
| reativa − heuristica | -339.8 ops | [-368.8; -310.7] | p < 0,001 | -0.725 | médio |
| reativa − art3miz_0.1 | 58.5 ops | [31.1; 85.9] | p < 0,001 | 0.132 | desprezível |
| heuristica − art3miz_0.1 | 398.2 ops | [364.1; 432.4] | p < 0,001 | 0.724 | médio |

---

## 3. StrategicScore com intervalo de confiança (bootstrap)

O escore composto combina cinco agregados e não possui forma fechada para o erro-padrão. O intervalo é obtido por reamostragem percentílica com 2000 repetições sobre as partidas de cada execução.

| Modelo | StrategicScore | IC 95% (bootstrap) |
|---|---|---|
| aleatoria | 0.1340 | [0.1138; 0.1495] |
| reativa | 0.4689 | [0.4532; 0.4843] |
| heuristica | 0.4380 | [0.4208; 0.4540] |
| art3miz_0.1 | 0.4942 | [0.4786; 0.5091] |

Intervalos que **não se sobrepõem** indicam diferença estatisticamente distinguível entre os escores.

---

## 4. Neutralidade do ambiente (teste formal)

No autoconfronto da IA Reativa, os três agentes executam o mesmo modelo. Sob um ambiente neutro, as vitórias devem distribuir-se uniformemente entre as três posições — qualquer desvio sistemático indicaria viés de terreno, de cor ou de ordem de jogada.

| Posição | Vitórias | Taxa | IC 95% |
|---|---|---|---|
| verde | 306/1000 | 0.306 | [0.278; 0.335] |
| vermelho | 328/1000 | 0.328 | [0.300; 0.358] |
| azul | 301/1000 | 0.301 | [0.273; 0.330] |

- χ² = **1.32** (df = 2), p = 0.5158
- Resultado: **NÃO SIGNIFICATIVO**

**Não se rejeita a hipótese nula de uniformidade.** A ausência de diferença estatisticamente detectável entre as posições sustenta que o ambiente não introduz viés sistemático — os controles de sorteio de setores e rotação de iniciativa cumprem sua função.

> Observação metodológica: não rejeitar a hipótese nula não *prova* a neutralidade; demonstra que, com potência para detectar diferenças da ordem de 1,5 ponto percentual, nenhuma foi encontrada.

---

## Notas sobre as aproximações

- **p-valores**: obtidos pela normal padrão. Com N = 1000, a diferença em relação à distribuição t (≈999 g.l.) é inferior a 0,001 no terceiro decimal.
- **Função erro**: aproximação de Abramowitz & Stegun (7.1.26), erro absoluto inferior a 1,5 × 10⁻⁷.
- **Qui-quadrado**: forma fechada exata para df = 2 (exp(−x/2)) e df = 1 (via função erro complementar).
- **Bootstrap**: reamostragem com semente fixa (20260726), garantindo que o relatório seja reproduzível.
- **Comparações múltiplas**: os testes par a par não recebem correção de Bonferroni. Como o teste global (qui-quadrado) antecede as comparações e os p-valores obtidos são ordens de grandeza inferiores a α, a correção não alteraria nenhuma conclusão. Está indicado onde um p-valor se aproxima do limiar.

