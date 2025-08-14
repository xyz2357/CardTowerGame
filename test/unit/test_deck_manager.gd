# test/unit/data/test_deck_manager_new.gd
# 牌组管理类测试 - 基于经验优化版

extends GdUnitTestSuite

var deck_manager: DeckManager

func before():
	deck_manager = DeckManager.new()
	# 验证初始状态
	assert_that(deck_manager.deck).is_empty()
	assert_that(deck_manager.hand).is_empty()
	assert_that(deck_manager.discard_pile).is_empty()
	assert_that(deck_manager.exhaust_pile).is_empty()

func after():
	if deck_manager:
		deck_manager = null

# === 初始化测试 ===

func test_initialize_default_deck():
	deck_manager.initialize_default_deck()
	
	assert_that(deck_manager.deck).is_not_empty()
	assert_that(deck_manager.hand).is_empty()
	assert_that(deck_manager.discard_pile).is_empty()
	assert_that(deck_manager.exhaust_pile).is_empty()
	
	# 验证牌组中的卡牌都有ID
	for card in deck_manager.deck:
		assert_that(card.has("id")).is_equal(true)
		assert_that(card.id).is_not_empty()
		assert_that(typeof(card.id)).is_equal(TYPE_STRING)

func test_default_deck_content():
	deck_manager.initialize_default_deck()
	
	# 验证默认牌组包含预期的卡牌
	var card_names = []
	for card in deck_manager.deck:
		card_names.append(card.name)
	
	assert_that("攻击" in card_names).is_equal(true)
	assert_that("重击" in card_names).is_equal(true)
	assert_that("能量药水" in card_names).is_equal(true)

func test_initialize_from_game_data():
	var player_deck: Array = [
		{"name": "攻击", "cost": 1, "damage": 6, "type": "attack"},
		{"name": "防御", "cost": 1, "block": 5, "type": "skill"},
		{"name": "治疗", "cost": 2, "heal": 8, "type": "skill"}
	]
	
	deck_manager.initialize_from_game_data(player_deck)
	
	assert_that(deck_manager.deck.size()).is_equal(3)
	assert_that(deck_manager.hand).is_empty()
	assert_that(deck_manager.discard_pile).is_empty()
	assert_that(deck_manager.exhaust_pile).is_empty()
	
	# 验证所有卡牌都被赋予了唯一ID
	var ids = []
	for card in deck_manager.deck:
		assert_that(card.has("id")).is_equal(true)
		assert_that(card.id).is_not_empty()
		assert_that(card.id in ids).is_equal(false)
		ids.append(card.id)

func test_initialize_from_empty_game_data():
	var empty_deck: Array = []
	
	deck_manager.initialize_from_game_data(empty_deck)
	
	assert_that(deck_manager.deck).is_empty()
	assert_that(deck_manager.hand).is_empty()

# === ID生成测试 ===

func test_generate_card_id():
	var id1 = deck_manager.generate_card_id()
	var id2 = deck_manager.generate_card_id()
	
	assert_that(id1).is_not_empty()
	assert_that(id2).is_not_empty()
	assert_that(id1).is_not_equal(id2)
	
	# 验证ID格式
	assert_that(id1.begins_with("card_")).is_equal(true)
	assert_that(id2.begins_with("card_")).is_equal(true)

func test_card_id_uniqueness():
	deck_manager.initialize_default_deck()
	
	var ids = []
	for card in deck_manager.deck:
		assert_that(card.id in ids).is_equal(false)
		ids.append(card.id)

# === 抽卡测试 ===

func test_draw_starting_hand():
	deck_manager.initialize_default_deck()
	var initial_deck_size = deck_manager.deck.size()
	
	deck_manager.draw_starting_hand()
	
	assert_that(deck_manager.hand.size()).is_equal(5)
	assert_that(deck_manager.deck.size()).is_equal(initial_deck_size - 5)

func test_draw_starting_hand_insufficient_cards():
	# 创建只有3张卡的牌组
	deck_manager.deck = [
		{"name": "攻击", "cost": 1, "id": "1"},
		{"name": "防御", "cost": 1, "id": "2"},
		{"name": "治疗", "cost": 2, "id": "3"}
	]
	deck_manager.hand.clear()
	deck_manager.discard_pile.clear()
	
	deck_manager.draw_starting_hand()
	
	# 应该只抽到3张卡
	assert_that(deck_manager.hand.size()).is_equal(3)
	assert_that(deck_manager.deck).is_empty()

func test_draw_card_success():
	deck_manager.initialize_default_deck()
	var initial_deck_size = deck_manager.deck.size()
	var initial_hand_size = deck_manager.hand.size()
	
	var result = deck_manager.draw_card()
	
	assert_that(result).is_equal(true)
	assert_that(deck_manager.hand.size()).is_equal(initial_hand_size + 1)
	assert_that(deck_manager.deck.size()).is_equal(initial_deck_size - 1)

func test_draw_card_empty_deck():
	deck_manager.deck.clear()
	deck_manager.hand.clear()
	deck_manager.discard_pile.clear()
	
	var result = deck_manager.draw_card()
	
	assert_that(result).is_equal(false)
	assert_that(deck_manager.hand).is_empty()

func test_draw_card_with_discard_shuffle():
	# 设置空牌库和有卡的弃牌堆
	deck_manager.deck.clear()
	deck_manager.hand.clear()
	deck_manager.discard_pile = [
		{"name": "攻击", "cost": 1, "id": "1"},
		{"name": "防御", "cost": 1, "id": "2"}
	]
	
	var result = deck_manager.draw_card()
	
	assert_that(result).is_equal(true)
	assert_that(deck_manager.hand.size()).is_equal(1)
	assert_that(deck_manager.discard_pile).is_empty()
	assert_that(deck_manager.deck.size()).is_equal(1)

func test_draw_cards_multiple():
	deck_manager.initialize_default_deck()
	var initial_deck_size = deck_manager.deck.size()
	
	deck_manager.draw_cards(3)
	
	assert_that(deck_manager.hand.size()).is_equal(3)
	assert_that(deck_manager.deck.size()).is_equal(initial_deck_size - 3)

func test_draw_cards_more_than_available():
	deck_manager.deck = [
		{"name": "攻击", "cost": 1, "id": "1"},
		{"name": "防御", "cost": 1, "id": "2"}
	]
	deck_manager.hand.clear()
	deck_manager.discard_pile.clear()
	
	deck_manager.draw_cards(5)
	
	assert_that(deck_manager.hand.size()).is_equal(2)
	assert_that(deck_manager.deck).is_empty()

# === 洗牌测试 ===

func test_shuffle_discard_into_deck():
	deck_manager.deck.clear()
	deck_manager.discard_pile = [
		{"name": "攻击", "cost": 1, "id": "1"},
		{"name": "防御", "cost": 1, "id": "2"},
		{"name": "治疗", "cost": 2, "id": "3"}
	]
	
	deck_manager.shuffle_discard_into_deck()
	
	assert_that(deck_manager.deck.size()).is_equal(3)
	assert_that(deck_manager.discard_pile).is_empty()

func test_shuffle_discard_into_deck_empty():
	deck_manager.deck.clear()
	deck_manager.discard_pile.clear()
	
	deck_manager.shuffle_discard_into_deck()
	
	assert_that(deck_manager.deck).is_empty()
	assert_that(deck_manager.discard_pile).is_empty()

func test_deck_shuffle_randomness():
	# 创建确定的牌组
	deck_manager.deck = [
		{"name": "卡1", "id": "1"},
		{"name": "卡2", "id": "2"},
		{"name": "卡3", "id": "3"},
		{"name": "卡4", "id": "4"},
		{"name": "卡5", "id": "5"}
	]
	deck_manager.discard_pile = deck_manager.deck.duplicate()
	deck_manager.deck.clear()
	
	# 记录洗牌前的顺序
	var original_order = []
	for card in deck_manager.discard_pile:
		original_order.append(card.id)
	
	deck_manager.shuffle_discard_into_deck()
	
	# 记录洗牌后的顺序
	var shuffled_order = []
	for card in deck_manager.deck:
		shuffled_order.append(card.id)
	
	# 验证卡牌数量不变
	assert_that(shuffled_order.size()).is_equal(original_order.size())
	
	# 验证包含相同的卡牌
	for id in original_order:
		assert_that(id in shuffled_order).is_equal(true)

# === 卡牌操作测试 ===

func test_play_card():
	deck_manager.initialize_default_deck()
	deck_manager.draw_starting_hand()
	
	var card_to_play = deck_manager.hand[0]
	var initial_hand_size = deck_manager.hand.size()
	
	deck_manager.play_card(card_to_play)
	
	assert_that(deck_manager.hand.size()).is_equal(initial_hand_size - 1)
	assert_that(deck_manager.discard_pile.size()).is_equal(1)
	assert_that(deck_manager.discard_pile[0].id).is_equal(card_to_play.id)

func test_play_card_not_in_hand():
	deck_manager.initialize_default_deck()
	deck_manager.draw_starting_hand()
	
	var fake_card = {"name": "假卡", "cost": 1, "id": "fake_id"}
	var initial_hand_size = deck_manager.hand.size()
	
	deck_manager.play_card(fake_card)
	
	# 手牌大小不应该改变
	assert_that(deck_manager.hand.size()).is_equal(initial_hand_size)
	# 但卡牌仍会被添加到弃牌堆
	assert_that(deck_manager.discard_pile.size()).is_equal(1)

func test_discard_hand():
	deck_manager.initialize_default_deck()
	deck_manager.draw_starting_hand()
	
	var hand_size = deck_manager.hand.size()
	
	deck_manager.discard_hand()
	
	assert_that(deck_manager.hand).is_empty()
	assert_that(deck_manager.discard_pile.size()).is_equal(hand_size)

func test_discard_card():
	deck_manager.initialize_default_deck()
	deck_manager.draw_starting_hand()
	
	var card_to_discard = deck_manager.hand[0]
	var initial_hand_size = deck_manager.hand.size()
	
	deck_manager.discard_card(card_to_discard)
	
	assert_that(deck_manager.hand.size()).is_equal(initial_hand_size - 1)
	assert_that(deck_manager.discard_pile.size()).is_equal(1)
	assert_that(deck_manager.discard_pile[0].id).is_equal(card_to_discard.id)

func test_exhaust_card():
	deck_manager.initialize_default_deck()
	deck_manager.draw_starting_hand()
	
	var card_to_exhaust = deck_manager.hand[0]
	var initial_hand_size = deck_manager.hand.size()
	
	deck_manager.exhaust_card(card_to_exhaust)
	
	assert_that(deck_manager.hand.size()).is_equal(initial_hand_size - 1)
	assert_that(deck_manager.exhaust_pile.size()).is_equal(1)
	assert_that(deck_manager.exhaust_pile[0].id).is_equal(card_to_exhaust.id)
	assert_that(deck_manager.discard_pile).is_empty()  # 消耗的卡不进弃牌堆

# === 牌组管理测试 ===

func test_add_card_to_deck():
	deck_manager.initialize_default_deck()
	var initial_deck_size = deck_manager.deck.size()
	
	var new_card = {"name": "新卡", "cost": 2, "type": "skill"}
	deck_manager.add_card_to_deck(new_card)
	
	assert_that(deck_manager.deck.size()).is_equal(initial_deck_size + 1)
	var added_card = deck_manager.deck[deck_manager.deck.size() - 1]
	assert_that(added_card.name).is_equal("新卡")
	assert_that(added_card.has("id")).is_equal(true)

func test_remove_card_from_deck():
	deck_manager.initialize_default_deck()
	
	# 获取牌库中的一张卡名
	var card_name = deck_manager.deck[0].name
	var initial_deck_size = deck_manager.deck.size()
	
	var result = deck_manager.remove_card_from_deck(card_name)
	
	assert_that(result).is_equal(true)
	assert_that(deck_manager.deck.size()).is_equal(initial_deck_size - 1)

func test_remove_card_from_discard():
	deck_manager.initialize_default_deck()
	deck_manager.draw_starting_hand()
	deck_manager.discard_hand()
	
	var card_name = deck_manager.discard_pile[0].name
	var initial_discard_size = deck_manager.discard_pile.size()
	
	var result = deck_manager.remove_card_from_deck(card_name)
	
	assert_that(result).is_equal(true)
	assert_that(deck_manager.discard_pile.size()).is_equal(initial_discard_size - 1)

func test_remove_nonexistent_card():
	deck_manager.initialize_default_deck()
	
	var result = deck_manager.remove_card_from_deck("不存在的卡")
	
	assert_that(result).is_equal(false)

# === 状态获取测试 ===

func test_get_hand_cards():
	deck_manager.initialize_default_deck()
	deck_manager.draw_starting_hand()
	
	var hand_cards = deck_manager.get_hand_cards()
	
	assert_that(hand_cards.size()).is_equal(deck_manager.hand.size())
	# 验证是副本而不是同一个引用
	hand_cards.append({"name": "测试卡", "id": "test"})
	assert_that(deck_manager.hand.size()).is_not_equal(hand_cards.size())

func test_get_deck_status():
	deck_manager.initialize_default_deck()
	deck_manager.draw_starting_hand()
	deck_manager.discard_hand()
	
	# 添加一张卡到消耗堆
	var exhaust_card = {"name": "消耗卡", "cost": 1, "id": "exhaust_1"}
	deck_manager.exhaust_pile.append(exhaust_card)
	
	var status = deck_manager.get_deck_status()
	
	assert_that(status.has("deck_size")).is_equal(true)
	assert_that(status.has("hand_size")).is_equal(true)
	assert_that(status.has("discard_size")).is_equal(true)
	assert_that(status.has("exhaust_size")).is_equal(true)
	
	assert_that(status.deck_size).is_equal(deck_manager.deck.size())
	assert_that(status.hand_size).is_equal(0)  # 手牌已弃掉
	assert_that(status.discard_size).is_equal(5)  # 起始手牌数
	assert_that(status.exhaust_size).is_equal(1)

func test_get_all_cards():
	deck_manager.initialize_default_deck()
	deck_manager.draw_cards(3)
	deck_manager.discard_hand()
	
	var all_cards = deck_manager.get_all_cards()
	var expected_total = deck_manager.deck.size() + deck_manager.hand.size() + deck_manager.discard_pile.size()
	
	assert_that(all_cards.size()).is_equal(expected_total)

# === 统计测试 ===

func test_count_cards_by_type():
	deck_manager.initialize_default_deck()
	
	var attack_count = deck_manager.count_cards_by_type("attack")
	var skill_count = deck_manager.count_cards_by_type("skill")
	
	assert_that(attack_count).is_greater(0)
	assert_that(skill_count).is_greater(0)

func test_count_cards_by_type_empty():
	deck_manager.deck.clear()
	deck_manager.hand.clear()
	deck_manager.discard_pile.clear()
	
	var count = deck_manager.count_cards_by_type("attack")
	
	assert_that(count).is_equal(0)

func test_count_cards_by_name():
	deck_manager.initialize_default_deck()
	
	var attack_count = deck_manager.count_cards_by_name("攻击")
	
	assert_that(attack_count).is_greater(0)

func test_count_cards_by_name_nonexistent():
	deck_manager.initialize_default_deck()
	
	var count = deck_manager.count_cards_by_name("不存在的卡")
	
	assert_that(count).is_equal(0)

# === 信号测试 ===

func test_hand_changed_signal():
	var signal_data = {"count": 0}
	
	deck_manager.hand_changed.connect(func(): 
		signal_data.count += 1
	)
	
	deck_manager.initialize_default_deck()
	deck_manager.draw_card()
	
	assert_that(signal_data.count).is_greater(0)

func test_deck_changed_signal():
	var signal_data = {"count": 0}
	
	deck_manager.deck_changed.connect(func(): 
		signal_data.count += 1
	)
	
	deck_manager.initialize_default_deck()
	deck_manager.draw_card()
	
	assert_that(signal_data.count).is_greater(0)

func test_signals_comprehensive():
	var signal_data = {
		"hand_changed": 0,
		"deck_changed": 0
	}
	
	deck_manager.hand_changed.connect(func(): 
		signal_data.hand_changed += 1
	)
	deck_manager.deck_changed.connect(func(): 
		signal_data.deck_changed += 1
	)
	
	# 执行各种操作
	deck_manager.initialize_default_deck()
	deck_manager.draw_cards(5)
	deck_manager.play_card(deck_manager.hand[0])
	deck_manager.discard_hand()
	deck_manager.shuffle_discard_into_deck()
	
	# 验证信号被发射
	assert_that(signal_data.hand_changed).is_greater(0)
	assert_that(signal_data.deck_changed).is_greater(0)

# === 场景测试 ===

func test_complete_game_scenario():
	# 模拟一个完整的游戏场景
	deck_manager.initialize_default_deck()
	
	# 1. 抽起始手牌
	deck_manager.draw_starting_hand()
	assert_that(deck_manager.hand.size()).is_equal(5)
	
	# 2. 打出一些卡牌
	var cards_to_play = deck_manager.hand.slice(0, 3)
	for card in cards_to_play:
		deck_manager.play_card(card)
	assert_that(deck_manager.hand.size()).is_equal(2)
	assert_that(deck_manager.discard_pile.size()).is_equal(3)
	
	# 3. 弃掉剩余手牌
	deck_manager.discard_hand()
	assert_that(deck_manager.hand).is_empty()
	assert_that(deck_manager.discard_pile.size()).is_equal(5)
	
	# 4. 消耗牌库中的一张卡（如果有的话）
	if deck_manager.deck.size() > 0:
		deck_manager.draw_card()
		deck_manager.exhaust_card(deck_manager.hand[0])
		assert_that(deck_manager.exhaust_pile.size()).is_equal(1)
	
	# 5. 洗牌重新开始
	deck_manager.shuffle_discard_into_deck()
	assert_that(deck_manager.discard_pile).is_empty()
	assert_that(deck_manager.deck.size()).is_greater(0)

# === 参数化测试 ===

func test_card_operation_sequences():
	var test_sequences = [
		["draw_5", "play_1", "discard_all"],
		["draw_3", "exhaust_1", "draw_2"],
		["draw_5", "discard_all", "shuffle", "draw_3"]
	]
	
	for sequence in test_sequences:
		deck_manager = DeckManager.new()
		deck_manager.initialize_default_deck()
		
		for action in sequence:
			match action:
				"draw_5":
					deck_manager.draw_cards(5)
				"draw_3":
					deck_manager.draw_cards(3)
				"draw_2":
					deck_manager.draw_cards(2)
				"play_1":
					if deck_manager.hand.size() > 0:
						deck_manager.play_card(deck_manager.hand[0])
				"exhaust_1":
					if deck_manager.hand.size() > 0:
						deck_manager.exhaust_card(deck_manager.hand[0])
				"discard_all":
					deck_manager.discard_hand()
				"shuffle":
					deck_manager.shuffle_discard_into_deck()
		
		# 验证基本不变量
		var status = deck_manager.get_deck_status()
		var total_cards = status.deck_size + status.hand_size + status.discard_size + status.exhaust_size
		assert_that(total_cards).is_greater(0)

# === 边界情况测试 ===

func test_edge_cases():
	# 测试空牌组的各种操作
	deck_manager.deck.clear()
	deck_manager.hand.clear()
	deck_manager.discard_pile.clear()
	deck_manager.exhaust_pile.clear()
	
	# 这些操作不应该崩溃
	deck_manager.draw_starting_hand()
	deck_manager.draw_card()
	deck_manager.discard_hand()
	deck_manager.shuffle_discard_into_deck()
	
	assert_that(deck_manager.hand).is_empty()
	assert_that(deck_manager.deck).is_empty()

func test_data_integrity():
	deck_manager.initialize_default_deck()
	
	# 记录初始卡牌总数
	var initial_total = deck_manager.get_all_cards().size()
	
	# 执行各种操作
	deck_manager.draw_cards(5)
	deck_manager.play_card(deck_manager.hand[0])
	deck_manager.discard_card(deck_manager.hand[0])
	deck_manager.exhaust_card(deck_manager.hand[0])
	
	# 验证卡牌总数（除了消耗的卡）
	var current_total = deck_manager.get_all_cards().size() + deck_manager.exhaust_pile.size()
	assert_that(current_total).is_equal(initial_total)

# === 压力测试 ===

func test_stress_operations():
	deck_manager.initialize_default_deck()
	
	# 执行大量操作
	for i in range(50):
		deck_manager.draw_cards(3)
		if deck_manager.hand.size() > 0:
			deck_manager.play_card(deck_manager.hand[0])
		deck_manager.discard_hand()
		deck_manager.shuffle_discard_into_deck()
	
	# 验证系统仍然正常工作
	var status = deck_manager.get_deck_status()
	assert_that(status.deck_size + status.discard_size + status.exhaust_size).is_greater(0)

# === 类型安全测试 ===

func test_type_safety():
	deck_manager.initialize_default_deck()
	
	# 验证返回值类型
	assert_that(typeof(deck_manager.get_hand_cards())).is_equal(TYPE_ARRAY)
	assert_that(typeof(deck_manager.get_deck_status())).is_equal(TYPE_DICTIONARY)
	assert_that(typeof(deck_manager.get_all_cards())).is_equal(TYPE_ARRAY)
	assert_that(typeof(deck_manager.count_cards_by_type("attack"))).is_equal(TYPE_INT)
	assert_that(typeof(deck_manager.count_cards_by_name("攻击"))).is_equal(TYPE_INT)
	assert_that(typeof(deck_manager.generate_card_id())).is_equal(TYPE_STRING)