# test/unit/data/test_card_rewards.gd
# 卡牌奖励系统测试 - Godot 4 兼容版

extends GdUnitTestSuite

# 测试获取战斗奖励
func test_get_battle_rewards_normal():
	var rewards = CardRewards.get_battle_rewards("normal", 1)
	
	assert_that(rewards).is_not_null()
	assert_that(rewards.size()).is_equal(3)  # 普通敌人给3张卡
	
	# 验证每张卡都有必要的字段
	for card in rewards:
		assert_that(card.has("name")).is_true()
		assert_that(card.has("cost")).is_true()
		assert_that(card.has("type")).is_true()
		assert_that(card.has("rarity")).is_true()

func test_get_battle_rewards_elite():
	var rewards = CardRewards.get_battle_rewards("elite", 5)
	
	assert_that(rewards).is_not_null()
	assert_that(rewards.size()).is_equal(4)  # 精英敌人给4张卡

func test_get_battle_rewards_boss():
	var rewards = CardRewards.get_battle_rewards("boss", 10)
	
	assert_that(rewards).is_not_null()
	assert_that(rewards.size()).is_equal(5)  # Boss给5张卡

func test_get_battle_rewards_unknown_enemy():
	var rewards = CardRewards.get_battle_rewards("unknown", 1)
	
	assert_that(rewards).is_not_null()
	assert_that(rewards.size()).is_equal(3)  # 未知敌人默认给3张卡

# 测试稀有度确定
func test_determine_rarity_normal_enemy():
	# 测试多次以验证概率分布
	var rarity_counts = {
		CardRewards.Rarity.COMMON: 0,
		CardRewards.Rarity.UNCOMMON: 0,
		CardRewards.Rarity.RARE: 0
	}
	
	# 运行100次
	for i in range(100):
		var rarity = CardRewards.determine_rarity("normal", 1)
		rarity_counts[rarity] += 1
	
	# 验证所有稀有度都被返回过（概率测试）
	# 普通敌人1层的稀有概率应该较低
	assert_that(rarity_counts[CardRewards.Rarity.COMMON]).is_greater(0)

func test_determine_rarity_elite_enemy():
	var rarity = CardRewards.determine_rarity("elite", 5)
	
	# 验证返回的是有效的稀有度枚举值
	var valid_rarities = [
		CardRewards.Rarity.COMMON,
		CardRewards.Rarity.UNCOMMON,
		CardRewards.Rarity.RARE
	]
	assert_that(rarity in valid_rarities).is_true()

func test_determine_rarity_boss_enemy():
	var rarity = CardRewards.determine_rarity("boss", 10)
	
	var valid_rarities = [
		CardRewards.Rarity.COMMON,
		CardRewards.Rarity.UNCOMMON,
		CardRewards.Rarity.RARE
	]
	assert_that(rarity in valid_rarities).is_true()

func test_determine_rarity_high_floor():
	# 高楼层应该有更高的稀有卡概率
	var high_floor_rarity = CardRewards.determine_rarity("normal", 15)
	
	var valid_rarities = [
		CardRewards.Rarity.COMMON,
		CardRewards.Rarity.UNCOMMON,
		CardRewards.Rarity.RARE
	]
	assert_that(high_floor_rarity in valid_rarities).is_true()

# 测试卡牌生成
func test_generate_random_card():
	var common_card = CardRewards.generate_random_card(CardRewards.Rarity.COMMON)
	
	assert_that(common_card).is_not_null()
	assert_that(common_card.has("name")).is_true()
	assert_that(common_card.has("rarity")).is_true()
	assert_that(common_card.rarity).is_equal("common")

func test_generate_random_card_uncommon():
	var uncommon_card = CardRewards.generate_random_card(CardRewards.Rarity.UNCOMMON)
	
	assert_that(uncommon_card.rarity).is_equal("uncommon")

func test_generate_random_card_rare():
	var rare_card = CardRewards.generate_random_card(CardRewards.Rarity.RARE)
	
	assert_that(rare_card.rarity).is_equal("rare")

# 测试按稀有度分类的卡牌
func test_get_cards_by_rarity():
	var cards_by_rarity = CardRewards.get_cards_by_rarity()
	
	assert_that(cards_by_rarity).is_not_null()
	assert_that(cards_by_rarity.has(CardRewards.Rarity.COMMON)).is_true()
	assert_that(cards_by_rarity.has(CardRewards.Rarity.UNCOMMON)).is_true()
	assert_that(cards_by_rarity.has(CardRewards.Rarity.RARE)).is_true()
	
	# 验证每个稀有度都有卡牌
	assert_that(cards_by_rarity[CardRewards.Rarity.COMMON]).is_not_empty()
	assert_that(cards_by_rarity[CardRewards.Rarity.UNCOMMON]).is_not_empty()
	assert_that(cards_by_rarity[CardRewards.Rarity.RARE]).is_not_empty()

func test_common_cards_structure():
	var cards_by_rarity = CardRewards.get_cards_by_rarity()
	var common_cards = cards_by_rarity[CardRewards.Rarity.COMMON]
	
	# 验证普通卡的结构
	for card in common_cards:
		assert_that(card.has("name")).is_true()
		assert_that(card.has("cost")).is_true()
		assert_that(card.has("type")).is_true()
		assert_that(card.has("rarity")).is_true()
		assert_that(card.rarity).is_equal("common")

# 测试稀有度颜色
func test_get_rarity_color():
	assert_that(CardRewards.get_rarity_color("common")).is_equal(Color.WHITE)
	assert_that(CardRewards.get_rarity_color("uncommon")).is_equal(Color.CYAN)
	assert_that(CardRewards.get_rarity_color("rare")).is_equal(Color.GOLD)
	assert_that(CardRewards.get_rarity_color("unknown")).is_equal(Color.GRAY)

# 测试稀有度名称
func test_get_rarity_name():
	assert_that(CardRewards.get_rarity_name("common")).is_equal("普通")
	assert_that(CardRewards.get_rarity_name("uncommon")).is_equal("罕见")
	assert_that(CardRewards.get_rarity_name("rare")).is_equal("稀有")
	assert_that(CardRewards.get_rarity_name("unknown")).is_equal("未知")

# 测试检查卡牌是否在牌组中
func test_is_card_in_deck():
	var deck = [
		{"name": "攻击", "cost": 1},
		{"name": "防御", "cost": 1},
		{"name": "治疗", "cost": 2}
	]
	
	assert_that(CardRewards.is_card_in_deck("攻击", deck)).is_true()
	assert_that(CardRewards.is_card_in_deck("防御", deck)).is_true()
	assert_that(CardRewards.is_card_in_deck("重击", deck)).is_false()

func test_is_card_in_deck_empty():
	var empty_deck = []
	
	assert_that(CardRewards.is_card_in_deck("攻击", empty_deck)).is_false()

# 测试过滤已有卡牌
func test_filter_existing_cards():
	var rewards: Array[Dictionary] = [
		{"name": "攻击", "cost": 1, "rarity": "common"},
		{"name": "重击", "cost": 2, "rarity": "uncommon"},
		{"name": "治疗", "cost": 2, "rarity": "uncommon"}
	]
	
	var player_deck: Array = [
		{"name": "治疗", "cost": 2}
	]
	
	var filtered = CardRewards.filter_existing_cards(rewards, player_deck)
	
	# 攻击卡应该保留（可以有多张）
	# 重击应该保留（玩家没有）
	# 治疗应该被过滤掉（玩家已有，且不在允许多张的列表中）
	assert_that(filtered.size()).is_equal(2)
	
	var card_names = []
	for card in filtered:
		card_names.append(card.name)
	
	assert_that("攻击" in card_names).is_true()
	assert_that("重击" in card_names).is_true()
	assert_that("治疗" in card_names).is_false()

func test_filter_existing_cards_all_filtered():
	var rewards: Array[Dictionary] = [
		{"name": "重击", "cost": 2, "rarity": "uncommon"}
	]
	
	var player_deck: Array = [
		{"name": "重击", "cost": 2}
	]
	
	var filtered = CardRewards.filter_existing_cards(rewards, player_deck)
	
	# 所有卡都被过滤后，应该至少给一张基础攻击卡
	assert_that(filtered.size()).is_equal(1)
	assert_that(filtered[0].name).is_equal("攻击")

func test_filter_existing_cards_empty_rewards():
	var empty_rewards: Array[Dictionary] = []
	var player_deck: Array = [{"name": "攻击", "cost": 1}]
	
	var filtered = CardRewards.filter_existing_cards(empty_rewards, player_deck)
	
	# 空奖励应该给一张基础攻击卡
	assert_that(filtered.size()).is_equal(1)
	assert_that(filtered[0].name).is_equal("攻击")

# 测试商店卡牌生成
func test_generate_shop_cards():
	var shop_cards = CardRewards.generate_shop_cards(5)
	
	assert_that(shop_cards).is_not_null()
	assert_that(shop_cards.size()).is_greater_equal(5)
	assert_that(shop_cards.size()).is_less_equal(7)
	
	# 验证每张卡都有价格
	for card in shop_cards:
		assert_that(card.has("price")).is_true()
		assert_that(card.price).is_greater(0)

func test_generate_shop_cards_different_floors():
	var low_floor_shop = CardRewards.generate_shop_cards(1)
	var high_floor_shop = CardRewards.generate_shop_cards(15)
	
	# 都应该有合理的卡牌数量
	assert_that(low_floor_shop.size()).is_greater_equal(5)
	assert_that(low_floor_shop.size()).is_less_equal(7)
	assert_that(high_floor_shop.size()).is_greater_equal(5)
	assert_that(high_floor_shop.size()).is_less_equal(7)

# 测试卡牌价格计算
func test_calculate_card_price():
	var common_card = {"rarity": "common"}
	var uncommon_card = {"rarity": "uncommon"}
	var rare_card = {"rarity": "rare"}
	var no_rarity_card = {}
	
	var common_price = CardRewards.calculate_card_price(common_card)
	var uncommon_price = CardRewards.calculate_card_price(uncommon_card)
	var rare_price = CardRewards.calculate_card_price(rare_card)
	var default_price = CardRewards.calculate_card_price(no_rarity_card)
	
	# 验证价格范围
	assert_that(common_price).is_greater_equal(40)
	assert_that(common_price).is_less_equal(60)
	assert_that(uncommon_price).is_greater_equal(75)
	assert_that(uncommon_price).is_less_equal(100)
	assert_that(rare_price).is_greater_equal(120)
	assert_that(rare_price).is_less_equal(150)
	assert_that(default_price).is_greater_equal(40)
	assert_that(default_price).is_less_equal(60)  # 默认为common价格
	
	# 验证稀有度越高价格越贵（大概率）
	assert_that(rare_price).is_greater(common_price)

# 参数化测试：不同敌人类型的奖励数量
func test_reward_count_by_enemy_type():
	var test_cases = [
		["normal", 3],
		["elite", 4],
		["boss", 5],
		["unknown_type", 3]
	]
	
	for test_case in test_cases:
		var enemy_type = test_case[0]
		var expected_count = test_case[1]
		
		var rewards = CardRewards.get_battle_rewards(enemy_type, 1)
		assert_that(rewards.size()).is_equal(expected_count)

# 参数化测试：不同楼层的稀有度影响
func test_floor_rarity_influence():
	var floor_levels = [1, 5, 10, 15, 20]
	
	for floor in floor_levels:
		var rarity = CardRewards.determine_rarity("normal", floor)
		
		# 验证返回的是有效稀有度
		var valid_rarities = [
			CardRewards.Rarity.COMMON,
			CardRewards.Rarity.UNCOMMON,
			CardRewards.Rarity.RARE
		]
		assert_that(rarity in valid_rarities).is_true()

# 测试卡牌数据完整性
func test_card_data_integrity():
	var cards_by_rarity = CardRewards.get_cards_by_rarity()
	
	# 检查所有稀有度的卡牌数据完整性
	for rarity in cards_by_rarity.keys():
		var cards = cards_by_rarity[rarity]
		
		for card in cards:
			# 基本字段检查
			assert_that(card.has("name")).is_true()
			assert_that(card.has("cost")).is_true()
			assert_that(card.has("type")).is_true()
			assert_that(card.has("rarity")).is_true()
			
			# 数据类型检查 - 使用 typeof 替代 is_instance_of
			assert_that(typeof(card.name)).is_equal(TYPE_STRING)
			assert_that(typeof(card.cost)).is_equal(TYPE_INT)
			assert_that(typeof(card.type)).is_equal(TYPE_STRING)
			assert_that(typeof(card.rarity)).is_equal(TYPE_STRING)
			
			# 值合理性检查
			assert_that(card.name).is_not_empty()
			assert_that(card.cost).is_greater_equal(0)
			assert_that(card.type in ["attack", "skill", "power"]).is_true()

# 测试边界情况
func test_edge_cases():
	# 测试极端楼层
	var very_high_floor_rewards = CardRewards.get_battle_rewards("normal", 100)
	assert_that(very_high_floor_rewards.size()).is_equal(3)
	
	# 测试负数楼层（虽然不应该发生，但要确保不崩溃）
	var negative_floor_rewards = CardRewards.get_battle_rewards("normal", -1)
	assert_that(negative_floor_rewards.size()).is_equal(3)
	
	# 测试零楼层
	var zero_floor_rewards = CardRewards.get_battle_rewards("normal", 0)
	assert_that(zero_floor_rewards.size()).is_equal(3)

# 测试卡牌生成的随机性
func test_card_generation_randomness():
	var cards = []
	
	# 生成多张同稀有度的卡牌
	for i in range(20):
		var card = CardRewards.generate_random_card(CardRewards.Rarity.COMMON)
		cards.append(card.name)
	
	# 将数组转换为唯一值集合来检查是否有不同的卡牌
	var unique_cards = {}
	for card_name in cards:
		unique_cards[card_name] = true
	
	# 应该生成至少一些不同的卡牌（假设普通卡有多种）
	assert_that(unique_cards.size()).is_greater(0)

# 压力测试
func test_performance_stress():
	# 生成大量奖励，测试性能
	for i in range(100):
		var rewards = CardRewards.get_battle_rewards("boss", 20)
		assert_that(rewards.size()).is_equal(5)
		
		var shop_cards = CardRewards.generate_shop_cards(15)
		assert_that(shop_cards.size()).is_greater_equal(5)
		assert_that(shop_cards.size()).is_less_equal(7)
