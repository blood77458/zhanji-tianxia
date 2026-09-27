-- UnionPkGetCityMemberListRequest.lua
-- 2015-1-9
-- zheng.che
-- 获得军团战城池报名成员列表

require "canon.request.BaseRequest"

UnionPkGetCityMemberListRequest = class(BaseRequest)

function UnionPkGetCityMemberListRequest:ctor()
  self.endpoint = "getUnionWarCityMembersList"--<<<<< 1. 修改指令名称 后端提供
  self.succeedEventName = self.endpoint .. "Succeed"
  self.failedEventName = self.endpoint .. "Failed"
end

function UnionPkGetCityMemberListRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(self.succeedEventName, data))
end

function UnionPkGetCityMemberListRequest:onError( error )
  self:dispatchEvent(Event.new(self.failedEventName, {retCode = error}))
end

-------------------------------------------------------------------静态函数

--发送请求 默认处理 成功返回之后可加额外处理(参数可传nil)
function UnionPkGetCityMemberListRequest.sendRequestDefalut(cityId, afterSucceedCallback)--<<<<< 3
	local function onSucceed(evt)
		UnionPkGetCityMemberListRequest.onSucceedDefault(evt)
		if afterSucceedCallback then
			afterSucceedCallback(evt)
		end
	end
	UnionPkGetCityMemberListRequest.sendRequest(cityId, onSucceed, UnionPkGetCityMemberListRequest.onFailedDefault)
end

--发送请求
function UnionPkGetCityMemberListRequest.sendRequest(cityId, succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
	local params = {cityId = cityId}--<<<<< 3

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
	local request = UnionPkGetCityMemberListRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(request.succeedEventName, onSucceedHandle)
	request:addEventListener(request.failedEventName, onFailedHandle)
	request:start()

	--onSucceedHandle(UnionPkTest.testGetCityMemberList())--测试用
end

--成功的默认处理
function UnionPkGetCityMemberListRequest.onSucceedDefault(event)--<<<<< 3
	if SystemManager.debug then
		print("onSucceedDefault! event = " .. table.tostring(event))
	end

	
end

--失败默认处理
function UnionPkGetCityMemberListRequest.onFailedDefault(event)--<<<<< 4. 修改错误码对应逻辑处理
	local errorCode = tonumber(event.data.retCode)
	local function onErrorConfirm(errorCode)
	end
	local ret = ErrorCodeManager.alert(errorCode, onErrorConfirm)
end