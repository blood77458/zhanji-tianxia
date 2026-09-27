-- <protocol desc="获得跨服PVP战报信息">
-- 	<request>
-- 	</request>
-- 	<response>
-- 		<list code="reports" ref="ReportInfo" desc="战报列表" />
-- 	</response>
-- </protocol>

require "canon.request.BaseRequest"

GetCrossPvpReportRequest = class(BaseRequest)
--测试状态 仅限内部测试用(一般用于假数据)
GetCrossPvpReportRequest.TEST = false --提测之前请务必改回默认 false !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

function GetCrossPvpReportRequest:ctor()
  self.endpoint = "getCrossPvpReport"--<<<<< 1. 修改指令名称 后端提供
  self.succeedEventName = self.endpoint .. "Succeed"
  self.failedEventName = self.endpoint .. "Failed"
end

function GetCrossPvpReportRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(self.succeedEventName, data))
end

function GetCrossPvpReportRequest:onError( error )
  self:dispatchEvent(Event.new(self.failedEventName, {retCode = error}))
end

-------------------------------------------------------------------静态函数

--发送请求 默认处理 成功返回之后可加额外处理(参数可传nil)
function GetCrossPvpReportRequest.sendRequestDefalut(afterSucceedCallback)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
	local function onSucceed(evt)
		GetCrossPvpReportRequest.onSucceedDefault(evt)
		if afterSucceedCallback then
			afterSucceedCallback(evt)
		end
	end
	GetCrossPvpReportRequest.sendRequest(onSucceed, GetCrossPvpReportRequest.onFailedDefault)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
end

--发送请求
function GetCrossPvpReportRequest.sendRequest(succeedCallback, failedCallback)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
	local params = {}--<<<<< 2. 附加参数转换成后端提供的接口格式

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

	if not GetCrossPvpReportRequest.TEST then
		--非测试状态 正常流程
		local request = GetCrossPvpReportRequest.new(params, rpc.SendingPriority.kHigh)
		request:addEventListener(request.succeedEventName, onSucceedHandle)
		request:addEventListener(request.failedEventName, onFailedHandle)
		request:start()
	else
		--测试流程 假数据
		onSucceedHandle(GetCrossPvpReportRequest.getDebugDatas())
	end
end

--成功的默认处理
function GetCrossPvpReportRequest.onSucceedDefault(event)--<<<<< 3. 成功的默认处理 do someting
	if SystemManager.debug then
		print("GetCrossPvpReportRequest->event = " .. tostringRich(event))
	end

	CrossArenaManager.setReportList( event.data )
	CrossArenaManager.setMyRank(event.data.rank)
	CrossArenaManager.setMyBattleScore(event.data.score)
end

--失败默认处理
function GetCrossPvpReportRequest.onFailedDefault(event)
	local errorCode = tonumber(event.data.retCode)
	local function onErrorConfirm(errorCode)
	end
	local ret = ErrorCodeManager.alert(errorCode, onErrorConfirm)
end

--获得测试用假数据--<<<<< 4. 根据需要填写测试假数据 用完删除
function GetCrossPvpReportRequest.getDebugDatas()
	local testEvt = {data = {}}
	testEvt.data.reports =  {}
	local rank
	
	rank = {}
	-- rank.itemType = 5
	rank.metaId = 101011
	rank.nickName = "fff"
	rank.server = 1
	rank.unionName = "fffdd"
	rank.win = true
	table.insert(testEvt.data.reports, rank)

	rank2 = {}
	-- rank.itemType = 5
	rank2.metaId = 101011
	rank2.nickName = "fff"
	rank2.server = 1
	rank2.unionName = "fffdd"
	rank2.win = false
	table.insert(testEvt.data.reports, rank2)

	return testEvt
end