extends Node

# 全局游戏数据管理
# 这个脚本应该设置为AutoLoad单例

signal game_data_changed

var current_floor = 1
var player_hp = 80
var player_max_hp = 80
var current_enemy_data = {}

# 玩家的卡组和遗物
var player_deck = []
var player_relics = []

# 游戏统计
var battles_won = 0
var total_damage_dealt = 0
var total_damage_taken = 0
var cards_played = 0

# 游戏设置
var master_volume = 1.0
var sfx_volume = 1.0
var music_volume = 1.0

func _ready():
	print("GameData singleton initialized")
	# 初始化默认卡组
	initialize_default_deck()
	
	# 连接信号用于保存游戏
	game_data_changed.connect(_on_game_data_changed)

func initialize_default_deck():
	print("Initializing default player deck...")
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
	print("Default deck initialized with ", player_deck.size(), " cards")

func reset_game():
	print("Resetting game data...")
	current_floor = 1
	player_hp = 80
	player_max_hp = 80
	current_enemy_data = {}
	player_relics.clear()
	battles_won = 0
	total_damage_dealt = 0
	total_damage_taken = 0
	cards_played = 0
	initialize_default_deck()
	emit_game_data_changed()

func add_card_to_deck(card_data: Dictionary):
	print("Adding card to deck: ", card_data.name)
	player_deck.append(card_data.duplicate())
	emit_game_data_changed()

func remove_card_from_deck(card_name: String) -> bool:
	for i in range(player_deck.size()):
		if player_deck[i].name == card_name:
			print("Removed card from deck: ", card_name)
			player_deck.remove_at(i)
			emit_game_data_changed()
			return true
	print("Card not found in deck: ", card_name)
	return false

func upgrade_card_in_deck(card_name: String) -> bool:
	for i in range(player_deck.size()):
		if player_deck[i].name == card_name:
			var card = player_deck[i]
			# 简单的升级逻辑
			if card.has("damage"):
				card.damage += 3
			if card.has("block"):
				card.block += 2
			if card.has("heal"):
				card.heal += 3
			
			card.name += "+"
			print("Upgraded card: ", card.name)
			emit_game_data_changed()
			return true
	return false

func add_relic(relic_data: Dictionary):
	print("Adding relic: ", relic_data.name)
	player_relics.append(relic_data.duplicate())
	emit_game_data_changed()

func remove_relic(relic_name: String) -> bool:
	for i in range(player_relics.size()):
		if player_relics[i].name == relic_name:
			print("Removed relic: ", relic_name)
			player_relics.remove_at(i)
			emit_game_data_changed()
			return true
	return false

func has_relic(relic_name: String) -> bool:
	for relic in player_relics:
		if relic.name == relic_name:
			return true
	return false

func get_current_enemy_data() -> Dictionary:
	return current_enemy_data

func set_current_enemy_data(enemy_data: Dictionary):
	current_enemy_data = enemy_data.duplicate()
	print("Set current enemy data: ", enemy_data)

# 统计相关函数
func record_battle_won():
	battles_won += 1
	emit_game_data_changed()

func record_damage_dealt(damage: int):
	total_damage_dealt += damage

func record_damage_taken(damage: int):
	total_damage_taken += damage

func record_card_played():
	cards_played += 1

func get_game_statistics() -> Dictionary:
	return {
		"battles_won": battles_won,
		"total_damage_dealt": total_damage_dealt,
		"total_damage_taken": total_damage_taken,
		"cards_played": cards_played,
		"current_floor": current_floor,
		"deck_size": player_deck.size(),
		"relics_count": player_relics.size()
	}

# 保存/加载系统
func save_game_data() -> Dictionary:
	var save_data = {
		"current_floor": current_floor,
		"player_hp": player_hp,
		"player_max_hp": player_max_hp,
		"player_deck": player_deck.duplicate(),
		"player_relics": player_relics.duplicate(),
		"battles_won": battles_won,
		"total_damage_dealt": total_damage_dealt,
		"total_damage_taken": total_damage_taken,
		"cards_played": cards_played,
		"master_volume": master_volume,
		"sfx_volume": sfx_volume,
		"music_volume": music_volume
	}
	
	print("Game data saved")
	return save_data

func load_game_data(save_data: Dictionary):
	if save_data.has("current_floor"):
		current_floor = save_data.current_floor
	if save_data.has("player_hp"):
		player_hp = save_data.player_hp
	if save_data.has("player_max_hp"):
		player_max_hp = save_data.player_max_hp
	if save_data.has("player_deck"):
		player_deck = save_data.player_deck.duplicate()
	if save_data.has("player_relics"):
		player_relics = save_data.player_relics.duplicate()
	if save_data.has("battles_won"):
		battles_won = save_data.battles_won
	if save_data.has("total_damage_dealt"):
		total_damage_dealt = save_data.total_damage_dealt
	if save_data.has("total_damage_taken"):
		total_damage_taken = save_data.total_damage_taken
	if save_data.has("cards_played"):
		cards_played = save_data.cards_played
	if save_data.has("master_volume"):
		master_volume = save_data.master_volume
	if save_data.has("sfx_volume"):
		sfx_volume = save_data.sfx_volume
	if save_data.has("music_volume"):
		music_volume = save_data.music_volume
	
	print("Game data loaded")
	emit_game_data_changed()

func save_to_file(filename: String = "savegame.dat"):
	var file = FileAccess.open("user://" + filename, FileAccess.WRITE)
	if file:
		var save_data = save_game_data()
		file.store_string(JSON.stringify(save_data))
		file.close()
		print("Game saved to file: ", filename)
	else:
		print("Failed to save game to file: ", filename)

func load_from_file(filename: String = "savegame.dat") -> bool:
	var file = FileAccess.open("user://" + filename, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		if parse_result == OK:
			var save_data = json.get_data()
			load_game_data(save_data)
			print("Game loaded from file: ", filename)
			return true
		else:
			print("Failed to parse save file: ", filename)
	else:
		print("Save file not found: ", filename)
	return false

func has_save_file(filename: String = "savegame.dat") -> bool:
	return FileAccess.file_exists("user://" + filename)

# 便利函数
func emit_game_data_changed():
	game_data_changed.emit()

func _on_game_data_changed():
	# 自动保存逻辑可以在这里实现
	pass

func get_deck_summary() -> String:
	var attack_count = 0
	var skill_count = 0
	var power_count = 0
	
	for card in player_deck:
		match card.type:
			"attack":
				attack_count += 1
			"skill":
				skill_count += 1
			"power":
				power_count += 1
	
	return "攻击: %d | 技能: %d | 能力: %d" % [attack_count, skill_count, power_count]

func get_player_status_summary() -> String:
	return "楼层 %d | 生命 %d/%d | %d 张卡牌 | %d 个遗物" % [current_floor, player_hp, player_max_hp, player_deck.size(), player_relics.size()]
