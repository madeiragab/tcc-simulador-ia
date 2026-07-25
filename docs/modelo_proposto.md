# Modelo Proposto — IA Híbrida

Contribuição central do trabalho. Implementação: `simulator/ai/ai_hybrid.gd`.

## Ideia central

Combinar valor estratégico e custo computacional na tomada de decisão, penalizando explicitamente as avaliações caras:

Score(A) = ValorEstratégico(A) − λ × CustoComputacional(A)

Com λ = 0 o modelo colapsa na IA Heurística pura; com λ grande, aproxima-se do comportamento reativo. O parâmetro converte operações em unidades de valor estratégico.

## Componentes

**ValorEstratégico(A)** — herdado da IA Heurística (`docs/ia.md` §4): vida, cobertura, proximidade, risco e o incentivo de movimentação.

**CustoComputacional(A)** — o custo, em operações contadas, de **avaliar aquela ação específica**: o delta do medidor (`cost_meter`) durante a avaliação da candidata. Essa definição foi escolhida a partir da evidência da campanha de coleta (`docs/resultados_campanha.md` §2.1): o custo marginal da heurística sobre a reativa concentra-se no loop de avaliação posicional (180 cálculos de LOS por partida contra 12 da reativa). Penalizar o custo *da ação* — e não o acumulado do turno — mantém a comparação entre candidatas justa e independente da ordem de avaliação.

## Dois mecanismos

### 1. Penalização (o modelo formal)

Cada candidata é pontuada e tem descontado o custo de tê-la avaliado. Ações que exigem muitas verificações para serem julgadas precisam entregar valor proporcionalmente maior.

### 2. Poda por orçamento (a economia real)

A penalização sozinha escolhe melhor, mas não economiza: o custo já foi pago quando a ação é descartada. Por isso o modelo ordena as candidatas por promessa — distância ao inimigo mais próximo, cálculo barato — e avalia apenas enquanto houver orçamento de operações no turno (`budget`, padrão 120). O restante fica sem avaliar.

É esse mecanismo que converte a formulação teórica em redução mensurável de processamento, mantendo a qualidade das decisões: as candidatas mais promissoras são sempre avaliadas primeiro.

## Parâmetros

| Parâmetro | Valor | Origem |
|---|---|---|
| λ | 0,02 | Varredura em {0,005; 0,01; 0,02; 0,05; 0,1} no banco de tuning (200 seeds) |
| budget | 120 operações/turno | Varredura no banco de tuning |
| Pesos iniciais | 0,092 / 0,307 / 0,495 / −0,228 | Melhor configuração aprendida no confronto misto de 1000 partidas (`docs/resultados_campanha.md` §2.2) |

Os pesos continuam sendo refinados pelo aprendizado entre partidas (`docs/ia.md` §6.5) — o híbrido herda o mecanismo da heurística.

## Uso

```bash
# Benchmark com o híbrido no verde
godot --headless --path simulator -- batch 1000 benchmark verde=hibrida

# Calibração (λ e orçamento ajustáveis por linha de comando)
godot --headless --path simulator -- batch 200 tuning verde=hibrida lambda=0.02 budget=120
```

## Hipótese

O modelo híbrido produz decisões de qualidade equivalente ou superior à heurística pura com custo computacional significativamente menor. Critério quantitativo de sucesso, fixado a partir da campanha: pontuação média ≥ −0,59 (desempenho da heurística no confronto misto) com custo < 1811 operações por partida.
