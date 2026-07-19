extends Node

const BASE_DAMAGE = 30

var x = 0
var y = 0
var max_hp = 100
var hp = 100
var is_alive = true

var team_id = 0
var vision_range = 8

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

	x = target_x
	y = target_y
	print("Agente moveu para: ", x, ", ", y)
	return true

# Ataca outro agente se houver linha de visão e ele estiver dentro do
# alcance de visão. Dano determinístico, reduzido pela cobertura
# direcional do alvo em relação a este atacante.
func attack(target):
	if grid == null or target == self:
		return 0
	if not is_alive or not target.is_alive:
		return 0

	var distance = max(abs(target.x - x), abs(target.y - y))
	if distance > vision_range:
		return 0

	if not grid.has_line_of_sight(x, y, target.x, target.y):
		return 0

	var reduction = grid.get_cover_reduction(target.x, target.y, x, y)
	var damage = max(BASE_DAMAGE - reduction, 0)

	target.take_damage(damage)
	damage_dealt += damage
	print("Agente (", x, ",", y, ") atacou (", target.x, ",", target.y, ") causando ", damage, " de dano")
	return damage

func take_damage(amount):
	damage_received += amount
	hp = max(hp - amount, 0)
	if hp == 0:
		is_alive = false
