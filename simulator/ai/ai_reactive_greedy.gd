extends "res://ai/ai_reactive.gd"

# Ablação pós-banca: IA Reativa + o mesmo deslocamento econômico do
# Art3miz 0.1 (passo guloso ao seguir o sensor ou explorar, com recuo à
# busca completa quando o caminho barato trava). Isola o efeito do passo
# guloso sobre um modelo que não delibera.

func decide(agent, sim):
	var visible = get_visible_enemies(agent, sim)

	var attackable = filter_attackable(agent, sim, visible)
	if not attackable.is_empty():
		return {"move_to": null, "attack_target": closest_of(agent, attackable)}

	if not visible.is_empty():
		return {"move_to": step_towards(agent, sim, closest_of(agent, visible)), "attack_target": null}

	var goal = pursuit_position(agent, sim)
	if goal == null:
		return {"move_to": null, "attack_target": null}

	# Caçar posição já vista mantém a busca completa (igual ao Art3miz).
	if not last_known.is_empty():
		return {"move_to": step_towards(agent, sim, goal), "attack_target": null}

	var path = cheap_path_towards(agent, sim, goal)
	if path.size() < 3:
		return {"move_to": step_towards(agent, sim, goal), "attack_target": null}
	return {"move_path": path, "attack_target": null}
