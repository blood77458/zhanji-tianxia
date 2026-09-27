--
-- SeckillGetInfoRequest.lua
-- Author: zheng.che
-- Date: 2014-04-23 17:16:04
-- 获得秒杀活动当前状态
--
require "canon.request.BaseRequest"

SeckillGetInfoRequest = class(BaseRequest)

function SeckillGetInfoRequest:ctor()
  self.endpoint = "getSeckillInfo"--<<<<< 1. 修改指令名称 后端提供
end

function SeckillGetInfoRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.SeckillGetInfoSucceed, data))--<<<<< 2. 修改枚举名称 定义在BaseRequest里 不能重复
end

function SeckillGetInfoRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.SeckillGetInfoFailed, {retCode = error}))--<<<<< 2
end

-------------------------------------------------------------------静态函数

function SeckillGetInfoRequest.sendRequest(succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
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
	local request = SeckillGetInfoRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.SeckillGetInfoSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.SeckillGetInfoFailed, onFailedHandle)--<<<<< 2
	request:start()
end

--成功的默认处理
function SeckillGetInfoRequest.onSucceedDefault(event)--<<<<< 3
	--print("onSucceedDefault! event = " .. table.tostring(event))
	local tempHash = {}
	for k, v in ipairs(event.data.seckillItems) do
		tempHash[v.id] = v
	end
	Activity_SeckillLayer.setSaleInfoList(tempHash)
end

--失败默认处理
function SeckillGetInfoRequest.onFailedDefault(event)--<<<<< 4. 修改错误码对应逻辑处理
	--print("onFailedDefault!")
	local errorCode = tonumber(event.data.retCode)
	if(errorCode == 714600) then
		CanonMessageBox:showCommErrorBox(CommErrorCodes.ACTIVITY_SECKILL_CLOSE, nil, nil, nil)
	else
		CanonMessageBox:showCommUnHandleErrorBox(errorCode)
	end
-- 	ACTIVITY_SECKILL_CLOSE(4600, "Activity seckill close: {0:uid}"),

end