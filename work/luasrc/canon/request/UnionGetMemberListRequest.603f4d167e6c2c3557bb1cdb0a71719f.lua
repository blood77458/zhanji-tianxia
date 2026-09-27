--
-- UnionGetMemberListRequest.lua
-- Author: zheng.che
-- Date: 2014-03-24 19:23:51
-- 获得军团成员列表
--
require "canon.request.BaseRequest"

UnionGetMemberListRequest = class(BaseRequest)

function UnionGetMemberListRequest:ctor()
  self.endpoint = "getUnionMembersList"--<<<<< 1. 修改指令名称 后端提供
end

function UnionGetMemberListRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.UnionGetMemberListSucceed, data))--<<<<< 2. 修改枚举名称 定义在BaseRequest里 不能重复
end

function UnionGetMemberListRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.UnionGetMemberListFailed, {retCode = error}))--<<<<< 2
end

-------------------------------------------------------------------静态函数

function UnionGetMemberListRequest.sendRequest(succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
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
	local request = UnionGetMemberListRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.UnionGetMemberListSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.UnionGetMemberListFailed, onFailedHandle)--<<<<< 2
	request:start()
end

--成功的默认处理
function UnionGetMemberListRequest.onSucceedDefault(event)
	if SystemManager.debug then
		print("onSucceedDefault! event = " .. table.tostring(event))
	end

	--设置成员列表
	UnionManager.setMembers(event.data.sharkUnionMemberWrappers or {})
	UnionManager.setUnionMemberCount(#event.data.sharkUnionMemberWrappers)--顺便修改人数

	--刷新成员列表成功后 也刷一下当前玩家的属性 因为可能有些属性有变化了
	UnionGetMyDataRequest.sendRequest(UnionGetMyDataRequest.onSucceedDefault, UnionGetMyDataRequest.onFailedDefault)
end

--失败默认处理
function UnionGetMemberListRequest.onFailedDefault(event)--<<<<< 4. 修改错误码对应逻辑处理
	--print("onFailedDefault!")
	local errorCode = tonumber(event.data.retCode)
	if(errorCode == 716313) then -- User has not joined any union: {0:uid}
		CanonMessageBox:showCommErrorBox(CommErrorCodes.USER_NOT_JOIN_ANY_UNION, nil, nil, nil)
	else
		CanonMessageBox:showCommUnHandleErrorBox(errorCode)
	end
	--USER_NOT_JOIN_ANY_UNION(6313, "User has not joined any union: {0:uid}")
end