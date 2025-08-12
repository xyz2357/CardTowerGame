extends RefCounted

# 选择生成器 - 生成楼层选择的逻辑
class_name ChoiceGenerator

enum ChoiceType {
	ENEMY,
	ELITE,
	REST,
	SHOP,
	TREASURE,
	BOSS
}

func generate_choices_for_floor(floor: int) -> Array[Dictionary]:
	var choices: Array[Dictionary] = []
	
	print("Generating choices for floor: ", floor)
	
	# Boss层只有Boss战
	if floor % 5 == 0:
		choices.append(create_boss_choice())
		print("Boss floor, created 1 boss choice")
		return choices
	
	# 普通层生成2-4个选择
	var available_choices = get_available_choices_for_floor(floor)
	print("Available choices for floor ", floor, ": ", available_choices.size())
	
	available_choices.shuffle()
	
	var choice_count = randi_range(2, 4)
	print("Will create ", choice_count, " choices")
	
	for i in range(min(choice_count, available_choices.size())):
		choices.append(available_choices[i])
		print("Added choice ", i, ": ", available_choices[i].name)
	
	print("Final choices array size: ", choices.size())
	return choices

func get_available_choices_for_floor(floor: int) -> Array[Dictionary]:
	var choices: Array[Dictionary] = []
	
	# 普通战斗 - 所有楼层都有 (选择2个不同的敌人)
	var enemy_choices = get_enemy_choices()
	enemy_choices.shuffle()
	for i in range(min(2, enemy_choices.size())):
		choices.append(enemy_choices[i])
	
	# 精英战 - 3层以上
	if floor >= 3:
		var elite_choices = get_elite_choices()
		if elite_choices.size() > 0:
			choices.append(elite_choices[0])
	
	# 休息点 - 所有楼层都有
	choices.append(create_rest_choice())
	
	# 商店 - 2层以上
	if floor >= 2:
		choices.append(create_shop_choice())
	
	# 宝箱 - 所有楼层都有
	choices.append(create_treasure_choice())
	
	print("Generated ", choices.size(), " available choices for floor ", floor)
	return choices

func get_enemy_choices() -> Array[Dictionary]:
	var enemies: Array[Dictionary] = [
		{"type": ChoiceType.ENEMY, "name": "哥布林", "description": "弱小的绿皮生物", "enemy_id": "goblin"},
		{"type": ChoiceType.ENEMY, "name": "骷髅兵", "description": "不死的战士", "enemy_id": "skeleton"},
		{"type": ChoiceType.ENEMY, "name": "野狼", "description": "饥饿的捕食者", "enemy_id": "wolf"},
		{"type": ChoiceType.ENEMY, "name": "强盗", "description": "危险的人类敌人", "enemy_id": "bandit"}
	]
	return enemies

func get_elite_choices() -> Array[Dictionary]:
	var elites: Array[Dictionary] = [
		{"type": ChoiceType.ELITE, "name": "兽人酋长", "description": "强大的精英敌人", "enemy_id": "orc_chief"},
		{"type": ChoiceType.ELITE, "name": "暗影刺客", "description": "致命的精英战士", "enemy_id": "shadow_assassin"}
	]
	return elites

func create_rest_choice() -> Dictionary:
	return {
		"type": ChoiceType.REST,
		"name": "篝火",
		"description": "恢复生命或升级卡牌"
	}

func create_shop_choice() -> Dictionary:
	return {
		"type": ChoiceType.SHOP,
		"name": "商店",
		"description": "购买卡牌和遗物"
	}

func create_treasure_choice() -> Dictionary:
	return {
		"type": ChoiceType.TREASURE,
		"name": "宝箱",
		"description": "获得稀有奖励"
	}

func create_boss_choice() -> Dictionary:
	return {
		"type": ChoiceType.BOSS,
		"name": "Boss战",
		"description": "挑战强大的Boss",
		"enemy_id": "boss_" + str((GameData.current_floor / 5))
	}
