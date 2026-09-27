--跨服GvG  军团界面弹框请求 
require "canon.request.BaseRequest"
--
CrossUnionPkcrossGvgCanMindApplyRequest = class(BaseRequest)
--测试状态 仅限内部测试用(一般用于假数据)
CrossUnionPkcrossGvgCanMindApplyRequest.TEST = false --提测之前请务必改回默认 false !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

function CrossUnionPkcrossGvgCanMindApplyRequest:ctor()
  self.endpoint = "crossGvgCanMindApply"--<<<<< 1. 修改指令名称 后端提供
  self.succeedEventName = self.endpoint .. "Succeed"
  self.failedEventName = self.endpoint .. "Failed"
end

function CrossUnionPkcrossGvgCanMindApplyRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(self.succeedEventName, data))
end

function CrossUnionPkcrossGvgCanMindApplyRequest:onError( error )
  self:dispatchEvent(Event.new(self.failedEventName, {retCode = error}))
end

-------------------------------------------------------------------静态函数

--发送请求 默认处理 成功返回之后可加额外处理(参数可传nil)
function CrossUnionPkcrossGvgCanMindApplyRequest.sendRequestDefalut(afterSucceedCallback)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
	local function onSucceed(evt)
		CrossUnionPkcrossGvgCanMindApplyRequest.onSucceedDefault(evt)
		if afterSucceedCallback then
			afterSucceedCallback(evt)
		end
	end
	CrossUnionPkcrossGvgCanMindApplyRequest.sendRequest(onSucceed, CrossUnionPkcrossGvgCanMindApplyRequest.onFailedDefault)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
end

--发送请求
function CrossUnionPkcrossGvgCanMindApplyRequest.sendRequest(succeedCallback, failedCallback)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
	local params = {}--<<<<< 2. 附加参数转换成后端提供的接口格式

	local function onSucceedHandle(event)
		event.params = params
		if succeedCallback then
			event.params = params
			event.Data = Data
			succeedCallback(event)
		end
	end 
	local function onFailedHandle(event)
		if failedCallback then
			event.params = params
			failedCallback(event)
		end
	end

	if not CrossUnionPkcrossGvgCanMindApplyRequest.TEST then
		--非测试状态 正常流程
		if SystemManager.debug then
			print("CrossUnionPkcrossGvgCanMindApplyRequest->params = " .. tostringRich(params, 2))--深度2 防止打印内容过多 一般够用
		end
		local request = CrossUnionPkcrossGvgCanMindApplyRequest.new(params, rpc.SendingPriority.kHigh)
		request:addEventListener(request.succeedEventName, onSucceedHandle)
		request:addEventListener(request.failedEventName, onFailedHandle)
		request:start()
	else
		--测试流程 假数据
		onSucceedHandle(CrossUnionPkcrossGvgCanMindApplyRequest.getDebugDatas())
	end
end

--成功的默认处理
function CrossUnionPkcrossGvgCanMindApplyRequest.onSucceedDefault(event)--<<<<< 3. 成功的默认处理 do someting
	if SystemManager.debug then
		print("CrossUnionPkcrossGvgCanMindApplyRequest->event = " .. tostringRich(event))
	end
end

--失败默认处理
function CrossUnionPkcrossGvgCanMindApplyRequest.onFailedDefault(event)
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



--获得测试用假数据--<<<<< 4. 根据需要填写测试假数据 用完删除  报名不需要假数据
function CrossUnionPkcrossGvgCanMindApplyRequest.getDebugDatas()
	local testEvt = {data = {}}
	-- <request>
	-- </request>
	-- <response>
 --    	<property code="applyCrossGvgRemind" type="boolean" desc="是否提醒报名跨服军团战" />
	-- </response>
	testEvt.data =  {}
	
	-- Info = {}
	testEvt.data.applyCrossGvgRemind = true

	-- table.insert(testEvt.data, Info)  

	return testEvt
end