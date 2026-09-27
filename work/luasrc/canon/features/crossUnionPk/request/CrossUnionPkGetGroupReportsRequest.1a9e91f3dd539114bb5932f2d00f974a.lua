-- CrossUnionPkGetGroupReportsRequest.lua
-- zheng.che
-- 2015-4-23
-- 获得跨服军团战小组赛战报

-- <protocol desc="获得跨服军团战小组赛战报">
-- 	<request>
-- 	</request>
-- 	<response>
-- 		<list code="reports" ref="GVGReport" desc="战报信息列表" />
-- 	</response>
-- </protocol>

-- <bean desc="战报信息">
-- 	<property code="uuid" type="int" desc="战报id" />
-- 	<property code="attUnionName" type="string" desc="进攻方公会名称" />
-- 	<property code="defUnionName" type="string" desc="防守方公会名称" />
-- 	<property code="win" type="boolean" desc="进攻方是否胜利" />
-- </bean>

require "canon.request.BaseRequest"

CrossUnionPkGetGroupReportsRequest = class(BaseRequest)
--测试状态 仅限内部测试用(一般用于假数据)
CrossUnionPkGetGroupReportsRequest.TEST = false --提测之前请务必改回默认 false !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

function CrossUnionPkGetGroupReportsRequest:ctor()
  self.endpoint = "getCrossGvgGroupReports"--<<<<< 1. 修改指令名称 后端提供
  self.succeedEventName = self.endpoint .. "Succeed"
  self.failedEventName = self.endpoint .. "Failed"
end

function CrossUnionPkGetGroupReportsRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(self.succeedEventName, data))
end

function CrossUnionPkGetGroupReportsRequest:onError( error )
  self:dispatchEvent(Event.new(self.failedEventName, {retCode = error}))
end

-------------------------------------------------------------------静态函数

--发送请求 默认处理 成功返回之后可加额外处理(参数可传nil)
function CrossUnionPkGetGroupReportsRequest.sendRequestDefalut(afterSucceedCallback)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
	local function onSucceed(evt)
		CrossUnionPkGetGroupReportsRequest.onSucceedDefault(evt)
		if afterSucceedCallback then
			afterSucceedCallback(evt)
		end
	end
	CrossUnionPkGetGroupReportsRequest.sendRequest(onSucceed, CrossUnionPkGetGroupReportsRequest.onFailedDefault)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
end

--发送请求
function CrossUnionPkGetGroupReportsRequest.sendRequest(succeedCallback, failedCallback)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
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

	if not CrossUnionPkGetGroupReportsRequest.TEST then
		--非测试状态 正常流程
		if SystemManager.debug then
			print("CrossUnionPkGetGroupReportsRequest->params = " .. tostringRich(params, 2))--深度2 防止打印内容过多 一般够用
		end
		local request = CrossUnionPkGetGroupReportsRequest.new(params, rpc.SendingPriority.kHigh)
		request:addEventListener(request.succeedEventName, onSucceedHandle)
		request:addEventListener(request.failedEventName, onFailedHandle)
		request:start()
	else
		--测试流程 假数据
		onSucceedHandle(CrossUnionPkGetGroupReportsRequest.getDebugDatas())
	end
end

--成功的默认处理
function CrossUnionPkGetGroupReportsRequest.onSucceedDefault(event)--<<<<< 3. 成功的默认处理 do someting
	if SystemManager.debug then
		print("CrossUnionPkGetGroupReportsRequest->event = " .. tostringRich(event))
	end

	CrossUnionPkData.setGroupChallengedRemind(false)
	UnionManager.eventDispatcher:dispatchEvent(Event.new(CrossUnionPkConsts.REFRESH_SHINE_DAILY_REPORTS))
end

--失败默认处理
function CrossUnionPkGetGroupReportsRequest.onFailedDefault(event)
	local errorCode = tonumber(event.data.retCode)
	local function onErrorConfirm(errorCode)
		if errorCode == 716313 then
			--玩家没加入任何军团 返回主界面
			local scene = Director:mgr():run()
			scene:replaceScene(MainMenuScene)
		end
	end
	local ret = ErrorCodeManager.alert(errorCode, onErrorConfirm)
end

--获得测试用假数据--<<<<< 4. 根据需要填写测试假数据 用完删除
function CrossUnionPkGetGroupReportsRequest.getDebugDatas()
-- 	<bean desc="跨服gvg战斗结果信息">
-- 	<property code="id" type="int" desc="用于获取战报的id" />
-- 	<property code="attUnion" ref="UnionIdentification" desc="进攻军团" />
-- 	<property code="defUnion" ref="UnionIdentification" desc="防守军团" />
-- 	<property code="win" type="boolean" desc="是否取胜" />
-- </bean>

-- <bean desc="军团标识">
-- 	<property code="serverId" type="int" desc="服务器id" />
-- 	<property code="unionId" type="int" desc="军团id" />
-- 	<property code="unionName" type="string" desc="军团名称" />
-- </bean>

	local outline
	local testEvt = {data = {}}

	testEvt.data.reports =  {}
	
	outline = {}
	outline.uuid = 12345
	outline.attUnionName = "attUnion"
	outline.defUnionName = "defUnion" 
	outline.win = true
	table.insert(testEvt.data.reports, outline)
	
	outline = {}
	outline.uuid = 12345
	outline.attUnionName = "attUnion"
	outline.defUnionName = "defUnion" 
	outline.win = false
	table.insert(testEvt.data.reports, outline)
	
	outline = {}
	outline.uuid = 12345
	outline.attUnionName = "attUnion"
	outline.defUnionName = "defUnion" 
	outline.win = false
	table.insert(testEvt.data.reports, outline)
	
	outline = {}
	outline.uuid = 12345
	outline.attUnionName = "attUnion"
	outline.defUnionName = "defUnion" 
	outline.win = false
	table.insert(testEvt.data.reports, outline)
	
	outline = {}
	outline.uuid = 12345
	outline.attUnionName = "attUnion"
	outline.defUnionName = "defUnion" 
	outline.win = false
	table.insert(testEvt.data.reports, outline)
	
	outline = {}
	outline.uuid = 12345
	outline.attUnionName = "attUnion"
	outline.defUnionName = "defUnion" 
	outline.win = false
	table.insert(testEvt.data.reports, outline)
	
	outline = {}
	outline.uuid = 12345
	outline.attUnionName = "attUnion"
	outline.defUnionName = "defUnion" 
	outline.win = false
	table.insert(testEvt.data.reports, outline)
	
	outline = {}
	outline.uuid = 12345
	outline.attUnionName = "attUnion"
	outline.defUnionName = "defUnion" 
	outline.win = false
	table.insert(testEvt.data.reports, outline)
	
	outline = {}
	outline.uuid = 12345
	outline.attUnionName = "attUnion"
	outline.defUnionName = "defUnion" 
	outline.win = false
	table.insert(testEvt.data.reports, outline)
	
	outline = {}
	outline.uuid = 12345
	outline.attUnionName = "attUnion"
	outline.defUnionName = "defUnion" 
	outline.win = false
	table.insert(testEvt.data.reports, outline)
	
	outline = {}
	outline.uuid = 12345
	outline.attUnionName = "attUnion"
	outline.defUnionName = "defUnion" 
	outline.win = false
	table.insert(testEvt.data.reports, outline)
	
	outline = {}
	outline.uuid = 12345
	outline.attUnionName = "attUnion"
	outline.defUnionName = "defUnion" 
	outline.win = false
	table.insert(testEvt.data.reports, outline)
	
	outline = {}
	outline.uuid = 12345
	outline.attUnionName = "attUnion"
	outline.defUnionName = "defUnion" 
	outline.win = false
	table.insert(testEvt.data.reports, outline)
	
	outline = {}
	outline.uuid = 12345
	outline.attUnionName = "attUnion"
	outline.defUnionName = "defUnion" 
	outline.win = false
	table.insert(testEvt.data.reports, outline)
	
	outline = {}
	outline.uuid = 12345
	outline.attUnionName = "attUnion"
	outline.defUnionName = "defUnion" 
	outline.win = false
	table.insert(testEvt.data.reports, outline)
	
	outline = {}
	outline.uuid = 12345
	outline.attUnionName = "attUnion"
	outline.defUnionName = "defUnion" 
	outline.win = false
	table.insert(testEvt.data.reports, outline)
	
	outline = {}
	outline.uuid = 12345
	outline.attUnionName = "attUnion"
	outline.defUnionName = "defUnion" 
	outline.win = false
	table.insert(testEvt.data.reports, outline)
	
	outline = {}
	outline.uuid = 12345
	outline.attUnionName = "attUnion"
	outline.defUnionName = "defUnion" 
	outline.win = false
	table.insert(testEvt.data.reports, outline)
	
	outline = {}
	outline.uuid = 12345
	outline.attUnionName = "attUnion"
	outline.defUnionName = "defUnion" 
	outline.win = false
	table.insert(testEvt.data.reports, outline)
	
	outline = {}
	outline.uuid = 12345
	outline.attUnionName = "attUnion"
	outline.defUnionName = "defUnion" 
	outline.win = false
	table.insert(testEvt.data.reports, outline)

	return testEvt
end