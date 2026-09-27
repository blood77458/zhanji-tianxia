--
-- UnionGetMyApplyListRequest.lua
-- Author: zheng.che
-- Date: 2014-03-17 11:47:54
-- 请求获取当前玩家的已申请军团列表
--
require "canon.request.BaseRequest"

UnionGetMyApplyListRequest = class(BaseRequest)

function UnionGetMyApplyListRequest:ctor()
  self.endpoint = "getAppliedUnions"--<<<<< 1. 修改指令名称 后端提供
end

function UnionGetMyApplyListRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.UnionGetMyApplyListSucceed, data))--<<<<< 2. 修改枚举名称 定义在BaseRequest里 不能重复
end

function UnionGetMyApplyListRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.UnionGetMyApplyListFailed, {retCode = error}))--<<<<< 2
end

-------------------------------------------------------------------静态函数

function UnionGetMyApplyListRequest.sendRequest(succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
	local function onSucceedHandle(event)
		if succeedCallback then
			succeedCallback(event)
		end
	end 
	local function onFailedHandle(event)
		if failedCallback then
			failedCallback(event)
		end
	end
	local params = {}--<<<<< 3
	local request = UnionGetMyApplyListRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.UnionGetMyApplyListSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.UnionGetMyApplyListFailed, onFailedHandle)--<<<<< 2
	request:start()
end

--成功的默认处理
function UnionGetMyApplyListRequest.onSucceedDefault(event)
	--print("onSucceedDefault! event = " .. table.tostring(event))
	
	--重置已申请军团列表
	UnionManager.setApplyedUnions(event.data.sharkUnionWrappers)
end

--失败默认处理
function UnionGetMyApplyListRequest.onFailedDefault(event)--<<<<< 4. 修改错误码对应逻辑处理
	--print("onFailedDefault!")
	--无错误码
	local errorCode = tonumber(event.data.retCode)
	CanonMessageBox:showCommUnHandleErrorBox(errorCode)
end