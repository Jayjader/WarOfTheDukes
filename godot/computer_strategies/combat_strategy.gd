class_name CombatStrategy
extends Node

func get_attackers_choice(allies, enemies, attacking, attacked, defended):
	if len(allies) == len(attacked):
		return null
	var possible_combats = []
	for enemy in enemies:
		if enemy in defended: continue
		if enemy.kind == Enums.Unit.Duke and len(Board.get_units_on(enemy.tile)) > 1: continue
		var can_attack = []
		for ally in allies:
			if ally.kind == Enums.Unit.Duke: continue
			if ally in attacked: continue
			if not Rules.is_in_range(ally, enemy): continue
			if ally.kind != Enums.Unit.Artillery and MapData.map.borders.get(0.5 * (ally.tile + enemy.tile)) == "River": continue
			can_attack.append(ally)
		if len(can_attack) > 0:
			possible_combats.append({attackers = can_attack, defender = enemy})
	if len(possible_combats) == 0:
		return null
	possible_combats.sort_custom(
		func(a, b):
			return (
				a.attackers.reduce(func(accum, next): return accum + allies[next], 0) / enemies[a.defender]
				< b.attackers.reduce(func(accum, next): return accum + allies[next], 0) / enemies[b.defender]
			)
	)
	var choice = possible_combats[0]
	print_debug("combat participants chosen")
	print_debug("defender at %s" % choice.defender.tile)
	for attacker in choice.attackers:
		print_debug("attacker at %s" % attacker.tile)
	return choice


