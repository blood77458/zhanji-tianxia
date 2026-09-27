-- UnionPkGetBattleReportRequest.lua
-- 2014-8-25
-- zheng.che
-- 战报接口

require "canon.request.BaseRequest"

UnionPkGetBattleReportRequest = class(BaseRequest)

function UnionPkGetBattleReportRequest:ctor()
  self.endpoint = "getUnionBattlefieldReport"--<<<<< 1. 修改指令名称 后端提供
  self.succeedEventName = self.endpoint .. "Succeed"
  self.failedEventName = self.endpoint .. "Failed"
end

function UnionPkGetBattleReportRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(self.succeedEventName, data))
end

function UnionPkGetBattleReportRequest:onError( error )
  self:dispatchEvent(Event.new(self.failedEventName, {retCode = error}))
end

-------------------------------------------------------------------静态函数

--发送请求 默认处理 成功返回之后可加额外处理(参数可传nil)
function UnionPkGetBattleReportRequest.sendRequestDefalut(unionCityId, reportId, afterSucceedCallback)--<<<<< 3
	local function onSucceed(evt)
		UnionPkGetBattleReportRequest.onSucceedDefault(evt)
		if afterSucceedCallback then
			afterSucceedCallback(evt)
		end
	end
	UnionPkGetBattleReportRequest.sendRequest(unionCityId, reportId, onSucceed, UnionPkGetBattleReportRequest.onFailedDefault)
end

--发送请求
function UnionPkGetBattleReportRequest.sendRequest(unionCityId, reportId, succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
	local params = {unionCityId = unionCityId, reportId = reportId}--<<<<< 3

	local function onSucceedHandle(event)
		if succeedCallback then
			event.params = params
			succeedCallback(event)
		end
	end 
	local function onFailedHandle(event)
		if failedCallback then
			event.params = params
			failedCallback(event)
		end
	end
	if SystemManager.debug then
		print("params = " .. table.tostring(params))
	end
	local request = UnionPkGetBattleReportRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(request.succeedEventName, onSucceedHandle)
	request:addEventListener(request.failedEventName, onFailedHandle)
	request:start()
end

--成功的默认处理
function UnionPkGetBattleReportRequest.onSucceedDefault(event)--<<<<< 3
	if SystemManager.debug then
		--print("onSucceedDefault! event = " .. table.tostring(event))--buffer too small
	end

	--进入战场
	UnionPK.gotoBattleField(event.data, event.params.unionCityId, event.params.reportId)
end

--失败默认处理
function UnionPkGetBattleReportRequest.onFailedDefault(event)--<<<<< 4. 修改错误码对应逻辑处理
	local errorCode = tonumber(event.data.retCode)
	local function onErrorConfirm(errorCode)
	end
	local ret = ErrorCodeManager.alert(errorCode, onErrorConfirm)
end