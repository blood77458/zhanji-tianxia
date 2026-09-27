-- CardOldToNewExchangeRequest.lua
-- 2014-11-13
-- zheng.che
-- 卡牌以旧换新兑换请求

require "canon.request.BaseRequest"

CardOldToNewExchangeRequest = class(BaseRequest)

function CardOldToNewExchangeRequest:ctor()
  self.endpoint = "exchangeCard"--<<<<< 1. 修改指令名称 后端提供
  self.succeedEventName = self.endpoint .. "Succeed"
  self.failedEventName = self.endpoint .. "Failed"
end

function CardOldToNewExchangeRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(self.succeedEventName, data))
end

function CardOldToNewExchangeRequest:onError( error )
  self:dispatchEvent(Event.new(self.failedEventName, {retCode = error}))
end

-------------------------------------------------------------------静态函数

--发送请求 默认处理 成功返回之后可加额外处理(参数可传nil)
-- shopId 目标数据编号
-- cardIds 材料卡牌id列表
-- needEssence 所需星灵数 *扣星灵用
function CardOldToNewExchangeRequest.sendRequestDefalut(shopId, cardIds, needEssence, afterSucceedCallback)--<<<<< 3
	local function onSucceed(evt)
		CardOldToNewExchangeRequest.onSucceedDefault(evt)
		if afterSucceedCallback then
			afterSucceedCallback(evt)
		end
	end
	CardOldToNewExchangeRequest.sendRequest(shopId, cardIds, needEssence, onSucceed, CardOldToNewExchangeRequest.onFailedDefault)
end

--发送请求
function CardOldToNewExchangeRequest.sendRequest(shopId, cardIds, needEssence, succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
	local params = {shopId = shopId, cardId = cardIds}--<<<<< 3

	local function onSucceedHandle(event)
		if succeedCallback then
			event.params = params
			event.needEssence = needEssence
			succeedCallback(event)
		end
	end 
	local function onFailedHandle(event)
		if failedCallback then
			event.params = params
			failedCallback(event)
		end
	end
	if SystemManager.debug then
		print("params = " .. table.tostring(params))
	end
	local request = CardOldToNewExchangeRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(request.succeedEventName, onSucceedHandle)
	request:addEventListener(request.failedEventName, onFailedHandle)
	request:start()
end

--成功的默认处理
function CardOldToNewExchangeRequest.onSucceedDefault(event)--<<<<< 3
	if SystemManager.debug then
		print("onSucceedDefault! event = " .. table.tostring(event))
	end

	--兑换数量+1
	Activity_CardOldToNewLayer.addCurrentExchangeNum(event.params.shopId)

	--去掉消耗 星灵
	RewardManager:getReward({{itemType = ResourceEnum.ASTRALESSENCE, amount = (-event.needEssence or 0)}})
	--去掉消耗 卡牌
	RewardManager:removeCards(event.params.cardId)

	--获得奖励
	RewardManager:getReward(event.data.reward)
end

--失败默认处理
function CardOldToNewExchangeRequest.onFailedDefault(event)--<<<<< 4. 修改错误码对应逻辑处理
	local errorCode = tonumber(event.data.retCode)
	local function onErrorConfirm(errorCode)
		if errorCode == 714700 then
			local scene = Director:mgr():run()
			scene:replaceScene(MainMenuScene)
		end
	end
	local ret = ErrorCodeManager.alert(errorCode, onErrorConfirm)
end