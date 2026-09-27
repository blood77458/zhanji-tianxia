--
-- UnionChangeNoticeRequest.lua
-- Author: zheng.che
-- Date: 2014-03-28 18:29:58
-- 换公告请求
--
require "canon.request.BaseRequest"

UnionChangeNoticeRequest = class(BaseRequest)

function UnionChangeNoticeRequest:ctor()
  self.endpoint = "modifyUnionNotice"--<<<<< 1. 修改指令名称 后端提供
end

function UnionChangeNoticeRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.UnionChangeNoticeSucceed, data))--<<<<< 2. 修改枚举名称 定义在BaseRequest里 不能重复
end

function UnionChangeNoticeRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.UnionChangeNoticeFailed, {retCode = error}))--<<<<< 2
end

-------------------------------------------------------------------静态函数

-- unionId 目标军团id
function UnionChangeNoticeRequest.sendRequest(noticeMsg, succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
	local function onSucceedHandle(event)
		if succeedCallback then
			succeedCallback(noticeMsg, event)--<<<<< 3
		end
	end 
	local function onFailedHandle(event)
		if failedCallback then
			failedCallback(event)
		end
	end
	local params = {notice = noticeMsg}--<<<<< 3
	local request = UnionChangeNoticeRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.UnionChangeNoticeSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.UnionChangeNoticeFailed, onFailedHandle)--<<<<< 2
	request:start()
end

--成功的默认处理
function UnionChangeNoticeRequest.onSucceedDefault(noticeMsg, event)--<<<<< 3
	--print("onSucceedDefault! event = " .. table.tostring(event))
	
	UnionManager.setUnionNotice(noticeMsg)
end

--失败默认处理
function UnionChangeNoticeRequest.onFailedDefault(event)--<<<<< 4. 修改错误码对应逻辑处理
	--print("onFailedDefault!")
	local errorCode = tonumber(event.data.retCode)
	if(errorCode == 716313) then -- User has not joined any union: {0:uid}
		CanonMessageBox:showCommErrorBox(CommErrorCodes.USER_NOT_JOIN_ANY_UNION, nil, nil, nil)
	elseif(errorCode == 716417) then -- User has no privilige to modify announcement: {0:uid}, {1:serverId}, {2:unionId}, {3:title}
		CanonMessageBox:showCommErrorBox(CommErrorCodes.HAS_NO_UNION_PRIVILIGE_MODIFY_ANNOUNCEMENT, nil, nil, nil)
	elseif(errorCode == 716335) then -- Union notice is too long: {0:notice}
		CanonMessageBox:showCommErrorBox(CommErrorCodes.UNION_NOTICE_TOO_LONG, nil, nil, nil)
	elseif(errorCode == 716336) then -- Union notice contains sensitive word: {0:notice}"
		CanonMessageBox:showCommErrorBox(CommErrorCodes.UNION_NOTICE_CONTAINS_SENSITIVE_WORD, nil, nil, nil)
	elseif(errorCode == 716337) then -- Union notice is empty: {0:notice}
		CanonMessageBox:showCommErrorBox(CommErrorCodes.UNION_NOTICE_IS_EMPTY, nil, nil, nil)
	elseif(errorCode == 716340) then -- 包含特殊字符
		CanonMessageBox:showCommErrorBox(CommErrorCodes.STR_HAS_WROWN_WORD, nil, nil, nil)
	else
		CanonMessageBox:showCommUnHandleErrorBox(errorCode)
	end
-- 	USER_NOT_JOIN_ANY_UNION(6313, "User has not joined any union: {0:uid}"),
-- HAS_NO_UNION_PRIVILIGE_MODIFY_ANNOUNCEMENT(6417, "User has no privilige to modify announcement: {0:uid}, {1:serverId}, {2:unionId}, {3:title}"),
-- UNION_NOTICE_TOO_LONG(6335, "Union notice is too long: {0:notice}"),
-- 	UNION_NOTICE_CONTAINS_SENSITIVE_WORD(6336, "Union notice contains sensitive word: {0:notice}"),
-- 	UNION_NOTICE_IS_EMPTY(6337, "Union notice is empty: {0:notice}"),
end