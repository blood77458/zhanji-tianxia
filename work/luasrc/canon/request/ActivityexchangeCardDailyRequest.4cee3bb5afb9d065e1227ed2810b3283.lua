--meilan.xie
--易帅换将
require "canon.request.BaseRequest"

ActivityexchangeCardDailyRequest = class(BaseRequest)

function ActivityexchangeCardDailyRequest:ctor()
  self.endpoint = "exchangeCardDaily"--<<<<< 1. 修改指令名称 后端提供
  self.succeedEventName = self.endpoint .. "Succeed"
  self.failedEventName = self.endpoint .. "Failed"
end

function ActivityexchangeCardDailyRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(self.succeedEventName, data))
end

function ActivityexchangeCardDailyRequest:onError( error )
  self:dispatchEvent(Event.new(self.failedEventName, {retCode = error}))
end

-------------------------------------------------------------------静态函数

--发送请求 默认处理 成功返回之后可加额外处理(参数可传nil)
-- metaId 目标数据编号
-- cardIds 材料卡牌id列表
-- needEssence 所需星灵数 *扣星灵用
function ActivityexchangeCardDailyRequest.sendRequestDefalut(metaId, cardIds, needEssence, afterSucceedCallback)--<<<<< 3
	local function onSucceed(evt)
		ActivityexchangeCardDailyRequest.onSucceedDefault(evt)
		if afterSucceedCallback then
			afterSucceedCallback(evt)
		end
	end
	ActivityexchangeCardDailyRequest.sendRequest(metaId, cardIds, needEssence, onSucceed, ActivityexchangeCardDailyRequest.onFailedDefault)
end

--发送请求
function ActivityexchangeCardDailyRequest.sendRequest(metaId, cardIds, needEssence, succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
	local params = {metaId = metaId, cardId = cardIds}--<<<<< 3
    -- print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~metaId = "..metaId.." cardIds = "..tostring(cardIds))
	local function onSucceedHandle(event)
		-- print("~~~~~~~~~~~~~~~~~~~成功了")
		if succeedCallback then
			event.params = params
			event.needEssence = needEssence
			succeedCallback(event)
		end
	end 
	local function onFailedHandle(event)
		-- print("~~~~~~~~~~~~~~~~~~~失败了")
		if failedCallback then
			event.params = params
			failedCallback(event)
		end
	end
	if SystemManager.debug then
		print("params = " .. table.tostring(params))
	end
	local request = ActivityexchangeCardDailyRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(request.succeedEventName, onSucceedHandle)
	request:addEventListener(request.failedEventName, onFailedHandle)
	request:start()
end

--成功的默认处理
function ActivityexchangeCardDailyRequest.onSucceedDefault(event)--<<<<< 3
	if SystemManager.debug then
		print("onSucceedDefault! event = " .. table.tostring(event))
	end
    
	--兑换数量+1
	Activity_ExchangeDailyLayer.addCurrentExchangeNum(event.params.metaId)

	--去掉消耗 星灵
	RewardManager:getReward({{itemType = ResourceEnum.ASTRALESSENCE, amount = (-event.needEssence or 0)}})
	--去掉消耗 卡牌
	RewardManager:removeCards(event.params.cardId)

	--获得奖励
	RewardManager:getReward(event.data.reward)
end

--失败默认处理
function ActivityexchangeCardDailyRequest.onFailedDefault(event)--<<<<< 4. 修改错误码对应逻辑处理
	local errorCode = tonumber(event.data.retCode)
	local function onErrorConfirm(errorCode)
		if errorCode == 714700 then
			local scene = Director:mgr():run()
			scene:replaceScene(MainMenuScene)
		end
	
	end
	local ret = ErrorCodeManager.alert(errorCode, onErrorConfirm)
end