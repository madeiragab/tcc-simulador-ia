extends Node

# Execução em lote (headless) sobre um banco de seeds congelado.
#
# Cada lote gera uma pasta autodocumentada em data/runs/<carimbo>/:
#   manifest.txt  — configuração completa da execução (banco, N, modelos,
#                   constantes de jogo, duração) para auditoria
#   partidas.csv  — uma linha por jogador por partida, com métricas
#                   brutas E derivadas, custo aberto por tipo de operação
#   resumo.csv    — agregados por jogador (média ± dp) e StrategicScore
#   turnos.csv    — (opcional, flag "turnos") log turno a turno
#
# Rotação de iniciativa (docs/turnos.md): a partida i começa pelo
# jogador i % 3 — cada um inicia exatamente 1/3 das simulações.

const Metrics = preload("res://core/metrics.gd")
const SimulationScript = preload("res://core/simulation.gd")

const MATCH_HEADER = "id_simulacao,seed,jogador_inicial,jogador,modelo_ia,vencedor,venceu,turnos,dano_causado,dano_recebido,damage_ratio,cover_usage,custo_total,custo_los,custo_nodos,custo_acoes"
const TURN_HEADER = "id_simulacao,seed,turno,jogador,acao,x,y,protegido,inimigos_visiveis"
const SUMMARY_HEADER = "jogador,modelo_ia,partidas,win_rate,damage_ratio_media,damage_ratio_dp,cover_usage_media,cover_usage_dp,turns_to_victory_media,efficiency,custo_medio,custo_dp,strategic_score"

# bank: "benchmark" ou "tuning"; count: quantas seeds do banco rodar.
func run(bank, count, log_turns = false):
	var seeds = load_seeds(bank)
	if seeds.is_empty():
		push_error("Banco de seeds não encontrado: " + bank)
		return
	count = min(count, seeds.size())

	var run_dir = make_run_dir(bank, count)
	var match_csv = FileAccess.open(run_dir.path_join("partidas.csv"), FileAccess.WRITE)
	match_csv.store_line(MATCH_HEADER)
	var turn_csv = null
	if log_turns:
		turn_csv = FileAccess.open(run_dir.path_join("turnos.csv"), FileAccess.WRITE)
		turn_csv.store_line(TURN_HEADER)

	var metric_rows = [[], [], []]

	print("Lote: %d partidas do banco '%s' -> %s" % [count, bank, run_dir])
	var t0 = Time.get_ticks_msec()

	for i in range(count):
		var sim = SimulationScript.new()
		add_child(sim)
		sim.collect_turn_log = log_turns
		sim.setup(seeds[i], i % 3)

		var result = sim.check_victory()
		while result == "":
			sim.run_turn()
			result = sim.check_victory()

		collect_match(match_csv, metric_rows, sim, i + 1, result)
		if turn_csv != null:
			for row in sim.turn_log:
				turn_csv.store_line("%d,%d,%d,%s,%s,%d,%d,%d,%d" % [
					i + 1, sim.map_seed, row["turno"], row["jogador"], row["acao"],
					row["x"], row["y"], 1 if row["protegido"] else 0, row["inimigos_visiveis"],
				])

		remove_child(sim)
		sim.free()

		if (i + 1) % 100 == 0:
			print("  ... %d/%d" % [i + 1, count])

	match_csv.close()
	if turn_csv != null:
		turn_csv.close()

	var duration = (Time.get_ticks_msec() - t0) / 1000.0
	write_summary(run_dir, metric_rows)
	write_manifest(run_dir, bank, count, seeds, log_turns, duration)
	print("Lote concluído em %.1fs — documentação completa em %s" % [duration, run_dir])

	print_aggregates(metric_rows)

func collect_match(csv, metric_rows, sim, match_id, result):
	var turns = sim.turn_system.turn_count
	var starter = sim.PLAYER_NAMES[sim.start_player]
	for p in range(sim.agents.size()):
		var stats = sim.get_player_stats(p)
		var venceu = result == sim.PLAYER_NAMES[p]
		var empate = result == "draw"
		var dr = Metrics.damage_ratio(stats["dano_causado"], stats["dano_recebido"])
		var cu = Metrics.cover_usage(stats["turnos_em_cobertura"], stats["turnos_agidos"])
		var meter = sim.cost_meters[p]

		csv.store_line("%d,%d,%s,%s,%s,%s,%d,%d,%d,%d,%.4f,%.4f,%d,%d,%d,%d" % [
			match_id, sim.map_seed, starter, stats["jogador"], stats["modelo_ia"],
			"empate" if empate else result, 1 if venceu else 0, turns,
			stats["dano_causado"], stats["dano_recebido"], dr, cu,
			meter.total(), meter.los_checks, meter.cells_explored, meter.actions_evaluated,
		])

		metric_rows[p].append({
			"venceu": venceu,
			"empate": empate,
			"turnos": turns,
			"damage_ratio": dr,
			"cover_usage": cu,
			"custo": meter.total(),
		})

func write_summary(run_dir, metric_rows):
	var csv = FileAccess.open(run_dir.path_join("resumo.csv"), FileAccess.WRITE)
	csv.store_line(SUMMARY_HEADER)
	for p in range(metric_rows.size()):
		var agg = Metrics.aggregate(metric_rows[p])
		csv.store_line("%s,%s,%d,%.4f,%.4f,%.4f,%.4f,%.4f,%.2f,%.6f,%.2f,%.2f,%.6f" % [
			SimulationScript.PLAYER_NAMES[p], SimulationScript.model_name(p), agg["n"],
			agg["win_rate"], agg["damage_ratio_mean"], agg["damage_ratio_std"],
			agg["cover_usage_mean"], agg["cover_usage_std"],
			agg["turns_to_victory_mean"], agg["efficiency"],
			agg["custo_mean"], agg["custo_std"], agg["strategic_score"],
		])
	csv.close()

func write_manifest(run_dir, bank, count, seeds, log_turns, duration):
	var agent_script = preload("res://agents/agent.gd")
	var grid_script = preload("res://map/grid.gd")
	var turn_script = preload("res://core/turn_system.gd")

	var file = FileAccess.open(run_dir.path_join("manifest.txt"), FileAccess.WRITE)
	file.store_line("Execução de lote — Simulador Tático para Avaliação de IA")
	file.store_line("data_hora: " + Time.get_datetime_string_from_system())
	file.store_line("godot: " + Engine.get_version_info()["string"])
	file.store_line("banco_seeds: " + bank)
	file.store_line("partidas: %d" % count)
	file.store_line("primeira_seed: %d" % seeds[0])
	file.store_line("ultima_seed: %d" % seeds[count - 1])
	file.store_line("rotacao_iniciativa: partida i inicia pelo jogador i mod 3")
	file.store_line("log_por_turno: " + ("sim" if log_turns else "nao"))
	file.store_line("duracao_segundos: %.1f" % duration)
	file.store_line("")
	file.store_line("[modelos]")
	for p in range(SimulationScript.PLAYER_NAMES.size()):
		file.store_line("%s: %s" % [SimulationScript.PLAYER_NAMES[p], SimulationScript.model_name(p)])
	file.store_line("")
	file.store_line("[constantes_de_jogo]")
	file.store_line("dano_base: %d" % agent_script.BASE_DAMAGE)
	file.store_line("reducao_cobertura_leve: %d" % grid_script.COVER_LIGHT_REDUCTION)
	file.store_line("reducao_cobertura_pesada: %d" % grid_script.COVER_HEAVY_REDUCTION)
	file.store_line("limite_turnos: %d" % turn_script.TURN_LIMIT)
	file.store_line("movimento_max_celulas: 3")
	file.store_line("hp_inicial: 100")
	file.store_line("alcance_visao_e_ataque: 8")
	file.store_line("")
	file.store_line("[parametros_ia]")
	var heuristic = preload("res://ai/ai_heuristic.gd")
	file.store_line("heuristica_pesos: vida=%.2f cobertura=%.2f proximidade=%.2f risco=%.2f" % [
		heuristic.W_VIDA, heuristic.W_COBERTURA, heuristic.W_PROXIMIDADE, heuristic.W_RISCO,
	])
	file.store_line("")
	file.store_line("[metricas]")
	file.store_line("formulas: docs/metricas.md (implementação literal em core/metrics.gd, epsilon=%d)" % Metrics.EPSILON)
	file.close()

func print_aggregates(metric_rows):
	print("\n===== MÉTRICAS AGREGADAS (média ± desvio padrão) =====")
	for p in range(metric_rows.size()):
		var agg = Metrics.aggregate(metric_rows[p])
		print("\n[%s — %s] (%d partidas)" % [SimulationScript.PLAYER_NAMES[p], SimulationScript.model_name(p), agg["n"]])
		print("  WinRate:          %.3f" % agg["win_rate"])
		print("  DamageRatio:      %.3f ± %.3f" % [agg["damage_ratio_mean"], agg["damage_ratio_std"]])
		print("  CoverUsage:       %.3f ± %.3f" % [agg["cover_usage_mean"], agg["cover_usage_std"]])
		print("  TurnsToVictory:   %.1f  (Efficiency: %.4f)" % [agg["turns_to_victory_mean"], agg["efficiency"]])
		print("  CustoComputMedio: %.1f ± %.1f" % [agg["custo_mean"], agg["custo_std"]])
		print("  StrategicScore:   %.4f" % agg["strategic_score"])

func load_seeds(bank):
	var path = repo_root().path_join("experiments/configs/seeds_%s.txt" % bank)
	if not FileAccess.file_exists(path):
		return []
	var file = FileAccess.open(path, FileAccess.READ)
	var seeds = []
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line.is_valid_int():
			seeds.append(int(line))
	return seeds

func repo_root():
	return ProjectSettings.globalize_path("res://").path_join("..")

func make_run_dir(bank, count):
	var stamp = Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	var dir = repo_root().path_join("data/runs").path_join("%s_%s_%d" % [stamp, bank, count])
	DirAccess.make_dir_recursive_absolute(dir)
	return dir
