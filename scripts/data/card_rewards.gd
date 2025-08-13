extends RefCounted

# 卡牌奖励系统
class_name CardRewards

enum Rarity {
	COMMON,
	UNCOMMON,
	RARE
}

# 获取战斗胜利后的卡牌奖励
static func get_battle_rewards(enemy_type: String, floor: int) -> Array[Dictionary]:
	var rewards: Array[Dictionary] = []
	
	print("Getting battle rewards for enemy_type: ", enemy_type, " floor: ", floor)
	
	# 根据敌人类型和楼层决定奖励数量
	var reward_count = 3
	match enemy_type:
		"elite":
			reward_count = 4
		"boss":
			reward_count = 5
		_:  # "normal" 或其他情况
			reward_count = 3
	
	print("Reward count: ", reward_count)
	
	# 生成奖励卡牌
	for i in range(reward_count):
		var rarity = determine_rarity(enemy_type, floor)
		var card = generate_random_card(rarity)
		rewards.append(card)
	
	return rewards

# 决定卡牌稀有度
static func determine_rarity(enemy_type: String, floor: int) -> Rarity:
	var rare_chance = 0.1 + floor * 0.02  # 楼层越高，稀有卡概率越高
	var uncommon_chance = 0.3
	
	match enemy_type:
		"elite":
			rare_chance += 0.15
			uncommon_chance += 0.2
		"boss":
			rare_chance += 0.25
			uncommon_chance += 0.3
		_:  # "normal" 或其他情况
			pass  # 使用基础概率
	
	var roll = randf()
	
	if roll < rare_chance:
		return Rarity.RARE
	elif roll < rare_chance + uncommon_chance:
		return Rarity.UNCOMMON
	else:
		return Rarity.COMMON

# 生成随机卡牌
static func generate_random_card(rarity: Rarity) -> Dictionary:
	var cards_by_rarity = get_cards_by_rarity()
	var available_cards = cards_by_rarity[rarity]
	
	if available_cards.is_empty():
		# 备用，如果没有对应稀有度的卡牌
		available_cards = cards_by_rarity[Rarity.COMMON]
	
	var random_index = randi() % available_cards.size()
	return available_cards[random_index].duplicate()

# 获取按稀有度分类的卡牌
static func get_cards_by_rarity() -> Dictionary:
	return {
		Rarity.COMMON: [
			{"name": "攻击", "cost": 1, "damage": 6, "type": "attack", "rarity": "common"},
			{"name": "防御", "cost": 1, "block": 5, "type": "skill", "rarity": "common"},
			{"name": "愤怒", "cost": 0, "damage": 3, "type": "attack", "rarity": "common"},
			{"name": "铁壁", "cost": 1, "block": 8, "type": "skill", "rarity": "common"},
			{"name": "快速攻击", "cost": 1, "damage": 4, "draw": 1, "type": "attack", "rarity": "common"},
			{"name": "治疗药水", "cost": 1, "heal": 5, "type": "skill", "rarity": "common"}
		],
		Rarity.UNCOMMON: [
			{"name": "重击", "cost": 2, "damage": 12, "type": "attack", "rarity": "uncommon"},
			{"name": "治疗", "cost": 2, "heal": 8, "type": "skill", "rarity": "uncommon"},
			{"name": "能量药水", "cost": 1, "energy": 2, "type": "skill", "rarity": "uncommon"},
			{"name": "致命打击", "cost": 2, "damage": 8, "vulnerable": 2, "type": "attack", "rarity": "uncommon"},
			{"name": "钢铁意志", "cost": 1, "block": 6, "artifact": 1, "type": "skill", "rarity": "uncommon"},
			{"name": "连击", "cost": 1, "damage": 5, "times": 2, "type": "attack", "rarity": "uncommon"}
		],
		Rarity.RARE: [
			{"name": "毁灭打击", "cost": 3, "damage": 20, "type": "attack", "rarity": "rare"},
			{"name": "完美防御", "cost": 2, "block": 15, "unbreakable": true, "type": "skill", "rarity": "rare"},
			{"name": "魔法药水", "cost": 2, "heal": 10, "energy": 1, "draw": 2, "type": "skill", "rarity": "rare"},
			{"name": "狂暴", "cost": 1, "damage": 4, "strength": 2, "type": "power", "rarity": "rare"},
			{"name": "金属化", "cost": 1, "block": 3, "permanent_block": 1, "type": "power", "rarity": "rare"},
			{"name": "吸血", "cost": 2, "damage": 10, "heal": 5, "type": "attack", "rarity": "rare"}
		]
	}

# 获取稀有度颜色
static func get_rarity_color(rarity: String) -> Color:
	match rarity:
		"common":
			return Color.WHITE
		"uncommon":
			return Color.CYAN
		"rare":
			return Color.GOLD
		_:
			return Color.GRAY

# 获取稀有度名称
static func get_rarity_name(rarity: String) -> String:
	match rarity:
		"common":
			return "普通"
		"uncommon":
			return "罕见"
		"rare":
			return "稀有"
		_:
			return "未知"

# 检查卡牌是否已在牌组中
static func is_card_in_deck(card_name: String, deck: Array) -> bool:
	for card in deck:
		if card.name == card_name:
			return true
	return false

# 过滤掉玩家已有的卡牌（避免重复）
static func filter_existing_cards(rewards: Array[Dictionary], player_deck: Array) -> Array[Dictionary]:
	var filtered_rewards: Array[Dictionary] = []
	
	for card in rewards:
		# 某些卡牌可以有多张，不过滤
		if card.name in ["攻击", "防御", "愤怒", "快速攻击"]:
			filtered_rewards.append(card)
		elif not is_card_in_deck(card.name, player_deck):
			filtered_rewards.append(card)
	
	# 如果过滤后没有卡牌，至少给一张基础卡
	if filtered_rewards.is_empty():
		filtered_rewards.append({"name": "攻击", "cost": 1, "damage": 6, "type": "attack", "rarity": "common"})
	
	return filtered_rewards

# 生成商店卡牌
static func generate_shop_cards(floor: int) -> Array[Dictionary]:
	var shop_cards: Array[Dictionary] = []
	
	# 商店通常有5-7张卡牌
	var card_count = randi_range(5, 7)
	
	for i in range(card_count):
		var rarity = determine_rarity("normal", floor)
		var card = generate_random_card(rarity)
		
		# 为商店卡牌添加价格
		card.price = calculate_card_price(card)
		shop_cards.append(card)
	
	return shop_cards

# 计算卡牌价格
static func calculate_card_price(card: Dictionary) -> int:
	var base_price = 50
	
	match card.get("rarity", "common"):
		"common":
			base_price = randi_range(40, 60)
		"uncommon":
			base_price = randi_range(75, 100)
		"rare":
			base_price = randi_range(120, 150)
	
	return base_price
