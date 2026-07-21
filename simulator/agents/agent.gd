extends Node

const BASE_DAMAGE = 30
const VISION_CONE_DEGREES = 120.0

var x = 0
var y = 0
var max_hp = 100
var hp = 100
var is_alive = true

var team_id = 0
var vision_range = 8

# Orientação: para onde o agente está olhando. Segue a última ação
# (mover vira para a direção do deslocamento; atacar vira para o alvo).
var facing = Vector2(1, 0)

# Posição de onde veio o último tiro sofrido (levar dano revela o
# atirador, mesmo fora do cone — o agente "ouve" o disparo).
var last_hit_from = null

# Acumuladores para as métricas da partida (docs/metricas.md).
var damage_dealt = 0
var damage_received = 0

var grid = null

func _ready():
	print("Agente criado em: ", x, ", ", y)

# Move até 3 células, validando o caminho pelo grid (respeita paredes).
func move_to(target_x, target_y):
	if grid == null:
		return false

	var reachable = grid.get_reachable_cells(x, y, 3)
	if not reachable.has(Vector2i(target_x, target_y)):
		print("Movimento inválido")
		return false

	var delta = Vector2(target_x - x, target_y - y)
	if delta != Vector2.ZERO:
		facing = delta.normalized()

	x = target_x
	y = target_y
	print("Agente moveu para: ", x, ", ", y)
	return true

# Linha reta no grid: horizontal, vertical ou diagonal perfeita.
static func is_straight_line(dx, dy):
	return dx == 0 or dy == 0 or abs(dx) == abs(dy)

# Campo de visão direcional: cone de VISION_CONE_DEGREES centrado na
# orientação, limitado pelo alcance; paredes bloqueiam (coberturas não).
func can_see(target_x, target_y):
	if grid == null:
		return false
	var dist = max(abs(target_x - x), abs(target_y - y))
	if dist > vision_range:
		return false
	var to_target = Vector2(target_x - x, target_y - y)
	if to_target != Vector2.ZERO:
		if abs(facing.angle_to(to_target)) > deg_to_rad(VISION_CONE_DEGREES / 2.0):
			return false
	return grid.has_line_of_sight(x, y, target_x, target_y)

# Ataca outro agente se houver linha de visão e ele estiver dentro do
# alcance de visão. Dano determinístico, reduzido pela cobertura
# direcional do alvo em relação a este atacante.
func attack(target):
	if grid == null or target == self:
		return 0
	if not is_alive or not target.is_alive:
		return 0

	var dx = target.x - x
	var dy = target.y - y

	var distance = max(abs(dx), abs(dy))
	if distance > vision_range:
		return 0

	# Tiro só em linha reta (horizontal, vertical ou diagonal perfeita):
	# fora dessas direções a cobertura direcional seria contornada.
	if not is_straight_line(dx, dy):
		return 0

	if not grid.has_line_of_sight(x, y, target.x, target.y):
		return 0

	var reduction = grid.get_cover_reduction(target.x, target.y, x, y)
	var damage = max(BASE_DAMAGE - reduction, 0)

	# Atacar vira o agente para o alvo.
	var to_target = Vector2(target.x - x, target.y - y)
	if to_target != Vector2.ZERO:
		facing = to_target.normalized()

	target.take_damage(damage, Vector2i(x, y))
	damage_dealt += damage
	print("Agente (", x, ",", y, ") atacou (", target.x, ",", target.y, ") causando ", damage, " de dano")
	return damage

func take_damage(amount, from_pos = null):
	damage_received += amount
	hp = max(hp - amount, 0)
	if hp == 0:
		is_alive = false
	if from_pos != null:
		last_hit_from = from_pos
