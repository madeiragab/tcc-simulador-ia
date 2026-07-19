extends Node

# Simulador/Core (docs/arquitetura.md e diagrams/arquitetura.png):
# orquestra grid, agentes e turnos. A IA de cada jogador é um módulo
# separado em res://ai/ — ela apenas SUGERE uma ação; quem aplica ao
# estado do jogo é esta classe.
#
# Modo de jogo: 3 agentes independentes (todos contra todos), nascendo
# em setores sorteados pela seed — ver docs/geracao_mapas.md.

const PLAYER_NAMES = ["verde", "vermelho", "azul"]

# ============================================================
# CONFIGURAÇÃO DAS IAs
# Para trocar a IA de um jogador, mude apenas a linha dele:
#   ai_reactive.gd — ataca se vê, senão aproxima (baseline)
#   ai_random.gd   — ação válida aleatória (baseline)
# ============================================================
const PLAYER_AI_SCRIPTS = [
	preload("res://ai/ai_reactive.gd"),   # verde
	preload("res://ai/ai_reactive.gd"),   # vermelho
	preload("res://ai/ai_reactive.gd"),   # azul
]

var grid = null
var agents = []
var ais = []
var turn_system = null
var map_seed = 0

# Eventos de tiro recentes, consumidos pela view para desenhar os tracers.
var recent_shots = []

# Última ocorrência de combate, exibida no log de linha única do HUD.
var last_event = ""

# ---------- INICIALIZAÇÃO (diagrams/fluxo_simulacao.png) ----------

func setup(seed_value):
	map_seed = seed_value

	grid = preload("res://map/grid.gd").new()
	add_child(grid)

	var generator = preload("res://map/map_generator.gd").new()
	var spawns = generator.generate(grid, seed_value)

	agents = []
	ais = []
	for i in range(spawns.size()):
		var agent = preload("res://agents/agent.gd").new()
		agent.x = spawns[i].x
		agent.y = spawns[i].y
		agent.team_id = i
		agent.grid = grid
		agents.append(agent)
		add_child(agent)
		ais.append(PLAYER_AI_SCRIPTS[i].new())

	turn_system = preload("res://core/turn_system.gd").new()
	add_child(turn_system)
	turn_system.setup(agents)

# ---------- LOOP PRINCIPAL ----------
# Um passo do loop: selecionar agente -> IA decide -> aplicar -> avançar.

func run_turn():
	var agent = turn_system.get_current_agent()
	if agent != null and agent.is_alive:
		var action = ais[agent.team_id].decide(agent, self)
		apply_action(agent, action)
		# (Fase 2) ponto de coleta: registrar métricas do turno aqui
	turn_system.advance()

# Aplica a ação sugerida pela IA: primeiro o movimento, depois o ataque.
func apply_action(agent, action):
	if action == null:
		return

	var move_to = action.get("move_to")
	if move_to != null:
		agent.move_to(move_to.x, move_to.y)

	var target = action.get("attack_target")
	if target != null:
		var damage = agent.attack(target)
		if damage > 0:
			recent_shots.append({
				"from": Vector2i(agent.x, agent.y),
				"to": Vector2i(target.x, target.y),
				"team_id": agent.team_id,
				"time_ms": Time.get_ticks_msec(),
			})
			var victim = PLAYER_NAMES[target.team_id]
			if target.is_alive:
				last_event = "%s tomou %d de dano — vida %d/%d" % [victim, damage, target.hp, target.max_hp]
			else:
				last_event = "%s tomou %d de dano e foi eliminado por %s" % [victim, damage, PLAYER_NAMES[agent.team_id]]

# ---------- CONSULTAS DE ESTADO ----------

func get_enemies(agent):
	var enemies = []
	for other in agents:
		if other != agent and other.is_alive:
			enemies.append(other)
	return enemies

func get_alive():
	var alive = []
	for agent in agents:
		if agent.is_alive:
			alive.append(agent)
	return alive

# "" = em andamento, nome do jogador = último vivo,
# "draw" = limite de 100 turnos com 2+ vivos (docs/regras.md §4.1).
func check_victory():
	var alive = get_alive()
	if alive.size() <= 1:
		if alive.size() == 1:
			return PLAYER_NAMES[alive[0].team_id]
		return "draw"
	if turn_system.is_turn_limit_reached():
		return "draw"
	return ""
