# Planejamento Experimental

## 1. Objetivo

Definir como os experimentos serão conduzidos para avaliar o desempenho dos modelos de IA.

---

## 2. Modelos Avaliados

- IA Aleatória
- IA Reativa
- IA Heurística
- Modelo Proposto (híbrido)

---

## 3. Configuração do Ambiente

- Grid (40x40) acoplado a um gerador de 1000 configurações simétricas baseado puramente em um banco de Sementes (*seeds* espaciais únicas testadas uniformemente entre baselines) garantindo variabilidade controlada em oposição ao determinismo repetitivo.
- Configuração fixa para confrontos de exatos 3 vs 3 agentes
- Posições predefinidas espelhadas limitando vantagens locais 
- Aplicação imperativa do revezamento 50/50 em viés inicial (*First-Mover Advantage*) garantindo probabilidade estatística de vitória inicial idêntica
- Execução de mecânicas determinísticas (Sem RNG em combates)
- Condição de vitória engatilhada apenas pela eliminação total do time rival (HP=0). Caso se atinja o limite máximo cravado de 100 turnos (*timeout cap* da restrição lógica), a simulação é finalizada em empate.

---

## 4. Execução Controlada

- Validação Paralela (Tuning de Pesos e Heurísticas de Risco): 200 iterativas isoladas para evitar Overfitting
- Testes Finais e Benchmark Absoluto em Batch: Exatas 1000 simulações finais sobre banco de dados congelado e uniforme para todos os modelos competidores
- Alternância em lote contínuo (*headless* simulado) em vez de tempo computacional (Aferição analítica proxy em vez de Wall-Clock *ms*)

---

## 5. Dados Coletados

Para cada simulação:

- vencedor
- número de turnos
- dano causado
- dano recebido
- custo algorítmico matemático proxy (Contagem em substituição aos Tempos de Custo)

---

## 6. Métricas Calculadas

- WinRate
- Damage Ratio
- Cover Usage
- Turns to Victory
- Tempo de Decisão
- Strategic Score

---

## 7. Validação

- Todos os modelos serão executados sob as mesmas condições
- Nenhuma alteração será feita durante os testes

---

## 8. Análise

Os resultados serão obrigatoriamente agregados e analisados baseando-se nos descritores absolutos de:
- média geral (tendência central)
- desvio padrão (variância e flutuação de eficácia)

Permitindo, de forma reprodutível:

- comparar rigorosamente o desempenho entre modelos
- avaliar eficiência estratégica validada em *sandbox* sem viés procedimental
- identificar robustez através de padrões de comportamento e flutuação estatística

---

## 9. Resultado Esperado

Espera-se que o modelo proposto apresente:

- desempenho superior aos modelos simples
- melhor equilíbrio entre estratégia e custo computacional
