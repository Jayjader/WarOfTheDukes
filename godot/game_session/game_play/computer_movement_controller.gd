extends Node

signal movement_ended
signal mover_chosen(unit: GamePiece)

var current_player: PlayerRs

func query_for_mover(moved: Array[GamePiece], alive: Array[GamePiece]):
	var allies: Array[GamePiece] = []
	var enemies: Array[GamePiece] = []
	for unit in alive:
		if unit.faction == current_player.faction:
			allies.append(unit)
		else:
			enemies.append(unit)
	var strategy = MovementStrategy.new()
	var choice = strategy.choose_next_mover(moved, allies, enemies, MapData.map)
	if choice is GamePiece:
		mover_chosen.emit(choice)
	else:
		movement_ended.emit()

signal destination_chosen(tile: Vector2i)
func query_for_destination(mover: GamePiece, _alive):
	var strategy = MovementStrategy.new()
	destination_chosen.emit(strategy.choose_destination(mover, MapData.map))
