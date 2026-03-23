# Arquitetura do Sistema

## 1. Visão Geral

O sistema é composto por módulos independentes responsáveis pela simulação do ambiente, tomada de decisão dos agentes e coleta de dados para análise.

A separação de responsabilidades permite facilitar testes, experimentos e evolução do sistema.

---

## 2. Módulos Principais

### 2.1 Simulador (Core)

Responsável por gerenciar o estado do ambiente e regras do jogo.

Funções:
- controlar o grid
- gerenciar agentes
- aplicar regras de movimento e combate
- executar turnos

---

### 2.2 Mapa

Representa o ambiente do jogo.

Funções:
- armazenar células
- verificar colisões
- calcular linha de visão
- identificar cobertura

---

### 2.3 Agentes

Representam os jogadores controlados pela IA.

Funções:
- armazenar estado (posição, vida, etc.)
- executar ações
- interagir com o ambiente

---

### 2.4 Sistema de IA

Responsável pela tomada de decisão dos agentes.

Funções:
- gerar ações possíveis
- avaliar ações
- selecionar melhor ação

---

### 2.5 Sistema de Turnos

Controla a ordem de execução dos agentes.

Funções:
- alternar entre agentes
- controlar início e fim de turnos

---

### 2.6 Logger / Coleta de Dados

Responsável por registrar informações das simulações.

Funções:
- salvar métricas
- registrar decisões da IA
- exportar dados (CSV ou JSON)

---

## 3. Fluxo do Sistema

1. Inicializar mapa e agentes
2. Iniciar simulação
3. Para cada turno:
   - selecionar agente
   - IA decide ação
   - aplicar ação no simulador
   - atualizar estado
   - registrar dados
4. Finalizar quando condição de vitória for atingida

---

## 4. Separação de Responsabilidades

- Simulador não conhece lógica da IA
- IA não altera diretamente o estado (apenas sugere ações)
- Logger apenas observa e registra

---

## 5. Objetivo da Arquitetura

Garantir:
- modularidade
- facilidade de testes
- execução de múltiplas simulações
- coleta consistente de dados
