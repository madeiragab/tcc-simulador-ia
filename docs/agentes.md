# Modelo de Agente

## Atributos

- posição (x, y)
- vida (hp)
- alcance de visão (também usado como alcance de ataque)
- estado (vivo ou morto)
- identificador do jogador (verde, vermelho ou azul)

## Estado inicial

Cada partida tem 3 agentes independentes (todos contra todos). Cada um nasce com vida cheia em um setor distinto do mapa, sorteado pela *seed* (ver `geracao_mapas.md`).

## Objetivo

Servir como entidade base para simulação de decisões e interação no ambiente tático.
