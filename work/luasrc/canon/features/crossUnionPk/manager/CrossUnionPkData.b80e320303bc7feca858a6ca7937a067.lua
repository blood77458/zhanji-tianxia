-- CrossUnionPkData.lua
-- geng.men
-- 2015-4-14
-- 跨服GVG数据管理

CrossUnionPkData = {}


--标志在军团战阶段是否点亮按钮
local _unionWarLightOnWhenIsRightTime = false

--getCrossGvgInfo返回的信息,调整阶段的信息
local _crossGVGTeamAdjustInfo = {}
--当前点选的位置
local _currentSelectedPos = 0

--跨服军团战版本号过期时间
CrossUnionPkData.reversionEndTime = 0
--跨服军团战时间段判定过期时间
CrossUnionPkData.timeLevelEndTime = 0

--呼吸灯点亮标志
local _CrossunionWarLightOn = false

--当前所处时间段
local  _currTimeLevel = nil

--战场相关数据
--战斗子类型 (淘汰赛类型)
local _battleSubType = CrossUnionPkConsts.KNOCKOUT_TYPE_16

local _teamAdjustLightOn = false

-------------------------------------------------
-- 操作
-------------------------------------------------
function CrossUnionPkData.startup()
end

function CrossUnionPkData.clear()
	CrossUnionPkData.reversionEndTime = 0
	CrossUnionPkData.timeLevelEndTime = 0
	_unionWarLightOnWhenIsRightTime = false
	_CrossunionWarLightOn = false
	_currentSelectedPos = 0
	_currTimeLevel = nil
	_crossGVGTeamAdjustInfo = {}
	_teamAdjustLightOn = false
	_battleSubType = CrossUnionPkConsts.KNOCKOUT_TYPE_16
end

-------------------------------------------------
-- 军团战按钮呼吸灯是否点亮
-------------------------------------------------
--设置
function CrossUnionPkData.setCrossUnionWarLightOn(v)
	_CrossunionWarLightOn = v
end
--读取
function CrossUnionPkData.getCrossUnionWarLightOn()
	return _CrossunionWarLightOn
end


--设置
function CrossUnionPkData.setUnionWarLightOnWhenIsRightTime(v)
	_unionWarLightOnWhenIsRightTime = v
end
--读取
function CrossUnionPkData.getUnionWarLightOnWhenIsRightTime()
	return _unionWarLightOnWhenIsRightTime
end

function CrossUnionPkData.getCrossGvgScore()
	return _crossGVGTeamAdjustInfo.score
end

function CrossUnionPkData.setCrossGvgInfo(c)
	_crossGVGTeamAdjustInfo = c
end

function CrossUnionPkData.getCrossGvgInfo()
	return _crossGVGTeamAdjustInfo
end

function CrossUnionPkData.setCrossGvgVersion(v)
	_crossGVGTeamAdjustInfo.version = v
end

function CrossUnionPkData.getCrossGvgVersion()
	return _crossGVGTeamAdjustInfo.version
end

function CrossUnionPkData.setAllSignedMenbers(s)
	_crossGVGTeamAdjustInfo.signs = s
end

function CrossUnionPkData.getAllSignedMenbers()
	return _crossGVGTeamAdjustInfo.signs
end

function CrossUnionPkData.getChallengeNum()
	return _crossGVGTeamAdjustInfo.challengeNum
end

function CrossUnionPkData.setChallengeNum(s)
	_crossGVGTeamAdjustInfo.challengeNum = s
end

function CrossUnionPkData.getTeamMirrorRemind()
	return _crossGVGTeamAdjustInfo.teamMirrorRemind
end

function CrossUnionPkData.setGroupChallengedRemind(s)
	_crossGVGTeamAdjustInfo.groupChallengedRemind = s
end

function CrossUnionPkData.getGroupChallengedRemind()
	return _crossGVGTeamAdjustInfo.groupChallengedRemind
end

function CrossUnionPkData.setTeamAdjustLightOn(s)
	_teamAdjustLightOn = s
end

function CrossUnionPkData.getTeamAdjustLightOn()
	return _teamAdjustLightOn
end

function CrossUnionPkData.setTeamMirrorRemind(s)
	_crossGVGTeamAdjustInfo.teamMirrorRemind = s
end


function CrossUnionPkData.getCurrentSelectedPos()
	return _currentSelectedPos
end

function CrossUnionPkData.setCurrentSelectedPos( s )
	_currentSelectedPos = s
end
--获取阵容，包括先锋和上阵信息
function CrossUnionPkData.getAllBattleInfo()
	local signs = _crossGVGTeamAdjustInfo.signs
	local pioneer = 0
	local headUids = {}
	local middleUids = {}
	local tailUids = {}
	local headTmp = {}
	local middleTmp = {}
	local tailTmp = {}
	for k,v in pairs(signs) do
		if v.position == 1 then
			pioneer = v.uid
		elseif v.position >= 10 and v.position < 20 then
			table.insert(headTmp,v)
		elseif v.position >= 20 and v.position < 30 then
			table.insert(middleTmp,v)
		elseif v.position >= 30 and v.position < 40 then
			table.insert(tailTmp,v)
		end
	end
	local function sortFunc( a , b )
		if a.position < b.position then
			return true
		else
			return false
		end
	end

	table.sort(headTmp , sortFunc)
	table.sort(middleTmp , sortFunc)
	table.sort(tailTmp , sortFunc)

	local function addToUids( t , u )
		for k,v in pairs(t) do
			table.insert(u , v.uid)
		end
	end

	local function changeFinalPos( t )
		if not t[1] then
			return 
		end
		--第一个位置也空的情况
		local firstPos = t[1].position - math.modf(t[1].position / 10) * 10
		print("####firstPos"..firstPos)
		if firstPos ~= 0 then
			t[1].position = math.modf(t[1].position / 10) * 10
		end
		
		for i=1,#t - 1 do
			if (t[i + 1].position - t[i].position) ~= 1 then
				t[i + 1].position = t[i].position + 1
			end
		end
	end
	--如果有空就自动补齐
	changeFinalPos(headTmp)
	changeFinalPos(middleTmp)
	changeFinalPos(tailTmp)

	addToUids(headTmp , headUids)
	addToUids(middleTmp , middleUids)
	addToUids(tailTmp , tailUids)

	print("pioneer"..pioneer)
	print("headUids"..table.tostring(headUids))
	print("middleUids"..table.tostring(middleUids))
	print("tailUids"..table.tostring(tailUids))

	return pioneer , headUids ,middleUids , tailUids
end

function CrossUnionPkData.getUploadTeamParams(override)
	local pioneer , headUids ,middleUids , tailUids = CrossUnionPkData.getAllBattleInfo()
	local ret = {
	override = override,
	version = CrossUnionPkData.getCrossGvgVersion(),
	forwardUid = pioneer,
	headUids= headUids,
	middleUids= middleUids,
	tailUids = tailUids,
}
	return ret
end
--银币
function CrossUnionPkData.getCoinInspireValue()
	return _crossGVGTeamAdjustInfo.coinInspireNum 
end

function CrossUnionPkData.setCoinInspireValue( s )
	_crossGVGTeamAdjustInfo.coinInspireNum = s
end
--金币
function CrossUnionPkData.getGemInspireValue()
	return _crossGVGTeamAdjustInfo.gemInspireNum 
end

function CrossUnionPkData.setGemInspireValue( s )
	_crossGVGTeamAdjustInfo.gemInspireNum = s
end
--是否奋力一击
function CrossUnionPkData.getStriveInspireNum()
	return _crossGVGTeamAdjustInfo.striveInspireNum 
end

function CrossUnionPkData.setStriveInspireNum(s)
	_crossGVGTeamAdjustInfo.striveInspireNum = s
end

function CrossUnionPkData.increaseSelfInspireNum( buffId )
	local pos = nil
	for k,v in pairs(_crossGVGTeamAdjustInfo.signs) do
		if v.uid == DataManager.getCurrUser().uid then
			pos = k
		end
	end
	if pos == nil then
		return
	end
	if buffId == 1 then
		_crossGVGTeamAdjustInfo.signs[pos].gemInspireNum = _crossGVGTeamAdjustInfo.signs[pos].gemInspireNum + 1
		UnionManager.eventDispatcher:dispatchEvent(Event.new(CrossUnionPkConsts.REFRESH_BATTLE_UI))
	elseif buffId == 2 then
		_crossGVGTeamAdjustInfo.signs[pos].coinInspireNum = _crossGVGTeamAdjustInfo.signs[pos].coinInspireNum + 1
	else
		_crossGVGTeamAdjustInfo.signs[pos].striveInspireNum = _crossGVGTeamAdjustInfo.signs[pos].striveInspireNum + 1
	end
end

--获得当前时间区间编号
function CrossUnionPkData.getCurrTimeLevel()
	local currTime = TimeUtil.getServerTimeSeconds()
	if (not _currTimeLevel) or  currTime > CrossUnionPkData.timeLevelEndTime then
		--超时 需要重新计算得到最新时间段
		CrossUnionPkUtils.refreshVersion()
	end
	return _currTimeLevel
end
--设置当前时间区间编号
function CrossUnionPkData.setCurrTimeLevel(v)
	_currTimeLevel = v
end

-------------------------------------------------
-- 战斗子类型
-------------------------------------------------
--设置
function CrossUnionPkData.setBattleSubType(v)
	_battleSubType = v
end
--读取
function CrossUnionPkData.getBattleSubType()
	return _battleSubType
end