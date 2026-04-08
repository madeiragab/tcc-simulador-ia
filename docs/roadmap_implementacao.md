# Roadmap de Implementação

## Fase 1 — Core da Simulação
- Grid funcional
- Tipos de célula
- Spawn de agentes
- Sistema de turnos
- Movimento básico
- Ataque básico
- Linha de visão

## Fase 2 — Infraestrutura Experimental
- Logger de métricas
- Sistema limitador em ciclo fechado (Custo Abstracto contra *time-clock*)
- Controle rigoroso (Alternância Injetada de Turno 1)
- Sistema banco de exclusividade das *Seeds* Randomizadas (1000 iterativas)
- Timeout limitando rodadas em marco 100 
- Exportação de arquivos CSV de Benchmark

## Fase 3 — IAs Base
- IA aleatória
- IA reativa
- IA heurística simples

## Fase 4 — Modelo Proposto
- Fase paralela preliminar: Validação empírica do Epsilon/Lambdas separados (Ex: em *dataset* gerado de 200 *seeds* exclusivas contra *Overfitting*)
- Implementação formal da IA híbrida e integração do *CustoComputacionalAbstrato*

## Fase 5 — Benchmark Oficial
- Execução isolada sobre escopo intocado das 1000 *seeds*
- Geração final das tabelas consolidadas
- Extrapolação estatística final e desvios numéricos