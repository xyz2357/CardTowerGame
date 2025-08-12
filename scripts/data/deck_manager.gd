extends RefCounted

# 牌组管理类 - 纯数据和逻辑
class_name DeckManager

signal hand_changed
signal deck_changed

var deck: Array[Dictionary] = []
var hand: Array[Dictionary] = []
var discard_pile: Array[Dictionary] = []
var exhaust_pile: Array[Dictionary] = []

func initialize_default_deck():
	print("Initializing default deck...")
	deck = create_default_deck()
	deck.shuffle()
	hand.clear()
	discard_pile.clear()
	exhaust_pile.clear()
	
	print("Deck initialized with ", deck.size(), " cards")

func initialize_from_game_data(player_deck: Array):
	print("Initializing deck from game data...")
	deck.clear()
	
	# 复制玩家卡组并添加ID
	for card in player_deck:
		var card_copy = card.duplicate()
		card_copy.id = generate_card_id()
		deck.append(card_copy)
	
	deck.shuffle()
	hand.clear()
	discard_pile.clear()
	exhaust_pile.clear()
	
	print("Deck initialized from game data with ", deck.size(), " cards")

func create_default_deck() -> Array[Dictionary]:
	return [
		{"name": "攻击", "cost": 1, "damage": 6, "type": "attack", "id": generate_card_id()},
		{"name": "攻击", "cost": 1, "damage": 6, "type": "attack", "id": generate_card_id()},
		{"name": "攻击", "cost": 1, "damage": 6, "type": "attack", "id": generate_card_id()},
		{"name": "攻击", "cost": 1, "damage": 6, "type": "attack", "id": generate_card_id()},
		{"name": "防御", "cost": 1, "block": 5, "type": "skill", "id": generate_card_id()},
		{"name": "防御", "cost": 1, "block": 5, "type": "skill", "id": generate_card_id()},
		{"name": "防御", "cost": 1, "block": 5, "type": "skill", "id": generate_card_id()},
		{"name": "重击", "cost": 2, "damage": 12, "type": "attack", "id": generate_card_id()},
		{"name": "治疗", "cost": 2, "heal": 8, "type": "skill", "id": generate_card_id()},
		{"name": "能量药水", "cost": 1, "energy": 2, "type": "skill", "id": generate_card_id()}
	]

func generate_card_id() -> String:
	return "card_" + str(Time.get_unix_time_from_system()) + "_" + str(randi())

func draw_starting_hand():
	print("Drawing starting hand...")
	hand.clear()  # 确保手牌为空
	for i in range(5):
		if draw_card():
			print("Drew card ", i + 1, ": ", hand[hand.size()-1].name)
		else:
			print("Failed to draw card ", i + 1)
	print("Starting hand size: ", hand.size())

func draw_card() -> bool:
	if deck.is_empty():
		print("Deck is empty, shuffling discard pile...")
		shuffle_discard_into_deck()
	
	if not deck.is_empty():
		var card = deck.pop_front()
		hand.append(card)
		print("Drew card: ", card.name, " (hand size: ", hand.size(), ")")
		hand_changed.emit()
		deck_changed.emit()
		return true
	else:
		print("No cards available to draw!")
		return false

func draw_cards(count: int):
	print("Drawing ", count, " cards...")
	for i in range(count):
		if not draw_card():
			break

func shuffle_discard_into_deck():
	if discard_pile.is_empty():
		print("Discard pile is empty, nothing to shuffle")
		return
	
	print("Shuffling ", discard_pile.size(), " cards from discard pile into deck")
	deck.append_array(discard_pile)
	discard_pile.clear()
	deck.shuffle()
	deck_changed.emit()

func play_card(card_data: Dictionary):
	print("Playing card: ", card_data.name)
	
	# 从手牌中移除
	var removed = false
	for i in range(hand.size()):
		if hand[i].id == card_data.id:
			hand.remove_at(i)
			removed = true
			print("Removed card from hand, new hand size: ", hand.size())
			break
	
	if not removed:
		print("WARNING: Card not found in hand!")
	
	# 添加到弃牌堆
	discard_pile.append(card_data)
	print("Added card to discard pile, discard size: ", discard_pile.size())
	
	hand_changed.emit()
	deck_changed.emit()

func discard_hand():
	print("Discarding entire hand...")
	discard_pile.append_array(hand)
	hand.clear()
	hand_changed.emit()
	deck_changed.emit()

func discard_card(card_data: Dictionary):
	# 从手牌中移除并放入弃牌堆
	for i in range(hand.size()):
		if hand[i].id == card_data.id:
			var card = hand[i]
			hand.remove_at(i)
			discard_pile.append(card)
			print("Discarded card: ", card.name)
			break
	
	hand_changed.emit()
	deck_changed.emit()

func exhaust_card(card_data: Dictionary):
	# 从手牌中移除并放入消耗堆（永久移除）
	for i in range(hand.size()):
		if hand[i].id == card_data.id:
			var card = hand[i]
			hand.remove_at(i)
			exhaust_pile.append(card)
			print("Exhausted card: ", card.name)
			break
	
	hand_changed.emit()
	deck_changed.emit()

func add_card_to_deck(card_data: Dictionary):
	card_data.id = generate_card_id()
	deck.append(card_data)
	deck_changed.emit()

func remove_card_from_deck(card_name: String) -> bool:
	# 优先从牌库中移除
	for i in range(deck.size()):
		if deck[i].name == card_name:
			deck.remove_at(i)
			deck_changed.emit()
			return true
	
	# 其次从弃牌堆中移除
	for i in range(discard_pile.size()):
		if discard_pile[i].name == card_name:
			discard_pile.remove_at(i)
			deck_changed.emit()
			return true
	
	return false

func get_hand_cards() -> Array[Dictionary]:
	var hand_copy = hand.duplicate()
	print("Returning hand with ", hand_copy.size(), " cards")
	return hand_copy

func get_deck_status() -> Dictionary:
	return {
		"deck_size": deck.size(),
		"hand_size": hand.size(),
		"discard_size": discard_pile.size(),
		"exhaust_size": exhaust_pile.size()
	}

func get_all_cards() -> Array[Dictionary]:
	var all_cards: Array[Dictionary] = []
	all_cards.append_array(deck)
	all_cards.append_array(hand)
	all_cards.append_array(discard_pile)
	return all_cards

# 获取指定类型的卡牌数量
func count_cards_by_type(card_type: String) -> int:
	var count = 0
	var all_cards = get_all_cards()
	for card in all_cards:
		if card.type == card_type:
			count += 1
	return count

# 获取指定名称的卡牌数量
func count_cards_by_name(card_name: String) -> int:
	var count = 0
	var all_cards = get_all_cards()
	for card in all_cards:
		if card.name == card_name:
			count += 1
	return count
