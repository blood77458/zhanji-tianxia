--
-- UnionGetApplierListRequest.lua
-- Author: zheng.che
-- Date: 2014-03-21 16:42:09
-- 请求获得申请者列表
--
require "canon.request.BaseRequest"

UnionGetApplierListRequest = class(BaseRequest)

function UnionGetApplierListRequest:ctor()
  self.endpoint = "getUnionAppliers"--<<<<< 1. 修改指令名称 后端提供
end

function UnionGetApplierListRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.UnionGetApplierListSucceed, data))--<<<<< 2. 修改枚举名称 定义在BaseRequest里 不能重复
end

function UnionGetApplierListRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.UnionGetApplierListFailed, {retCode = error}))--<<<<< 2
end

-------------------------------------------------------------------静态函数

function UnionGetApplierListRequest.sendRequest(succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
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
	local request = UnionGetApplierListRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.UnionGetApplierListSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.UnionGetApplierListFailed, onFailedHandle)--<<<<< 2
	request:start()
end

--成功的默认处理
function UnionGetApplierListRequest.onSucceedDefault(event)
	--print("onSucceedDefault! event = " .. table.tostring(event))
	UnionManager.setApplierList(event.data.sharkUnionAppliers)
end

--失败默认处理
function UnionGetApplierListRequest.onFailedDefault(event)--<<<<< 4. 修改错误码对应逻辑处理
	--print("onFailedDefault!")
	local errorCode = tonumber(event.data.retCode)
	if(errorCode == 716313) then -- User has not joined any union: {0:uid}
		CanonMessageBox:showCommErrorBox(CommErrorCodes.USER_NOT_JOIN_ANY_UNION, nil, nil, nil)
	elseif(errorCode == 716421) then -- User has no privilige to applly examine: {0:uid}, {1:serverId}, {2:unionId}, {3:title}
		--有可能玩家自身不知道 不给任何提示
	else
		CanonMessageBox:showCommUnHandleErrorBox(errorCode)
	end
-- 	USER_NOT_JOIN_ANY_UNION(6313, "User has not joined any union: {0:uid}")
-- HAS_NO_UNION_PRIVILIGE_APPLY_EXAMINE(6421, "User has no privilige to applly examine: {0:uid}, {1:serverId}, {2:unionId}, {3:title}")

end