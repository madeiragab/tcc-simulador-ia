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

## Fase 2 — Infraestrutura Experimental ✅ concluída
- [x] Geração procedural de mapas por *seed* (4 setores, spawn sorteado, validação de conectividade — ver `geracao_mapas.md`)
- [x] Limite de 100 turnos com empate
- [x] Modo de execução rápida sem animação (embrião do modo *headless* em lote)
- [x] Contadores de custo computacional abstrato por agente (LOS, nodos de busca, ações avaliadas)
- [x] Rotação uniforme da ordem inicial entre os 3 jogadores (partida i inicia pelo jogador i mod 3)
- [x] Banco fixo de 1000 *seeds* de benchmark + 200 de validação (`experiments/configs/`)
- [x] Execução em lote de múltiplas simulações (`godot --headless -- batch <N> [banco]`)
- [x] Exportação CSV (`data/partidas.csv`, uma linha por jogador por partida)
- [x] Métricas agregadas com StrategicScore literal (`core/metrics.gd`, fórmula de `metricas.md`)

## Fase 3 — IAs Base ✅ concluída
- [x] IA aleatória (`ai/ai_random.gd`)
- [x] IA reativa (`ai/ai_reactive.gd`) — também serve de adversário padrão
- [x] IA heurística (`ai/ai_heuristic.gd`) — Utility AI com pesos calibráveis
- [x] Aprendizado entre partidas por *hill-climbing* nos pesos (`ai/ai_base.gd`),
      com evolução registrada em `aprendizado.csv`
- [x] Campanha de coleta das etapas 1 e 2 (4 lotes × 1000 partidas) — ver
      `resultados_campanha.md`

## Fase 4 — Modelo Proposto (em andamento)
- [ ] Implementação da IA híbrida com integração do custo computacional abstrato
      (`ScoreAção = ValorEstratégico − λ × Custo`)
- [ ] Validação preliminar dos pesos e do λ nas 200 *seeds* de tuning (contra *overfitting*)
      — varredura planejada em λ ∈ {0,005; 0,01; 0,02; 0,05}

Pesos de partida definidos empiricamente pela campanha (melhor configuração
adotada no confronto misto):
`w_vida = 0,092 | w_cobertura = 0,307 | w_proximidade = 0,495 | w_risco = −0,228`

Meta quantitativa (critério de sucesso da hipótese): pontuação média ≥ −0,59
com custo < 1811, idealmente próximo do patamar da reativa (~1360).

## Fase 5 — Benchmark Oficial
- [ ] Execução do híbrido sobre as 1000 *seeds* reservadas
- [ ] Geração das tabelas consolidadas
- [ ] Análise estatística final (médias e desvios padrão)
