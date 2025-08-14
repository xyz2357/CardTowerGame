extends RefCounted

# 爬塔数据类 - 纯数据
class_name TowerData

var current_floor: int = 1
var max_floor: int = 20
var player_hp: int = 80
var player_max_hp: int = 80

enum FloorType {
	First,
	Normal,
	Boss,
	Final,
	Unexpected
}

func reset():
	current_floor = 1
	player_hp = 80
	player_max_hp = 80

func is_boss_floor() -> bool:
	return current_floor % 5 == 0 and current_floor <= max_floor

func is_final_floor() -> bool:
	return current_floor == max_floor

func get_floor_type() -> FloorType:
	if is_final_floor():
		return FloorType.Final
	elif is_boss_floor():
		return FloorType.Boss
	elif current_floor == 1:
		return FloorType.First
	elif current_floor <= max_floor and current_floor > 0:
		return FloorType.Normal
	return FloorType.Unexpected
