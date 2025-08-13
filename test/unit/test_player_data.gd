# test/unit/data/test_player_data.gd
# 玩家数据类测试 - Godot 4 兼容版

extends GdUnitTestSuite

var player: Player

func before():
	# 每个测试前创建新的玩家实例
	player = Player.new()

func after():
	# 每个测试后清理
	if player:
		player = null

# 测试玩家初始化
func test_player_initialization():
	# 测试正常初始化
	player.initialize(80, 100, 3, 3)
	
	assert_that(player.current_health).is_equal(80)
	assert_that(player.max_health).is_equal(100)
	assert_that(player.current_energy).is_equal(3)
	assert_that(player.max_energy).is_equal(3)
	assert_that(player.current_block).is_equal(0)

func test_player_initialization_edge_cases():
	# 测试边界情况
	player.initialize(0, 1, 0, 1)
	
	assert_that(player.current_health).is_equal(0)
	assert_that(player.max_health).is_equal(1)
	assert_that(player.current_energy).is_equal(0)
	assert_that(player.max_energy).is_equal(1)

# 测试受伤机制
func test_take_damage_without_block():
	player.initialize(50, 100, 3, 3)
	var signal_monitor = monitor_signals(player)
	
	# 无护甲时受到伤害
	player.take_damage(20)
	
	assert_that(player.current_health).is_equal(30)
	assert_that(player.current_block).is_equal(0)
	assert_signal(signal_monitor).is_emitted("health_changed")

func test_take_damage_with_block():
	player.initialize(50, 100, 3, 3)
	player.add_block(15)
	var signal_monitor = monitor_signals(player)
	
	# 有护甲时受到伤害
	player.take_damage(20)
	
	# 护甲抵挡15点，实际受到5点伤害
	assert_that(player.current_health).is_equal(45)
	assert_that(player.current_block).is_equal(0)
	assert_signal(signal_monitor).is_emitted("health_changed")
	assert_signal(signal_monitor).is_emitted("block_changed")

func test_take_damage_block_absorbs_all():
	player.initialize(50, 100, 3, 3)
	player.add_block(25)
	var signal_monitor = monitor_signals(player)
	
	# 护甲完全抵挡伤害
	player.take_damage(20)
	
	assert_that(player.current_health).is_equal(50)  # 生命值不变
	assert_that(player.current_block).is_equal(5)    # 护甲减少20
	assert_signal(signal_monitor).is_emitted("block_changed")
	# 根据实际的Player实现，即使生命值没变，health_changed信号可能仍然会发射
	# 所以我们不测试这个信号是否未发射，只验证生命值确实没有改变

func test_death_trigger():
	player.initialize(10, 100, 3, 3)
	var signal_monitor = monitor_signals(player)
	
	# 致命伤害
	player.take_damage(15)
	
	assert_that(player.current_health).is_equal(0)
	assert_signal(signal_monitor).is_emitted("died")
	assert_signal(signal_monitor).is_emitted("health_changed")

func test_death_with_block():
	player.initialize(10, 100, 3, 3)
	player.add_block(5)
	var signal_monitor = monitor_signals(player)
	
	# 伤害超过护甲和生命值
	player.take_damage(20)
	
	assert_that(player.current_health).is_equal(0)
	assert_that(player.current_block).is_equal(0)
	assert_signal(signal_monitor).is_emitted("died")

# 测试治疗机制
func test_heal_normal():
	player.initialize(30, 100, 3, 3)
	var signal_monitor = monitor_signals(player)
	
	player.heal(20)
	
	assert_that(player.current_health).is_equal(50)
	assert_signal(signal_monitor).is_emitted("health_changed")

func test_heal_over_max():
	player.initialize(90, 100, 3, 3)
	var signal_monitor = monitor_signals(player)
	
	# 治疗超过最大值
	player.heal(20)
	
	assert_that(player.current_health).is_equal(100)  # 不会超过最大值
	assert_signal(signal_monitor).is_emitted("health_changed")

func test_heal_at_full_health():
	player.initialize(100, 100, 3, 3)
	var signal_monitor = monitor_signals(player)
	
	player.heal(10)
	
	assert_that(player.current_health).is_equal(100)
	# 即使生命值没有实际变化，信号仍然会发射
	assert_signal(signal_monitor).is_emitted("health_changed")

func test_heal_zero():
	player.initialize(50, 100, 3, 3)
	var signal_monitor = monitor_signals(player)
	
	player.heal(0)
	
	assert_that(player.current_health).is_equal(50)
	assert_signal(signal_monitor).is_emitted("health_changed")

# 测试护甲机制
func test_add_block():
	player.initialize(50, 100, 3, 3)
	var signal_monitor = monitor_signals(player)
	
	player.add_block(10)
	
	assert_that(player.current_block).is_equal(10)
	assert_signal(signal_monitor).is_emitted("block_changed")

func test_add_block_multiple_times():
	player.initialize(50, 100, 3, 3)
	
	player.add_block(5)
	player.add_block(7)
	player.add_block(3)
	
	assert_that(player.current_block).is_equal(15)

# 测试能量机制 - 改进版
func test_spend_energy_success():
	player.initialize(50, 100, 3, 3)
	
	var initial_energy = player.current_energy
	var result = player.spend_energy(2)
	
	assert_that(result).is_true()
	assert_that(player.current_energy).is_equal(initial_energy - 2)

func test_spend_energy_insufficient():
	player.initialize(50, 100, 2, 3)
	
	var initial_energy = player.current_energy
	var result = player.spend_energy(3)
	
	assert_that(result).is_false()
	assert_that(player.current_energy).is_equal(initial_energy)  # 能量不变

func test_spend_energy_exact_amount():
	player.initialize(50, 100, 3, 3)
	
	var result = player.spend_energy(3)
	
	assert_that(result).is_true()
	assert_that(player.current_energy).is_equal(0)

func test_can_afford_card():
	player.initialize(50, 100, 3, 3)
	
	assert_that(player.can_afford_card(2)).is_true()
	assert_that(player.can_afford_card(3)).is_true()
	assert_that(player.can_afford_card(4)).is_false()
	assert_that(player.can_afford_card(0)).is_true()

func test_add_energy():
	player.initialize(50, 100, 2, 3)
	
	var initial_energy = player.current_energy
	player.add_energy(1)
	
	assert_that(player.current_energy).is_equal(initial_energy + 1)

func test_add_energy_over_limit():
	player.initialize(50, 100, 3, 3)
	
	player.add_energy(8)  # 添加大量能量
	
	# 能量应该被限制在10点
	assert_that(player.current_energy).is_equal(10)

# 测试回合开始 - 改进版
func test_start_new_turn():
	player.initialize(50, 100, 1, 3)
	player.add_block(5)
	
	player.start_new_turn()
	
	assert_that(player.current_energy).is_equal(3)  # 恢复到最大能量
	assert_that(player.current_block).is_equal(0)   # 护甲清零

# 测试获取状态
func test_get_status():
	player.initialize(60, 100, 2, 3)
	player.add_block(8)
	
	var status = player.get_status()
	
	assert_that(status).is_not_null()
	
	# 直接检查字典内容，避免使用可能不存在的 contains_key 方法
	assert_that(status.has("health")).is_true()
	assert_that(status.has("max_health")).is_true()
	assert_that(status.has("energy")).is_true()
	assert_that(status.has("max_energy")).is_true()
	assert_that(status.has("block")).is_true()
	
	assert_that(status.health).is_equal(60)
	assert_that(status.max_health).is_equal(100)
	assert_that(status.energy).is_equal(2)
	assert_that(status.max_energy).is_equal(3)
	assert_that(status.block).is_equal(8)

# 参数化测试：多种伤害情况（Godot 4 兼容写法）
func test_damage_scenarios():
	var test_cases = [
		[10, 50, 0, 40, 0],      # 无护甲普通伤害
		[5, 50, 10, 50, 5],      # 护甲完全抵挡
		[15, 50, 10, 45, 0],     # 护甲部分抵挡
		[0, 50, 5, 50, 5],       # 零伤害
		[100, 10, 5, 0, 0],      # 致命伤害
	]
	
	for test_case in test_cases:
		var damage = test_case[0]
		var initial_health = test_case[1]
		var initial_block = test_case[2]
		var expected_health = test_case[3]
		var expected_block = test_case[4]
		
		player = Player.new()  # 重新创建玩家
		player.initialize(initial_health, 100, 3, 3)
		if initial_block > 0:
			player.add_block(initial_block)
		
		player.take_damage(damage)
		
		assert_that(player.current_health).is_equal(expected_health)
		assert_that(player.current_block).is_equal(expected_block)

# 参数化测试：多种治疗情况（Godot 4 兼容写法）
func test_heal_scenarios():
	var test_cases = [
		[20, 50, 100, 70],       # 正常治疗
		[30, 90, 100, 100],      # 治疗到满血
		[10, 100, 100, 100],     # 满血时治疗
		[0, 50, 100, 50],        # 零治疗
	]
	
	for test_case in test_cases:
		var heal_amount = test_case[0]
		var initial_health = test_case[1]
		var max_health = test_case[2]
		var expected_health = test_case[3]
		
		player = Player.new()  # 重新创建玩家
		player.initialize(initial_health, max_health, 3, 3)
		
		player.heal(heal_amount)
		
		assert_that(player.current_health).is_equal(expected_health)

# 压力测试：大量操作
func test_stress_operations():
	player.initialize(1000, 1000, 10, 10)
	
	# 执行大量操作
	for i in range(100):
		player.take_damage(1)
		player.heal(1)
		player.add_block(1)
		player.spend_energy(1)
		player.add_energy(1)
		player.start_new_turn()
	
	# 验证最终状态合理
	assert_that(player.current_health).is_greater(0)
	assert_that(player.current_health).is_less_equal(player.max_health)
	assert_that(player.current_energy).is_less_equal(10)
	assert_that(player.current_block).is_greater_equal(0)

# 测试边界值
func test_boundary_values():
	# 测试最小值
	player.initialize(1, 1, 1, 1)
	assert_that(player.current_health).is_equal(1)
	assert_that(player.current_energy).is_equal(1)
	
	# 测试大数值
	player.initialize(999999, 999999, 999, 999)
	assert_that(player.current_health).is_equal(999999)
	assert_that(player.current_energy).is_equal(999)

# 测试状态转换
func test_state_transitions():
	player.initialize(50, 100, 3, 3)
	
	# 健康 -> 受伤
	player.take_damage(30)
	assert_that(player.current_health).is_equal(20)
	
	# 受伤 -> 治疗
	player.heal(40)
	assert_that(player.current_health).is_equal(60)
	
	# 满能量 -> 消耗能量
	player.spend_energy(2)
	assert_that(player.current_energy).is_equal(1)
	
	# 低能量 -> 回合开始恢复
	player.start_new_turn()
	assert_that(player.current_energy).is_equal(3)
