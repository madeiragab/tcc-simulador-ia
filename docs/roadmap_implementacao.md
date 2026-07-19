# Roadmap de Implementação

## Fase 1 — Core da Simulação ✅ concluída
- [x] Grid funcional
- [x] Tipos de célula (vazio, parede, cobertura leve, cobertura pesada)
- [x] Spawn de agentes
- [x] Sistema de turnos
- [x] Movimento com validação de caminho (BFS, até 3 células)
- [x] Ataque determinístico com cobertura direcional
- [x] Linha de visão (paredes bloqueiam visão e tiro)
- [x] Visualização do grid e dos 3 jogadores
- [x] Efeitos visuais de acompanhamento (tracer de tiro, marcador de morte, tela de vitória com reinício)

## Fase 2 — Infraestrutura Experimental (em andamento)
- [x] Geração procedural de mapas por *seed* (4 setores, spawn sorteado, validação de conectividade — ver `geracao_mapas.md`)
- [x] Limite de 100 turnos com empate
- [x] Modo de execução rápida sem animação (embrião do modo *headless* em lote)
- [x] Contadores de custo computacional abstrato por agente (LOS, nodos de busca, ações avaliadas)
- [x] Rotação uniforme da ordem inicial entre os 3 jogadores (partida i inicia pelo jogador i mod 3)
- [x] Banco fixo de 1000 *seeds* de benchmark + 200 de validação (`experiments/configs/`)
- [x] Execução em lote de múltiplas simulações (`godot --headless -- batch <N> [banco]`)
- [x] Exportação CSV (`data/partidas.csv`, uma linha por jogador por partida)
- [x] Métricas agregadas com StrategicScore literal (`core/metrics.gd`, fórmula de `metricas.md`)

## Fase 3 — IAs Base
- [ ] IA aleatória
- [ ] IA reativa (também servirá de adversário padrão nas avaliações)
- [ ] IA heurística simples

## Fase 4 — Modelo Proposto
- [ ] Validação preliminar dos pesos e do λ nas 200 *seeds* de tuning (contra *overfitting*)
- [ ] Implementação da IA híbrida com integração do custo computacional abstrato

## Fase 5 — Benchmark Oficial
- [ ] Execução sobre as 1000 *seeds* reservadas
- [ ] Geração das tabelas consolidadas
- [ ] Análise estatística final (médias e desvios padrão)
