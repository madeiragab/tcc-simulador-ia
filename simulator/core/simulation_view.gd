extends Node2D

# Desenha o estado atual da Simulation: grid, paredes/cobertura, os
# 3 jogadores (verde, vermelho, azul) com efeito de brilho, os mortos
# em cinza e os tracers de tiro com fade.
# Só leitura — não altera o estado do jogo.

const CELL_SIZE = 27  # 40 células x 27px = viewport de 1080
const AGENT_RADIUS = CELL_SIZE * 0.36
const SHOT_LIFETIME_MS = 450

const COLOR_BACKGROUND = Color(0.09, 0.09, 0.11)
const COLOR_CHECKER = Color(1, 1, 1, 0.015)
const COLOR_GRID_LINE = Color(1, 1, 1, 0.05)
const COLOR_WALL = Color(0.58, 0.58, 0.63)
const COLOR_COVER_LIGHT = Color(0.42, 0.42, 0.47)
const COLOR_COVER_HEAVY = Color(0.29, 0.29, 0.33)
const COLOR_DEAD = Color(0.42, 0.42, 0.44)
const PLAYER_COLORS = [
	Color(0.25, 0.95, 0.4),
	Color(1.0, 0.28, 0.24),
	Color(0.3, 0.6, 1.0),
]

var simulation = null

var wall_box = null
var cover_light_box = null
var cover_heavy_box = null

func _ready():
	wall_box = make_box(COLOR_WALL, 5)
	cover_light_box = make_box(COLOR_COVER_LIGHT, 6)
	cover_heavy_box = make_box(COLOR_COVER_HEAVY, 6)

func make_box(color, radius):
	var box = StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(radius)
	return box

func _process(_delta):
	if simulation == null:
		return
	# Enquanto houver tracer vivo, redesenha todo frame para o fade.
	if not simulation.recent_shots.is_empty():
		var now = Time.get_ticks_msec()
		simulation.recent_shots = simulation.recent_shots.filter(
			func(shot): return now - shot["time_ms"] < SHOT_LIFETIME_MS
		)
		queue_redraw()

func _draw():
	if simulation == null or simulation.grid == null:
		return

	var grid = simulation.grid
	draw_rect(Rect2(0, 0, grid.width * CELL_SIZE, grid.height * CELL_SIZE), COLOR_BACKGROUND)

	for x in range(grid.width):
		for y in range(grid.height):
			var rect = Rect2(x * CELL_SIZE, y * CELL_SIZE, CELL_SIZE, CELL_SIZE)
			if (x + y) % 2 == 0:
				draw_rect(rect, COLOR_CHECKER)

			var type = grid.grid[x][y]["type"]
			if type == "wall":
				draw_style_box(wall_box, rect)
			elif type == "cover_light":
				draw_style_box(cover_light_box, rect.grow(-3))
			elif type == "cover_heavy":
				draw_style_box(cover_heavy_box, rect.grow(-3))

	for x in range(grid.width + 1):
		draw_line(Vector2(x * CELL_SIZE, 0), Vector2(x * CELL_SIZE, grid.height * CELL_SIZE), COLOR_GRID_LINE)
	for y in range(grid.height + 1):
		draw_line(Vector2(0, y * CELL_SIZE), Vector2(grid.width * CELL_SIZE, y * CELL_SIZE), COLOR_GRID_LINE)

	# Cones de visão por baixo de tudo que está vivo.
	for agent in simulation.agents:
		if agent.is_alive:
			draw_vision_cone(agent)

	# Mortos (por baixo dos vivos): marcador cinza de onde caíram.
	for agent in simulation.agents:
		if not agent.is_alive:
			draw_dead_agent(cell_center(agent.x, agent.y))

	draw_shots()

	for agent in simulation.agents:
		if agent.is_alive:
			draw_agent(cell_center(agent.x, agent.y), PLAYER_COLORS[agent.team_id])
			draw_sensor_hint(agent)

func cell_center(x, y):
	return Vector2(x * CELL_SIZE + CELL_SIZE / 2.0, y * CELL_SIZE + CELL_SIZE / 2.0)

# Halo externo suave + corpo colorido + miolo claro quase branco.
func draw_agent(center, color):
	draw_circle(center, AGENT_RADIUS * 2.1, Color(color.r, color.g, color.b, 0.10))
	draw_circle(center, AGENT_RADIUS * 1.5, Color(color.r, color.g, color.b, 0.25))
	draw_circle(center, AGENT_RADIUS, color)
	draw_circle(center, AGENT_RADIUS * 0.55, color.lightened(0.6))
	draw_circle(center, AGENT_RADIUS * 0.3, Color(1, 1, 1, 0.95))

func draw_dead_agent(center):
	draw_circle(center, AGENT_RADIUS * 0.9, COLOR_DEAD)
	draw_circle(center, AGENT_RADIUS * 0.45, COLOR_DEAD.darkened(0.35))

# Indício do sensor de proximidade (estilo detector de movimento):
# arco na borda do agente apontando a direção do inimigo mais próximo,
# com intensidade conforme a faixa de distância. Não revela a posição.
func draw_sensor_hint(agent):
	var enemies = []
	for other in simulation.agents:
		if other != agent and other.is_alive:
			enemies.append(other)
	if enemies.is_empty():
		return

	var nearest_dist = INF
	var nearest = null
	for enemy in enemies:
		var dist = max(abs(enemy.x - agent.x), abs(enemy.y - agent.y))
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy
	if nearest == null or nearest_dist > 15:
		return

	var intensidade = 0.85 if nearest_dist <= 5 else (0.55 if nearest_dist <= 10 else 0.3)
	var color = PLAYER_COLORS[agent.team_id]
	var center = cell_center(agent.x, agent.y)
	var dir = Vector2(nearest.x - agent.x, nearest.y - agent.y).normalized()
	var base = center + dir * (AGENT_RADIUS * 2.3)

	# Três traços curtos perpendiculares à direção, como um "eco".
	var perp = Vector2(-dir.y, dir.x)
	for i in range(3):
		var offset = dir * (i * 3.5)
		var largura = AGENT_RADIUS * (0.75 - i * 0.18)
		draw_line(
			base + offset + perp * largura,
			base + offset - perp * largura,
			Color(color.r, color.g, color.b, intensidade * (1.0 - i * 0.28)),
			2.0
		)

# Leque translúcido na cor do jogador, indicando para onde ele olha.
func draw_vision_cone(agent):
	var color = PLAYER_COLORS[agent.team_id]
	var center = cell_center(agent.x, agent.y)
	var radius = agent.vision_range * CELL_SIZE
	var base_angle = agent.facing.angle()
	var half = deg_to_rad(agent.VISION_CONE_DEGREES / 2.0)

	var points = PackedVector2Array()
	points.append(center)
	var steps = 20
	for i in range(steps + 1):
		var a = base_angle - half + (2.0 * half) * i / steps
		points.append(center + Vector2(cos(a), sin(a)) * radius)
	draw_colored_polygon(points, Color(color.r, color.g, color.b, 0.05))

# Tracer na cor do atirador, esvaindo com o tempo, com clarão no impacto.
func draw_shots():
	var now = Time.get_ticks_msec()
	for shot in simulation.recent_shots:
		var age = now - shot["time_ms"]
		if age >= SHOT_LIFETIME_MS:
			continue
		var fade = 1.0 - float(age) / SHOT_LIFETIME_MS
		var color = PLAYER_COLORS[shot["team_id"]]
		var from_pos = cell_center(shot["from"].x, shot["from"].y)
		var to_pos = cell_center(shot["to"].x, shot["to"].y)

		draw_line(from_pos, to_pos, Color(color.r, color.g, color.b, 0.75 * fade), 3.0)
		draw_line(from_pos, to_pos, Color(1, 1, 1, 0.35 * fade), 1.5)
		draw_circle(to_pos, AGENT_RADIUS * (1.1 + 0.7 * (1.0 - fade)), Color(1, 1, 1, 0.45 * fade))
