extends SceneTree

# Recalcula o resumo.csv de todas as execuções em data/runs/ a partir
# do partidas.csv preservado, aplicando a fórmula vigente de
# core/metrics.gd.
#
# A coleta não muda — apenas a agregação. Isso permite corrigir a
# métrica composta sem repetir simulações, mantendo a rastreabilidade:
# os dados brutos de cada partida continuam intactos.
#
# Uso: godot --headless --path simulator --script res://tools/recalcular_resumos.gd

const Metrics = preload("res://core/metrics.gd")
const SUMMARY_HEADER = "jogador,modelo_ia,partidas,pontos_total,pontos_media,win_rate,damage_ratio_media,damage_ratio_dp,cover_usage_media,cover_usage_dp,turns_to_victory_media,efficiency,custo_medio,custo_dp,strategic_score"

func _initialize():
	var runs_dir = ProjectSettings.globalize_path("res://").path_join("../data/runs")
	var dir = DirAccess.open(runs_dir)
	if dir == null:
		push_error("não abri: " + runs_dir)
		quit()
		return

	var total = 0
	for name in dir.get_directories():
		var path = runs_dir.path_join(name)
		if FileAccess.file_exists(path.path_join("partidas.csv")):
			if recalcular(path):
				total += 1
	print("Resumos recalculados: ", total)
	quit()

func recalcular(run_dir):
	var file = FileAccess.open(run_dir.path_join("partidas.csv"), FileAccess.READ)
	if file == null:
		return false

	var header = file.get_line().split(",")
	var idx = {}
	for i in range(header.size()):
		idx[header[i]] = i

	# Agrupa as linhas por jogador, preservando a ordem de aparição.
	var por_jogador = {}
	var ordem = []
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line == "":
			continue
		var f = line.split(",")
		if f.size() < header.size():
			continue
		var jogador = f[idx["jogador"]]
		if not por_jogador.has(jogador):
			por_jogador[jogador] = {"modelo": f[idx["modelo_ia"]], "rows": []}
			ordem.append(jogador)
		por_jogador[jogador]["rows"].append({
			"venceu": f[idx["venceu"]] == "1",
			"empate": f[idx["vencedor"]] == "empate",
			"turnos": int(f[idx["turnos"]]),
			"damage_ratio": float(f[idx["damage_ratio"]]),
			"cover_usage": float(f[idx["cover_usage"]]),
			"custo": int(f[idx["custo_total"]]),
		})
	file.close()

	var out = FileAccess.open(run_dir.path_join("resumo.csv"), FileAccess.WRITE)
	out.store_line(SUMMARY_HEADER)
	for jogador in ordem:
		var dados = por_jogador[jogador]
		var agg = Metrics.aggregate(dados["rows"])
		out.store_line("%s,%s,%d,%d,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.2f,%.6f,%.2f,%.2f,%.6f" % [
			jogador, dados["modelo"], agg["n"],
			agg["points_total"], agg["points_mean"],
			agg["win_rate"], agg["damage_ratio_mean"], agg["damage_ratio_std"],
			agg["cover_usage_mean"], agg["cover_usage_std"],
			agg["turns_to_victory_mean"], agg["efficiency"],
			agg["custo_mean"], agg["custo_std"], agg["strategic_score"],
		])
	out.close()
	print("  ok: ", run_dir.get_file())
	return true
