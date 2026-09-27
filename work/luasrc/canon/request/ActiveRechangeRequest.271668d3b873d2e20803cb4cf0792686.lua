-- ActiveRechangeRequest.lua
-- 2014-1-19
-- meilan.xie
-- <?xml version="1.0" encoding="UTF-8"?>
-- <protocol desc="领取世界Boss奖励">
-- 	<request>
-- 		<property code="level" type="int" desc="奖励等级" />
-- 	</request>
-- 	<response>
-- 		<list code="rewards" ref="Reward" desc="等级奖励" />
-- 	</response>
-- </protocol>

require "canon.request.BaseRequest"

ActiveRechangeRequest = class(BaseRequest)

function ActiveRechangeRequest:ctor()
  self.endpoint = "gainLimitReward"--<<<<< 1. 修改指令名称 后端提供
  self.succeedEventName = self.endpoint .. "Succeed"
  self.failedEventName = self.endpoint .. "Failed"
end

function ActiveRechangeRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(self.succeedEventName, data))
end

function ActiveRechangeRequest:onError( error )
  self:dispatchEvent(Event.new(self.failedEventName, {retCode = error}))
end

-------------------------------------------------------------------静态函数

--发送请求 默认处理 成功返回之后可加额外处理(参数可传nil)
function ActiveRechangeRequest.sendRequestDefalut(RewardData, afterSucceedCallback)--<<<<< 3
	local function onSucceed(evt)
		ActiveRechangeRequest.onSucceedDefault(evt)
		if afterSucceedCallback then
			afterSucceedCallback(evt)
		end
	end
	ActiveRechangeRequest.sendRequest(RewardData, onSucceed, ActiveRechangeRequest.onFailedDefault)
end

--发送请求
--equipData 装备数据
function ActiveRechangeRequest.sendRequest(RewardData, succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
	local params = {stepId = RewardData.stepId}--<<<<< 3

	print("~~~~~~~~~~~~~~~~~~~~~~~~领奖Id~~~~~~~~~~~~~~~~"..params.stepId)

	local function onSucceedHandle(event)
		if succeedCallback then
			event.params = params
			event.RewardData = RewardData
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
	local request = ActiveRechangeRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(request.succeedEventName, onSucceedHandle)
	request:addEventListener(request.failedEventName, onFailedHandle)
	request:start()
end

--成功的默认处理
function ActiveRechangeRequest.onSucceedDefault(event)--<<<<< 3
	if SystemManager.debug then
		print("onSucceedDefault! event = " .. table.tostring(event))
	end

	
end

--失败默认处理
function ActiveRechangeRequest.onFailedDefault(event)--<<<<< 4. 修改错误码对应逻辑处理
	local errorCode = tonumber(event.data.retCode)
	local function onErrorConfirm(errorCode)
	end
	local ret = ErrorCodeManager.alert(errorCode, onErrorConfirm)
end