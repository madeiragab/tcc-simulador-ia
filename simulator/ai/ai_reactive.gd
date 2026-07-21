extends "res://ai/ai_base.gd"

# IA Reativa (docs/baseline.md):
# - se tem linha de tiro reta para um inimigo -> atacar o mais próximo
# - se vê alguém mas sem linha de tiro -> aproximar para alinhar
# - senão -> caçar a última posição conhecida, ou explorar
#
# Sem avaliação estratégica; é também o adversário padrão nas avaliações.

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
	return {"move_to": step_towards(agent, sim, goal), "attack_target": null}
