# Métricas de Avaliação

## Objetivo

Definir métricas quantitativas para avaliar o desempenho e a qualidade estratégica dos agentes no ambiente simulado.

## Métricas Individuais

### WinRate
Percentual de vitórias do agente em múltiplas simulações.

### Damage Ratio
Relação dada pelo (total de dano causado pela equipe) dividido pelo (total de dano recebido). Caso nenhum dano seja recebido, define-se um limitador (teto numérico ou valor fixo padrão) para prevenir erros no cálculo.

### Cover Usage
Percentual médio global, considerando a quantidade de turnos nos quais todos os agentes da equipe sobreviveram estando ativamente atrás de algum tipo de cobertura.

### Turns to Victory
Número médio de turnos totais necessários para derrotar a equipe inimiga (vencendo o cenário). Para penalizar inércia ou loops infinitos de agentes reativos que sobrevivam até o teto lógico de processamento, caso a partida termine em empate pelo limite de 100 turnos fixos imposto globalmente, o modelo recebe de penalidade automática o valor máximo de tempo de arena.

### Tempo de Decisão
Tempo médio global da execução sintática (normalmente medido em milissegundos) que o processo do agente necessitou para rodar suas diretrizes e escolher uma ação. Incorpora-se aqui formalmente uma constante matemática ε (Epsilon = 0.0001) como limitador de piso em fórmulas matemáticas de proporção, sendo somada ou comparada para precaver qualquer *Crash* matemático caso a máquina calcule tudo em tempo real de 0.0s.

## Métrica Composta

### Strategic Score

A eficiência e o desempenho estratégico global serão avaliados por modelo através de uma composição linear padronizada pelas frações:

StrategicScore =
0.3 * WinRate +
0.2 * DamageRatio +
0.2 * CoverUsage +
0.2 * Efficiency +
0.1 * (1 / max(TempoDecisão, ε))

Onde:

- Efficiency = 1 / max(TurnsToVictory, 1) (Usado unicamente para contornar resultados irreais)
- $\epsilon = 0.0001$ é a constante técnica (*Epsilon*) fixada para proteger matematicamente as operações envolvendo tempo de latência de 0 absoluto (que resultariam no estouro imperativo da métrica global por Float Exception).

### Agregação Oficial das Métricas

Por fim, após a rodada dos exatos 1000 cenários definidos na Metodologia, o *output* avaliado no TCC consiste nas análises das métricas individuais obtidas do *framework* através da extração das **Médias Exatas Individuais por Parâmetro** contrastadas por seus **Desvios Padrão** (para auditar comportamento anômalo contra tendências lineares).

## Observações

A métrica composta permite avaliar o agente de forma mais abrangente, considerando não apenas o resultado final, mas também a eficiência e qualidade das decisões.
