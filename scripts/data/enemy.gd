extends RefCounted

# 敌人数据类 - 纯数据和逻辑
class_name Enemy

signal health_changed
signal died

var max_health: int
var current_health: int
var enemy_name: String
var ai_pattern: Array[Dictionary] = []
var current_intent_index: int = 0

func initialize(health: int, max_hp: int, name: String = "敌人"):
	max_health = max_hp
	current_health = health
	enemy_name = name
	setup_ai_pattern()

func setup_ai_pattern():
	# 简单的AI模式：攻击 -> 攻击 -> 防御 -> 重复
	ai_pattern = [
		{"type": "attack", "damage": randi_range(8, 12), "name": "利爪攻击"},
		{"type": "attack", "damage": randi_range(6, 10), "name": "撕咬"},
		{"type": "defend", "block": randi_range(8, 15), "name": "防御姿态"}
	]

func take_damage(amount: int):
	current_health = max(0, current_health - amount)
	health_changed.emit()
	
	if current_health <= 0:
		died.emit()

func get_attack_damage() -> int:
	var intent = get_current_intent()
	advance_intent()
	
	if intent.type == "attack":
		return intent.damage
	return 0

func get_current_intent() -> Dictionary:
	if ai_pattern.is_empty():
		return {"type": "attack", "damage": 5, "name": "基础攻击"}
	
	return ai_pattern[current_intent_index]

func advance_intent():
	current_intent_index = (current_intent_index + 1) % ai_pattern.size()

func get_next_intent_preview() -> Dictionary:
	if ai_pattern.is_empty():
		return {"type": "attack", "damage": 5, "name": "基础攻击"}
	
	var next_index = (current_intent_index + 1) % ai_pattern.size()
	return ai_pattern[next_index]

func get_status() -> Dictionary:
	return {
		"health": current_health,
		"max_health": max_health,
		"name": enemy_name,
		"current_intent": get_current_intent(),
		"next_intent": get_next_intent_preview()
	}
