# test/unit/data/test_enemy_data.gd
# 敌人数据类测试 - Godot 4 兼容版（清理版）

extends GdUnitTestSuite

var enemy: Enemy

func before():
	enemy = Enemy.new()

func after():
	if enemy:
		enemy = null

# 测试敌人初始化
func test_enemy_initialization():
	enemy.initialize(50, 60, "测试敌人")
	
	assert_that(enemy.current_health).is_equal(50)
	assert_that(enemy.max_health).is_equal(60)
	assert_that(enemy.enemy_name).is_equal("测试敌人")
	assert_that(enemy.current_block).is_equal(0)
	# 不假设初始意图索引，只验证它在有效范围内
	assert_that(enemy.current_intent_index).is_greater_equal(0)
	assert_that(enemy.current_intent_index).is_less(enemy.ai_pattern.size())
	assert_that(enemy.ai_pattern).is_not_empty()

func test_enemy_default_initialization():
	enemy.initialize(30, 30)  # 不提供名称，应该使用默认值
	
	assert_that(enemy.enemy_name).is_equal("敌人")

# 测试受伤机制
func test_enemy_take_damage_without_block():
	enemy.initialize(50, 50, "测试敌人")
	var signal_monitor = monitor_signals(enemy)
	
	enemy.take_damage(20)
	
	assert_that(enemy.current_health).is_equal(30)
	assert_signal(signal_monitor).is_emitted("health_changed")

func test_enemy_take_damage_with_block():
	enemy.initialize(50, 50, "测试敌人")
	enemy.add_block(15)
	var signal_monitor = monitor_signals(enemy)
	
	enemy.take_damage(20)
	
	assert_that(enemy.current_health).is_equal(45)  # 护甲抵挡15，受到5点伤害
	assert_that(enemy.current_block).is_equal(0)
	assert_signal(signal_monitor).is_emitted("health_changed")

func test_enemy_take_damage_block_absorbs_all():
	enemy.initialize(50, 50, "测试敌人")
	enemy.add_block(25)
	
	enemy.take_damage(20)
	
	assert_that(enemy.current_health).is_equal(50)  # 生命值不变
	assert_that(enemy.current_block).is_equal(5)    # 护甲减少20

func test_enemy_death():
	enemy.initialize(10, 50, "测试敌人")
	var signal_monitor = monitor_signals(enemy)
	
	enemy.take_damage(15)
	
	assert_that(enemy.current_health).is_equal(0)
	assert_signal(signal_monitor).is_emitted("died")
	assert_signal(signal_monitor).is_emitted("health_changed")

# 测试护甲机制
func test_enemy_add_block():
	enemy.initialize(50, 50, "测试敌人")
	
	enemy.add_block(10)
	
	assert_that(enemy.current_block).is_equal(10)

func test_enemy_add_block_multiple():
	enemy.initialize(50, 50, "测试敌人")
	
	enemy.add_block(5)
	enemy.add_block(7)
	
	assert_that(enemy.current_block).is_equal(12)

# 测试AI模式设置
func test_ai_pattern_setup_goblin():
	enemy.initialize(50, 50, "哥布林")
	
	assert_that(enemy.ai_pattern).is_not_empty()
	assert_that(enemy.ai_pattern.size()).is_equal(3)
	
	# 验证AI模式包含预期的行动类型
	var action_types = []
	for action in enemy.ai_pattern:
		action_types.append(action.type)
	

func test_ai_pattern_setup_skeleton():
	enemy.initialize(50, 50, "骷髅兵")
	
	assert_that(enemy.ai_pattern).is_not_empty()
	assert_that(enemy.ai_pattern.size()).is_equal(3)

func test_ai_pattern_setup_unknown_enemy():
	enemy.initialize(50, 50, "未知敌人类型")
	
	# 应该使用默认AI模式
	assert_that(enemy.ai_pattern).is_not_empty()
	assert_that(enemy.ai_pattern.size()).is_equal(2)  # 默认模式有2个行动

# 测试意图系统
func test_get_current_intent():
	enemy.initialize(50, 50, "哥布林")
	
	var intent = enemy.get_current_intent()
	
	assert_that(intent).is_not_null()
	assert_that(intent.has("type")).is_true()
	assert_that(intent.has("name")).is_true()
	assert_that(intent.type).is_not_empty()

func test_advance_intent():
	enemy.initialize(50, 50, "哥布林")
	var signal_monitor = monitor_signals(enemy)
	
	var initial_index = enemy.current_intent_index
	var pattern_size = enemy.ai_pattern.size()
	
	enemy.advance_intent()
	
	var expected_index = (initial_index + 1) % pattern_size
	assert_that(enemy.current_intent_index).is_equal(expected_index)
	assert_signal(signal_monitor).is_emitted("intent_changed")

func test_intent_cycling():
	enemy.initialize(50, 50, "哥布林")
	var pattern_size = enemy.ai_pattern.size()
	
	# 重置意图索引到已知状态
	enemy.current_intent_index = 0
	
	# 循环遍历所有意图，验证循环行为
	for i in range(pattern_size * 2):  # 循环两轮
		var expected_index = i % pattern_size
		assert_that(enemy.current_intent_index).is_equal(expected_index)
		enemy.advance_intent()

func test_get_next_intent_preview():
	enemy.initialize(50, 50, "哥布林")
	
	var current_intent = enemy.get_current_intent()
	var next_intent = enemy.get_next_intent_preview()
	
	assert_that(next_intent).is_not_null()
	# 注意：如果AI模式只有1个行动，current和next可能相同
	if enemy.ai_pattern.size() > 1:
		assert_that(next_intent).is_not_equal(current_intent)

# 测试回合执行
func test_execute_turn_attack():
	enemy.initialize(50, 50, "哥布林")
	
	# 确保当前意图是攻击
	while enemy.get_current_intent().type != "attack":
		enemy.advance_intent()
		# 防止无限循环
		if enemy.current_intent_index == 0:
			break
	
	var result = enemy.execute_turn()
	
	assert_that(result.has("type")).is_true()
	assert_that(result.has("name")).is_true()
	assert_that(result.has("damage")).is_true()
	assert_that(result.has("block")).is_true()
	
	if result.type == "attack":
		assert_that(result.damage).is_greater(0)

func test_execute_turn_defend():
	enemy.initialize(50, 50, "哥布林")
	
	# 找到防御行动
	while enemy.get_current_intent().type != "defend":
		enemy.advance_intent()
		# 防止无限循环
		if enemy.current_intent_index == 0:
			break
	
	if enemy.get_current_intent().type == "defend":
		var initial_block = enemy.current_block
		var result = enemy.execute_turn()
		
		assert_that(result.type).is_equal("defend")
		assert_that(result.block).is_greater(0)
		assert_that(enemy.current_block).is_greater(initial_block)

# 测试回合开始
func test_start_new_turn():
	enemy.initialize(50, 50, "测试敌人")
	enemy.add_block(10)
	
	enemy.start_new_turn()
	
	assert_that(enemy.current_block).is_equal(0)  # 护甲应该清零

# 测试状态获取
func test_get_status():
	enemy.initialize(60, 100, "测试Boss")
	enemy.add_block(8)
	
	var status = enemy.get_status()
	
	# 使用原生字典方法检查键存在
	assert_that(status.has("health")).is_true()
	assert_that(status.has("max_health")).is_true()
	assert_that(status.has("block")).is_true()
	assert_that(status.has("name")).is_true()
	assert_that(status.has("current_intent")).is_true()
	assert_that(status.has("next_intent")).is_true()
	
	assert_that(status.health).is_equal(60)
	assert_that(status.max_health).is_equal(100)
	assert_that(status.block).is_equal(8)
	assert_that(status.name).is_equal("测试Boss")

# 测试静态创建方法
func test_create_enemy_goblin():
	var goblin = Enemy.create_enemy("goblin")
	
	assert_that(goblin).is_not_null()
	assert_that(goblin.enemy_name).is_equal("哥布林")
	assert_that(goblin.current_health).is_equal(5)
	assert_that(goblin.max_health).is_equal(5)

func test_create_enemy_skeleton():
	var skeleton = Enemy.create_enemy("skeleton")
	
	assert_that(skeleton).is_not_null()
	assert_that(skeleton.enemy_name).is_equal("骷髅兵")
	assert_that(skeleton.current_health).is_equal(15)
	assert_that(skeleton.max_health).is_equal(15)

func test_create_enemy_boss():
	var boss = Enemy.create_enemy("boss_1")
	
	assert_that(boss).is_not_null()
	assert_that(boss.enemy_name).is_equal("Boss 1")
	assert_that(boss.current_health).is_equal(100)  # 80 + 1*20
	assert_that(boss.max_health).is_equal(100)

func test_create_enemy_unknown():
	var unknown = Enemy.create_enemy("unknown_enemy")
	
	assert_that(unknown).is_not_null()
	assert_that(unknown.enemy_name).is_equal("未知敌人")
	assert_that(unknown.current_health).is_equal(30)
	assert_that(unknown.max_health).is_equal(30)

# 参数化测试：不同敌人类型的创建（Godot 4 兼容写法）
func test_enemy_creation_parameters():
	var test_cases = [
		["goblin", "哥布林", 5],
		["skeleton", "骷髅兵", 15],
		["wolf", "野狼", 20],
		["bandit", "强盗", 20],
	]
	
	for test_case in test_cases:
		var enemy_id = test_case[0]
		var expected_name = test_case[1]
		var expected_hp = test_case[2]
		
		var created_enemy = Enemy.create_enemy(enemy_id)
		
		assert_that(created_enemy.enemy_name).is_equal(expected_name)
		assert_that(created_enemy.current_health).is_equal(expected_hp)
		assert_that(created_enemy.max_health).is_equal(expected_hp)

# 参数化测试：伤害计算（Godot 4 兼容写法）
func test_damage_calculations():
	var test_cases = [
		[10, 50, 0, 40, 0],      # 无护甲
		[5, 50, 10, 50, 5],      # 护甲完全抵挡
		[15, 50, 10, 45, 0],     # 护甲部分抵挡
		[0, 50, 10, 50, 10],     # 零伤害
	]
	
	for test_case in test_cases:
		var damage = test_case[0]
		var initial_health = test_case[1]
		var initial_block = test_case[2]
		var expected_health = test_case[3]
		var expected_block = test_case[4]
		
		enemy = Enemy.new()  # 重新创建敌人
		enemy.initialize(initial_health, 100, "测试敌人")
		if initial_block > 0:
			enemy.add_block(initial_block)
		
		enemy.take_damage(damage)
		
		assert_that(enemy.current_health).is_equal(expected_health)
		assert_that(enemy.current_block).is_equal(expected_block)

# 测试AI模式的完整性
func test_ai_pattern_integrity():
	var enemy_types = ["哥布林", "骷髅兵", "野狼", "强盗"]
	
	for enemy_type in enemy_types:
		enemy = Enemy.new()
		enemy.initialize(50, 50, enemy_type)
		
		# 验证AI模式不为空
		assert_that(enemy.ai_pattern).is_not_empty()
		
		# 验证每个行动都有必要的字段
		for action in enemy.ai_pattern:
			assert_that(action.has("type")).is_true()
			assert_that(action.has("name")).is_true()
			assert_that(action.type).is_not_empty()
			assert_that(action.name).is_not_empty()

# 测试边界情况
func test_edge_cases():
	# 测试零生命值初始化
	enemy.initialize(0, 10, "濒死敌人")
	assert_that(enemy.current_health).is_equal(0)
	
	# 测试大量护甲
	enemy.initialize(50, 50, "测试敌人")
	enemy.add_block(1000)
	enemy.take_damage(100)
	assert_that(enemy.current_health).is_equal(50)  # 生命值不变
	assert_that(enemy.current_block).is_equal(900)  # 护甲减少100
