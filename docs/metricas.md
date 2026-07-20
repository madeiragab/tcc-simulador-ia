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

A eficiência e o desempenho estratégico global serão avaliados por modelo através de uma composição linear padronizada pelas frações:

StrategicScore =
0.3 * WinRate +
0.2 * DamageRatio +
0.2 * CoverUsage +
0.2 * Efficiency +
0.1 * (1 / max(CustoComputacionalMedio, ε))

Onde:

- Efficiency = 1 / max(TurnsToVictory, 1) (Usado unicamente para contornar resultados irreais)
- ε = 1 é a constante de base técnica (*Epsilon*) fixada estritamente contra *Float Exception* quando uma IA escolhe ação em custo unitário e zero não seja formalmente processado.

### Agregação Oficial das Métricas

Por fim, após a rodada dos exatos 1000 cenários definidos na Metodologia, o *output* avaliado no TCC consiste nas análises das métricas individuais obtidas do *framework* através da extração das **Médias Exatas Individuais por Parâmetro** contrastadas por seus **Desvios Padrão** (para auditar comportamento anômalo contra tendências lineares).

## Observações

A métrica composta permite avaliar o agente de forma mais abrangente, considerando não apenas o resultado final, mas também a eficiência e qualidade das decisões.
