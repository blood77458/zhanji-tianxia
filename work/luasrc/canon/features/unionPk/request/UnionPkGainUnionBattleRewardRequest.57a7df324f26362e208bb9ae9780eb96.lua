-- UnionPkGainUnionBattleRewardRequest.lua
-- 2014-9-18
-- zhehua.ou
-- 军团战 请求获得 我的奖励

require "canon.request.BaseRequest"

UnionPkGainUnionBattleRewardRequest = class(BaseRequest)

function UnionPkGainUnionBattleRewardRequest:ctor()
  self.endpoint = "gainUnionBattleReward"--<<<<< 1. 修改指令名称 后端提供
  self.succeedEventName = self.endpoint .. "Succeed"
  self.failedEventName = self.endpoint .. "Failed"
end

function UnionPkGainUnionBattleRewardRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(self.succeedEventName, data))
end

function UnionPkGainUnionBattleRewardRequest:onError( error )
  self:dispatchEvent(Event.new(self.failedEventName, {retCode = error}))
end

-------------------------------------------------------------------静态函数

--发送请求 默认处理 成功返回之后可加额外处理(参数可传nil)
function UnionPkGainUnionBattleRewardRequest.sendRequestDefalut(rewardId, afterSucceedCallback)--<<<<< 3
	local function onSucceed(evt)
		UnionPkGainUnionBattleRewardRequest.onSucceedDefault(evt)
		if afterSucceedCallback then
			afterSucceedCallback(evt)
		end
	end
	UnionPkGainUnionBattleRewardRequest.sendRequest(rewardId, onSucceed, UnionPkGainUnionBattleRewardRequest.onFailedDefault)
end

--发送请求
function UnionPkGainUnionBattleRewardRequest.sendRequest(rewardId, succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
	local params = {rewardId = rewardId}--<<<<< 3

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
	if SystemManager.debug then
		print("params = " .. table.tostring(params))
	end
	local request = UnionPkGainUnionBattleRewardRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(request.succeedEventName, onSucceedHandle)
	request:addEventListener(request.failedEventName, onFailedHandle)
	request:start()
end

--成功的默认处理
function UnionPkGainUnionBattleRewardRequest.onSucceedDefault(event)--<<<<< 3
	if SystemManager.debug then
		print("onSucceedDefault! event = " .. table.tostring(event))
	end
end

--失败默认处理
function UnionPkGainUnionBattleRewardRequest.onFailedDefault(event)--<<<<< 4. 修改错误码对应逻辑处理
	local errorCode = tonumber(event.data.retCode)
	local function onErrorConfirm(errorCode)
	end
	local ret = ErrorCodeManager.alert(errorCode, onErrorConfirm)
end