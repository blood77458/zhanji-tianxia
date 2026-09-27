--
-- UnionApplyRequest.lua
-- Author: zheng.che
-- Date: 2014-03-17 19:17:08
-- 请求加入某军团
--
require "canon.request.BaseRequest"

UnionApplyRequest = class(BaseRequest)

function UnionApplyRequest:ctor()
  self.endpoint = "applyUnion"--<<<<< 1. 修改指令名称 后端提供
end

function UnionApplyRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.UnionApplySucceed, data))--<<<<< 2. 修改枚举名称 定义在BaseRequest里 不能重复
end

function UnionApplyRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.UnionApplyFailed, {retCode = error}))--<<<<< 2
end

-------------------------------------------------------------------静态函数

-- unionData 目标军团信息
function UnionApplyRequest.sendRequest(unionData, succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
	local function onSucceedHandle(event)
		if succeedCallback then
			succeedCallback(unionData, event)--<<<<< 3
		end
	end 
	local function onFailedHandle(event)
		if failedCallback then
			failedCallback(event)
		end
	end
	local params = {unionId = unionData.unionId}--<<<<< 3
	local request = UnionApplyRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.UnionApplySucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.UnionApplyFailed, onFailedHandle)--<<<<< 2
	request:start()
end

--成功的默认处理
function UnionApplyRequest.onSucceedDefault(unionData, event)--<<<<< 3
	--print("onSucceedDefault! event = " .. table.tostring(event))

	--添加到已申请军团数据中
	UnionManager.addApplyedUnion(unionData)

	local scene = Director:mgr():run()
	SuspensionLabel:showContent(scene, Localization:getInstance():getText("union_apply_finish_remind"))--成功提交申请
end

--失败默认处理
function UnionApplyRequest.onFailedDefault(event)--<<<<< 4. 修改错误码对应逻辑处理
	--print("onFailedDefault!")
	local errorCode = tonumber(event.data.retCode)
	if(errorCode == 716300) then --User has already joined a union: {0:uid}
		CanonMessageBox:showCommErrorBox(CommErrorCodes.USER_JOINED_UNION, nil, nil, nil)
	elseif(errorCode == 716301) then -- User is in union cold time: {0:uid}
		CanonMessageBox:showCommErrorBox(CommErrorCodes.USER_IN_UNION_COLD, nil, nil, nil)
	elseif(errorCode == 716311) then -- User apply union reach upper: {0:uid}, {1:cnt}
		CanonMessageBox:showCommErrorBox(CommErrorCodes.USER_APPLY_UNION_REACH_UPPER, nil, nil, nil)
	elseif(errorCode == 716312) then -- Union appliers reach uppper: {0:unionId}, {1:cnt}, {2:uid}
		CanonMessageBox:showCommErrorBox(CommErrorCodes.UNION_APPLIERS_REACH_UPPER, nil, nil, nil)
	else
		CanonMessageBox:showCommUnHandleErrorBox(errorCode)
	end
-- 	USER_JOINED_UNION(6300, "User has already joined a union: {0:uid}"),
-- USER_IN_UNION_COLD(6301, "User is in union cold time: {0:uid}"),
-- USER_APPLY_UNION_REACH_UPPER(6311, "User apply union reach upper: {0:uid}, {1:cnt}"),
-- UNION_APPLIERS_REACH_UPPER(6312, "Union appliers reach uppper: {0:unionId}, {1:cnt}, {2:uid}"),
end