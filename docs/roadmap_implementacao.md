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

## Fase 4 — Modelo Proposto ✅ concluída
- [x] Implementação da IA híbrida (`ai/ai_hybrid.gd`) com integração do custo
      computacional abstrato (`ScoreAção = ValorEstratégico − λ × Custo`),
      onde o custo é o de avaliar a própria ação — ver `modelo_proposto.md`
- [x] Poda por orçamento de operações: candidatas ordenadas por promessa e
      avaliadas enquanto houver orçamento, convertendo a penalidade formal
      em economia real de processamento
- [x] Pesos de partida herdados do aprendizado da campanha
      (`w = 0,092 / 0,307 / 0,495 / −0,228`)
- [x] Varredura de λ e do orçamento nas 200 *seeds* de tuning (isoladas do
      benchmark, contra *overfitting*) — ver `resultados_hibrido.md`
- [x] λ e orçamento ajustáveis por linha de comando (`lambda=`, `budget=`)

Meta quantitativa (critério de sucesso da hipótese): pontuação média ≥ −0,59
com custo < 1811, idealmente próximo do patamar da reativa (~1360).

## Fase 5 — Benchmark Oficial ✅ concluída
- [x] Execução do híbrido sobre as 1000 *seeds* reservadas (7.000 partidas: 3 confrontos diretos + 4 autoconfrontos)
- [x] Tabelas consolidadas em `resultados_finais.md`
- [x] Análise estatística final (médias e desvios padrão) e interpretação da hipótese
