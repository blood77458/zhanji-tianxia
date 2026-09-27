--
-- SeckillBuyRequest.lua
-- Author: zheng.che
-- Date: 2014-04-23 17:18:40
-- 购买限时秒杀物品接口
--
require "canon.request.BaseRequest"

SeckillBuyRequest = class(BaseRequest)

function SeckillBuyRequest:ctor()
  self.endpoint = "buySeckillItem"--<<<<< 1. 修改指令名称 后端提供
end

function SeckillBuyRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.SeckillBuySucceed, data))--<<<<< 2. 修改枚举名称 定义在BaseRequest里 不能重复
end

function SeckillBuyRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.SeckillBuyFailed, {retCode = error}))--<<<<< 2
end

-------------------------------------------------------------------静态函数

function SeckillBuyRequest.sendRequest(aData, succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
	local function onSucceedHandle(event)
		if succeedCallback then
			succeedCallback(aData, event)--<<<<< 3
		end
	end 
	local function onFailedHandle(event)
		if failedCallback then
			failedCallback(aData, event)
		end
	end
	local params = {id = aData.id}--<<<<< 3
	--print("params = " .. table.tostring(params))
	local request = SeckillBuyRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.SeckillBuySucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.SeckillBuyFailed, onFailedHandle)--<<<<< 2
	request:start()
end

--成功的默认处理
function SeckillBuyRequest.onSucceedDefault(aData, event)--<<<<< 3
	--print("onSucceedDefault! event = " .. table.tostring(event))

	--购买数增加
	Activity_SeckillLayer.addRealBroughtNum(aData.id)--物品被买次数+1
	Activity_SeckillLayer.addTodayMyBroughtTimes(aData.id)--自己已购买次数+1

	--获得奖励
	RewardManager:getReward(event.data.rewards)

	--去掉消耗
    if aData.coinType == 1 then
      --银币
      RewardManager:getReward({{itemType = ResourceEnum.COIN, amount = (-aData.presentPrice or 0)}})
    else
      --金币
      RewardManager:getReward({{itemType = ResourceEnum.GEMS, amount = (-aData.presentPrice or 0)}})
    end

    --显示获得的奖励
    local scene = Director:mgr():run()
	local aRewardPanel = RewardReviewPanel:create( scene, {rewardList = event.data.rewards, rewardTitle = Localization:getInstance():getText("activity_newyear_rewardTitle")} )
	scene:addChild(aRewardPanel)
	aRewardPanel:scaleIn()
end

--失败默认处理
function SeckillBuyRequest.onFailedDefault(aData, event)--<<<<< 4. 修改错误码对应逻辑处理
	--print("onFailedDefault!")
	local errorCode = tonumber(event.data.retCode)
	if(errorCode == 710513) then -- 金币不足
		local scene = Director:mgr():run()
		local aPanel = AssistantMessageBoxPanel:create(scene, AsMessageBoxType.addCoin, nil)
		scene:addChild(aPanel)
		aPanel:scaleIn()
	elseif(errorCode == 710512) then -- 银币不足
		local scene = Director:mgr():run()
		local aPanel = MessageBoxPanel:create(scene, MessageBoxType.kCoinLimit)
		scene:addChild(aPanel)
		aPanel:scaleIn()
	elseif(errorCode == 710516) then -- 背包满
		NewPackageFullPanel:show()
		-- CanonMessageBox:Show(Localization:getInstance():getText("shop_inventoryFull"), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, nil, nil)
	elseif(errorCode == 714600) then
		CanonMessageBox:showCommErrorBox(CommErrorCodes.ACTIVITY_SECKILL_CLOSE, nil, nil, nil)
	elseif(errorCode == 714603) then
		CanonMessageBox:showCommErrorBox(CommErrorCodes.ACTIVITY_SECKILL_USER_PURCHASE_LIMIT, nil, nil, nil)
	elseif(errorCode == 714604) then
		CanonMessageBox:showCommErrorBox(CommErrorCodes.ACTIVITY_SECKILL_ITEM_SOLD_OUT, nil, nil, nil)
		--提示同时设置已完售
		Activity_SeckillLayer.setSoldOut(aData.id)
	elseif(errorCode == 714605) then
		CanonMessageBox:showCommErrorBox(CommErrorCodes.ACTIVITY_SECKILL_ITEM_NOT_IN_TIME, nil, nil, nil)
	else
		CanonMessageBox:showCommUnHandleErrorBox(errorCode)
	end
-- ACTIVITY_SECKILL_CLOSE(4600, "Activity seckill close: {0:uid}"),
-- ACTIVITY_SECKILL_ITEM_NOT_CONFIG(4601, "Activity seckill item is not configed: {0:uid}, {1:id}"),
-- ACTIVITY_SECKILL_CURRENCY_TYPE_NOT_SUPPORT(4602, "Activity seckill currency type not support: {0:uid}, {1:type}"),
-- ACTIVITY_SECKILL_USER_PURCHASE_LIMIT(4603, "Activity seckill user purchase limit: {0:uid}, {1:id}, {2:buyNum}"),
-- ACTIVITY_SECKILL_ITEM_SOLD_OUT(4604, "Activity seckill item sold out: {0:uid}, {1:uid}, {2:buyNum}"),
-- ACTIVITY_SECKILL_ITEM_NOT_IN_TIME(4605, "Activity seckill item not in time: {0:uid}, {1:id}"),

end