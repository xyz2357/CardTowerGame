extends RefCounted

# 爬塔数据类 - 纯数据
class_name TowerData

var current_floor: int = 1
var max_floor: int = 20
var player_hp: int = 80
var player_max_hp: int = 80

func reset():
	current_floor = 1
	player_hp = 80
	player_max_hp = 80

func is_boss_floor() -> bool:
	return current_floor % 5 == 0

func is_final_floor() -> bool:
	return current_floor >= max_floor

func get_floor_type() -> String:
	if is_boss_floor():
		return "boss"
	elif current_floor == 1:
		return "first"
	elif is_final_floor():
		return "final"
	else:
		return "normal"
