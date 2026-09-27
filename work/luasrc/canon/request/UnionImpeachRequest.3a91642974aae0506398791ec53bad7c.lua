--
-- UnionImpeachRequest.lua
-- Author: zheng.che
-- Date: 2014-03-26 10:31:48
-- 弹劾军团长
--
require "canon.request.BaseRequest"

UnionImpeachRequest = class(BaseRequest)

function UnionImpeachRequest:ctor()
  self.endpoint = "impeachUnionManager"--<<<<< 1. 修改指令名称 后端提供
end

function UnionImpeachRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.UnionImpeachSucceed, data))--<<<<< 2. 修改枚举名称 定义在BaseRequest里 不能重复
end

function UnionImpeachRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.UnionImpeachFailed, {retCode = error}))--<<<<< 2
end

-------------------------------------------------------------------静态函数

function UnionImpeachRequest.sendRequest(succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
	local function onSucceedHandle(event)
		if succeedCallback then
			succeedCallback(event)--<<<<< 3
		end
	end 
	local function onFailedHandle(event)
		if failedCallback then
			failedCallback(event)
		end
	end
	local params = {}--<<<<< 3
	local request = UnionImpeachRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.UnionImpeachSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.UnionImpeachFailed, onFailedHandle)--<<<<< 2
	request:start()
end

--成功的默认处理
function UnionImpeachRequest.onSucceedDefault(event)--<<<<< 3
	--print("onSucceedDefault! event = " .. table.tostring(event))

	local scene = Director:mgr():run()
	SuspensionLabel:showContent(scene, Localization:getInstance():getText("union_player_button_impeach_complete", {name = event.data.currManagerNickName}))--弹劾军团长成功，{name}成为新的军团长
end

--失败默认处理
function UnionImpeachRequest.onFailedDefault(event)--<<<<< 4. 修改错误码对应逻辑处理
	--print("onFailedDefault!")
	local errorCode = tonumber(event.data.retCode)
	if(errorCode == 716313) then -- User has not joined any union: {0:uid}
		CanonMessageBox:showCommErrorBox(CommErrorCodes.USER_NOT_JOIN_ANY_UNION, nil, nil, nil)
	elseif(errorCode == 716325) then -- Unio manager leave time not enough: {0:uid}, {1:managerId}
		CanonMessageBox:showCommErrorBox(CommErrorCodes.UNION_MANAGER_LEAVE_TIME_NOT_ENOUGH, nil, nil, nil)
	elseif(errorCode == 716326) then -- 
		CanonMessageBox:showCommErrorBox(CommErrorCodes.NO_MEMBERS_IN_UNION, nil, nil, nil)
	else
		CanonMessageBox:showCommUnHandleErrorBox(errorCode)
	end
-- 	USER_NOT_JOIN_ANY_UNION(6313, "User has not joined any union: {0:uid}")
-- UNION_MANAGER_LEAVE_TIME_NOT_ENOUGH(6325, "Unio manager leave time not enough: {0:uid}, {1:managerId}")

end