-- UnionPkData.lua
-- zheng.che
-- 2014-7-24
-- 军团战数据管理

--UnionManager.getChallengeCityId()--报名战斗城池
--UnionManager.getCoinInspireNum()--银币鼓舞次数
--UnionManager.getStriveInspireNum()--奋力一击鼓舞次数
--UnionManager.getGemInspireNum()--金币鼓舞次数
--UnionManager.getUnionWarVersion()--版本号 *算法:军团战开始时间时间戳开始 一周时间内为1 两周内为2 以此类推
--UnionManager.getUnionWarRound()--轮次

--DataManager.getGameInitData().sharkUser.uid--当前玩家uid

UnionPkData = {}

---------------------------------------------------系统变量

--军团战版本号过期时间
UnionPkData.reversionEndTime = 0
--军团战时间段判定过期时间
UnionPkData.timeLevelEndTime = 0

---------------------------------------------------游戏变量

--小城池总数
local _smallCityNum = 0
--我军本轮财富值
local _roundWealth = 0

--我军占领城池哈希表
local _defenceCityIdsHash = {}

--当前所处时间段
local  _currTimeLevel = nil

--战场临时记录用变量
--当前战斗对应城池id
local _battleCityId = nil
--当前战斗对应第几轮
local _battleRound = nil

--第二轮军团战结束时当前玩家所处的职位
local _historyTitle

--军团战按钮是否点亮
local _unionWarLightOn = false

--当前正在战斗的城池id列表
local _fightingCityIds = {}

--标志在军团战阶段是否点亮按钮
local _unionWarLightOnWhenIsRightTime = false

--军团战军团胜利次数列表
-- <bean desc="军团战军团胜利次数">
-- 	<property code="cityId" type="int" desc="城池id" />
-- 	<property code="winNum" type="int" desc="胜利次数" />
-- </bean>
local _unionWinNumList = {}

--参加军团战斗次数（同一城池打两次算参加两次）
local _attendBattleNum = 0

--军团主界面里 军团战icon角标数量
local _unionWarHintNum = 0
--军团总战力
local _unionTotalFightCapacity = 0

-------------------------------------------------
-- 操作
-------------------------------------------------
function UnionPkData.startup()
	--默认值
	_historyTitle = UnionManager.TITLE_NONE--默认没有职位
end

function UnionPkData.clear()
	UnionPkData.reversionEndTime = 0

	_smallCityNum = 0
	_roundWealth = 0
	_defenceCityIdsHash = {}

	--清空鼓舞话费提示是否确认的状态
	_powerupSilverConfirmed = false
	_powerupGoldConfirmed = false
	
	UnionPkData.clearMarkHash()

	_unionWarLightOn = false

	_fightingCityIds = {}
	_unionWarLightOnWhenIsRightTime = false
	_unionWinNumList = {}

	_attendBattleNum = 0
	_unionWarHintNum = 0
	_unionTotalFightCapacity = 0

	UnionPkData.startup()
end

--清除城池id标记
function UnionPkData.clearMarkHash()
	UnionPkData.clearCityErrorTags()
end

-------------------------------------------------
-- update
-------------------------------------------------

--更新城池列表导致刷新
function UnionPkData.updateForCityList()
	--目前暂时没有需要 先放着
end

-------------------------------------------------
-- getter
-------------------------------------------------

function UnionPkData.getSmallCityNum()
	return _smallCityNum
end

function UnionPkData.getRoundWealth()
	return _roundWealth
end

function UnionPkData.getDefenceCityIdsHash()
	return _defenceCityIdsHash
end

--获得已占领城池的总数
function UnionPkData.getDefenceCityNum()
	local count = 0
	for k,v in pairs(_defenceCityIdsHash) do
		count = count + 1
	end
	return count
	--return #_defenceCityIdsHash 注意哈希表table不能用这种方式获得长度...
end

--获得总共能报名竞标的城池个数
function UnionPkData.getMaxCanSignNum()
	return UnionPkConfig.citySignLimit() - UnionPkData.getDefenceCityNum()
end

--获得当前时间区间编号
function UnionPkData.getCurrTimeLevel()
	local currTime = TimeUtil.getServerTimeSeconds()
	if (not _currTimeLevel) or  currTime > UnionPkData.timeLevelEndTime then
		--超时 需要重新计算得到最新时间段
		UnionPkUtils.refreshVersion()
	end
	return _currTimeLevel
end

--获得当前战斗对应的城池编号
function UnionPkData.getBattleCityId()
	return _battleCityId
end

--获得当前战斗对应的轮数
function UnionPkData.getBattleRound()
	return _battleRound
end

--获得 第二轮军团战结束时当前玩家所处的职位
function UnionPkData.getHistoryTitle()
	return _historyTitle
end

-------------------------------------------------
-- setter
-------------------------------------------------

function UnionPkData.setSmallCityNum(v)
	_smallCityNum = v
end

function UnionPkData.setRoundWealth(v)
	_roundWealth = v
end

function UnionPkData.setDefenceCityIdsHase(v)
	_defenceCityIdsHash = v
end

function UnionPkData.setHistoryTitle(v)
	_historyTitle = v
end

--设置当前战斗的前端数据
function UnionPkData.setBattleArgv(cityId, round)
	_battleCityId = cityId
	_battleRound = round
end

--设置当前时间区间编号
function UnionPkData.setCurrTimeLevel(v)
	_currTimeLevel = v
end

-------------------------------------------------
-- check
-------------------------------------------------

--某城镇id是否是当前所在军团正在防守的城市
function UnionPkData.cityIsInMyDefence(cityId)
	return _defenceCityIdsHash[cityId]
end

-------------------------------------------------
-- 报名过的城池列表
-------------------------------------------------

--已报名的城池id列表
local _signedCity = {}
--设置
function UnionPkData.setSignedCity(v)
	_signedCity = v or {}
end
--读取
function UnionPkData.getSignedCity()
	return _signedCity
end
--添加
function UnionPkData.addSignedCity(cityId)
	table.insert(_signedCity, cityId)
end
--查询数量
function UnionPkData.signedCityCount()
	return #_signedCity
end

-------------------------------------------------
-- 银币鼓舞的提示状态
-------------------------------------------------

local _powerupSilverConfirmed = false

function UnionPkData.setPowerupSilverConfirmed(v)
	_powerupSilverConfirmed = v or false
end

function UnionPkData.getPowerupSilverConfirmed()
	return _powerupSilverConfirmed
end

-------------------------------------------------
-- 金币鼓舞的提示状态
-------------------------------------------------

local _powerupGoldConfirmed = false

function UnionPkData.setPowerupGoldConfirmed(v)
	_powerupGoldConfirmed = v or false
end

function UnionPkData.getPowerupGoldConfirmed()
	return _powerupGoldConfirmed
end

-------------------------------------------------
-- 城池相关的各种错误码标记(标记后防止再次请求接口 可直接弹出错误码)
-------------------------------------------------

--本轮军团战 某城池是否存在某个标记<城池id + "_" + tagId, true为已标记>
local _cityErrorTagHash = {}

--设置
function UnionPkData.setCityErrorTag(cityId, tagID)
	_cityErrorTagHash[cityId.."_"..tagID] = true
end
--读取
function UnionPkData.getCityErrorTag(cityId, tagID)
	if _cityErrorTagHash[cityId.."_"..tagID] == true then
		return true
	end
	return false
end
--清空
function UnionPkData.clearCityErrorTags()
	_cityErrorTagHash = {}
end

-------------------------------------------------
-- 军团战按钮呼吸灯是否点亮
-------------------------------------------------
--设置
function UnionPkData.setUnionWarLightOn(v)
	_unionWarLightOn = v
end
--读取
function UnionPkData.getUnionWarLightOn()
	return _unionWarLightOn
end

-------------------------------------------------
-- 正在战斗城池列表相关
-------------------------------------------------

function UnionPkData.setFightingCityIds(v)
	_fightingCityIds = v
end

function UnionPkData.getFightingCityIds()
	return _fightingCityIds
end

function UnionPkData.addFightingCityIds(cityId)
	table.insert(_fightingCityIds, cityId)
end

function UnionPkData.checkIsFightingCityId(cityId)
	if table.indexOf(_fightingCityIds, cityId) == nil then
		return false
	end
	return true
end

------------------------

--设置
function UnionPkData.setUnionWarLightOnWhenIsRightTime(v)
	_unionWarLightOnWhenIsRightTime = v
end
--读取
function UnionPkData.getUnionWarLightOnWhenIsRightTime()
	return _unionWarLightOnWhenIsRightTime
end

-------------------------------------------------
-- 军团战军团胜利次数列表相关
-------------------------------------------------

function UnionPkData.setUnionWinNumList(v)
	_unionWinNumList = v
end

function UnionPkData.getUnionWinNumList()
	return _unionWinNumList
end

--获得当前军团在某城池胜利次数
function UnionPkData.findCityWinNum(cityId)
	for i, v in ipairs(_unionWinNumList) do
		local winNumData = _unionWinNumList[i]
		if cityId == winNumData.cityId then
			return winNumData.winNum
		end
	end
	return 0
end

-------------------------------------------------
-- 参加军团战斗次数（同一城池打两次算参加两次）
-------------------------------------------------
--设置
function UnionPkData.setAttendBattleNum(v)
	_attendBattleNum = v
end
--读取
function UnionPkData.getAttendBattleNum()
	return _attendBattleNum
end

-------------------------------------------------
-- 军团主界面里 军团战icon角标数量
-------------------------------------------------
--设置
function UnionPkData.setUnionWarHintNum(v)
	_unionWarHintNum = v
end
--读取
function UnionPkData.getUnionWarHintNum()
	return _unionWarHintNum
end

-------------------------------------------------
-- 军团总战力
-------------------------------------------------
--设置
function UnionPkData.setUnionTotalFightCapacity(v)
	_unionTotalFightCapacity = v
end
--读取
function UnionPkData.getUnionTotalFightCapacity()
	return _unionTotalFightCapacity
end