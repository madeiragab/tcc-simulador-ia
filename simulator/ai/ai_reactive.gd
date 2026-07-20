extends "res://ai/ai_base.gd"

# IA Reativa (docs/baseline.md):
# - se houver inimigo VISÍVEL -> atacar o mais próximo
# - senão -> caçar a última posição onde viu um inimigo, ou explorar
#
# Sem avaliação estratégica; é também o adversário padrão nas avaliações.

func decide(agent, sim):
	var visible = get_visible_enemies(agent, sim)
	if not visible.is_empty():
		return {"move_to": null, "attack_target": closest_of(agent, visible)}

	var goal = pursuit_position(agent, sim)
	if goal == null:
		return {"move_to": null, "attack_target": null}
	return {"move_to": step_towards(agent, sim, goal), "attack_target": null}
