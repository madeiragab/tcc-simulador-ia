# Modelo de Tomada de Decisão da IA

## 1. Visão Geral

A IA é responsável por selecionar a melhor ação possível a cada turno com base em uma função de avaliação estratégica.

O modelo segue o paradigma de decisão reativa, no qual as ações são avaliadas considerando apenas o estado atual do ambiente, sem planejamento de múltiplos turnos.

Essa abordagem é inspirada em técnicas de Utility AI, amplamente utilizadas em jogos digitais para tomada de decisão baseada em múltiplos critérios (MARK; DILL, 2010; MILLINGTON; FUNGE, 2016).

---

## 2. Geração de Ações

Em cada turno, o agente gera um conjunto de ações possíveis, incluindo:

- Movimentos para posições alcançáveis (até 3 células)
- Ações de ataque, quando houver linha de visão válida

Cada ação representa uma possível transição de estado dentro do ambiente.

---

## 3. Filtragem de Ações

Para reduzir a complexidade computacional, ações irrelevantes são descartadas antes da avaliação.

Critérios de filtragem:

- posições sem linha de visão de inimigos
- posições com risco elevado (exposição múltipla)
- posições redundantes ou equivalentes

Essa etapa é fundamental para evitar explosão combinatória, um problema comum em sistemas de tomada de decisão (RUSSELL; NORVIG, 2010).

---

## 4. Avaliação de Ações (IA Heurística)

Cada ação é julgada puramente (e apenas) por uma função de valor estratégico empírico, que reflete benefícios táticos baseados no estado do jogo, como vida e cobertura (*IA Heurística*):

ValorEstratégico =
w1 * Vida +
w2 * Cobertura +
w3 * Proximidade +
w4 * Risco

Onde:

- Vida: proporção de HP atual do agente
- Cobertura: nível de proteção da posição (0, 1 ou 2)
- Proximidade: inverso da distância até o inimigo
- Risco: quantidade de inimigos com linha de visão

Os pesos (w1, w2, w3, w4) serão definidos empiricamente com base nos resultados das simulações.

O fator risco possui impacto negativo, penalizando posições com maior exposição.

Esse tipo de modelagem é consistente com abordagens de decisão multi-critério utilizadas em sistemas de IA aplicados a jogos (MILLINGTON; FUNGE, 2016). Ela define a *IA Heurística* no presente estudo, cujo custo computacional e tempo despendido para alcançar esse grau cognitivo não penalizam estruturalmente a tomada de decisão da ação proposta.

---

## 5. Seleção da Ação

A IA seleciona a ação com maior valor estratégico:

AçãoEscolhida = argmax(ValorEstratégico)

Essa abordagem caracteriza um processo de otimização local, comum em agentes reativos avançados.

---

## 6. Extensão do Modelo (Modelo Proposto - Híbrido)

Diferenciando-se objetiva e metodologicamente da *IA Heurística* padrão, o modelo matemático proposto adiciona restrição de esforço e latência. Portanto, no *Modelo Proposto (Híbrido)*, essa estrutura é estendida para considerar o próprio *custo computacional (Tempo despendido)* da simulação na sua respectiva equação decisória final (impactando diretamente a viabilidade tática em *runtime*):

ScoreFinal = ValorEstratégico − λ × CustoComputacional

Onde:

- CustoComputacional representa e rastreia o tempo necessário para avaliar a ação
- λ é um parâmetro restritivo de ajuste do trade-off

A inclusão desse fator permite equilibrar qualidade estratégica e eficiência, distinguindo-se estrutural e logicamente da *IA Heurística*, unindo otimização de processador à utilidade de campo. Alinhando-se a estudos sobre trade-offs em algoritmos de decisão (BROWNE et al., 2012).

---

## 7. Limitações

- O modelo não considera planejamento de longo prazo
- As decisões são baseadas apenas no estado atual
- A qualidade depende da escolha dos pesos
- Não há exploração de cenários futuros (lookahead)

---

## 8. Justificativa

A escolha de um modelo baseado em avaliação de ações se deve à sua:

- simplicidade de implementação
- eficiência computacional
- capacidade de lidar com múltiplos fatores simultaneamente

Comparado a abordagens como Monte Carlo Tree Search (MCTS), o modelo adotado possui menor custo computacional, sendo mais adequado para múltiplas simulações em larga escala (BROWNE et al., 2012).

---

## 9. Evolução do Modelo

O modelo poderá ser aprimorado por meio de:

- ajuste dos pesos com base nos resultados experimentais
- inclusão de novos fatores na função de avaliação
- comparação com outros modelos de decisão (heurísticos, MCTS, etc.)


## 10. Natureza do Modelo

O modelo descrito neste documento é uma proposta de abordagem para tomada de decisão em ambientes táticos.

Sua implementação e validação serão realizadas ao longo do desenvolvimento do trabalho, por meio de simulações controladas.