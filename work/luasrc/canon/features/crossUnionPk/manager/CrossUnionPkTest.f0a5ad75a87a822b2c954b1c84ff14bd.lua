-- CrossUnionPkTest.lua
-- geng.men
-- 2015-4-14
-- 跨服GVG测试接口 同时也可提供测试样例

CrossUnionPkTest = {}

--弹出测试的战斗结算面板
function CrossUnionPkTest.showBattleResult()
	local battleType = CrossUnionPkConsts.BATTLE_TYPE_KONCKOUT
	local battleSubType = CrossUnionPkConsts.KNOCKOUT_TYPE_16
	local battleData = {}
	local currentPoint = 1
	local changePoint = -2

	battleData.warWin = true
	battleData.cardInitDatas = {}
	battleData.singleBattleAttName = "singleBattleAttName"
	battleData.singleBattleDefName = "singleBattleDefName"
	battleData.attUnionLeftPlayer = "attUnionLeftPlayer"
	battleData.defUnionLeftPlayer = "defUnionLeftPlayer"
	battleData.attackUnionName = "attackUnionName"
	battleData.defenseUnionName = "defenseUnionName"

	battleData.cardInitDatas[1] = {pos = 1, uid = 123, metaId = 101066}
	battleData.cardInitDatas[2] = {pos = 10000, uid = 123, metaId = 101367}

	CrossUnionPk.popBattleResultPanel(battleType, battleData, currentPoint, changePoint)
end