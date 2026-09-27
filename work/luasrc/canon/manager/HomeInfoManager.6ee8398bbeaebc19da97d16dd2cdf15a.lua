--------------------------------------------------------------------------------
-- HomeInfoManager.lua -- 主页信息管理器
-- author: Jiang Yize
-- date: 2013-12-20
--------------------------------------------------------------------------------
require "canon.data.MetaManager"

HomeInfoManager = {}

-- 获取指定GachaId的上次免费扭蛋时间
local function getLastFreeTime(gachaId)
  local gameInitData = DataManager.getGameInitData()
  local sharkUserExtend = gameInitData["sharkUserExtend"]
  if not sharkUserExtend then
    return nil
  end
  
  local freeGachaInfos = gameInitData["sharkUserExtend"].countdownFreeGachaInfos
  if not freeGachaInfos then
    return nil
  end
  
  for k,v in ipairs(freeGachaInfos) do
    if tonumber(v.gachaNodeId) == tonumber(gachaId) then
      return tonumber(v.latestFreeGachaTime)
    end
  end
  
  return nil
end

-- 获取指定GachaId是否可以免费扭蛋
local function canFreeGacha(gachaId, needTime)
  if gachaId == 4 and not MaintenanceManager.isActivityOpen("activityGacha1") then
    return false
  end

  local lastFreeTime = getLastFreeTime(gachaId)
  if not lastFreeTime then
    return true
  end
  
  local nextFreeTime = lastFreeTime + needTime
  local serverTime = TimeUtil.getServerTimeSeconds()
  local diffTime = serverTime - nextFreeTime
  if diffTime >= 0 then
    return true
  end
  
  return false  
end

-- 获取免费扭蛋状态
-- 返回当前是否可以免费扭蛋的种类数
function HomeInfoManager.getFreeGachaStatus()
  local freeNum = 0
  for k, v in pairs(MetaManager.gacha_card) do
    if(v.countdownFree and canFreeGacha(v.id, v.countdownDuration)) then
      freeNum = freeNum + 1
    end
  end
  return freeNum
end

-- 判断是否领取过充值奖励
local function gainedChargeReward(rewardId, chargeRewards)
  for k, v in pairs(chargeRewards) do
    if tonumber(v) == tonumber(rewardId) then
      return true
    end
  end
  return false
end

-- 获取充值奖励状态
-- 返回玩家是否充值、充值后是否有未领取的奖励
function HomeInfoManager.getChargeRewardStatus()
  local gameInitData = DataManager.getGameInitData()
  local sharkUser = gameInitData["sharkUser"]
  local sharkUserExtend = gameInitData["sharkUserExtend"]
  local chargeRewards = {}
  if sharkUserExtend.gainedChargeMoneyRewardList then
    chargeRewards = sharkUserExtend.gainedChargeMoneyRewardList
  end
  
  local rewardId = -1
  local rechargeGems = sharkUser.rechargeGems

  for k, v in pairs(MetaManager.charge_money_reward) do
    if tonumber(rechargeGems) >= tonumber(v.requireGold) then
      if not gainedChargeReward(v.id, chargeRewards) then
        return true
      end
    end
  end

  return false
end
