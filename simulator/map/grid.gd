extends Node

const COVER_LIGHT_REDUCTION = 10
const COVER_HEAVY_REDUCTION = 20

var width = 40
var height = 40

var grid = []

func _ready():
	create_grid()
	print("Grid criado: ", width, "x", height)

func create_grid():
	for x in range(width):
		var row = []
		for y in range(height):
			row.append({
				"type": "empty"
			})
		grid.append(row)

func is_valid_position(x, y):
	if x < 0 or y < 0:
		return false
	if x >= width or y >= height:
		return false

	var cell = grid[x][y]

	if cell["type"] == "wall":
		return false
	return true

func get_cell_type(x, y):
	if x < 0 or y < 0 or x >= width or y >= height:
		return "wall"
	return grid[x][y]["type"]

func set_cell_type(x, y, type):
	if x >= 0 and x < width and y >= 0 and y < height:
		grid[x][y]["type"] = type

func set_rect_type(x1, y1, x2, y2, type):
	for x in range(x1, x2 + 1):
		for y in range(y1, y2 + 1):
			set_cell_type(x, y, type)

func get_cover_reduction_for_type(type):
	if type == "cover_light":
		return COVER_LIGHT_REDUCTION
	if type == "cover_heavy":
		return COVER_HEAVY_REDUCTION
	return 0

# Retorna as células alcançáveis a partir de (x, y) em até max_steps
# movimentos ortogonais, respeitando paredes (BFS).
func get_reachable_cells(x, y, max_steps):
	var visited = {Vector2i(x, y): true}
	var queue = [[Vector2i(x, y), 0]]
	var result = []

	var directions = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

	while queue.size() > 0:
		var current = queue.pop_front()
		var pos = current[0]
		var dist = current[1]

		if dist > 0:
			result.append(pos)

		if dist >= max_steps:
			continue

		for dir in directions:
			var next_pos = pos + dir
			if visited.has(next_pos):
				continue
			if not is_valid_position(next_pos.x, next_pos.y):
				continue
			visited[next_pos] = true
			queue.append([next_pos, dist + 1])

	return result

# Traça a reta (Bresenham) entre duas células, incluindo as pontas.
func get_line_cells(x1, y1, x2, y2):
	var cells = []
	var dx = abs(x2 - x1)
	var dy = -abs(y2 - y1)
	var sx = 1 if x1 < x2 else -1
	var sy = 1 if y1 < y2 else -1
	var err = dx + dy
	var cx = x1
	var cy = y1

	while true:
		cells.append(Vector2i(cx, cy))
		if cx == x2 and cy == y2:
			break
		var e2 = 2 * err
		if e2 >= dy:
			err += dy
			cx += sx
		if e2 <= dx:
			err += dx
			cy += sy

	return cells

# Só paredes bloqueiam linha de visão; cobertura não bloqueia.
func has_line_of_sight(x1, y1, x2, y2):
	var cells = get_line_cells(x1, y1, x2, y2)
	for i in range(1, cells.size() - 1):
		var cell = cells[i]
		if get_cell_type(cell.x, cell.y) == "wall":
			return false
	return true

# Cobertura direcional: só protege o defensor se houver uma célula de
# cobertura entre ele e o atacante especificamente.
func get_cover_reduction(defender_x, defender_y, attacker_x, attacker_y):
	var dx = sign(attacker_x - defender_x)
	var dy = sign(attacker_y - defender_y)

	var reduction = 0

	if dx != 0:
		var side_type = get_cell_type(defender_x + dx, defender_y)
		reduction = max(reduction, get_cover_reduction_for_type(side_type))

	if dy != 0:
		var side_type = get_cell_type(defender_x, defender_y + dy)
		reduction = max(reduction, get_cover_reduction_for_type(side_type))

	return reduction
