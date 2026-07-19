# Sistema de Turnos

## Regras

- Cada agente atua uma vez por turno
- Um turno completo ocorre quando todos os agentes vivos agem
- Agentes mortos são pulados na ordem
- Cada agente pode:
  - mover até 3 células
  - executar uma ação
- A ordem inicial de jogo é rotacionada uniformemente entre os 3 agentes ao longo das simulações (cada um inicia 1/3 das partidas), eliminando o viés de primeiro turno

## Objetivo

Controlar a ordem de execução e preparar o sistema para decisões automatizadas
