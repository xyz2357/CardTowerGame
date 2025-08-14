extends RefCounted

# 玩家数据类 - 纯数据和逻辑
class_name Player

signal health_changed
signal energy_changed
signal block_changed
signal died

var max_health: int
var current_health: int
var max_energy: int
var current_energy: int
var current_block: int = 0

func initialize(health: int, max_hp: int, energy: int, max_en: int):
	max_health = max_hp
	current_health = health
	max_energy = max_en
	current_energy = energy
	current_block = 0

func take_damage(amount: int):
	var initial_health = current_health
	# 护甲先抵挡伤害
	if current_block > 0:
		var blocked = min(current_block, amount)
		current_block -= blocked
		amount -= blocked
		block_changed.emit()
	
	# 剩余伤害扣血
	if amount > 0:
		current_health = max(0, current_health - amount)
		health_changed.emit()  # 只在生命值实际改变时发射
		
		if current_health <= 0:
			died.emit()
	
func heal(amount: int):
	current_health = min(max_health, current_health + amount)
	health_changed.emit()

func add_block(amount: int):
	current_block += amount
	block_changed.emit()

func spend_energy(amount: int) -> bool:	
	if current_energy >= amount:
		current_energy -= amount
		energy_changed.emit()
		return true
	else:
		return false

func can_afford_card(cost: int) -> bool:
	var can_afford = current_energy >= cost
	return can_afford

func add_energy(amount: int):
	var old_energy = current_energy
	current_energy = min(current_energy + amount, 10)  # 设置能量上限
	energy_changed.emit()

func start_new_turn():
	current_energy = max_energy
	# 护甲每回合清零（可以根据游戏设计调整）
	current_block = 0
	energy_changed.emit()
	block_changed.emit()

func get_status() -> Dictionary:
	return {
		"health": current_health,
		"max_health": max_health,
		"energy": current_energy,
		"max_energy": max_energy,
		"block": current_block
	}
