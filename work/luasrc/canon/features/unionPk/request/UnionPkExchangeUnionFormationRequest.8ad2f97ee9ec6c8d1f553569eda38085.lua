-- UnionPkExchangeUnionFormationRequest.lua
-- 2014-9-9
-- zheng.che
-- 军团战更换阵型请求

require "canon.request.BaseRequest"

UnionPkExchangeUnionFormationRequest = class(BaseRequest)

function UnionPkExchangeUnionFormationRequest:ctor()
  self.endpoint = "exchangeUnionFormation"--<<<<< 1. 修改指令名称 后端提供
  self.succeedEventName = self.endpoint .. "Succeed"
  self.failedEventName = self.endpoint .. "Failed"
end

function UnionPkExchangeUnionFormationRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(self.succeedEventName, data))
end

function UnionPkExchangeUnionFormationRequest:onError( error )
  self:dispatchEvent(Event.new(self.failedEventName, {retCode = error}))
end

-------------------------------------------------------------------静态函数

--发送请求 默认处理 成功返回之后可加额外处理(参数可传nil)
function UnionPkExchangeUnionFormationRequest.sendRequestDefalut(unionCityId, forwardUid, headUids, middleUids, tailUids, afterSucceedCallback)--<<<<< 3
	local function onSucceed(evt)
		UnionPkExchangeUnionFormationRequest.onSucceedDefault(evt)
		if afterSucceedCallback then
			afterSucceedCallback(evt)
		end
	end
	UnionPkExchangeUnionFormationRequest.sendRequest(unionCityId, forwardUid, headUids, middleUids, tailUids, onSucceed, UnionPkExchangeUnionFormationRequest.onFailedDefault)
end

--发送请求
function UnionPkExchangeUnionFormationRequest.sendRequest(unionCityId, forwardUid, headUids, middleUids, tailUids, succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
	local params = {unionCityId = unionCityId, forwardUid = forwardUid, headUids = headUids, middleUids = middleUids, tailUids = tailUids}--<<<<< 3

	local function onSucceedHandle(event)
		if succeedCallback then
			event.params = params
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
	local request = UnionPkExchangeUnionFormationRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(request.succeedEventName, onSucceedHandle)
	request:addEventListener(request.failedEventName, onFailedHandle)
	request:start()
end

--成功的默认处理
function UnionPkExchangeUnionFormationRequest.onSucceedDefault(event)--<<<<< 3
	if SystemManager.debug then
		print("onSucceedDefault! event = " .. table.tostring(event))
	end

end

--失败默认处理
function UnionPkExchangeUnionFormationRequest.onFailedDefault(event)--<<<<< 4. 修改错误码对应逻辑处理
	local errorCode = tonumber(event.data.retCode)
	local function onErrorConfirm(errorCode)
		if errorCode == 716429 then
			--权限不够 刷新权限相关的数据
			local function onGetDataComplete(getDataEvent)
				UnionGetMyDataRequest.onSucceedDefault(getDataEvent)

				--通知更新
				UnionManager.eventDispatcher:dispatchEvent(Event.new(UnionPkConsts.UNIONPK_USERDATA_UPDATE))
			end
			UnionGetMyDataRequest.sendRequest(onGetDataComplete, UnionGetMyDataRequest.onFailedDefault)
			return
		end

		if errorCode == 716612 then
			--调整时间已过 通知
			UnionManager.eventDispatcher:dispatchEvent(Event.new(UnionPkConsts.UNIONPK_ERROR_CONFIRM_EXCHANGE_TIME_PASSED))
			return
		end
	end
	local ret = ErrorCodeManager.alert(errorCode, onErrorConfirm)
end