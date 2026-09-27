--------------------------------------------------------------------------------
-- DailyDataManager.lua -- 每日数据本地获取、存取、清理的Manager
-- author: Jiang Yize
-- date: 2013-11-04
--------------------------------------------------------------------------------
require "canon.data.DataManager"
require "canon.utils.TimeUtil"

DailyDataManager = {}

local init = false;
function DailyDataManager.init()
  local _dailyData = DataManager.getGameInitData().sharkDailyData or {}

  if not DataManager.getGameInitData().sharkDailyDataExtend or not DataManager.getGameInitData().sharkDailyDataExtend.treasureSacrificeTimes then
    _dailyData.treasureSacrificeTimes = 0
  else
    _dailyData.treasureSacrificeTimes = DataManager.getGameInitData().sharkDailyDataExtend.treasureSacrificeTimes
  end

  if not DataManager.getGameInitData().sharkDailyDataExtend or not DataManager.getGameInitData().sharkDailyDataExtend.mysteriousChallengeTimes then
    _dailyData.mysteriousChallengeTimes = {}
  else
    _dailyData.mysteriousChallengeTimes = DataManager.getGameInitData().sharkDailyDataExtend.mysteriousChallengeTimes
  end

  if not DataManager.getGameInitData().sharkDailyDataExtend or not DataManager.getGameInitData().sharkDailyDataExtend.mysteriousExchangeTimes then
    _dailyData.mysteriousExchangeTimes = {}
  else
    _dailyData.mysteriousExchangeTimes = DataManager.getGameInitData().sharkDailyDataExtend.mysteriousExchangeTimes
  end
  
  local whetherPassDay = false
  if _dailyData._date then
    if TimeUtil.getPasseddDaysToNow(_dailyData._date) > 0 then
      whetherPassDay = true
    end
  end
  if(not _dailyData._date or whetherPassDay) then 
    _dailyData._date = TimeUtil.getServerTimeSeconds()
    DailyDataManager.setDailyData(_dailyData)
  end
  init = true
end

function DailyDataManager.getDailyData()
  if(not init) then
    DailyDataManager.init()
  end
  
  local _dailyData = DataManager.getGameInitData().sharkDailyData
  
  local whetherPassDay = false
  if _dailyData and _dailyData._date then
    if TimeUtil.getPasseddDaysToNow(_dailyData._date) > 0 then
      whetherPassDay = true
    end
  end
  if(not _dailyData or not _dailyData._date or whetherPassDay) then
    _dailyData= {}
    _dailyData._date = TimeUtil.getServerTimeSeconds()
    DailyDataManager.setDailyData(_dailyData)
  end
  
  return _dailyData
end

function DailyDataManager.setDailyData(dailyData)
  local gameInitData = DataManager.getGameInitData()
  gameInitData.sharkDailyData = dailyData or {}
  
  DataManager.setGameInitData(gameInitData)
end

function DailyDataManager.getEnergyBoughtNum()
  local dailyData = DailyDataManager.getDailyData()
  return dailyData.energyBoughtNum or 0
end

function DailyDataManager.setEnergyBoughtNum(energyBoughtNum)
  local dailyData = DailyDataManager.getDailyData()
  dailyData.energyBoughtNum = energyBoughtNum
  
  DailyDataManager.setDailyData(dailyData)
end

function DailyDataManager.getEventPointBoughtNum()
  local dailyData = DailyDataManager.getDailyData()
  return dailyData.eventPointBoughtNum or 0
end

function DailyDataManager.setEventPointBoughtNum(eventPointBoughtNum)
  local dailyData = DailyDataManager.getDailyData()
  dailyData.eventPointBoughtNum = eventPointBoughtNum
  
  DailyDataManager.setDailyData(dailyData)
end

function DailyDataManager.getDailyLimitGoodsData()
	local dailyData = DailyDataManager.getDailyData()
	return dailyData.dailyLimitGoods or {}
end

function DailyDataManager.setDailyLimitGoodsData(data)
	local dailyData = DailyDataManager.getDailyData()
	dailyData.dailyLimitGoods = data
	DailyDataManager.setDailyData(dailyData)
end

function DailyDataManager.getResetMissionNum()
	local dailyData = DailyDataManager.getDailyData()
	return dailyData.resetMissionNum or 0
end

function DailyDataManager.setResetMissionNum(resetMissionNum)
	local dailyData = DailyDataManager.getDailyData()
	dailyData.resetMissionNum = resetMissionNum
	DailyDataManager.setDailyData(dailyData)
end

function DailyDataManager.getFightFriendUids()
	local dailyData = DailyDataManager.getDailyData()
  
	return dailyData.fightFriendUids or {}
end

function DailyDataManager.setFightFriendUids(fightFriendUids)
  local dailyData = DailyDataManager.getDailyData()
  dailyData.fightFriendUids = fightFriendUids
  
  DailyDataManager.setDailyData(dailyData)
end

function DailyDataManager.getResetEliteNum()
	local dailyData = DailyDataManager.getDailyData()
  
	return dailyData.resetEliteNum or 0
end

function DailyDataManager.incrResetEliteNum(value)
  if(not value) then
    return
  end
  
  local dailyData = DailyDataManager.getDailyData()
  local resetEliteNum = dailyData.resetEliteNum
  if(not resetEliteNum) then
    resetEliteNum = value
  else
    resetEliteNum = resetEliteNum + value
  end
  dailyData.resetEliteNum = resetEliteNum 
  
  DailyDataManager.setDailyData(dailyData)
end

function DailyDataManager.getDailyDataFortuneNum()
  local dailyData = DailyDataManager.getDailyData()
  return dailyData.fortuneNum or 0
end

function DailyDataManager.setDailyDataFortuneNum(aFortuneNum)
  local dailyData = DailyDataManager.getDailyData()
  dailyData.fortuneNum = aFortuneNum
  
  DailyDataManager.setDailyData(dailyData)
end

function DailyDataManager.getDailyDataPrayNum()
  local dailyData = DailyDataManager.getDailyData()
  return dailyData.prayNum or 0
end

function DailyDataManager.setDailyDataPrayNum(aPrayNum)
  local dailyData = DailyDataManager.getDailyData()
  dailyData.prayNum = aPrayNum
  
  DailyDataManager.setDailyData(dailyData)
end

function DailyDataManager.getLstCowStageInfo()
  local dailyData = DailyDataManager.getDailyData()
  return dailyData.lstCowStageInfo or {}
end

function DailyDataManager.setLstCowStageInfo(aCowStageInfo)
  local dailyData = DailyDataManager.getDailyData()
  dailyData.lstCowStageInfo = aCowStageInfo
  
  DailyDataManager.setDailyData(dailyData)
end

function DailyDataManager.getPkBuffStatus()
  local dailyData = DailyDataManager.getDailyData()
  return dailyData.pkBuffStatus or false
end

function DailyDataManager.setPkBuffStatus(pkBuffStatus)
  local dailyData = DailyDataManager.getDailyData()
  dailyData.pkBuffStatus = pkBuffStatus

  DailyDataManager.setDailyData(dailyData)
end

function DailyDataManager.getPkBuffNum()
  local dailyData = DailyDataManager.getDailyData()
  return dailyData.pkBuffNum or 0
end

function DailyDataManager.setPkBuffNum(pkBuffNum)
  local dailyData = DailyDataManager.getDailyData()
  dailyData.pkBuffNum = pkBuffNum

  DailyDataManager.setDailyData(dailyData)
end

function DailyDataManager.getDailyDataUnionNormalProps()
  local dailyData = DailyDataManager.getDailyData()
  return dailyData.unionNormalPropsDailyLimit or {}
end

function DailyDataManager.setDailyDataUnionNormalProps(aUnionNormalProps)
  local dailyData = DailyDataManager.getDailyData()
  dailyData.unionNormalPropsDailyLimit = aUnionNormalProps
  
  DailyDataManager.setDailyData(dailyData)
end

function DailyDataManager.getDailyDataReceivedWage()
  local dailyData = DailyDataManager.getDailyData()
  return dailyData.receivedWage or false
end

function DailyDataManager.setDailyDataReceivedWage(aReceivedWage)
  local dailyData = DailyDataManager.getDailyData()
  dailyData.receivedWage = aReceivedWage
  
  DailyDataManager.setDailyData(dailyData)
end

function DailyDataManager.getWorldMessageNum()
  local dailyData = DailyDataManager.getDailyData()
  return dailyData.worldMessageNum or 0
end

function DailyDataManager.setWorldMessageNum(aNum)
  local dailyData = DailyDataManager.getDailyData()
  dailyData.worldMessageNum = aNum
  
  DailyDataManager.setDailyData(dailyData)
end

function DailyDataManager.getSharkUserContend()
  local dailyData = DailyDataManager.getDailyData()
  local sharkUserContend = dailyData.sharkUserContend or {}
  sharkUserContend.contendInfo = sharkUserContend.contendInfo or {}
  return sharkUserContend
end

function DailyDataManager.setSharkUserContend(aSharkUserContend)
  local dailyData = DailyDataManager.getDailyData()
  dailyData.sharkUserContend = aSharkUserContend
  
  DailyDataManager.setDailyData(dailyData)
end

--获得周末秒杀活动当天购买信息
function DailyDataManager.getDailyDataSeckillLimitGoods()
  local dailyData = DailyDataManager.getDailyData()
  return dailyData.seckillDailyLimitGoods or {}
end

--设置周末秒杀活动当天购买信息
function DailyDataManager.setDailyDataSeckillLimitGoods(v)
  local dailyData = DailyDataManager.getDailyData()
  dailyData.seckillDailyLimitGoods = v
  
  DailyDataManager.setDailyData(dailyData)
end

--获得军团斗兽场今日挑战次数
function DailyDataManager.getChallengeUnionMonsterTimes()
  local dailyData = DailyDataManager.getDailyData()
  return dailyData.challengeUnionMonsterTimes or 0
end

--设置周末秒杀活动当天购买信息
function DailyDataManager.setChallengeUnionMonsterTimes(v)
  local dailyData = DailyDataManager.getDailyData()
  dailyData.challengeUnionMonsterTimes = v
  
  DailyDataManager.setDailyData(dailyData)
end

--
--获得免费凝神次数
function DailyDataManager.getDailyDataSpiritConcentrateNum()
  local dailyData = DailyDataManager.getDailyData()
  return dailyData.spiritConcentrateNum or 0
end

--设置免费凝神次数
function DailyDataManager.setDailyDataSpiritConcentrateNum(v)
  local dailyData = DailyDataManager.getDailyData()
  dailyData.spiritConcentrateNum = v
  
  DailyDataManager.setDailyData(dailyData)
end

--获得vip凝神次数
function DailyDataManager.getDailyDataSpiritConcentrateVipNum()
  local dailyData = DailyDataManager.getDailyData()
  return dailyData.spiritConcentrateVipNum or 0
end

--设置vip凝神次数
function DailyDataManager.setDailyDataSpiritConcentrateVipNum(v)
  local dailyData = DailyDataManager.getDailyData()
  dailyData.spiritConcentrateVipNum = v
  
  DailyDataManager.setDailyData(dailyData)
end

--获得投放马数据
function DailyDataManager.getWantedActivityData()
  local dailyData = DailyDataManager.getDailyData()
  return dailyData.wantedInfo or {refresh = false , wantedConfigId = 1 , wanteds = 0 , fake = true}
end

--设置投放马数据
function DailyDataManager.setWantedActivityData(v)
  local dailyData = DailyDataManager.getDailyData()
  dailyData.wantedInfo = v
  
  DailyDataManager.setDailyData(dailyData)
end
--获得军团战 每日奖励领取状态
function DailyDataManager.getDailyDataGainUnionWarDailyReward()
  local dailyData = DailyDataManager.getDailyData()
  return dailyData.gainUnionWarDailyReward or false
end

--设置军团战 每日奖励领取状态
function DailyDataManager.setDailyDataGainUnionWarDailyReward(v)
  local dailyData = DailyDataManager.getDailyData()
  dailyData.gainUnionWarDailyReward = v
  
  DailyDataManager.setDailyData(dailyData)
end

--获得跨服boss当日挑战总次数
function DailyDataManager.getCrossBossTimes()
  local dailyData = DailyDataManager.getDailyData()
  return dailyData.crossBossTimes or 0
end

--设置跨服boss当日挑战总次数
function DailyDataManager.setCrossBossTimes(v)
  local dailyData = DailyDataManager.getDailyData()
  dailyData.crossBossTimes = v
  
  DailyDataManager.setDailyData(dailyData)
end

--------------------------------------------------------
-- 今日许愿次数
--------------------------------------------------------

--获得
function DailyDataManager.getWishings()
  local dailyData = DailyDataManager.getDailyData()
  return dailyData.wishings or 0
end

--设置
function DailyDataManager.setWishings(v)
  local dailyData = DailyDataManager.getDailyData()
  dailyData.wishings = v
  
  DailyDataManager.setDailyData(dailyData)
end


--------------------------------------------------------
-- 跨服pvp
--------------------------------------------------------

--获得
function DailyDataManager.getCrossPvpDailyData()
  local dailyData = DailyDataManager.getDailyData()
  if SystemManager.debug then
    print("dailyData.crossPvpDailyData = " .. tostringRich(dailyData.crossPvpDailyData))
  end
  return dailyData.crossPvpDailyData or {crossPvpTimes = 0 ,crossPvpBuyTimes = 0, crossPvpRefreshTimes = 0, activeScore = 0 , activeRewards={}}
end

--设置
function DailyDataManager.setCrossPvpDailyData(v)
  local dailyData = DailyDataManager.getDailyData()
  dailyData.crossPvpDailyData = v
  
  DailyDataManager.setDailyData(dailyData)
end

--------------------------------------------------------
-- 宝物祭恋
--------------------------------------------------------
--获得
function DailyDataManager.getTreasureSacrificeTimes()
  local dailyData = DailyDataManager.getDailyData()
  if SystemManager.debug then
    print("dailyData.crossPvpDailyData = " .. tostringRich(dailyData.crossPvpDailyData))
  end
  return dailyData.treasureSacrificeTimes or 0
end

--设置
function DailyDataManager.setTreasureSacrificeTimes(v)
  local dailyData = DailyDataManager.getDailyData()
  dailyData.treasureSacrificeTimes = v
  
  DailyDataManager.setDailyData(dailyData)
end


---------------------------------------------------------
--秘境
----------------------------------------------------
function DailyDataManager.getMysteriousChallengeTimes()
  local dailyData = DailyDataManager.getDailyData()

  return dailyData.mysteriousChallengeTimes or {}
end

--设置
function DailyDataManager.setMysteriousChallengeTimes(v)
  local dailyData = DailyDataManager.getDailyData()
  dailyData.mysteriousChallengeTimes = v
  
  DailyDataManager.setDailyData(dailyData)
end

function DailyDataManager.getMysteriousExchangeTimes()
  local dailyData = DailyDataManager.getDailyData()

  return dailyData.mysteriousExchangeTimes or {}
end

--设置
function DailyDataManager.setMysteriousExchangeTimes(v)
  local dailyData = DailyDataManager.getDailyData()
  dailyData.mysteriousExchangeTimes = v
  
  DailyDataManager.setDailyData(dailyData)
end