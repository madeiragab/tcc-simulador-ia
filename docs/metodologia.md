# Metodologia Experimental

## Abordagem

O estudo será conduzido por meio de simulações automatizadas em um ambiente tático controlado.

## Configuração do Ambiente

- Grid bidimensional simétrico (NxN) com geração procedural atrelada rigidamente a *seeds* exclusivas.
- Banco padronizado de 1000 *seeds* definindo mapas, as quais serão enfrentadas de forma matematicamente idêntica por todos os modelos concorrentes
- Configuração fixa para confrontos de 3 agentes (equipes lado-a-lado ou espelhadas horizontalmente)
- Anulação do Viés de Primeiro Turno (*first-mover advantage*): distribuição obrigatória de 50/50 das rodadas iniciadas pelo primeiro ou segundo contendor
- Sistema de combate determinístico blindando viés em confrontos e desvios por *RNG*

## Procedimento Experimental

1. Inicializar o labirinto/cenário e distribuir obstáculos validados através do banco fechado de Sementes (*seeds* espaciais)
2. Engatilhar o sorteio 50/50 de quem efetuará a iniciativa do combate para eliminar vantagem assimétrica
3. Registrar e iterar as métricas sobre avaliação matemática (Operações executadas substituem avaliações em milissegundos puramente do hardware nativo)
4. Executar e consolidar em empate com valor numérico máximo após extrapolação imperiosa de limite global para o cravado de 100 turnos

## Execução

- Validação (*Tuning*): 200 simulações preliminares em *seeds* únicas e exclusivas para calibração paramétrica, prevenindo *overfitting* de heurísticas e *lambdas* da IA.
- Teste Cego Final (*Benchmark*): Exatas 1000 simulações oficiais no banco isolado de *seeds* reservadas para análise das vitórias cegas
- Execução automatizada e sem renderização em lotes contínuos.

## Modelos Avaliados

- IA Aleatória
- IA Reativa
- IA Heurística
- Modelo Proposto (híbrido)

## Coleta de Dados

Serão coletados:

- resultados das partidas iteradas e métricas matemáticas abstraídas de hardware local (tais como as verificações analíticas do terreno no Custo Computacional)

## Análise

Os dados serão analisados de forma quantitativa, permitindo comparação entre os modelos e identificação de padrões de comportamento.
