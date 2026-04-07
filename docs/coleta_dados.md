# Coleta e Armazenamento de Dados

## 1. Objetivo

Definir como os dados das simulações serão coletados, armazenados e organizados para análise posterior.

---

## 2. Estrutura de Coleta

Os dados serão coletados em dois níveis:

### 2.1 Dados por Simulação

Para cada partida executada:

- id_simulacao
- modelo_ia
- vencedor
- numero_turnos
- dano_causado
- dano_recebido
- tempo_total_decisao

---

### 2.2 Dados por Turno (Opcional)

Para análises mais detalhadas:

- turno
- agente
- ação escolhida
- posição
- em_cobertura (sim/não)
- inimigos_visiveis

---

## 3. Formato de Armazenamento

Os dados serão armazenados em formato CSV, permitindo fácil manipulação e análise.

### Exemplo (simulação)

```csv
id_simulacao,modelo_ia,vencedor,turnos,dano_causado,dano_recebido,tempo_decisao
1,heuristica,A,25,120,80,0.032
2,reativa,B,40,90,130,0.010
```

## 4. Organização dos Arquivos

```text
data/
├── aleatoria.csv
├── reativa.csv
├── heuristica.csv
├── modelo_proposto.csv
```
