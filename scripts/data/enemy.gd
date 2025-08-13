extends RefCounted

# 敌人数据类 - 纯数据和逻辑
class_name Enemy

signal health_changed
signal died
signal intent_changed

var max_health: int
var current_health: int
var enemy_name: String
var ai_pattern: Array[Dictionary] = []
var current_intent_index: int = 0
var current_block: int = 0

func initialize(health: int, max_hp: int, name: String = "敌人"):
	max_health = max_hp
	current_health = health
	enemy_name = name
	current_block = 0
	setup_ai_pattern()
	print("Enemy initialized: ", enemy_name, " HP: ", current_health, "/", max_health)

func setup_ai_pattern():
	# 根据敌人类型设置不同的AI模式
	match enemy_name:
		"哥布林":
			ai_pattern = [
				{"type": "attack", "damage": randi_range(4, 6), "name": "利爪攻击"},
				{"type": "attack", "damage": randi_range(3, 5), "name": "撕咬"},
				{"type": "defend", "block": randi_range(3, 5), "name": "防御姿态"}
			]
		"骷髅兵":
			ai_pattern = [
				{"type": "attack", "damage": randi_range(6, 8), "name": "骨剑斩击"},
				{"type": "attack", "damage": randi_range(4, 6), "name": "骨矛刺击"},
				{"type": "defend", "block": randi_range(5, 8), "name": "骨盾防御"}
			]
		"野狼":
			ai_pattern = [
				{"type": "attack", "damage": randi_range(7, 9), "name": "撕咬"},
				{"type": "attack", "damage": randi_range(5, 7), "name": "爪击"},
				{"type": "special", "damage": 3, "times": 2, "name": "连续攻击"}
			]
		"强盗":
			ai_pattern = [
				{"type": "attack", "damage": randi_range(8, 10), "name": "刀刃攻击"},
				{"type": "defend", "block": randi_range(6, 10), "name": "格挡"},
				{"type": "attack", "damage": randi_range(6, 8), "name": "偷袭"}
			]
		_:
			# 默认敌人模式
			ai_pattern = [
				{"type": "attack", "damage": randi_range(5, 8), "name": "基础攻击"},
				{"type": "defend", "block": randi_range(4, 7), "name": "基础防御"}
			]
	
	print("Enemy AI pattern set up with ", ai_pattern.size(), " actions")

func take_damage(amount: int):
	# 护甲先抵挡伤害
	if current_block > 0:
		var blocked = min(current_block, amount)
		current_block -= blocked
		amount -= blocked
		print("Enemy blocked ", blocked, " damage, remaining block: ", current_block)
	
	# 剩余伤害扣血
	if amount > 0:
		current_health = max(0, current_health - amount)
		print("Enemy took ", amount, " damage, HP: ", current_health, "/", max_health)
	
	health_changed.emit()
	
	if current_health <= 0:
		print("Enemy died!")
		died.emit()

func add_block(amount: int):
	current_block += amount
	print("Enemy gained ", amount, " block, total: ", current_block)

func execute_turn() -> Dictionary:
	var intent = get_current_intent()
	var result = {"type": intent.type, "name": intent.name, "damage": 0, "block": 0}
	
	match intent.type:
		"attack":
			result.damage = intent.damage
		"defend":
			add_block(intent.block)
			result.block = intent.block
		"special":
			if intent.has("times"):
				# 连续攻击
				result.damage = intent.damage * intent.times
				result.name += " (" + str(intent.times) + "次)"
			else:
				result.damage = intent.damage
	
	advance_intent()
	print("Enemy executed: ", result.name, " Damage: ", result.damage, " Block: ", result.block)
	return result

func get_attack_damage() -> int:
	var intent = get_current_intent()
	advance_intent()
	
	match intent.type:
		"attack":
			return intent.damage
		"special":
			if intent.has("times"):
				return intent.damage * intent.times
			else:
				return intent.damage
		_:
			return 0

func get_current_intent() -> Dictionary:
	if ai_pattern.is_empty():
		return {"type": "attack", "damage": 5, "name": "基础攻击"}
	
	return ai_pattern[current_intent_index]

func advance_intent():
	current_intent_index = (current_intent_index + 1) % ai_pattern.size()
	intent_changed.emit()

func get_next_intent_preview() -> Dictionary:
	if ai_pattern.is_empty():
		return {"type": "attack", "damage": 5, "name": "基础攻击"}
	
	var next_index = (current_intent_index + 1) % ai_pattern.size()
	return ai_pattern[next_index]

func start_new_turn():
	# 每回合开始时清除护甲
	current_block = 0
	print("Enemy started new turn, block reset to 0")

func get_status() -> Dictionary:
	return {
		"health": current_health,
		"max_health": max_health,
		"block": current_block,
		"name": enemy_name,
		"current_intent": get_current_intent(),
		"next_intent": get_next_intent_preview()
	}

# 根据敌人ID创建特定敌人的静态方法
static func create_enemy(enemy_id: String) -> Enemy:
	var enemy = Enemy.new()
	
	match enemy_id:
		"goblin":
			enemy.initialize(5, 5, "哥布林")
		"skeleton":
			enemy.initialize(15, 15, "骷髅兵")
		"wolf":
			enemy.initialize(20, 20, "野狼")
		"bandit":
			enemy.initialize(20, 20, "强盗")
		"orc_chief":
			enemy.initialize(30, 30, "兽人酋长")
		"shadow_assassin":
			enemy.initialize(15, 15, "暗影刺客")
		_:
			if enemy_id.begins_with("boss_"):
				var boss_level = enemy_id.split("_")[1].to_int()
				enemy.initialize(80 + boss_level * 20, 80 + boss_level * 20, "Boss " + str(boss_level))
			else:
				enemy.initialize(30, 30, "未知敌人")
	
	return enemy
