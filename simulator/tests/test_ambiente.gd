extends SceneTree

# Regressão do ambiente — o mapa, a linha de visada e a cobertura direcional.
#
# Uso: godot --headless --path simulator --script res://tests/test_ambiente.gd
#
# Por que estes testes existem: a monografia inteira afirma que o ambiente é
# neutro, determinístico e reprodutível, e nada verificava isso. O risco não é
# teórico — erro de script no GDScript não aborta a execução. Um grid que
# nasceu sem células deixa o gerador escrever em um array vazio, as partidas
# rodam do começo ao fim sobre um mapa que não existe, e o processo termina com
# código zero. Aconteceu. Nenhum teste pegou, porque nenhum existia.
#
# A conectividade é conferida por uma busca escrita aqui, e não pela
# `spawns_connected` do próprio gerador: um teste que chama a função que
# deveria estar validando não valida nada.

const GridScript = preload("res://map/grid.gd")
const GeradorScript = preload("res://map/map_generator.gd")
const AgentScript = preload("res://agents/agent.gd")

# Seeds do banco oficial de benchmark (experiments/seeds_benchmark.txt).
const SEEDS = [438557537, 1864560048, 990947591, 980411883, 1364875354, 1247406621]

# Quantas verificacoes esta sui­te faz quando roda inteira.
#
# Sem este numero a sui­te mente. Erro de script no GDScript nao aborta o
# processo: uma chamada invalida no meio de uma funcao interrompe aquela
# funcao, o restante das verificacoes nunca acontece, e o rodape imprime
# "todas passaram" sobre um punhado delas -- com o CI verde. Aconteceu aqui,
# 20 de 75. O denominador anda junto do numerador.
const VERIFICACOES_ESPERADAS = 75

var falhas := 0
var total := 0

# Grid e gerador sao Nodes criados fora da arvore: ninguem os libera por nos.
# Sem esta lista o Godot fecha reclamando de instancias vazadas, e um aviso
# ruidoso no fim do log e como um teste vermelho que todo mundo aprende a
# ignorar.
var criados := []


func _initialize() -> void:
	testar_determinismo()
	testar_mapa_nao_nasce_vazio()
	testar_spawns_conectados()
	testar_zona_de_seguranca()
	testar_linha_de_visada()
	testar_cobertura_direcional()
	testar_tiro_em_linha_reta()

	for objeto in criados:
		objeto.free()
	criados.clear()

	print("")
	if total != VERIFICACOES_ESPERADAS:
		print("ESPERADAS %d verificações, %d aconteceram — alguma função parou no meio"
			% [VERIFICACOES_ESPERADAS, total])
		quit(1)
	elif falhas == 0:
		print("%d verificações, todas passaram" % total)
		quit(0)
	else:
		print("%d verificações, %d FALHARAM" % [total, falhas])
		quit(1)


# ---------- infraestrutura mínima ----------

func verdade(nome: String, condicao: bool) -> void:
	total += 1
	if condicao:
		print("  OK   %s" % nome)
	else:
		falhas += 1
		print("  FALHA %s" % nome)


func igual_int(nome: String, obtido: int, esperado: int) -> void:
	total += 1
	if obtido == esperado:
		print("  OK   %s" % nome)
	else:
		falhas += 1
		print("  FALHA %s: esperado %d, obtido %d" % [nome, esperado, obtido])


# Grid fora da árvore: `_ready()` só roda quando o nó entra em cena, e um
# script de ferramenta não tem cena. `create_grid()` é chamado à mão.
func novo_grid() -> Object:
	var grid = GridScript.new()
	grid.create_grid()
	criados.append(grid)
	return grid


func gerar(seed_value: int) -> Array:
	var grid = novo_grid()
	# O gerador e RefCounted: some sozinho quando a referencia sai de escopo.
	# Chamar free() nele e erro -- e o erro aborta esta funcao no meio.
	var spawns = GeradorScript.new().generate(grid, seed_value)
	return [grid, spawns]


func desenhar(grid) -> String:
	var texto := ""
	for y in range(grid.height):
		for x in range(grid.width):
			texto += grid.get_cell_type(x, y).substr(0, 1)
	return texto


# ---------- determinismo ----------

func testar_determinismo() -> void:
	print("determinismo: a mesma seed produz o mesmo mapa")
	for seed_value in SEEDS:
		var a = gerar(seed_value)
		var b = gerar(seed_value)
		verdade("seed %d: mapa idêntico" % seed_value, desenhar(a[0]) == desenhar(b[0]))
		verdade("seed %d: spawns idênticos" % seed_value, a[1] == b[1])

	# O contrário também precisa valer: um gerador que devolve sempre o mesmo
	# mapa passaria em todas as verificações acima.
	var primeiro = desenhar(gerar(SEEDS[0])[0])
	var diferentes := 0
	for i in range(1, SEEDS.size()):
		if desenhar(gerar(SEEDS[i])[0]) != primeiro:
			diferentes += 1
	igual_int("seeds diferentes produzem mapas diferentes", diferentes, SEEDS.size() - 1)


# ---------- o mapa existe ----------

func testar_mapa_nao_nasce_vazio() -> void:
	print("o mapa gerado tem grid, parede e cobertura")
	for seed_value in SEEDS:
		var grid = gerar(seed_value)[0]

		igual_int("seed %d: linhas do grid" % seed_value, grid.grid.size(), grid.width)
		igual_int("seed %d: colunas do grid" % seed_value, grid.grid[0].size(), grid.height)

		var paredes := 0
		var coberturas := 0
		for y in range(grid.height):
			for x in range(grid.width):
				var tipo = grid.get_cell_type(x, y)
				if tipo == "wall":
					paredes += 1
				elif tipo == "cover_light" or tipo == "cover_heavy":
					coberturas += 1

		verdade("seed %d: tem parede (%d)" % [seed_value, paredes], paredes > 0)
		verdade("seed %d: tem cobertura (%d)" % [seed_value, coberturas], coberturas > 0)


# ---------- conectividade ----------

# Busca em largura independente do gerador, com a mesma regra de movimento do
# jogo: quatro direções, parede bloqueia.
func alcancaveis(grid, origem: Vector2i) -> Dictionary:
	var vistos := {origem: true}
	var fila := [origem]
	var direcoes := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

	while fila.size() > 0:
		var atual = fila.pop_front()
		for direcao in direcoes:
			var proximo = atual + direcao
			if vistos.has(proximo):
				continue
			if not grid.is_valid_position(proximo.x, proximo.y):
				continue
			vistos[proximo] = true
			fila.append(proximo)
	return vistos


func testar_spawns_conectados() -> void:
	print("todo spawn alcança os outros dois")
	for seed_value in SEEDS:
		var resultado = gerar(seed_value)
		var grid = resultado[0]
		var spawns = resultado[1]

		igual_int("seed %d: três spawns" % seed_value, spawns.size(), 3)

		var vistos = alcancaveis(grid, spawns[0])
		var ok := true
		for i in range(1, spawns.size()):
			if not vistos.has(spawns[i]):
				ok = false
		verdade("seed %d: spawns mutuamente alcançáveis" % seed_value, ok)


func testar_zona_de_seguranca() -> void:
	print("nenhum obstáculo dentro da folga do spawn")
	var folga = GeradorScript.SPAWN_CLEARANCE
	for seed_value in SEEDS:
		var resultado = gerar(seed_value)
		var grid = resultado[0]
		var spawns = resultado[1]

		var invasoes := 0
		for spawn in spawns:
			for dy in range(-folga, folga + 1):
				for dx in range(-folga, folga + 1):
					var tipo = grid.get_cell_type(spawn.x + dx, spawn.y + dy)
					# Fora do grid `get_cell_type` devolve "wall": esse caso é
					# borda do mapa, não obstáculo colocado pelo gerador.
					if not grid.is_valid_position(spawn.x + dx, spawn.y + dy):
						continue
					if tipo != "empty":
						invasoes += 1
		igual_int("seed %d: obstáculos na zona de segurança" % seed_value, invasoes, 0)


# ---------- linha de visada ----------

func testar_linha_de_visada() -> void:
	print("só parede bloqueia linha de visada")
	var grid = novo_grid()

	verdade("corredor livre", grid.has_line_of_sight(5, 5, 12, 5))

	grid.set_cell_type(8, 5, "wall")
	verdade("parede no meio bloqueia", not grid.has_line_of_sight(5, 5, 12, 5))

	grid.set_cell_type(8, 5, "cover_heavy")
	verdade("cobertura pesada no meio NÃO bloqueia", grid.has_line_of_sight(5, 5, 12, 5))

	grid.set_cell_type(8, 5, "empty")

	# As pontas ficam de fora do laço: um agente encostado numa parede ainda
	# enxerga, e um alvo em cima de uma não fica invisível por isso.
	grid.set_cell_type(5, 5, "wall")
	grid.set_cell_type(12, 5, "wall")
	verdade("as pontas não bloqueiam", grid.has_line_of_sight(5, 5, 12, 5))

	grid.set_cell_type(5, 5, "empty")
	grid.set_cell_type(12, 5, "empty")

	grid.set_cell_type(8, 8, "wall")
	verdade("parede na diagonal bloqueia", not grid.has_line_of_sight(5, 5, 12, 12))


# ---------- cobertura direcional ----------

func testar_cobertura_direcional() -> void:
	print("a cobertura só protege na direção do atacante")
	var grid = novo_grid()
	var defensor := Vector2i(20, 20)

	igual_int("sem cobertura, redução 0",
		grid.get_cover_reduction(defensor.x, defensor.y, 25, 20), 0)

	# Cobertura à direita do defensor: protege de quem vem da direita.
	grid.set_cell_type(21, 20, "cover_light")
	igual_int("leve entre defensor e atacante = 10",
		grid.get_cover_reduction(defensor.x, defensor.y, 25, 20), 10)
	igual_int("a mesma cobertura não protege pelo lado oposto",
		grid.get_cover_reduction(defensor.x, defensor.y, 15, 20), 0)

	grid.set_cell_type(21, 20, "cover_heavy")
	igual_int("pesada entre defensor e atacante = 20",
		grid.get_cover_reduction(defensor.x, defensor.y, 25, 20), 20)

	# Com cobertura dos dois lados vale a maior, e é a do lado do atacante.
	grid.set_cell_type(19, 20, "cover_light")
	igual_int("atacante à direita continua vendo a pesada",
		grid.get_cover_reduction(defensor.x, defensor.y, 25, 20), 20)
	igual_int("atacante à esquerda vê a leve",
		grid.get_cover_reduction(defensor.x, defensor.y, 15, 20), 10)

	# Cover Usage conta posição protegida em qualquer direção — é outra
	# pergunta, e a resposta certa aqui é sim.
	verdade("posição com cobertura adjacente conta como protegida",
		grid.has_adjacent_cover(defensor.x, defensor.y))
	verdade("posição isolada não conta", not grid.has_adjacent_cover(2, 2))


# ---------- tiro em linha reta ----------

func testar_tiro_em_linha_reta() -> void:
	print("tiro só na horizontal, vertical ou diagonal perfeita")
	verdade("horizontal", AgentScript.is_straight_line(5, 0))
	verdade("vertical", AgentScript.is_straight_line(0, -4))
	verdade("diagonal perfeita", AgentScript.is_straight_line(3, -3))
	verdade("mesma célula", AgentScript.is_straight_line(0, 0))

	# Sem esta regra a cobertura direcional seria contornável por ângulo: o
	# atacante escolheria um vetor que não passa pela célula que protege.
	verdade("2 por 1 é recusado", not AgentScript.is_straight_line(2, 1))
	verdade("1 por 3 é recusado", not AgentScript.is_straight_line(1, 3))
	verdade("5 por 4 é recusado", not AgentScript.is_straight_line(5, 4))
