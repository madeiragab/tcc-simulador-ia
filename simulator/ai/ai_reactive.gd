extends "res://ai/ai_base.gd"

# IA Reativa (docs/baseline.md):
# - se houver inimigo visível e no alcance -> atacar o mais próximo
# - caso contrário -> mover em direção ao inimigo mais próximo
#
# Sem avaliação estratégica; é também o adversário padrão nas avaliações.

func decide(agent, sim):
	var attackable = get_attackable_enemies(agent, sim)
	if not attackable.is_empty():
		return {"move_to": null, "attack_target": closest_of(agent, attackable)}

	var target = closest_enemy(agent, sim)
	if target == null:
		return {"move_to": null, "attack_target": null}
	return {"move_to": step_towards(agent, sim, target), "attack_target": null}
