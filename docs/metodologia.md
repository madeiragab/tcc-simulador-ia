> 🇧🇷 **Português** · 🇬🇧 [English](en/methodology.md)

# Metodologia Experimental

## Abordagem

O estudo será conduzido por meio de simulações automatizadas em um ambiente tático controlado.

## Configuração do Ambiente

- Grid bidimensional 40x40 com geração procedural determinística de mapas a partir de *seeds* (ver `geracao_mapas.md`).
- Banco padronizado de 1000 *seeds* definindo mapas e posições de nascimento, enfrentado de forma idêntica por todos os modelos comparados.
- Confronto entre 3 agentes independentes (todos contra todos), identificados por cor: verde, vermelho e azul.
- Neutralização de vantagem de terreno: o mapa é dividido em 4 setores e cada agente nasce em um setor distinto, sorteado pela *seed* — nenhuma posição favorece sistematicamente um jogador ao longo das 1000 simulações.
- Neutralização do viés de ordem de turno: a ordem inicial de jogo é rotacionada uniformemente entre os 3 agentes ao longo das simulações (cada um inicia 1/3 das partidas).
- Combate determinístico (sem RNG durante a partida): toda a aleatoriedade do experimento se concentra na geração do mapa via *seed*.

## Composição dos Confrontos

Em cada simulação, o modelo avaliado controla um dos agentes; os outros dois executam um modelo adversário fixo (IA Reativa), idêntico em todas as avaliações. Isso garante que todos os modelos sejam medidos contra a mesma oposição, nas mesmas condições.

## Procedimento Experimental

1. Gerar mapa e posições de nascimento a partir da *seed* do banco.
2. Definir o agente que inicia a partida conforme a rotação de iniciativa.
3. Executar turnos até restar um único agente vivo (vitória) ou atingir o limite de 100 turnos (empate).
4. Registrar as métricas da partida. O custo computacional é medido por contagem de operações (avaliações de LOS, pathfinding, ações geradas), e não por tempo de relógio, eliminando a dependência do hardware onde o experimento roda.

## Execução

- Validação (*tuning*): 200 simulações preliminares, com *seeds* exclusivas, para calibração dos pesos e do λ — separadas do benchmark para prevenir *overfitting*.
- Benchmark final: 1000 simulações oficiais no banco de *seeds* reservado, idêntico para todos os modelos.
- Execução automatizada e sem renderização, em lotes.

## Modelos Avaliados

- IA Aleatória
- IA Reativa
- IA Heurística
- Art3miz 0.1 (híbrido)

## Coleta de Dados

Para cada simulação serão registrados: resultado, número de turnos, dano causado e recebido pelo agente avaliado, e custo computacional (contagem de operações).

## Análise

Os dados serão analisados de forma quantitativa, permitindo comparação entre os modelos e identificação de padrões de comportamento.
