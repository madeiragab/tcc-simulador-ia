extends RefCounted

# Gera o mapa a partir de uma seed, seguindo docs/geracao_mapas.md:
# 4 setores, spawn dos 3 jogadores em setores distintos sorteados,
# obstáculos aleatórios e validação de conectividade por BFS.
# Mesma seed => mesmo mapa e mesmos spawns, sempre.

const MAX_ATTEMPTS = 25
const SPAWN_CLEARANCE = 2
const PLAYER_COUNT = 3
const SECTOR_SIZE = 20

func generate(grid, seed_value):
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_value

	for attempt in range(MAX_ATTEMPTS):
		clear_grid(grid)
		var spawns = pick_spawns(rng)
		place_obstacles(grid, rng, spawns)
		if spawns_connected(grid, spawns):
			return spawns

	# Salvaguarda: mapa aberto garante conectividade.
	clear_grid(grid)
	return pick_spawns(rng)

func clear_grid(grid):
	for x in range(grid.width):
		for y in range(grid.height):
			grid.grid[x][y]["type"] = "empty"

# Embaralha os 4 setores com o RNG da seed (Fisher-Yates) e coloca um
# jogador na região central de cada um dos 3 primeiros.
func pick_spawns(rng):
	var sectors = [0, 1, 2, 3]
	for i in range(sectors.size() - 1, 0, -1):
		var j = rng.randi_range(0, i)
		var tmp = sectors[i]
		sectors[i] = sectors[j]
		sectors[j] = tmp

	var spawns = []
	for i in range(PLAYER_COUNT):
		var sector = sectors[i]
		var origin_x = (sector % 2) * SECTOR_SIZE
		var origin_y = (sector / 2) * SECTOR_SIZE
		var spawn_x = origin_x + rng.randi_range(5, SECTOR_SIZE - 6)
		var spawn_y = origin_y + rng.randi_range(5, SECTOR_SIZE - 6)
		spawns.append(Vector2i(spawn_x, spawn_y))
	return spawns

func place_obstacles(grid, rng, spawns):
	var wall_count = rng.randi_range(10, 14)
	for i in range(wall_count):
		place_wall_segment(grid, rng, spawns)

	var light_count = rng.randi_range(8, 12)
	for i in range(light_count):
		place_cover_block(grid, rng, spawns, "cover_light")

	var heavy_count = rng.randi_range(4, 6)
	for i in range(heavy_count):
		place_cover_block(grid, rng, spawns, "cover_heavy")

# Segmento reto de parede, horizontal ou vertical, de 3 a 7 células.
func place_wall_segment(grid, rng, spawns):
	var length = rng.randi_range(3, 7)
	var horizontal = rng.randi_range(0, 1) == 0
	var x = rng.randi_range(1, grid.width - 2 - (length if horizontal else 0))
	var y = rng.randi_range(1, grid.height - 2 - (0 if horizontal else length))

	for i in range(length):
		var cx = x + (i if horizontal else 0)
		var cy = y + (0 if horizontal else i)
		set_obstacle(grid, spawns, cx, cy, "wall")

# Bloco de cobertura de 1 a 2 células.
func place_cover_block(grid, rng, spawns, type):
	var length = rng.randi_range(1, 2)
	var horizontal = rng.randi_range(0, 1) == 0
	var x = rng.randi_range(1, grid.width - 2 - (length if horizontal else 0))
	var y = rng.randi_range(1, grid.height - 2 - (0 if horizontal else length))

	for i in range(length):
		var cx = x + (i if horizontal else 0)
		var cy = y + (0 if horizontal else i)
		set_obstacle(grid, spawns, cx, cy, type)

# Escreve a célula respeitando a zona de segurança dos spawns.
func set_obstacle(grid, spawns, x, y, type):
	for spawn in spawns:
		if max(abs(spawn.x - x), abs(spawn.y - y)) <= SPAWN_CLEARANCE:
			return
	grid.set_cell_type(x, y, type)

# BFS a partir do primeiro spawn: o mapa só vale se alcançar os demais.
func spawns_connected(grid, spawns):
	var visited = {spawns[0]: true}
	var queue = [spawns[0]]
	var directions = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

	while queue.size() > 0:
		var pos = queue.pop_front()
		for dir in directions:
			var next_pos = pos + dir
			if visited.has(next_pos):
				continue
			if not grid.is_valid_position(next_pos.x, next_pos.y):
				continue
			visited[next_pos] = true
			queue.append(next_pos)

	for i in range(1, spawns.size()):
		if not visited.has(spawns[i]):
			return false
	return true
