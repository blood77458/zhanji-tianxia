--
-- UnionSearchRequest.lua
-- Author: zheng.che
-- Date: 2014-03-17 21:16:18
-- 查找军团请求
--
require "canon.request.BaseRequest"

UnionSearchRequest = class(BaseRequest)

function UnionSearchRequest:ctor()
  self.endpoint = "searchUnion"--<<<<< 1. 修改指令名称 后端提供
end

function UnionSearchRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.UnionSearchSucceed, data))--<<<<< 2. 修改枚举名称 定义在BaseRequest里 不能重复
end

function UnionSearchRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.UnionSearchFailed, {retCode = error}))--<<<<< 2
end

-------------------------------------------------------------------静态函数

-- unionId 目标军团id
function UnionSearchRequest.sendRequest(targetUnionName, succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
	local function onSucceedHandle(event)
		if succeedCallback then
			succeedCallback(targetUnionName, event)--<<<<< 3
		end
	end 
	local function onFailedHandle(event)
		if failedCallback then
			failedCallback(event)
		end
	end
	local params = {unionName = targetUnionName}--<<<<< 3
	local request = UnionSearchRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.UnionSearchSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.UnionSearchFailed, onFailedHandle)--<<<<< 2
	request:start()
end

--成功的默认处理
function UnionSearchRequest.onSucceedDefault(targetUnionName, event)--<<<<< 3
	--print("onSucceedDefault! event = " .. table.tostring(event))
	--消耗资源
end

--失败默认处理
function UnionSearchRequest.onFailedDefault(event)--<<<<< 4. 修改错误码对应逻辑处理
	--print("onFailedDefault!")
	--没有错误码
	local errorCode = tonumber(event.data.retCode)
	CanonMessageBox:showCommUnHandleErrorBox(errorCode)

end