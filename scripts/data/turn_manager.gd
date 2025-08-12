extends RefCounted

# 回合管理类 - 纯逻辑
class_name TurnManager

signal turn_started(is_player: bool)
signal turn_ended(is_player: bool)

var current_turn: int = 0
var is_player_turn_active: bool = false

func start_player_turn():
	current_turn += 1
	is_player_turn_active = true
	turn_started.emit(true)

func end_player_turn():
	is_player_turn_active = false
	turn_ended.emit(true)

func start_enemy_turn():
	is_player_turn_active = false
	turn_started.emit(false)

func end_enemy_turn():
	turn_ended.emit(false)

func is_player_turn() -> bool:
	return is_player_turn_active

func get_turn_number() -> int:
	return current_turn
