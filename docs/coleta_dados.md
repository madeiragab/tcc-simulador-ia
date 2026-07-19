# Coleta e Armazenamento de Dados

## 1. Objetivo

Definir como os dados das simulações serão coletados, armazenados e organizados para análise posterior.

---

## 2. Estrutura de Coleta

Os dados serão coletados em dois níveis:

### 2.1 Dados por Simulação

Para cada partida executada:

- id_simulacao
- seed
- modelo_ia (modelo que controla o agente avaliado)
- vencedor (verde, vermelho, azul ou empate)
- numero_turnos
- dano_causado (pelo agente avaliado)
- dano_recebido (pelo agente avaliado)
- custo_computacional (contagem de operações do agente avaliado)

---

### 2.2 Dados por Turno (Opcional)

Para análises mais detalhadas:

- turno
- agente
- ação escolhida
- posição
- protegido_por_cobertura (sim/não)
- inimigos_visiveis

---

## 3. Formato de Armazenamento

Os dados serão armazenados em formato CSV, permitindo fácil manipulação e análise.

### Exemplo (simulação)

```csv
id_simulacao,seed,modelo_ia,vencedor,turnos,dano_causado,dano_recebido,custo_computacional
1,42,heuristica,verde,25,120,80,1430
2,43,reativa,empate,100,90,130,610
```

## 4. Organização dos Arquivos

```text
data/
├── aleatoria.csv
├── reativa.csv
├── heuristica.csv
├── modelo_proposto.csv
```
