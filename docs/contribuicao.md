# Contribuição Proposta

## Objetivo

Propor um modelo de tomada de decisão para agentes em ambientes táticos que equilibre qualidade estratégica e custo computacional.

## Modelo

O modelo proposto é definido pela seguinte função:

ScoreAção = ValorEstratégico − λ × CustoComputacional

## Componentes

### Valor Estratégico

Considera fatores como:

- posicionamento no grid
- uso de cobertura
- dano potencial
- risco da ação

### Custo Computacional

Representa o tempo ou complexidade necessária para avaliar uma ação.

### Parâmetro λ

Controla o equilíbrio entre qualidade estratégica e custo computacional.

## Hipótese

A introdução do custo computacional na tomada de decisão permite evitar escolhas excessivamente complexas, mantendo um bom nível estratégico.

## Contribuição

O trabalho contribui com:

- um modelo híbrido de decisão
- uma abordagem de avaliação baseada em múltiplas métricas
- um ambiente controlado para experimentação
