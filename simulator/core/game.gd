extends Node2D

# Game (Controller) — topo da hierarquia (diagrams/arquitetura.png).
# Monta a Simulation, a view e o HUD, e dirige o passo-a-passo visual.

const STEP_INTERVAL = 0.35
const ZOOM_LEVEL = 3.0
const ZOOM_DURATION = 1.1

var simulation = null
var view = null
var timer = null
var hud_label = null
var log_label = null

func _ready():
	print("Simulador iniciado")

	# Argumentos após "--":
	#   <seed>            roda uma partida com essa seed (reprodutível)
	#   fast              roda a partida inteira sem animação e sai
	#   batch <N> [banco] [turnos]
	#                     roda N partidas do banco de seeds ("benchmark"
	#                     por padrão, ou "tuning"), documentando tudo em
	#                     data/runs/; "turnos" liga o log turno a turno
	var map_seed = 0
	var fast_mode = false
	var args = OS.get_cmdline_user_args()

	if args.size() > 0 and args[0] == "batch":
		var count = int(args[1]) if args.size() > 1 and args[1].is_valid_int() else 1000
		var bank = "benchmark"
		var log_turns = false
		var sim_script = preload("res://core/simulation.gd")
		for extra in args.slice(2):
			if extra == "turnos":
				log_turns = true
			elif extra in ["benchmark", "tuning"]:
				bank = extra
			elif extra.begins_with("lambda="):
				# Calibração do modelo híbrido: lambda=0.02
				preload("res://ai/ai_art3miz.gd").lambda_atual = float(extra.split("=")[1])
			elif extra.begins_with("mapa="):
				# Generalização: tamanho do grid (mapa=25, mapa=60)
				preload("res://map/grid.gd").default_size = int(extra.split("=")[1])
			elif extra.begins_with("budget="):
				# Orçamento de avaliação do híbrido (0 = sem poda)
				preload("res://ai/ai_art3miz.gd").budget_atual = int(extra.split("=")[1])
			elif "=" in extra:
				# Escalação: verde=heuristica vermelho=aleatoria azul=reativa
				var parts = extra.split("=")
				var player_id = sim_script.PLAYER_NAMES.find(parts[0])
				if player_id >= 0 and sim_script.AI_BY_NAME.has(parts[1]):
					sim_script.ai_overrides[player_id] = sim_script.AI_BY_NAME[parts[1]]
				else:
					push_error("Escalação inválida: " + extra)
		var runner = preload("res://core/batch_runner.gd").new()
		add_child(runner)
		runner.run(bank, count, log_turns)
		get_tree().quit()
		return

	for arg in args:
		if arg == "fast":
			fast_mode = true
		elif arg.is_valid_int():
			map_seed = int(arg)
	if map_seed == 0:
		randomize()
		map_seed = randi() % 1000000
	print("Seed do mapa: ", map_seed)

	simulation = preload("res://core/simulation.gd").new()
	add_child(simulation)
	simulation.setup(map_seed)

	# Modo rápido (headless/lote): roda a simulação inteira de uma vez.
	if fast_mode:
		var result = simulation.check_victory()
		while result == "":
			simulation.run_turn()
			result = simulation.check_victory()
		print("Resultado: ", result, " em ", simulation.turn_system.turn_count, " turnos")
		print("Custo computacional: ", simulation.cost_summary())
		get_tree().quit()
		return

	view = preload("res://core/simulation_view.gd").new()
	view.simulation = simulation
	add_child(view)
	view.queue_redraw()

	setup_hud(map_seed)

	timer = Timer.new()
	timer.wait_time = STEP_INTERVAL
	timer.timeout.connect(_on_step)
	add_child(timer)
	timer.start()

func setup_hud(map_seed):
	var layer = CanvasLayer.new()
	add_child(layer)

	hud_label = Label.new()
	hud_label.add_theme_font_size_override("font_size", 22)
	hud_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	hud_label.position = Vector2(14, 10)
	hud_label.text = "Seed %d  |  Turno 0/100" % map_seed
	layer.add_child(hud_label)

	# Log de combate em linha única, canto inferior esquerdo.
	log_label = Label.new()
	log_label.add_theme_font_size_override("font_size", 20)
	log_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
	log_label.position = Vector2(14, get_viewport_rect().size.y - 38)
	log_label.text = ""
	layer.add_child(log_label)

func _on_step():
	var result = simulation.check_victory()
	if result != "":
		timer.stop()
		if result == "draw":
			print("Resultado: empate em ", simulation.turn_system.turn_count, " turnos")
		else:
			print("Resultado: vitória do ", result, " em ", simulation.turn_system.turn_count, " turnos")
		print("Custo computacional: ", simulation.cost_summary())
		finish(result)
		return

	simulation.run_turn()
	hud_label.text = "Seed %d  |  Turno %d/100" % [simulation.map_seed, simulation.turn_system.turn_count]
	log_label.text = simulation.last_event
	view.queue_redraw()

# ---------- Fim de partida ----------

func finish(result):
	view.queue_redraw()

	var winner_id = simulation.PLAYER_NAMES.find(result)  # -1 para "draw"
	if winner_id >= 0:
		zoom_to_winner(winner_id)

	var screen = preload("res://core/victory_screen.gd").new()
	screen.winner_id = winner_id
	var layer = CanvasLayer.new()
	add_child(layer)
	layer.add_child(screen)

# Dá zoom da view até a célula onde o vencedor está — ele não sai do lugar,
# a câmera é que vai até ele.
func zoom_to_winner(winner_id):
	var winner = simulation.agents[winner_id]
	var cell = view.CELL_SIZE
	var target = Vector2(winner.x * cell + cell / 2.0, winner.y * cell + cell / 2.0)
	var screen_center = get_viewport_rect().size / 2.0

	var tween = create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(view, "scale", Vector2(ZOOM_LEVEL, ZOOM_LEVEL), ZOOM_DURATION)
	tween.tween_property(view, "position", screen_center - target * ZOOM_LEVEL, ZOOM_DURATION)
