# Modelo Proposto

## Ideia central

Combinar valor estratégico e custo computacional na tomada de decisão.

## Fórmula

Score(A) = ValorEstratégico(A) - λ * CustoComputacional(A)

## Componentes

ValorEstratégico:
- dano potencial
- risco
- cobertura
- posição

CustoComputacional (Abstrato e Determinístico):
- total de ações válidas avaliadas
- quantidade de cálculos de linha de visão (LOS) e pathfinding acionados
- número de verificações de estado heurístico realizadas

## Hipótese

O modelo híbrido produz decisões mais eficientes que abordagens isoladas.