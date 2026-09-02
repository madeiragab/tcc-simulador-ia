extends SceneTree

# Exporta partidas completas em JSON para o site de demonstração.
#
# O site não reimplementa nada: ele desenha o que este arquivo gravou. O
# mapa vem do gerador procedural, os movimentos vêm das mesmas IAs do
# benchmark, e a seed vai junto para que qualquer linha seja refeita com
#   godot --headless --path simulator -- batch 1 <modelos>
#
# Uso:
#   godot --headless --path simulator --script res://tools/replay_dump.gd
#   godot --headless --path simulator --script res://tools/replay_dump.gd -- partidas=8
#
# Argumentos (todos opcionais):
#   partidas=N   quantas seeds do banco de benchmark exportar (padrão 6)
#   saida=CAM    caminho do JSON, relativo à raiz do repositório
#                (padrão site/dados/replays.json)

const SimulationScript = preload("res://core/simulation.gd")
const Metrics = preload("res://core/metrics.gd")

# Escalação oficial do confronto triplo (docs/resultados_finais.md §2.1).
const ESCALACAO = ["art3miz", "heuristica", "reativa"]

# Um caractere por tipo de célula. O site desenha a partir destas letras.
const CELULA = {
	"empty": ".",
	"wall": "#",
	"cover_light": "l",
	"cover_heavy": "H",
}

# O trabalho não cabe em _initialize(): a árvore ainda não está viva ali, e
# um Node adicionado à raiz não recebe _ready(). O grid sai sem células, o
# gerador escreve em um array vazio, e como erro de script no GDScript não
# aborta nada, a partida inteira roda sobre um mapa que não existe. Então a
# execução espera o primeiro quadro, quando add_child() já vale.
var feito = false

func _process(_delta):
	if feito:
		return true
	feito = true
	trabalhar()
	return true

func trabalhar():
	var opcoes = ler_argumentos()
	var raiz = ProjectSettings.globalize_path("res://").path_join("..")

	var seeds = ler_seeds(raiz.path_join("experiments/seeds_benchmark.txt"))
	if seeds.is_empty():
		push_error("Banco de seeds de benchmark não encontrado.")
		quit(1)
		return

	var total = min(opcoes["partidas"], seeds.size())
	for i in range(SimulationScript.PLAYER_NAMES.size()):
		SimulationScript.ai_overrides[i] = SimulationScript.AI_BY_NAME[ESCALACAO[i]]

	# IAs persistentes, como no lote: elas aprendem entre partidas, e um
	# replay com instâncias novas a cada seed não seria o mesmo jogo.
	var ias = []
	for i in range(SimulationScript.PLAYER_NAMES.size()):
		var ia = SimulationScript.ai_script_for(i).new()
		ia.player_id = i
		ias.append(ia)

	var partidas = []
	for i in range(total):
		partidas.append(rodar(seeds[i], i, ias))
		print("  partida %d/%d  seed %d" % [i + 1, total, seeds[i]])

	# Caminho absoluto vale por si; relativo conta a partir da raiz do repo.
	var saida = opcoes["saida"]
	if not saida.is_absolute_path():
		saida = raiz.path_join(saida)
	DirAccess.make_dir_recursive_absolute(saida.get_base_dir())
	var arquivo = FileAccess.open(saida, FileAccess.WRITE)
	if arquivo == null:
		push_error("Não foi possível gravar " + saida)
		quit(1)
		return
	arquivo.store_string(JSON.stringify({
		"gerado_em": Time.get_datetime_string_from_system(true),
		"godot": Engine.get_version_info()["string"],
		"escalacao": ESCALACAO,
		"legenda_celulas": CELULA,
		"partidas": partidas,
	}))
	arquivo.close()
	print("%d partidas -> %s" % [partidas.size(), saida])
	quit()

# ---------- uma partida ----------

func rodar(seed_value, indice, ias):
	var sim = SimulationScript.new()
	root.add_child(sim)
	sim.setup(seed_value, indice % 3, ias)

	var quadros = [instantaneo(sim, 0, -1, "", Vector2i(-1, -1))]
	var resultado = sim.check_victory()
	while resultado == "":
		var agente = sim.turn_system.get_current_agent()
		var time_da_vez = agente.team_id if agente != null else -1
		var origem = Vector2i(agente.x, agente.y) if agente != null else Vector2i(-1, -1)

		# A simulação não limpa nenhum dos dois: sem zerar aqui, todo quadro
		# herdaria o último tiro e a última frase de combate, e o site
		# desenharia um tiro por turno em uma partida que teve poucos.
		sim.recent_shots.clear()
		sim.last_event = ""

		sim.run_turn()
		resultado = sim.check_victory()
		quadros.append(instantaneo(
			sim, sim.turn_system.turn_count, time_da_vez, sim.last_event, origem))

	for p in range(ias.size()):
		var venceu = resultado == SimulationScript.PLAYER_NAMES[p]
		ias[p].learn(Metrics.match_points(venceu, resultado == "draw"))

	var partida = {
		"seed": seed_value,
		"jogador_inicial": SimulationScript.PLAYER_NAMES[indice % 3],
		"vencedor": resultado,
		"turnos": sim.turn_system.turn_count,
		"mapa": desenhar_mapa(sim.grid),
		"quadros": quadros,
	}

	root.remove_child(sim)
	sim.free()
	return partida

# Estado dos três agentes no fim de um turno. O site interpola nada: cada
# quadro é uma posição que a simulação realmente ocupou.
func instantaneo(sim, turno, time_da_vez, evento, origem):
	var agentes = []
	for agente in sim.agents:
		agentes.append({
			"x": agente.x,
			"y": agente.y,
			"hp": agente.hp,
			"vivo": agente.is_alive,
		})

	# Os tiros deste turno, como a view do simulador os desenha: origem,
	# alvo e de quem partiu. Só entram os que causaram dano -- tiro sem
	# linha de visada ou fora da linha reta nem chega a virar evento.
	var tiros = []
	for tiro in sim.recent_shots:
		tiros.append({
			"de": [tiro["from"].x, tiro["from"].y],
			"para": [tiro["to"].x, tiro["to"].y],
			"time": tiro["team_id"],
		})

	return {
		"turno": turno,
		"vez": time_da_vez,
		"evento": evento,
		"saiu_de": [origem.x, origem.y],
		"tiros": tiros,
		"agentes": agentes,
	}

# O grid inteiro como uma linha de texto por coluna y, para caber no JSON
# sem 1600 objetos por partida.
func desenhar_mapa(grid):
	var linhas = []
	for y in range(grid.height):
		var linha = ""
		for x in range(grid.width):
			linha += CELULA.get(grid.get_cell_type(x, y), ".")
		linhas.append(linha)
	return {"largura": grid.width, "altura": grid.height, "celulas": linhas}

# ---------- entrada ----------

func ler_argumentos():
	var opcoes = {"partidas": 6, "saida": "site/dados/replays.json"}
	for arg in OS.get_cmdline_user_args():
		var par = arg.split("=", true, 1)
		if par.size() != 2:
			continue
		if par[0] == "partidas":
			opcoes["partidas"] = max(1, int(par[1]))
		elif par[0] == "saida":
			opcoes["saida"] = par[1]
	return opcoes

func ler_seeds(caminho):
	if not FileAccess.file_exists(caminho):
		return []
	var seeds = []
	var arquivo = FileAccess.open(caminho, FileAccess.READ)
	while not arquivo.eof_reached():
		var linha = arquivo.get_line().strip_edges()
		if linha != "" and not linha.begins_with("#"):
			seeds.append(int(linha))
	arquivo.close()
	return seeds
