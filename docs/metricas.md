> 🇧🇷 **Português** · 🇬🇧 [English](en/metrics.md)

# Métricas de Avaliação

## Objetivo

Definir métricas quantitativas para avaliar o desempenho e a qualidade estratégica dos agentes no ambiente simulado.

## Métricas Individuais

### WinRate
Percentual de vitórias do agente em múltiplas simulações.

### Damage Ratio
Relação dada pelo total de dano causado pelo agente avaliado dividido pelo total de dano recebido por ele. O limitador contra divisão por zero segue o padrão ε do trabalho:

DamageRatio = dano_causado / max(dano_recebido, ε), com ε = 1

### Cover Usage
Percentual de turnos em que o agente avaliado terminou o turno em posição protegida (com célula de cobertura adjacente, oferecendo proteção potencial em pelo menos uma direção).

### Turns to Victory
Número médio de turnos necessários para o agente avaliado vencer a partida. Para penalizar inércia ou loops de sobrevivência passiva, caso a partida termine em empate pelo limite de 100 turnos, o modelo recebe como penalidade o valor máximo (100).

### Pontuação de Partida (Match Points)

Cada partida atribui pontos ao modelo conforme o resultado:

- Vitória: **+3**
- Empate: **−1**
- Derrota: **−3**

O empate é deliberadamente penalizado (e não tratado como neutro): um modelo que apenas sobrevive sem decidir a partida — por exemplo, entrincheirando-se até o limite de turnos — não demonstra eficácia estratégica. A agregação usa o total e a média de pontos por partida (faixa −3 a +3).

### Custo Computacional Médio
Esforço algorítmico médio global (medido através de contagem computacional abstrata de operações em código, como a taxa cumulativa de cálculos efetuados de LOS, ações geradas e nodos filtrados). Emprega-se tal métrica para substituir e nulificar as falhas de medição empírico-temporais em milissegundos *wall-clock time*, evitando dependência direta de hardware do avaliador do TCC. Incorpora-se uma constante matemática ε (Epsilon = 1) no algoritmo para delimitar um piso lógico nas fórmulas de proporção e obstar divisão paramétrica por zero.

## Métrica Composta

### Strategic Score

A composição linear pondera cinco dimensões do desempenho. Para que os pesos correspondam de fato à importância pretendida, **todos os termos são normalizados ao intervalo [0, 1]** antes da ponderação, de modo que o escore final também pertence a [0, 1]:

StrategicScore =
0.30 * WinRate +
0.20 * DamageNorm +
0.20 * CoverUsage +
0.20 * EficienciaTurnos +
0.10 * EficienciaCusto

Onde:

- **WinRate** ∈ [0, 1] — fração de vitórias (já normalizada por definição).
- **DamageNorm** = DamageRatio / (1 + DamageRatio) ∈ [0, 1) — saturação suave da razão de dano. Vale 0,5 quando o agente causa exatamente o dano que recebe, tende a 1 conforme domina a troca e a 0 quando só apanha. Dispensa teto arbitrário e preserva a ordenação entre modelos.
- **CoverUsage** ∈ [0, 1] — fração de turnos em posição protegida (já normalizada).
- **EficienciaTurnos** = (LimiteTurnos − min(TurnsToVictory, LimiteTurnos)) / LimiteTurnos ∈ [0, 1] — fração do orçamento de turnos economizada. Vale 1 na vitória imediata e 0 no empate por esgotamento (LimiteTurnos = 100).
- **EficienciaCusto** = CustoReferência / (CustoReferência + CustoComputacionalMedio) ∈ (0, 1) — vale 0,5 quando o modelo gasta exatamente o custo de referência (CustoReferência = 1000 operações, ordem de grandeza típica observada), tende a 1 conforme decide mais barato e a 0 conforme encarece.

#### Justificativa da normalização

A formulação original somava grandezas em escalas incompatíveis, o que fazia os pesos nominais divergirem radicalmente do efeito real. Medido no confronto triplo do benchmark oficial, o termo de dano — nominalmente 20% — contribuía com 0,85 a 1,12 do escore, enquanto o WinRate — nominalmente 30% — contribuía com 0,07 a 0,10, e o custo — nominalmente 10% — contribuía com 0,0002, cerca de quatro mil vezes menos que o previsto. Na prática, o escore media quase exclusivamente a razão de dano e era cego à eficiência computacional, justamente a dimensão central da pesquisa.

A correção atua **apenas sobre a escala dos termos**: os pesos permanecem exatamente os originalmente definidos (0,30 / 0,20 / 0,20 / 0,20 / 0,10), preservando a intenção do projeto de pesquisa e afastando qualquer suspeita de ajuste da métrica em favor do Art3miz 0.1. Como a alteração incide sobre a agregação e não sobre a coleta, os escores de todas as execuções já realizadas foram recalculados a partir dos dados brutos preservados, sem necessidade de repetir simulações.

- ε = 1 permanece como piso contra divisão por zero no cálculo do DamageRatio individual.

### Agregação Oficial das Métricas

Por fim, após a rodada dos exatos 1000 cenários definidos na Metodologia, o *output* avaliado no TCC consiste nas análises das métricas individuais obtidas do *framework* através da extração das **Médias Exatas Individuais por Parâmetro** contrastadas por seus **Desvios Padrão** (para auditar comportamento anômalo contra tendências lineares).

## Observações

A métrica composta permite avaliar o agente de forma mais abrangente, considerando não apenas o resultado final, mas também a eficiência e qualidade das decisões.
