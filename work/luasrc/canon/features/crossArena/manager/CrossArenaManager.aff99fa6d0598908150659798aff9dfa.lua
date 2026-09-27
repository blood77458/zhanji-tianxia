require "hecore.display.CocosObject"
CrossArenaManager = {}

CrossPVP_Stage = {
	Battle = 1,
	Reward = 2,
}
--我的排名
local _myRank = 0
--我的天梯积分
local _myBattleScore = 0
--我的活跃积分
local _myActiveScore = 0

--显示的排名列表
local _showRanks = {}
--领奖阶段前三名信息列表
local _top3Ranks = {}
--排名奖 领奖状态(0-不可领奖;1-可以领奖;2-已领奖)
local _rankRewardStatus = 0
--冠军奖 领奖状态(0-不可领奖;1-可以领奖;2-已领奖)
local _serverRewardStatus = 0

--显示战报列表
local _reportList = {}

--倒计时时间戳
local _freeRefreshTimestamp = 0
--匹配列表
local _matchList = {}

--战报相关
CrossArenaManager._lastString = nil
CrossArenaManager._lastPosX = 0
CrossArenaManager._startTimeInArena = false
CrossArenaManager._durationInArena = -1    --used for showing report
CrossArenaManager._shouldStayInArena = false
--战报
local crossPVP_broadcast_cache_max = 30
CrossArenaManager._crossPVPReports = {}

function CrossArenaManager.getCrossArenaSetting()
	return DataManager.GameMetaData.crossArenaSettingConfig or {}
end

function CrossArenaManager.getVersion()
	local crossArenaSetting = CrossArenaManager.getCrossArenaSetting()
	local featureNameBattle = MaintenanceManager:getStartAndEndTime(crossArenaSetting.featureNameBattle)
	-- local activityDuring = MaintenanceManager:getActivityDuring( crossArenaSetting.featureNameBattle )

	local currentTime = TimeUtil.getServerTimeSeconds()
	local version = math.modf((currentTime - featureNameBattle[1].activityBeginTimeStamp) / 1209600) + 1
	
	return version
end

function CrossArenaManager.checkPVPIsOpen()
	local crossArenaSetting = CrossArenaManager.getCrossArenaSetting()
	local featureNameBattle = MaintenanceManager:getStartAndEndTime(crossArenaSetting.featureNameBattle)
	local currentTime = TimeUtil.getServerTimeSeconds()
	local isOpen
	if currentTime >= featureNameBattle[1].activityBeginTimeStamp then
		isOpen = true
	else
		isOpen = false
	end
	if isOpen then
		gameInitData = DataManager.getGameInitData()
		return gameInitData.crossPvpActivityStatus
	else
		return false
	end
end

function CrossArenaManager.getBattleBeginTime()
	local version = CrossArenaManager.getVersion()
	local crossArenaSetting = CrossArenaManager.getCrossArenaSetting()
	local featureNameBattle = MaintenanceManager:getStartAndEndTime(crossArenaSetting.featureNameBattle)
	local oepn = MaintenanceManager:getActivityOpen( crossArenaSetting.featureNameBattle )
	local activityDuring = MaintenanceManager:getActivityDuring( crossArenaSetting.featureNameBattle )

	return featureNameBattle[1].activityBeginTimeStamp + (version -1) * 1209600 + oepn
end

function CrossArenaManager.getBattleEndTime()
	local version = CrossArenaManager.getVersion()
	local crossArenaSetting = CrossArenaManager.getCrossArenaSetting()
	local featureNameBattle = MaintenanceManager:getStartAndEndTime(crossArenaSetting.featureNameBattle)
	local oepn = MaintenanceManager:getActivityOpen( crossArenaSetting.featureNameBattle )
	local activityDuring = MaintenanceManager:getActivityDuring( crossArenaSetting.featureNameBattle )

	return featureNameBattle[1].activityBeginTimeStamp + activityDuring * 60 + (version -1) * 1209600 + oepn
end

function CrossArenaManager.getRewardEndTime()
	local version = CrossArenaManager.getVersion()
	local crossArenaSetting = CrossArenaManager.getCrossArenaSetting()
	local featureNameReward = MaintenanceManager:getStartAndEndTime(crossArenaSetting.featureNameReward)
	local oepn = MaintenanceManager:getActivityOpen( crossArenaSetting.featureNameReward )
	local activityDuring = MaintenanceManager:getActivityDuring( crossArenaSetting.featureNameReward )

	return featureNameReward[1].activityBeginTimeStamp  + (4*24*60*60)  + (version -1) * 1209600
end

function CrossArenaManager.getCurrentStage()
	local currentTime = TimeUtil.getServerTimeSeconds()
	local battleEndTime = CrossArenaManager.getBattleEndTime()
	if currentTime <= battleEndTime then
		return CrossPVP_Stage.Battle
	else
		return CrossPVP_Stage.Reward
	end
end

--获取剩余的挑战次数
function CrossArenaManager.getLastChangllengeNum()
	local crossArenaSetting = CrossArenaManager.getCrossArenaSetting()
	local pvpDailyInfo = DailyDataManager.getCrossPvpDailyData()
	local lastChallengeTimes = crossArenaSetting.freeBattleNum - pvpDailyInfo.crossPvpTimes + pvpDailyInfo.crossPvpBuyTimes
	return lastChallengeTimes
end

-- 获得奖励配置
function CrossArenaManager.getRewardConfig()
	--print("DataManager.GameMetaData.crossArenaRewardConfig = " .. tostringRich(DataManager.GameMetaData.crossArenaRewardConfig))
	return DataManager.GameMetaData.crossArenaRewardConfig or {}
end

-- 天梯排名奖励
function CrossArenaManager.getBattleRewards()
	return CrossArenaManager.getRewardConfig().battleRewards or {}
end











--天梯积分
function CrossArenaManager.getMyBattleScore()
	return _myBattleScore
end

function CrossArenaManager.setMyBattleScore( v )
	_myBattleScore = v
end
--排名
function CrossArenaManager.getMyRank()
	return _myRank
end

function CrossArenaManager.setMyRank( v )
	_myRank = v
end

--活跃积分
function CrossArenaManager.getMyActiveScore()
	return DataManager.getGameInitData().sharkDailyData and DataManager.getGameInitData().sharkDailyData.crossPvpDailyData
		and DataManager.getGameInitData().sharkDailyData.crossPvpDailyData.activeScore or 0
	--return _myActiveScore
end

function CrossArenaManager.setMyActiveScore( v )
	local gameData = DataManager.getGameInitData()
	if not gameData.sharkDailyData then gameData.sharkDailyData = {} end
	if not gameData.sharkDailyData.crossPvpDailyData then gameData.sharkDailyData.crossPvpDailyData = {} end
	gameData.sharkDailyData.crossPvpDailyData.activeScore = v
	DataManager.setGameInitData(gameData)
	--_myActiveScore = v
end

--已领活跃积分奖励信息
function CrossArenaManager.getMyActiveRewards()
	return DailyDataManager.getCrossPvpDailyData().activeRewards
	-- return DataManager.getGameInitData().sharkDailyData and DataManager.getGameInitData().sharkDailyData.crossPvpDailyData
	-- 	and DataManager.getGameInitData().sharkDailyData.crossPvpDailyData.activeRewards or {}
	--return _myActiveScore
end

function CrossArenaManager.setMyActiveRewards( arr )
	if type(arr) ~= "table" then return end
	local pvpDailyInfo = DailyDataManager.getCrossPvpDailyData()
    pvpDailyInfo.activeRewards = arr
    DailyDataManager.setCrossPvpDailyData(pvpDailyInfo)
	-- local gameData = DataManager.getGameInitData()
	-- if not gameData.sharkDailyData then gameData.sharkDailyData = {} end
	-- if not gameData.sharkDailyData.crossPvpDailyData then gameData.sharkDailyData.crossPvpDailyData = {} end
	-- gameData.sharkDailyData.crossPvpDailyData.activeRewards = arr
	-- DataManager.setGameInitData(gameData)
	--_myActiveScore = v
end

--显示排名
function CrossArenaManager.getShowRanks()
	return _showRanks
end

function CrossArenaManager.setShowRanks( v )
	_showRanks = v
end

--前三名排名
function CrossArenaManager.getTop3Ranks()
	return _top3Ranks
end

function CrossArenaManager.setTop3Ranks( v )
	_top3Ranks = v
end

--能否领取 战斗排名奖
function CrossArenaManager.canGainRankReward()
	return _rankRewardStatus ~= CrossArenaConsts.REWARD_STATE_NONE
end

--是否已领 战斗排名奖
function CrossArenaManager.isGainedRankReward()
	return _rankRewardStatus == CrossArenaConsts.REWARD_STATE_GAINED
end

--设置排名奖状态
function CrossArenaManager.setRankRewardStatus( v )
	_rankRewardStatus = v
end

--能否领取 冠军奖
function CrossArenaManager.canGainServerReward()
	return _serverRewardStatus ~= CrossArenaConsts.REWARD_STATE_NONE
end

--是否已领 冠军奖
function CrossArenaManager.isGainedServerReward()
	return _serverRewardStatus == CrossArenaConsts.REWARD_STATE_GAINED
end

--设置冠军奖状态
function CrossArenaManager.setServerRewardStatus( v )
	_serverRewardStatus = v
end

--战报信息
function CrossArenaManager.getReportList()
	return _reportList
end

function CrossArenaManager.setReportList( v )
	_reportList = v
end

--匹配信息
function CrossArenaManager.getMatchList()
	return _matchList
end

function CrossArenaManager.setMatchList( v )
	_matchList = v
end

--上次刷新时间戳
function CrossArenaManager.getFreeRefreshTimestamp()
	return _freeRefreshTimestamp
end

function CrossArenaManager.setFreeRefreshTimestamp( v )
	_freeRefreshTimestamp = v
end

function CrossArenaManager:getLastString()
	return _lastString
end

function CrossArenaManager:setLastString(v)
	_lastString = v
end

function CrossArenaManager:getLastPosX()
	return _lastPosX
end

function CrossArenaManager:setLastPosX(v)
	_lastPosX = v
end

function CrossArenaManager:getStartTimeInArena()
	return _startTimeInArena
end

function CrossArenaManager:setStartTimeInArena(v)
	_startTimeInArena = v
end

function CrossArenaManager:getDurationInArena()
	return _durationInArena
end

function CrossArenaManager:setDurationInArena(v)
	_durationInArena = v
end

function CrossArenaManager:getShouldStayInArena()
	return _shouldStayInArena
end

function CrossArenaManager:setShouldStayInArena(v)
	_shouldStayInArena = v
end

function CrossArenaManager.receiveNewReport(aReport)
  table.insert(CrossArenaManager._crossPVPReports, aReport)
  if #CrossArenaManager._crossPVPReports > crossPVP_broadcast_cache_max then
    table.remove(CrossArenaManager._crossPVPReports, 1)
  end
  if _shouldStayInArena then
    table.remove(CrossArenaManager._crossPVPReports, 1)
    _shouldStayInArena = false
  end
end

--弹出一条战报
function CrossArenaManager.popoutReport()
	local _json = require("cjson")
  --
  local aReport
  if #CrossArenaManager._crossPVPReports == 1 then
    aReport = CrossArenaManager._crossPVPReports[1]
    _shouldStayInArena = true
  else
    aReport = table.remove(CrossArenaManager._crossPVPReports, 1)
    _shouldStayInArena = false
  end
  
  local result
  if aReport.type == 29 then
  	--排名进入前N
  	local aList = _json.decode(aReport.content)
  	result = getTextByKey("crossArena_talk2" , {num1 = aList.serverId , num2 = aReport.userName , num3 = aList.topRank , num4 = aList.pvpRank})
  elseif aReport.type == 30 then
  	--连胜
  	local aList = _json.decode(aReport.content)
  	if aList.battleConinuousWins == 3 then
  		result = getTextByKey("crossArena_talk3" , {num1 = aList.serverId, num2 = aReport.userName	})
	elseif aList.battleConinuousWins == 5 then
		result = getTextByKey("crossArena_talk4" , {num1 = aList.serverId, num2 = aReport.userName	})
	elseif aList.battleConinuousWins == 10 then
		result = getTextByKey("crossArena_talk5" , {num1 = aList.serverId, num2 = aReport.userName	})
  	end
  end
  return result
end