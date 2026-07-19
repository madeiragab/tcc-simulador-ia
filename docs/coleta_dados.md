# Coleta e Armazenamento de Dados

## 1. Objetivo

Definir como os dados das simulações serão coletados, armazenados e organizados para análise posterior.

---

## 2. Estrutura de Coleta

Os dados serão coletados em dois níveis:

### 2.1 Dados por Simulação

Para cada partida executada, grava-se **uma linha por jogador** (3 linhas por partida), permitindo analisar qualquer modelo presente no confronto:

- id_simulacao
- seed
- jogador (verde, vermelho ou azul)
- modelo_ia (modelo que controla esse jogador)
- vencedor (verde, vermelho, azul ou empate)
- turnos
- dano_causado
- dano_recebido
- cover_usage (fração de turnos terminados em posição protegida)
- custo_computacional (contagem de operações da decisão)

---

### 2.2 Dados por Turno (Opcional)

Habilitado com a flag `turnos` no lote. Para cada turno de cada agente:

- id_simulacao, seed
- turno
- jogador
- ação escolhida (mover, atacar, mover_e_atacar, esperar)
- posição (x, y)
- protegido (terminou o turno com cobertura adjacente)
- inimigos_visiveis (com linha de visão e no alcance)

---

## 3. Formato de Armazenamento

Os dados serão armazenados em formato CSV, permitindo fácil manipulação e análise.

### Exemplo (simulação)

```csv
id_simulacao,seed,jogador,modelo_ia,vencedor,turnos,dano_causado,dano_recebido,cover_usage,custo_computacional
1,438557537,verde,reativa,azul,9,90,120,0.0000,71
1,438557537,vermelho,reativa,azul,9,120,120,0.0000,130
1,438557537,azul,reativa,azul,9,30,0,0.2222,181
```

## 4. Organização dos Arquivos

Cada execução de lote (`godot --headless -- batch <N> [banco] [turnos]`) gera uma pasta autodocumentada e imutável:

```text
data/runs/<data-hora>_<banco>_<N>/
├── manifest.txt   # configuração completa: banco, seeds, modelos por jogador,
│                  # constantes de jogo, duração — auditoria da execução
├── partidas.csv   # uma linha por jogador por partida: métricas brutas e
│                  # derivadas (damage_ratio, cover_usage), vitória, custo
│                  # total e aberto por tipo (LOS, nodos, ações)
├── resumo.csv     # agregados por jogador: média ± desvio padrão de cada
│                  # métrica e o StrategicScore
└── turnos.csv     # (opcional) log turno a turno
```

Os recortes por modelo (aleatoria, reativa, heuristica, modelo_proposto) são derivados de `partidas.csv` filtrando a coluna `modelo_ia` na etapa de análise.
