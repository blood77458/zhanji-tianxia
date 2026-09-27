--
-- UnionAppointRequest.lua
-- Author: zheng.che
-- Date: 2014-03-26 10:42:22
-- 任命职务请求
--
require "canon.request.BaseRequest"

UnionAppointRequest = class(BaseRequest)

function UnionAppointRequest:ctor()
  self.endpoint = "appointUnion"--<<<<< 1. 修改指令名称 后端提供
end

function UnionAppointRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.UnionAppointSucceed, data))--<<<<< 2. 修改枚举名称 定义在BaseRequest里 不能重复
end

function UnionAppointRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.UnionAppointFailed, {retCode = error}))--<<<<< 2
end

-------------------------------------------------------------------静态函数

function UnionAppointRequest.sendRequest(targetMemberData, targetTitle, succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
	local function onSucceedHandle(event)
		if succeedCallback then
			succeedCallback(targetMemberData, targetTitle, event)--<<<<< 3
		end
	end 
	local function onFailedHandle(event)
		if failedCallback then
			failedCallback(event)
		end
	end
	local params = {appointUid = targetMemberData.uid, title = targetTitle}--<<<<< 3
	--print("params = " .. table.tostring(params))
	local request = UnionAppointRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.UnionAppointSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.UnionAppointFailed, onFailedHandle)--<<<<< 2
	request:start()
end

--成功的默认处理
function UnionAppointRequest.onSucceedDefault(targetMemberData, targetTitle, event)--<<<<< 3
	--print("onSucceedDefault! event = " .. table.tostring(event))

	local scene = Director:mgr():run()
	if targetTitle == UnionManager.TITLE_MEMBER then
		SuspensionLabel:showContent(scene, Localization:getInstance():getText("union_player_button_recall_complete", {name = targetMemberData.nickName}))--玩家{name}已经被罢免职务
	else
		SuspensionLabel:showContent(scene, Localization:getInstance():getText("union_player_button_appointment_complete", {name1 = targetMemberData.nickName, name2 = UnionManager.getTitleName(targetTitle)}))--玩家{name1}已经被任命为{name2}
	end
end

--失败默认处理
function UnionAppointRequest.onFailedDefault(event)--<<<<< 4. 修改错误码对应逻辑处理
	--print("onFailedDefault!")
	local errorCode = tonumber(event.data.retCode)
	if(errorCode == 716313) then -- User has not joined any union: {0:uid}
		CanonMessageBox:showCommErrorBox(CommErrorCodes.USER_NOT_JOIN_ANY_UNION, nil, nil, nil)
	elseif(errorCode == 716319) then -- User is not in the same union: {0:uids}
		CanonMessageBox:showCommErrorBox(CommErrorCodes.USERS_NOT_IN_SAME_UNION, nil, nil, nil)
	elseif(errorCode == 716323) then -- Unsupport union appoint type: {0:uid}, {1:awardedUid}, {2:originalTitle}, {3:appointTitle}
		CanonMessageBox:showCommErrorBox(CommErrorCodes.UNSUPPORT_UNION_APPOINT_TYPE, nil, nil, nil)
	elseif(errorCode == 716324) then -- Unoin members subtype reach upper: {0:serverId}, {1:unionId}, {2:title}, {3:currNum}
		CanonMessageBox:showCommErrorBox(CommErrorCodes.UNION_MEMBERS_SUBTYPE_REACH_UPPER, nil, nil, nil)
	elseif(errorCode == 716412) then -- User has no privilige to appoint vice manager: {0:uid}, {1:serverId}, {2:unionId}, {3:title}
		CanonMessageBox:showCommErrorBox(CommErrorCodes.HAS_NO_UNION_PRIVILIGE_APPOINT_VICE_MANAGER, nil, nil, nil)
	elseif(errorCode == 716415) then -- User has no privilige to recall vice manager: {0:uid}, {1:serverId}, {2:unionId}, {3:title}
		CanonMessageBox:showCommErrorBox(CommErrorCodes.HAS_NO_UNION_PRIVILIGE_RECALL_VICE_MANAGER, nil, nil, nil)
	elseif(errorCode == 716418) then -- User has no privilige to appoint elite member: {0:uid}, {1:serverId}, {2:unionId}, {3:title}
		CanonMessageBox:showCommErrorBox(CommErrorCodes.HAS_NO_UNION_PRIVILIGE_APPOINT_ELITE_MEMBER, nil, nil, nil)
	elseif(errorCode == 716419) then -- User has no privilige to recall elite member: {0:uid}, {1:serverId}, {2:unionId}, {3:title}
		CanonMessageBox:showCommErrorBox(CommErrorCodes.HAS_NO_UNION_PRIVILIGE_RECALL_ELITE_MEMBER, nil, nil, nil)
	else
		CanonMessageBox:showCommUnHandleErrorBox(errorCode)
	end

-- 	UNION_CAREER_META_NOT_CONFIGED(6410, "Union career meta not configed in union-career.xml: {1:careerId}"),
-- USER_NOT_JOIN_ANY_UNION(6313, "User has not joined any union: {0:uid}"),
-- USERS_NOT_IN_SAME_UNION(6319, "User is not in the same union: {0:uids}"),
-- UNSUPPORT_UNION_APPOINT_TYPE(6323, "Unsupport union appoint type: {0:uid}, {1:awardedUid}, {2:originalTitle}, {3:appointTitle}"),
-- HAS_NO_UNION_PRIVILIGE_APPOINT_VICE_MANAGER(6412, "User has no privilige to appoint vice manager: {0:uid}, {1:serverId}, {2:unionId}, {3:title}"),
-- HAS_NO_UNION_PRIVILIGE_RECALL_VICE_MANAGER(6415, "User has no privilige to recall vice manager: {0:uid}, {1:serverId}, {2:unionId}, {3:title}"),
-- HAS_NO_UNION_PRIVILIGE_APPOINT_ELITE_MEMBER(6418, "User has no privilige to appoint elite member: {0:uid}, {1:serverId}, {2:unionId}, {3:title}"),
-- HAS_NO_UNION_PRIVILIGE_RECALL_ELITE_MEMBER(6419, "User has no privilige to recall elite member: {0:uid}, {1:serverId}, {2:unionId}, {3:title}"),
-- UNION_MEMBERS_SUBTYPE_REACH_UPPER(6324, "Unoin members subtype reach upper: {0:serverId}, {1:unionId}, {2:title}, {3:currNum}"),
end