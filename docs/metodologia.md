# Metodologia Experimental

## Abordagem

O estudo será conduzido por meio de simulações automatizadas em um ambiente tático controlado.

## Configuração do Ambiente

- Grid bidimensional simétrico (NxN) com layout espelhado horizontalmente
- Sistema simétrico com exatos 3 agentes por equipe (confronto 3 vs 3)
- Condições iniciais padronizadas para cada cenário avaliado (posições fixamente predefinidas visando manter a equidade)
- Utilização de sementes (*seeds*) pseudoaleatórias fixas (ex: *seed* = 42) ou múltiplas sementes rigidamente rastreadas para garantir a reprodutibilidade exata de cada cenário avaliado
- Agentes com atributos definidos e padronizados
- Sistema de combate determinístico
- Regras fixas para todos os testes

## Procedimento Experimental

1. Inicializar o ambiente com posições definidas, conforme o cenário e número de agentes
2. Executar a simulação até a condição de término (vencedor definido pela eliminação adversária, ou empate por limite fixo de 100 turnos)
3. Registrar métricas de desempenho
4. Repetir o processo múltiplas vezes

## Execução

- Número mínimo de simulações: 1000 por modelo
- Execução automatizada e sem renderização para maior presteza e ganho de processamento

## Modelos Avaliados

- IA Aleatória
- IA Reativa
- IA Heurística
- Modelo Proposto (híbrido)

## Coleta de Dados

Serão coletados:

- resultados das partidas
- métricas de desempenho
- tempo de decisão

## Análise

Os dados serão analisados de forma quantitativa, permitindo comparação entre os modelos e identificação de padrões de comportamento.
