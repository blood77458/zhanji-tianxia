--------------------------------------------------------------------------------
-- BuyTreasureGridRequest.lua --宝物扭蛋
-- author: l1ghtsaber
-- date: 2015-7-28
--------------------------------------------------------------------------------

require "canon.request.BaseRequest"

GachaTreasureRequest = class(BaseRequest)

function GachaTreasureRequest:ctor(params, priority)
    self.endpoint = "gachaTreasure"--<<<<< 1. 修改指令名称 后端提供
  	self.succeedEventName = self.endpoint .. "Succeed"
  	self.failedEventName = self.endpoint .. "Failed"
end

function GachaTreasureRequest:onSuccess( data )
  	self:dispatchEvent(Event.new(self.succeedEventName, data))
end

function GachaTreasureRequest:onError(error)
  	self:dispatchEvent(Event.new(self.failedEventName, {retCode = error}))
end

--发送请求 默认处理 成功返回之后可加额外处理(参数可传nil)
function GachaTreasureRequest.sendRequestDefalut(time, free, afterSucceedCallback)--<<<<< 3
	local function onSucceed(evt)
		GachaTreasureRequest.onSucceedDefault(evt)
		if afterSucceedCallback then
			afterSucceedCallback(evt)
		end
	end
	GachaTreasureRequest.sendRequest(time, free, onSucceed, GachaTreasureRequest.onFailedDefault)
end

function GachaTreasureRequest.sendRequest(time, free, succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
	local params = {time = time, free = free}--<<<<< 3

	local function onSucceedHandle(event)
		if succeedCallback then
			event.params = params
			succeedCallback(event)--<<<<< 3
		end
	end 
	local function onFailedHandle(event)
		if failedCallback then
			event.params = params
			failedCallback(event)
		end
	end

	local request = GachaTreasureRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(request.succeedEventName, onSucceedHandle)--<<<<< 2
	request:addEventListener(request.failedEventName, onFailedHandle)--<<<<< 2
	request:start()
end

--成功的默认处理
function GachaTreasureRequest.onSucceedDefault(event)--<<<<< 3
  RewardManager:getReward(event.data.rewards)
end

--失败默认处理
function GachaTreasureRequest.onFailedDefault(event)--<<<<< 4. 修改错误码对应逻辑处理
	local errorCode = tonumber(event.data.retCode)
	local function onErrorConfirm(errorCode)
	end
	local ret = ErrorCodeManager.alert(errorCode, onErrorConfirm)
end