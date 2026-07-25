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

# Modelos disponíveis por nome (usado pela escalação via linha de comando,
# ex.: godot -- batch 1000 verde=heuristica vermelho=aleatoria).
const AI_BY_NAME = {
	"aleatoria": preload("res://ai/ai_random.gd"),
	"reativa": preload("res://ai/ai_reactive.gd"),
	"heuristica": preload("res://ai/ai_heuristic.gd"),
	"hibrida": preload("res://ai/ai_hybrid.gd"),
}

# Sobrescreve a IA de jogadores específicos em tempo de execução
# (player_id -> script). Configurado pelo game.gd a partir dos argumentos.
static var ai_overrides = {}

var grid = null
var agents = []
var ais = []
var cost_meters = []
var turn_system = null
var map_seed = 0
var start_player = 0

# Coleta por jogador (docs/metricas.md): turnos em que agiu e turnos que
# terminou em posição protegida por cobertura adjacente.
var turns_acted = []
var turns_in_cover = []

# Log detalhado turno a turno (docs/coleta_dados.md §2.2). Desligado por
# padrão; o batch_runner liga quando o lote pede documentação por turno.
var collect_turn_log = false
var turn_log = []

# Eventos de tiro recentes, consumidos pela view para desenhar os tracers.
var recent_shots = []

# Última ocorrência de combate, exibida no log de linha única do HUD.
var last_event = ""

# ---------- INICIALIZAÇÃO (diagrams/fluxo_simulacao.png) ----------

# injected_ais: instâncias persistentes de IA (modo lote, para o
# aprendizado entre partidas). Sem elas, cria instâncias novas.
func setup(seed_value, first_player = 0, injected_ais = null):
	map_seed = seed_value
	start_player = first_player

	grid = preload("res://map/grid.gd").new()
	add_child(grid)

	var generator = preload("res://map/map_generator.gd").new()
	var spawns = generator.generate(grid, seed_value)

	agents = []
	ais = []
	cost_meters = []
	turns_acted = []
	turns_in_cover = []
	for i in range(spawns.size()):
		var agent = preload("res://agents/agent.gd").new()
		agent.x = spawns[i].x
		agent.y = spawns[i].y
		agent.team_id = i
		agent.grid = grid
		agents.append(agent)
		add_child(agent)
		if injected_ais != null:
			injected_ais[i].reset_match_state()
			ais.append(injected_ais[i])
		else:
			ais.append(ai_script_for(i).new())
		cost_meters.append(preload("res://core/cost_meter.gd").new())
		turns_acted.append(0)
		turns_in_cover.append(0)

	turn_system = preload("res://core/turn_system.gd").new()
	add_child(turn_system)
	turn_system.setup(agents, start_player)

# ---------- LOOP PRINCIPAL ----------
# Um passo do loop: selecionar agente -> IA decide -> aplicar -> avançar.

func run_turn():
	var agent = turn_system.get_current_agent()
	if agent != null and agent.is_alive:
		# O medidor fica acoplado só durante a decisão: o custo medido é
		# o esforço da IA para decidir, não o da execução da ação.
		grid.cost_meter = cost_meters[agent.team_id]
		var action = ais[agent.team_id].decide(agent, self)
		grid.cost_meter = null

		apply_action(agent, action)

		# Coleta do turno (métrica Cover Usage).
		turns_acted[agent.team_id] += 1
		var protegido = agent.is_alive and grid.has_adjacent_cover(agent.x, agent.y)
		if protegido:
			turns_in_cover[agent.team_id] += 1

		if collect_turn_log:
			log_turn(agent, action, protegido)
	turn_system.advance()

# Registra a linha do turno. Roda com o medidor desacoplado: as contagens
# feitas aqui (LOS para inimigos visíveis) não entram no custo da IA.
func log_turn(agent, action, protegido):
	var acao = "esperar"
	var moveu = action != null and action.get("move_to") != null
	var atacou = action != null and action.get("attack_target") != null
	if moveu and atacou:
		acao = "mover_e_atacar"
	elif moveu:
		acao = "mover"
	elif atacou:
		acao = "atacar"

	var visiveis = 0
	for enemy in get_enemies(agent):
		var dist = max(abs(enemy.x - agent.x), abs(enemy.y - agent.y))
		if dist <= agent.vision_range and grid.has_line_of_sight(agent.x, agent.y, enemy.x, enemy.y):
			visiveis += 1

	turn_log.append({
		"turno": turn_system.turn_count,
		"jogador": PLAYER_NAMES[agent.team_id],
		"acao": acao,
		"x": agent.x,
		"y": agent.y,
		"protegido": protegido,
		"inimigos_visiveis": visiveis,
	})

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

static func ai_script_for(player_id):
	return ai_overrides.get(player_id, PLAYER_AI_SCRIPTS[player_id])

# Nome do modelo de IA de um jogador (derivado do script configurado).
static func model_name(player_id):
	var file = ai_script_for(player_id).resource_path.get_file()
	match file:
		"ai_reactive.gd":
			return "reativa"
		"ai_random.gd":
			return "aleatoria"
		"ai_heuristic.gd":
			return "heuristica"
		"ai_hybrid.gd":
			return "modelo_proposto"
	return file.trim_suffix(".gd")

# Estatísticas brutas de um jogador ao fim da partida — a matéria-prima
# das métricas de docs/metricas.md.
func get_player_stats(player_id):
	var agent = agents[player_id]
	return {
		"jogador": PLAYER_NAMES[player_id],
		"modelo_ia": model_name(player_id),
		"dano_causado": agent.damage_dealt,
		"dano_recebido": agent.damage_received,
		"turnos_agidos": turns_acted[player_id],
		"turnos_em_cobertura": turns_in_cover[player_id],
		"custo_computacional": cost_meters[player_id].total(),
	}

# Custo computacional acumulado de cada jogador, para log e coleta.
func cost_summary():
	var parts = []
	for i in range(agents.size()):
		parts.append("%s=%d" % [PLAYER_NAMES[i], cost_meters[i].total()])
	return "  ".join(parts)

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
