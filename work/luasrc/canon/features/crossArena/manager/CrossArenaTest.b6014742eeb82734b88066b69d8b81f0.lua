-- CrossArenaTest.lua
-- 2015-3-9
-- zheng.che
-- 跨服pvp测试相关

CrossArenaTest = {}

--生成排名表
function CrossArenaTest.createRanks()
	-- <bean desc="排行榜信息">
	-- 	<property code="rank" type="int" desc="排名" />
	-- 	<property code="battleScore" type="int" desc="天梯积分" />
	-- 	<property code="metaId" type="int" desc="主卡牌ID" />
	-- 	<property code="nickName" type="string" desc="昵称" />
	-- 	<property code="level" type="int" desc="等级" />
	-- 	<property code="server" type="int" desc="服务器" />
	-- 	<property code="unionName" type="string" desc="军团名称" />
	-- 	<property code="combat" type="int" desc="战斗力" />
	-- </bean>

	local result = {}
	local rank

	rank = {}
	rank.rank = 1
	rank.battleScore = 1000
	rank.metaId = 101011
	rank.nickName = "nickName1"
	rank.level = 123
	rank.server = 56
	rank.unionName = "unionName1"
	rank.combat = 112233
	table.insert(result, rank)

	rank = {}
	rank.rank = 2
	rank.battleScore = 1000
	rank.metaId = 101011
	rank.nickName = "nickName2"
	rank.level = 123
	rank.server = 56
	rank.unionName = "unionName2"
	rank.combat = 112233
	table.insert(result, rank)

	rank = {}
	rank.rank = 3
	rank.battleScore = 1000
	rank.metaId = 101011
	rank.nickName = "nickName3"
	rank.level = 123
	rank.server = 56
	rank.unionName = "unionName3"
	rank.combat = 112233
	table.insert(result, rank)

	rank = {}
	rank.rank = 4
	rank.battleScore = 1000
	rank.metaId = 101011
	rank.nickName = "nickName4"
	rank.level = 123
	rank.server = 56
	rank.unionName = "unionName4"
	rank.combat = 112233
	table.insert(result, rank)

	return result
end