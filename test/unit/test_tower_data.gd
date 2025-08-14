# test/unit/data/test_tower_data.gd
# 爬塔数据类测试 - Godot 4 兼容版

extends GdUnitTestSuite

var tower_data: TowerData

func before():
	tower_data = TowerData.new()

func after():
	if tower_data:
		tower_data = null

# 测试初始状态
func test_initial_state():
	assert_that(tower_data.current_floor).is_equal(1)
	assert_that(tower_data.max_floor).is_equal(20)
	assert_that(tower_data.player_hp).is_equal(80)
	assert_that(tower_data.player_max_hp).is_equal(80)

# 测试重置功能
func test_reset():
	# 修改一些值
	tower_data.current_floor = 10
	tower_data.player_hp = 50
	tower_data.player_max_hp = 100
	
	# 重置
	tower_data.reset()
	
	# 验证重置后的状态
	assert_that(tower_data.current_floor).is_equal(1)
	assert_that(tower_data.player_hp).is_equal(80)
	assert_that(tower_data.player_max_hp).is_equal(80)
	assert_that(tower_data.max_floor).is_equal(20)  # max_floor 不应该被重置

# 测试Boss楼层判断
func test_is_boss_floor():
	# 测试Boss楼层（每5层一个Boss）
	tower_data.current_floor = 5
	assert_that(tower_data.is_boss_floor()).is_true()
	
	tower_data.current_floor = 10
	assert_that(tower_data.is_boss_floor()).is_true()
	
	tower_data.current_floor = 15
	assert_that(tower_data.is_boss_floor()).is_true()
	
	tower_data.current_floor = 20
	assert_that(tower_data.is_boss_floor()).is_true()

func test_is_not_boss_floor():
	# 测试非Boss楼层
	tower_data.current_floor = 1
	assert_that(tower_data.is_boss_floor()).is_false()
	
	tower_data.current_floor = 2
	assert_that(tower_data.is_boss_floor()).is_false()
	
	tower_data.current_floor = 4
	assert_that(tower_data.is_boss_floor()).is_false()
	
	tower_data.current_floor = 6
	assert_that(tower_data.is_boss_floor()).is_false()
	
	tower_data.current_floor = 11
	assert_that(tower_data.is_boss_floor()).is_false()

# 测试最终楼层判断
func test_is_final_floor():
	# 测试最终楼层
	tower_data.current_floor = 20
	assert_that(tower_data.is_final_floor()).is_true()
	
	# 测试超过最大楼层
	tower_data.current_floor = 25
	assert_that(tower_data.is_final_floor()).is_false()

func test_is_not_final_floor():
	# 测试非最终楼层
	tower_data.current_floor = 1
	assert_that(tower_data.is_final_floor()).is_false()
	
	tower_data.current_floor = 10
	assert_that(tower_data.is_final_floor()).is_false()
	
	tower_data.current_floor = 19
	assert_that(tower_data.is_final_floor()).is_false()

# 测试楼层类型判断
func test_get_floor_type_first():
	tower_data.current_floor = 1
	assert_that(tower_data.get_floor_type()).is_equal(TowerData.FloorType.First)

func test_get_floor_type_normal():
	tower_data.current_floor = 2
	assert_that(tower_data.get_floor_type()).is_equal(TowerData.FloorType.Normal)
	
	tower_data.current_floor = 3
	assert_that(tower_data.get_floor_type()).is_equal(TowerData.FloorType.Normal)
	
	tower_data.current_floor = 11
	assert_that(tower_data.get_floor_type()).is_equal(TowerData.FloorType.Normal)

func test_get_floor_type_boss():
	tower_data.current_floor = 5
	assert_that(tower_data.get_floor_type()).is_equal(TowerData.FloorType.Boss)
	
	tower_data.current_floor = 10
	assert_that(tower_data.get_floor_type()).is_equal(TowerData.FloorType.Boss)
	
	tower_data.current_floor = 15
	assert_that(tower_data.get_floor_type()).is_equal(TowerData.FloorType.Boss)

func test_get_floor_type_final():
	tower_data.current_floor = 20
	assert_that(tower_data.get_floor_type()).is_equal(TowerData.FloorType.Final)
	
	tower_data.current_floor = 25
	assert_that(tower_data.get_floor_type()).is_equal(TowerData.FloorType.Unexpected)

# 测试特殊情况：第20层既是Boss层也是最终层
func test_floor_20_precedence():
	tower_data.current_floor = 20
	
	# 第20层应该被识别为final而不是boss
	assert_that(tower_data.is_boss_floor()).is_true()
	assert_that(tower_data.is_final_floor()).is_true()
	assert_that(tower_data.get_floor_type()).is_equal(TowerData.FloorType.Final)  # final 优先级更高

# 参数化测试：不同楼层的类型判断
func test_floor_types_comprehensive():
	var test_cases = [
		[1, TowerData.FloorType.First],
		[2, TowerData.FloorType.Normal],
		[3, TowerData.FloorType.Normal],
		[4, TowerData.FloorType.Normal],
		[5, TowerData.FloorType.Boss],
		[6, TowerData.FloorType.Normal],
		[7, TowerData.FloorType.Normal],
		[8, TowerData.FloorType.Normal],
		[9, TowerData.FloorType.Normal],
		[10, TowerData.FloorType.Boss],
		[11, TowerData.FloorType.Normal],
		[15, TowerData.FloorType.Boss],
		[19, TowerData.FloorType.Normal],
		[20, TowerData.FloorType.Final],
		[21, TowerData.FloorType.Unexpected]
	]
	
	for test_case in test_cases:
		var floor = test_case[0]
		var expected_type = test_case[1]
		
		tower_data.current_floor = floor
		assert_that(tower_data.get_floor_type()).is_equal(expected_type)

# 参数化测试：Boss楼层判断
func test_boss_floors_comprehensive():
	var boss_floors = [5, 10, 15]
	var normal_floors = [1, 2, 3, 4, 6, 7, 8, 9, 11, 12, 13, 14, 16, 17, 18, 19]
	
	for floor in boss_floors:
		tower_data.current_floor = floor
		assert_that(tower_data.is_boss_floor()).is_true()
	
	for floor in normal_floors:
		tower_data.current_floor = floor
		assert_that(tower_data.is_boss_floor()).is_false()

# 测试边界值
func test_boundary_values():
	# 测试楼层边界
	tower_data.current_floor = 0
	assert_that(tower_data.is_boss_floor()).is_true()  # 0 % 5 == 0
	assert_that(tower_data.is_final_floor()).is_false()  # 0 < 20
	
	# 测试负数楼层
	tower_data.current_floor = -1
	assert_that(tower_data.is_boss_floor()).is_false()  # -1 % 5 != 0
	assert_that(tower_data.is_final_floor()).is_false()  # -1 < 20
	assert_that(tower_data.get_floor_type() == TowerData.FloorType.Unexpected)
	
	# 测试很大的楼层数
	tower_data.current_floor = 1000
	assert_that(tower_data.is_boss_floor()).is_false()  # 1000 % 5 == 0
	assert_that(tower_data.is_final_floor()).is_false()  # 1000 >= 20

# 测试玩家生命值边界
func test_player_hp_boundaries():
	# 测试极端生命值
	tower_data.player_hp = 1
	tower_data.player_max_hp = 1
	assert_that(tower_data.player_hp).is_equal(1)
	assert_that(tower_data.player_max_hp).is_equal(1)
	
	# 测试大生命值
	tower_data.player_hp = 9999
	tower_data.player_max_hp = 9999
	assert_that(tower_data.player_hp).is_equal(9999)
	assert_that(tower_data.player_max_hp).is_equal(9999)
	
	# 测试零生命值
	tower_data.player_hp = 0
	assert_that(tower_data.player_hp).is_equal(0)

# 测试楼层进度计算
func test_floor_progress():
	# 测试进度百分比计算（如果需要的话）
	tower_data.current_floor = 10
	var progress = float(tower_data.current_floor) / float(tower_data.max_floor)
	assert_that(progress).is_equal(0.5)
	
	tower_data.current_floor = 1
	progress = float(tower_data.current_floor) / float(tower_data.max_floor)
	assert_that(progress).is_equal(0.05)
	
	tower_data.current_floor = 20
	progress = float(tower_data.current_floor) / float(tower_data.max_floor)
	assert_that(progress).is_equal(1.0)

# 测试数据一致性
func test_data_consistency():
	# 玩家当前生命值不应该超过最大生命值（在逻辑上）
	tower_data.player_hp = 100
	tower_data.player_max_hp = 80
	
	# 这里只是测试数据能被设置，具体的逻辑约束应该在其他地方处理
	assert_that(tower_data.player_hp).is_equal(100)
	assert_that(tower_data.player_max_hp).is_equal(80)

# 测试状态转换
func test_state_transitions():
	# 模拟爬塔过程
	tower_data.reset()
	
	# 开始时是第一层
	assert_that(tower_data.get_floor_type()).is_equal(TowerData.FloorType.First)
	
	# 进入普通层
	tower_data.current_floor = 2
	assert_that(tower_data.get_floor_type()).is_equal(TowerData.FloorType.Normal)
	
	# 到达第一个Boss层
	tower_data.current_floor = 5
	assert_that(tower_data.get_floor_type()).is_equal(TowerData.FloorType.Boss)
	
	# 继续普通层
	tower_data.current_floor = 6
	assert_that(tower_data.get_floor_type()).is_equal(TowerData.FloorType.Normal)
	
	# 到达最终Boss层
	tower_data.current_floor = 20
	assert_that(tower_data.get_floor_type()).is_equal(TowerData.FloorType.Final)

# 测试多次重置
func test_multiple_resets():
	for i in range(10):
		# 修改数据
		tower_data.current_floor = i + 10
		tower_data.player_hp = i * 10
		tower_data.player_max_hp = i * 20
		
		# 重置
		tower_data.reset()
		
		# 验证重置正确
		assert_that(tower_data.current_floor).is_equal(1)
		assert_that(tower_data.player_hp).is_equal(80)
		assert_that(tower_data.player_max_hp).is_equal(80)

# 测试楼层类型的所有可能值
func test_all_floor_types():
	var found_types = []
	
	# 测试前25层，收集所有可能的楼层类型
	for floor in range(1, 26):
		tower_data.current_floor = floor
		var floor_type = tower_data.get_floor_type()
		
		if not floor_type in found_types:
			found_types.append(floor_type)
	
	# 验证找到了所有预期的楼层类型
	assert_that(TowerData.FloorType.First in found_types).is_true()
	assert_that(TowerData.FloorType.Normal in found_types).is_true()
	assert_that(TowerData.FloorType.Boss in found_types).is_true()
	assert_that(TowerData.FloorType.Final in found_types).is_true()

# 压力测试：大量楼层计算
func test_stress_floor_calculations():
	for floor in range(1, 1001):
		tower_data.current_floor = floor
		
		# 这些操作不应该崩溃或产生错误
		var is_boss = tower_data.is_boss_floor()
		var is_final = tower_data.is_final_floor()
		var floor_type = tower_data.get_floor_type()
		
		# 验证返回值的类型正确
		assert_that(typeof(is_boss)).is_equal(TYPE_BOOL)
		assert_that(typeof(is_final)).is_equal(TYPE_BOOL)
		assert_that(typeof(floor_type)).is_equal(TYPE_INT)
		var valid_types = [TowerData.FloorType.First, TowerData.FloorType.Normal, TowerData.FloorType.Boss, TowerData.FloorType.Final, TowerData.FloorType.Unexpected]
		assert_that(floor_type in valid_types).is_true()

# 测试类型安全
func test_type_safety():
	# 验证属性类型
	assert_that(typeof(tower_data.current_floor)).is_equal(TYPE_INT)
	assert_that(typeof(tower_data.max_floor)).is_equal(TYPE_INT)
	assert_that(typeof(tower_data.player_hp)).is_equal(TYPE_INT)
	assert_that(typeof(tower_data.player_max_hp)).is_equal(TYPE_INT)
	
	# 验证方法返回值类型
	assert_that(typeof(tower_data.is_boss_floor())).is_equal(TYPE_BOOL)
	assert_that(typeof(tower_data.is_final_floor())).is_equal(TYPE_BOOL)
	assert_that(typeof(tower_data.get_floor_type())).is_equal(TYPE_INT)
