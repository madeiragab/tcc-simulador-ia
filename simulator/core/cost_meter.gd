extends RefCounted

# Medidor de custo computacional abstrato (docs/metricas.md): conta
# operações em vez de medir tempo de relógio, eliminando a dependência
# do hardware onde o experimento roda.
#
# Cada agente tem o seu medidor, ligado ao grid apenas enquanto a IA
# dele está decidindo — o custo medido é o custo DA DECISÃO, não da
# execução da ação.
#
# Contadores (alinhados à definição em docs/metricas.md):
#   los_checks        — cálculos de linha de visão acionados
#   cells_explored    — nodos visitados/filtrados nas buscas (BFS)
#   actions_evaluated — ações geradas e avaliadas pela IA

var los_checks = 0
var cells_explored = 0
var actions_evaluated = 0

func total():
	return los_checks + cells_explored + actions_evaluated

func reset():
	los_checks = 0
	cells_explored = 0
	actions_evaluated = 0
