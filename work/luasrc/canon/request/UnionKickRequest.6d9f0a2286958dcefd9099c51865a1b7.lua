--
-- UnionKickRequest.lua
-- Author: zheng.che
-- Date: 2014-03-26 10:49:05
-- 军团踢人请求
--
require "canon.request.BaseRequest"

UnionKickRequest = class(BaseRequest)

function UnionKickRequest:ctor()
  self.endpoint = "forceQuitUnion"--<<<<< 1. 修改指令名称 后端提供
end

function UnionKickRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.UnionKickSucceed, data))--<<<<< 2. 修改枚举名称 定义在BaseRequest里 不能重复
end

function UnionKickRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.UnionKickFailed, {retCode = error}))--<<<<< 2
end

-------------------------------------------------------------------静态函数

function UnionKickRequest.sendRequest(targetMemberData, succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
	local function onSucceedHandle(event)
		if succeedCallback then
			succeedCallback(targetMemberData, event)--<<<<< 3
		end
	end 
	local function onFailedHandle(event)
		if failedCallback then
			failedCallback(event)
		end
	end
	local params = {quitUid = targetMemberData.uid}--<<<<< 3
	local request = UnionKickRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.UnionKickSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.UnionKickFailed, onFailedHandle)--<<<<< 2
	request:start()
end

--成功的默认处理
function UnionKickRequest.onSucceedDefault(targetMemberData, event)--<<<<< 3
	--print("onSucceedDefault! event = " .. table.tostring(event))

	local scene = Director:mgr():run()
	SuspensionLabel:showContent(scene, Localization:getInstance():getText("union_player_button_eviction_complete", {name = targetMemberData.nickName}))--玩家{name}已经被踢出军团
  
  ChatManager.sendChat({method = MethodDict.QUITUNION, uid = targetMemberData.uid, unionId = UnionManager.getUnionId()})
end

--失败默认处理
function UnionKickRequest.onFailedDefault(event)--<<<<< 4. 修改错误码对应逻辑处理
	--print("onFailedDefault!")
	local errorCode = tonumber(event.data.retCode)
	if(errorCode == 716313) then -- User has not joined any union: {0:uid}
		CanonMessageBox:showCommErrorBox(CommErrorCodes.USER_NOT_JOIN_ANY_UNION, nil, nil, nil)
	elseif(errorCode == 716318) then -- 军团长不能踢自己
		CanonMessageBox:showCommErrorBox(CommErrorCodes.USER_IS_UNION_MANAGER, nil, nil, nil)
	elseif(errorCode == 716319) then -- User is not in the same union: {0:uids}
		CanonMessageBox:showCommErrorBox(CommErrorCodes.USERS_NOT_IN_SAME_UNION, nil, nil, nil)
	elseif(errorCode == 716414) then -- User has no privilige to kick out vice manager: {0:uid}, {1:serverId}, {2:unionId}, {3:title}
		CanonMessageBox:showCommErrorBox(CommErrorCodes.HAS_NO_UNION_PRIVILIGE_KICK_OUT_VICE_MANAGER, nil, nil, nil)
	elseif(errorCode == 716422) then -- User has no privilige to kick out members: {0:uid}, {1:serverId}, {2:unionId}, {3:title}
		CanonMessageBox:showCommErrorBox(CommErrorCodes.HAS_NO_UNION_PRIVILIGE_KICK_OUT_MEMBER, nil, nil, nil)
	elseif(errorCode == 716633) then -- 在军团战期间禁止操作
		CanonMessageBox.showTextBox(getTextByKey("UnionWar_error_txt1"), nil)
	else
		CanonMessageBox:showCommUnHandleErrorBox(errorCode)
	end
	-- 	USER_NOT_JOIN_ANY_UNION(6313, "User has not joined any union: {0:uid}")
-- USERS_NOT_IN_SAME_UNION(6319, "User is not in the same union: {0:uids}")
-- HAS_NO_UNION_PRIVILIGE_KICK_OUT_VICE_MANAGER(6414, "User has no privilige to kick out vice manager: {0:uid}, {1:serverId}, {2:unionId}, {3:title}")
-- HAS_NO_UNION_PRIVILIGE_KICK_OUT_MEMBER(6422, "User has no privilige to kick out members: {0:uid}, {1:serverId}, {2:unionId}, {3:title}")

end