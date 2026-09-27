--
-- UnionColosseumGiveUpAllocationRequest.lua
-- Author: zheng.che
-- Date: 2014-05-26 15:33:52
-- 军团斗兽场放弃分配
--
require "canon.request.BaseRequest"

UnionColosseumGiveUpAllocationRequest = class(BaseRequest)

function UnionColosseumGiveUpAllocationRequest:ctor()
  self.endpoint = "unionMonsterRewardDistributeGiveUp"--<<<<< 1. 修改指令名称 后端提供
end

function UnionColosseumGiveUpAllocationRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.UnionColosseumGiveUpAllocationSucceed, data))--<<<<< 2. 修改枚举名称 定义在BaseRequest里 不能重复
end

function UnionColosseumGiveUpAllocationRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.UnionColosseumGiveUpAllocationFailed, {retCode = error}))--<<<<< 2
end

-------------------------------------------------------------------静态函数

function UnionColosseumGiveUpAllocationRequest.sendRequest(succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
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
	local request = UnionColosseumGiveUpAllocationRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.UnionColosseumGiveUpAllocationSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.UnionColosseumGiveUpAllocationFailed, onFailedHandle)--<<<<< 2
	request:start()
end

--成功的默认处理
function UnionColosseumGiveUpAllocationRequest.onSucceedDefault(event)--<<<<< 3
	if SystemManager.debug then
		print("onSucceedDefault! event = " .. tostringRich({event}))--<<<<< 3
	end

	--修改分配状态 改为无分配者
	UnionManager.setColosseumDividerUid(0)
end

--失败默认处理
function UnionColosseumGiveUpAllocationRequest.onFailedDefault(event)--<<<<< 4. 修改错误码对应逻辑处理
	--print("onFailedDefault!")
	local errorCode = tonumber(event.data.retCode)
	CanonMessageBox:showCommUnHandleErrorBox(errorCode)
-- 	无错误码

end