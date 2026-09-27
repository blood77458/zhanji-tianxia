--
-- UnionTransferRequest.lua
-- Author: zheng.che
-- Date: 2014-03-26 10:02:28
-- 移交军团长请求
--
require "canon.request.BaseRequest"

UnionTransferRequest = class(BaseRequest)

function UnionTransferRequest:ctor()
  self.endpoint = "transferUnion"--<<<<< 1. 修改指令名称 后端提供
end

function UnionTransferRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.UnionTransferSucceed, data))--<<<<< 2. 修改枚举名称 定义在BaseRequest里 不能重复
end

function UnionTransferRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.UnionTransferFailed, {retCode = error}))--<<<<< 2
end

-------------------------------------------------------------------静态函数

function UnionTransferRequest.sendRequest(targetMemberData, succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
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
	local params = {transferedUid = targetMemberData.uid}--<<<<< 3
	local request = UnionTransferRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.UnionTransferSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.UnionTransferFailed, onFailedHandle)--<<<<< 2
	request:start()
end

--成功的默认处理
function UnionTransferRequest.onSucceedDefault(targetMemberData, event)--<<<<< 3
	--print("onSucceedDefault! event = " .. table.tostring(event))

	UnionManager.setUnionTransferTime(event.data.transferTime)--设定转让到期时间
	UnionManager.setUnionStatus(UnionManager.UNION_STATUS_TRANSFERING)--设定转让状态
	UnionManager.setNextManagerId(targetMemberData.uid)--设定被转让副军团长id

	local hours = TimeUtil.getHoursBySec(event.data.transferTime - TimeUtil.getServerTimeSeconds())
	local scene = Director:mgr():run()
	SuspensionLabel:showContent(scene, Localization:getInstance():getText("union_player_button_change_major_complete", {name = targetMemberData.nickName, num = hours}))--军团长已开始转让给{name},{num}小时后完成转让
end

--失败默认处理
function UnionTransferRequest.onFailedDefault(event)--<<<<< 4. 修改错误码对应逻辑处理
	--print("onFailedDefault!")
	local errorCode = tonumber(event.data.retCode)
	if(errorCode == 716313) then -- User has not joined any union: {0:uid}
		CanonMessageBox:showCommErrorBox(CommErrorCodes.USER_NOT_JOIN_ANY_UNION, nil, nil, nil)
	elseif(errorCode == 716413) then -- User has no privilige to transfer union: {0:uid}, {1:serverId}, {2:unionId}, {3:title}
		CanonMessageBox:showCommErrorBox(CommErrorCodes.HAS_NO_UNION_PRIVILIGE_TRANSFER_UNION, nil, nil, nil)
	else
		CanonMessageBox:showCommUnHandleErrorBox(errorCode)
	end
-- 	HAS_NO_UNION_PRIVILIGE_TRANSFER_UNION(6413, "User has no privilige to transfer union: {0:uid}, {1:serverId}, {2:unionId}, {3:title}")
-- USER_NOT_JOIN_ANY_UNION(6313, "User has not joined any union: {0:uid}")
end