-- UnionPkGetApplyUnionsRequest.lua
-- 2014-8-19
-- zhehua.ou
-- 军团战 获得指定城池具体信息

require "canon.request.BaseRequest"

UnionPkGetApplyUnionsRequest = class(BaseRequest)

function UnionPkGetApplyUnionsRequest:ctor()
  self.endpoint = "getApplyUnions"--<<<<< 1. 修改指令名称 后端提供
  self.succeedEventName = self.endpoint .. "Succeed"
  self.failedEventName = self.endpoint .. "Failed"
end

function UnionPkGetApplyUnionsRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(self.succeedEventName, data))
end

function UnionPkGetApplyUnionsRequest:onError( error )
  self:dispatchEvent(Event.new(self.failedEventName, {retCode = error}))
end

-------------------------------------------------------------------静态函数

--发送请求 默认处理 成功返回之后可加额外处理(参数可传nil)
function UnionPkGetApplyUnionsRequest.sendRequestDefalut(unionCityId, afterSucceedCallback)--<<<<< 3
	local function onSucceed(evt)
		UnionPkGetApplyUnionsRequest.onSucceedDefault(evt)
		if afterSucceedCallback then
			afterSucceedCallback(evt)
		end
	end
	UnionPkGetApplyUnionsRequest.sendRequest(unionCityId, onSucceed, UnionPkGetApplyUnionsRequest.onFailedDefault)
end

--发送请求
function UnionPkGetApplyUnionsRequest.sendRequest(unionCityId, succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
	local params = {unionCityId = unionCityId}--<<<<< 3

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
	local request = UnionPkGetApplyUnionsRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(request.succeedEventName, onSucceedHandle)
	request:addEventListener(request.failedEventName, onFailedHandle)
	request:start()
end

--成功的默认处理
function UnionPkGetApplyUnionsRequest.onSucceedDefault(event)--<<<<< 3
	if SystemManager.debug then
		print("onSucceedDefault! event = " .. table.tostring(event))
	end
end

--失败默认处理
function UnionPkGetApplyUnionsRequest.onFailedDefault(event)--<<<<< 4. 修改错误码对应逻辑处理
	local errorCode = tonumber(event.data.retCode)
	local function onErrorConfirm(errorCode)
	end
	local ret = ErrorCodeManager.alert(errorCode, onErrorConfirm)
end