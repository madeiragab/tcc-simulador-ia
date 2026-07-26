# Planejamento Experimental

## 1. Objetivo

Definir como os experimentos serão conduzidos para avaliar o desempenho dos modelos de IA.

---

## 2. Modelos Avaliados

- IA Aleatória
- IA Reativa
- IA Heurística
- Art3miz 0.1 (híbrido)

Em cada simulação, o modelo avaliado controla um agente; os outros dois agentes executam a IA Reativa como adversário padrão, garantindo oposição idêntica para todos os modelos.

---

## 3. Configuração do Ambiente

- Grid 40x40 com mapas gerados proceduralmente a partir de um banco de 1000 *seeds* (ver `geracao_mapas.md`) — os mesmos mapas e posições de nascimento para todos os modelos comparados.
- Confronto entre 3 agentes independentes (todos contra todos).
- Posições de nascimento sorteadas pela *seed* em 3 dos 4 setores do mapa (nunca dois agentes no mesmo setor), diluindo estatisticamente qualquer vantagem de terreno.
- Rotação uniforme da ordem inicial de jogo entre os 3 agentes (cada um inicia 1/3 das simulações), eliminando o viés de primeiro turno.
- Mecânica determinística: sem RNG em combate.
- Condição de vitória: último agente vivo. Ao atingir o limite de 100 turnos, a simulação termina em empate.

---

## 4. Execução Controlada

- Validação (*tuning* de pesos e λ): 200 simulações em *seeds* exclusivas, separadas do benchmark para evitar *overfitting*.
- Benchmark final em lote: 1000 simulações sobre o banco de *seeds* congelado, uniforme para todos os modelos.
- Execução *headless* (sem renderização). Custo medido por contagem de operações, não por tempo de relógio.

---

## 5. Dados Coletados

Para cada simulação:

- seed
- vencedor
- número de turnos
- dano causado
- dano recebido
- custo computacional (contagem de operações)

---

## 6. Métricas Calculadas

- WinRate
- Damage Ratio
- Cover Usage
- Turns to Victory
- Custo Computacional Médio
- Strategic Score

---

## 7. Validação

- Todos os modelos serão executados sob as mesmas condições
- Nenhuma alteração será feita durante os testes

---

## 8. Análise

Os resultados serão agregados e analisados por:

- média (tendência central)
- desvio padrão (variância e flutuação de eficácia)

Permitindo, de forma reprodutível:

- comparar o desempenho entre modelos
- avaliar eficiência estratégica sem viés procedimental
- identificar robustez através de padrões de comportamento e flutuação estatística

---

## 9. Resultado Esperado

Espera-se que o Art3miz 0.1 apresente:

- desempenho superior aos modelos simples
- melhor equilíbrio entre estratégia e custo computacional
