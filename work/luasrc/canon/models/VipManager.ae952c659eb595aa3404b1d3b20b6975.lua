--------------------------------------------------------------------------------
-- VipManager.lua - vip功能相关常量
-- author: xiaojie.bai
-- date: 2013-09-26 10:53
--------------------------------------------------------------------------------

require "canon.data.MetaManager"
require "canon.utils.StringUtil"

VipManager = class()

VipPrivEnum = {
    MediumGachaTen = 1, --中级扭蛋十连抽
    SeniorGachaTen = 2, --高级扭蛋10连抽
    MasterCardTraining = 3, --大师级培养
    SkipBattleAnimation = 4, --跳过战斗动画
    InstantClimbedBabel = 5, --立即完成自动爬塔
    BuyDailyLimitVipGoods = 6, --每日限购型VIP商品
    VipGiftPack = 7, --VIP礼包
    UseVipProp = 8, --使用VIP道具
    BuyEliteChallengeTimes = 9, --精英关卡增加每日次数
    MakeupMaterialInEquipEvolve = 10, --装备升阶补足材料
    MakeupMaterialInSkillUpgrade = 11 --技能升级补足材料
  }
  
function VipManager.getVipInfo(vipLevel)
  return MetaManager.vip_setting[vipLevel]
end

function VipManager.isOwnPriv(vipLevel, vipPrivEnum)
  local vipInfo = VipManager.getVipInfo(vipLevel)
  
  if(not vipInfo) then
    return false
  end
  
  local privArray = StringUtil.split(vipInfo.unlockContents, ",")
  for _, value in pairs(privArray) do
    if(tonumber(value) == vipPrivEnum) then
      return true
    end
  end
  
  return false
end


function VipManager.getStartUpVipLevel(vipPrivEnum)
--[[
	local vipInfo = MetaManager.vip_setting
  
	if(not vipInfo) then
		return 1
	end
	
	for i=1,100 do
		local vipSetting = vipInfo[i]
		if not vipSetting then
			return 1
		end
		
		local unlockString = vipSetting.unlockContents
		local privArray = StringUtil.split(unlockString, ",")
		for _, value in pairs(privArray) do
			if(tonumber(value) == vipPrivEnum) then
			  return i
			end
		end
	end
	  
	return 1
	--]]
	for i=1, 16 do
		if VipManager.isOwnPriv(i, vipPrivEnum) then
			return i
		end
	end
end

local function addDataById(id)
	local gameInitData = DataManager.getGameInitData()
	local sharkShop = gameInitData.sharkShop
	if sharkShop == nil then
		gameInitData.sharkShop = {loopPurchaseInfos = {}}
		sharkShop = {loopPurchaseInfos = {}}
		DataManager.setGameInitData(gameInitData)
	end
	local isFind = false
	for k,v in pairs(sharkShop.loopPurchaseInfos) do
		if v.shopMetaId == id then
			isFind = true
		end
	end
	if not isFind then
		local itemMeta = MetaManager.shop_meta[id]
		local beginTimeTable = string.split(itemMeta.loopLimitDateStart , '/')
		local beginTime = TimeUtil.toServerTimestamp({day=beginTimeTable[3], month=beginTimeTable[2],year=beginTimeTable[1], hour=0, min=0, sec=0}) 
		sharkShop.loopPurchaseInfos[#sharkShop.loopPurchaseInfos + 1] = {
			version = beginTime,
			shopMetaId = id,
			buyTimes  = 0,
			lastestBuySeconds = 0,
		}
		DataManager.setGameInitData(gameInitData)
	end
end

function VipManager.getRedPacketBuyTimes(id)
	addDataById(id)
	local gameInitData = DataManager.getGameInitData()
	local sharkShop = gameInitData.sharkShop
	-- if sharkShop == nil then
	-- 	local itemMeta = MetaManager.shop_meta[id]
	-- 	--如果从来没买过就填充数据
	-- 	gameInitData.sharkShop = {loopPurchaseInfos = {
	-- 		version = itemMeta.loopLimitDateStart,
	-- 		shopMetaId = id,
	-- 		buyTimes  = 0,
	-- 		lastestBuySeconds = 0,
	-- 	}}
	-- 	DataManager.setGameInitData(gameInitData)
	-- end
	local loopPurchaseInfos = sharkShop.loopPurchaseInfos

	local currentTime = TimeUtil.getServerTimeSeconds()

	for k,v in pairs(loopPurchaseInfos) do
		if id == v.shopMetaId then
			local refreshTimeDuringTable = string.split(MetaManager.shop_meta[id].loopLimitTime , '|')
			local refreshTimeDuring = refreshTimeDuringTable[1] * 24 * 3600 + refreshTimeDuringTable[2] * 3600 + refreshTimeDuringTable[3] * 60
			-- local beginTimeTable = string.split(v.version , '/')
			-- print(table.tostring(beginTimeTable))
			-- local beginTime = TimeUtil.toServerTimestamp({day=beginTimeTable[3], month=beginTimeTable[2],year=beginTimeTable[1], hour=0, min=0, sec=0}) 
			-- print(beginTime.."揍你！")
			local version1 = math.modf((currentTime - v.version) / refreshTimeDuring)
			local version2 = math.modf((v.lastestBuySeconds - v.version) / refreshTimeDuring)
			if version1 ~= version2 then
				loopPurchaseInfos[k].buyTimes = 0
				DataManager.setGameInitData(gameInitData)
			end
			return loopPurchaseInfos[k].buyTimes
		end
	end

	return 0 
end

function VipManager.getNextRefreshTime(id)
	addDataById(id)
	local gameInitData = DataManager.getGameInitData()
	local sharkShop = gameInitData.sharkShop
	local loopPurchaseInfos = sharkShop.loopPurchaseInfos
	local currentTime = TimeUtil.getServerTimeSeconds()


	for k,v in pairs(loopPurchaseInfos) do
		if id == v.shopMetaId then
			local refreshTimeDuringTable = string.split(MetaManager.shop_meta[id].loopLimitTime , '|')
			local refreshTimeDuring = refreshTimeDuringTable[1] * 24 * 3600 + refreshTimeDuringTable[2] * 3600 + refreshTimeDuringTable[3] * 60
			-- local beginTimeTable = string.split(v.version , '/')
			-- local beginTime = TimeUtil.toServerTimestamp({day=beginTimeTable[3], month=beginTimeTable[2],year=beginTimeTable[1], hour=0, min=0, sec=0})
			local endTime = v.version + refreshTimeDuring 
			if endTime > currentTime then
				return endTime
			end
			while true do
				endTime = endTime + refreshTimeDuring
				if endTime > currentTime then
					return endTime
				end
			end

		end
	end

	return 0 
end

function VipManager.addItemNum(id , num)
	num = num or 1
	local gameInitData = DataManager.getGameInitData()
	local sharkShop = gameInitData.sharkShop
	local loopPurchaseInfos = sharkShop.loopPurchaseInfos
	local currentTime = TimeUtil.getServerTimeSeconds()
	print(table.tostring(loopPurchaseInfos))
	for k,v in pairs(loopPurchaseInfos) do
		if id == v.shopMetaId then
			loopPurchaseInfos[k].buyTimes = loopPurchaseInfos[k].buyTimes + num
			loopPurchaseInfos[k].lastestBuySeconds = currentTime
		end
	end
	DataManager.setGameInitData(gameInitData)
end