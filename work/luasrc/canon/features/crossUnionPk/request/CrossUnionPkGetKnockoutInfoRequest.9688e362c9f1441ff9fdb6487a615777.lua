-- CrossUnionPkGetKnockoutInfoRequest.lua
-- 2015-4-15
-- zheng.che
-- 取得跨服gvg 排位赛数据

-- <protocol desc="获取淘汰赛信息">
-- 	<request>
-- 	</request>
-- 	<response>
-- 		<list code="sixteen" ref="CrossGvgResultOutline" desc="16强" />
-- 		<list code="eight" ref="CrossGvgResultOutline" desc="8强" />
-- 		<list code="four" ref="CrossGvgResultOutline" desc="4强" />
-- 		<property code="championBattle" ref="CrossGvgResultOutline" desc="冠军赛" />
-- 		<property code="thirdPlaceBattle" ref="CrossGvgResultOutline" desc="季军赛" />
-- 	</response>
-- </protocol>

-- <bean desc="跨服gvg战斗结果信息">
-- 	<property code="id" type="int" desc="用于获取战报的id" />
-- 	<property code="attUnion" ref="UnionIdentification" desc="进攻军团" />
-- 	<property code="defUnion" ref="UnionIdentification" desc="防守军团" />
-- 	<property code="win" type="boolean" desc="是否取胜" />
-- </bean>

require "canon.request.BaseRequest"

CrossUnionPkGetKnockoutInfoRequest = class(BaseRequest)
--测试状态 仅限内部测试用(一般用于假数据)
CrossUnionPkGetKnockoutInfoRequest.TEST = false --提测之前请务必改回默认 false !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

function CrossUnionPkGetKnockoutInfoRequest:ctor()
  self.endpoint = "getGvgKnockoutInfo"--<<<<< 1. 修改指令名称 后端提供
  self.succeedEventName = self.endpoint .. "Succeed"
  self.failedEventName = self.endpoint .. "Failed"
end

function CrossUnionPkGetKnockoutInfoRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(self.succeedEventName, data))
end

function CrossUnionPkGetKnockoutInfoRequest:onError( error )
  self:dispatchEvent(Event.new(self.failedEventName, {retCode = error}))
end

-------------------------------------------------------------------静态函数

--发送请求 默认处理 成功返回之后可加额外处理(参数可传nil)
function CrossUnionPkGetKnockoutInfoRequest.sendRequestDefalut(afterSucceedCallback)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
	local function onSucceed(evt)
		CrossUnionPkGetKnockoutInfoRequest.onSucceedDefault(evt)
		if afterSucceedCallback then
			afterSucceedCallback(evt)
		end
	end
	CrossUnionPkGetKnockoutInfoRequest.sendRequest(onSucceed, CrossUnionPkGetKnockoutInfoRequest.onFailedDefault)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
end

--发送请求
function CrossUnionPkGetKnockoutInfoRequest.sendRequest(succeedCallback, failedCallback)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
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

	if not CrossUnionPkGetKnockoutInfoRequest.TEST then
		--非测试状态 正常流程
		if SystemManager.debug then
			print("CrossUnionPkGetKnockoutInfoRequest->params = " .. tostringRich(params, 2))--深度2 防止打印内容过多 一般够用
		end
		local request = CrossUnionPkGetKnockoutInfoRequest.new(params, rpc.SendingPriority.kHigh)
		request:addEventListener(request.succeedEventName, onSucceedHandle)
		request:addEventListener(request.failedEventName, onFailedHandle)
		request:start()
	else
		--测试流程 假数据
		onSucceedHandle(CrossUnionPkGetKnockoutInfoRequest.getDebugDatas())
	end
end

--成功的默认处理
function CrossUnionPkGetKnockoutInfoRequest.onSucceedDefault(event)--<<<<< 3. 成功的默认处理 do someting
	if SystemManager.debug then
		print("CrossUnionPkGetKnockoutInfoRequest->event = " .. tostringRich(event))

		--校验返回内容
		currentTimeLevel = CrossUnionPkUtils.findCurrentTimeLevel()
		if currentTimeLevel >= CrossUnionPkConsts.TIME_ARMY2_FIGHTING_THIRD then
			--已到季军赛角逐阶段
			DebugManager.assert(event.data.championBattle ~= nil, "已到季军赛角逐阶段, 但是缺少冠军赛战斗结果! ")
		end
	end
end

--失败默认处理
function CrossUnionPkGetKnockoutInfoRequest.onFailedDefault(event)
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
function CrossUnionPkGetKnockoutInfoRequest.getDebugDatas()
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

	--16强
	testEvt.data.sixteen =  {}
	
	outline = {}
	outline.id = 12345
	outline.attUnion = {serverId = 123, unionId = 234, unionName = "attUnion"}
	outline.defUnion = {serverId = 123, unionId = 234, unionName = "defUnion"}
	outline.win = true
	table.insert(testEvt.data.sixteen, outline)
	
	outline = {}
	outline.id = 12345
	outline.attUnion = {serverId = 123, unionId = 234, unionName = "attUnion"}
	outline.defUnion = {serverId = 123, unionId = 234, unionName = "defUnion"}
	outline.win = false
	table.insert(testEvt.data.sixteen, outline)
	
	outline = {}
	outline.id = 12345
	outline.attUnion = {serverId = 123, unionId = 234, unionName = "attUnion"}
	outline.defUnion = {serverId = 123, unionId = 234, unionName = "defUnion"}
	outline.win = false
	table.insert(testEvt.data.sixteen, outline)
	
	outline = {}
	outline.id = 12345
	outline.attUnion = {serverId = 123, unionId = 234, unionName = "attUnion"}
	outline.defUnion = {serverId = 123, unionId = 234, unionName = "defUnion"}
	outline.win = true
	table.insert(testEvt.data.sixteen, outline)

	--8强
	testEvt.data.eight =  {}
	
	outline = {}
	outline.id = 12345
	outline.attUnion = {serverId = 123, unionId = 234, unionName = "attUnion"}
	outline.defUnion = {serverId = 123, unionId = 234, unionName = "defUnion"}
	outline.win = false
	table.insert(testEvt.data.eight, outline)

	--4强
	testEvt.data.four =  {}
	
	outline = {}
	outline.id = 12345
	outline.attUnion = {serverId = 123, unionId = 234, unionName = "attUnion"}
	outline.defUnion = {serverId = 123, unionId = 234, unionName = "defUnion"}
	outline.win = false
	table.insert(testEvt.data.four, outline)

	--冠军赛
	outline = {}
	outline.id = 12345
	outline.attUnion = {serverId = 123, unionId = 234, unionName = "attUnion"}
	outline.defUnion = {serverId = 123, unionId = 234, unionName = "defUnion"}
	outline.win = false
	testEvt.data.championBattle =  outline

	--季军赛
	outline = {}
	outline.id = 12345
	outline.attUnion = {serverId = 123, unionId = 234, unionName = "attUnion"}
	outline.defUnion = {serverId = 123, unionId = 234, unionName = "defUnion"}
	outline.win = false
	testEvt.data.thirdPlaceBattle =  outline

	return testEvt
end