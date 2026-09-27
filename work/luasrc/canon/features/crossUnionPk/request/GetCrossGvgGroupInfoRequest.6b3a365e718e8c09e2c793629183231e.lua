-- <?xml version="1.0" encoding="UTF-8"?>
-- <protocol desc="获得跨服军团战分在同一个组的服务器id">
-- 	<request>
-- 	</request>
-- 	<response>
-- 		<list code="serverIds" type="int" desc="分在同一个组的服务器id" />
-- 	</response>
-- </protocol>

require "canon.request.BaseRequest"

GetCrossGvgGroupInfoRequest = class(BaseRequest)
--测试状态 仅限内部测试用(一般用于假数据)
GetCrossGvgGroupInfoRequest.TEST = false --提测之前请务必改回默认 false !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

function GetCrossGvgGroupInfoRequest:ctor()
  self.endpoint = "getCrossGvgGroupInfo"--<<<<< 1. 修改指令名称 后端提供
  self.succeedEventName = self.endpoint .. "Succeed"
  self.failedEventName = self.endpoint .. "Failed"
end

function GetCrossGvgGroupInfoRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(self.succeedEventName, data))
end

function GetCrossGvgGroupInfoRequest:onError( error )
  self:dispatchEvent(Event.new(self.failedEventName, {retCode = error}))
end

-------------------------------------------------------------------静态函数

--发送请求 默认处理 成功返回之后可加额外处理(参数可传nil)
function GetCrossGvgGroupInfoRequest.sendRequestDefalut(params , afterSucceedCallback)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
	local function onSucceed(evt)
		GetCrossGvgGroupInfoRequest.onSucceedDefault(evt)
		if afterSucceedCallback then
			afterSucceedCallback(evt)
		end
	end
	GetCrossGvgGroupInfoRequest.sendRequest(params,onSucceed, GetCrossGvgGroupInfoRequest.onFailedDefault)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
end

--发送请求
function GetCrossGvgGroupInfoRequest.sendRequest(params,succeedCallback, failedCallback)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
	-- local params = params or {}--<<<<< 2. 附加参数转换成后端提供的接口格式

	local function onSucceedHandle(event)
		event.params = params
		if succeedCallback then
			succeedCallback(event)
		end
	end 
	local function onFailedHandle(event)
		if failedCallback then
			failedCallback(event)
		end
	end

	if not GetCrossGvgGroupInfoRequest.TEST then
		--非测试状态 正常流程
		if SystemManager.debug then
			print("GetCrossGvgGroupInfoRequest->params = " .. tostringRich(params, 2))--深度2 防止打印内容过多 一般够用
		end
		local request = GetCrossGvgGroupInfoRequest.new(params, rpc.SendingPriority.kHigh)
		request:addEventListener(request.succeedEventName, onSucceedHandle)
		request:addEventListener(request.failedEventName, onFailedHandle)
		request:start()
	else
		--测试流程 假数据
		onSucceedHandle(GetCrossGvgGroupInfoRequest.getDebugDatas())
	end
end

--成功的默认处理
function GetCrossGvgGroupInfoRequest.onSucceedDefault(event)--<<<<< 3. 成功的默认处理 do someting
	if SystemManager.debug then
		print("GetCrossGvgGroupInfoRequest->event = " .. tostringRich(event))
	end
end

--失败默认处理
function GetCrossGvgGroupInfoRequest.onFailedDefault(event)
	local errorCode = tonumber(event.data.retCode)
	local function onErrorConfirm(errorCode)
	end
	local ret = ErrorCodeManager.alert(errorCode, onErrorConfirm)
end


--获得测试用假数据--<<<<< 4. 根据需要填写测试假数据 用完删除
function GetCrossGvgGroupInfoRequest.getDebugDatas()
	local testEvt = {data = {}}

	return testEvt
end