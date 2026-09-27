-- UnionPKGetMyGuildInfoRequest.lua
-- 2014-8-25
-- zhehua.ou
-- 军团战 获得 我的军团 列表信息

require "canon.request.BaseRequest"

UnionPKGetMyGuildInfoRequest = class(BaseRequest)

function UnionPKGetMyGuildInfoRequest:ctor()
  self.endpoint = "getOwnUnionInfo"
  self.succeedEventName = self.endpoint .. "Succeed"
  self.failedEventName = self.endpoint .. "Failed"
end

function UnionPKGetMyGuildInfoRequest:onSuccess( data )
  self:dispatchEvent(Event.new(self.succeedEventName, data))
end

function UnionPKGetMyGuildInfoRequest:onError( error )
  self:dispatchEvent(Event.new(self.failedEventName, {retCode = error}))
end

-------------------------------------------------------------------静态函数

--发送请求 默认处理 成功返回之后可加额外处理(参数可传nil)
function UnionPKGetMyGuildInfoRequest.sendRequestDefalut(afterSucceedCallback)
	local function onSucceed(evt)
		UnionPKGetMyGuildInfoRequest.onSucceedDefault(evt)
		if afterSucceedCallback then
			afterSucceedCallback(evt)
		end
	end
	UnionPKGetMyGuildInfoRequest.sendRequest(onSucceed, UnionPKGetMyGuildInfoRequest.onFailedDefault)
end

--发送请求
function UnionPKGetMyGuildInfoRequest.sendRequest(succeedCallback, failedCallback)
	local params = {}

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
	local request = UnionPKGetMyGuildInfoRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(request.succeedEventName, onSucceedHandle)
	request:addEventListener(request.failedEventName, onFailedHandle)
	request:start()
end

--成功的默认处理
function UnionPKGetMyGuildInfoRequest.onSucceedDefault(event)--<<<<< 3
	if SystemManager.debug then
		print("onSucceedDefault! event = " .. table.tostring(event))
	end
end

--失败默认处理
function UnionPKGetMyGuildInfoRequest.onFailedDefault(event)
	local errorCode = tonumber(event.data.retCode)
	local function onErrorConfirm(errorCode)
	end
	local ret = ErrorCodeManager.alert(errorCode, onErrorConfirm)
end