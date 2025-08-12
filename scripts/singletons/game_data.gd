extends Node

# 全局游戏数据管理
# 这个脚本应该设置为AutoLoad单例

var current_floor = 1
var player_hp = 80
var player_max_hp = 80
var current_enemy_data = {}

# 玩家的卡组
var player_deck = []
var player_relics = []

func _ready():
	# 初始化默认卡组
	initialize_default_deck()

func initialize_default_deck():
	player_deck = [
		{"name": "攻击", "cost": 1, "damage": 6, "type": "attack"},
		{"name": "攻击", "cost": 1, "damage": 6, "type": "attack"},
		{"name": "攻击", "cost": 1, "damage": 6, "type": "attack"},
		{"name": "攻击", "cost": 1, "damage": 6, "type": "attack"},
		{"name": "防御", "cost": 1, "block": 5, "type": "skill"},
		{"name": "防御", "cost": 1, "block": 5, "type": "skill"},
		{"name": "防御", "cost": 1, "block": 5, "type": "skill"},
		{"name": "重击", "cost": 2, "damage": 12, "type": "attack"},
		{"name": "治疗", "cost": 2, "heal": 8, "type": "skill"},
		{"name": "能量药水", "cost": 1, "energy": 2, "type": "skill"}
	]

func reset_game():
	current_floor = 1
	player_hp = 80
	player_max_hp = 80
	current_enemy_data = {}
	player_relics.clear()
	initialize_default_deck()

func add_card_to_deck(card_data: Dictionary):
	player_deck.append(card_data)

func remove_card_from_deck(card_name: String) -> bool:
	for i in range(player_deck.size()):
		if player_deck[i].name == card_name:
			player_deck.remove_at(i)
			return true
	return false

func add_relic(relic_data: Dictionary):
	player_relics.append(relic_data)

func has_relic(relic_name: String) -> bool:
	for relic in player_relics:
		if relic.name == relic_name:
			return true
	return false

func get_current_enemy_data() -> Dictionary:
	return current_enemy_data
