--跨服GvG  获取淘汰信息
require "canon.request.BaseRequest"
--
CrossUnionPkGetCrossGvgInfoBaseRequest = class(BaseRequest)
--测试状态 仅限内部测试用(一般用于假数据)
CrossUnionPkGetCrossGvgInfoBaseRequest.TEST = false --提测之前请务必改回默认 false !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

function CrossUnionPkGetCrossGvgInfoBaseRequest:ctor()
  self.endpoint = "getCrossGvgInfoBase"--<<<<< 1. 修改指令名称 后端提供
  self.succeedEventName = self.endpoint .. "Succeed"
  self.failedEventName = self.endpoint .. "Failed"
end

function CrossUnionPkGetCrossGvgInfoBaseRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(self.succeedEventName, data))
end

function CrossUnionPkGetCrossGvgInfoBaseRequest:onError( error )
  self:dispatchEvent(Event.new(self.failedEventName, {retCode = error}))
end

-------------------------------------------------------------------静态函数

--发送请求 默认处理 成功返回之后可加额外处理(参数可传nil)
function CrossUnionPkGetCrossGvgInfoBaseRequest.sendRequestDefalut(afterSucceedCallback)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
	local function onSucceed(evt)
		CrossUnionPkGetCrossGvgInfoBaseRequest.onSucceedDefault(evt)
		if afterSucceedCallback then
			afterSucceedCallback(evt)
		end
	end
	CrossUnionPkGetCrossGvgInfoBaseRequest.sendRequest(onSucceed, CrossUnionPkGetCrossGvgInfoBaseRequest.onFailedDefault)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
end

--发送请求
function CrossUnionPkGetCrossGvgInfoBaseRequest.sendRequest(succeedCallback, failedCallback)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
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

	if not CrossUnionPkGetCrossGvgInfoBaseRequest.TEST then
		--非测试状态 正常流程
		if SystemManager.debug then
			print("CrossUnionPkGetCrossGvgInfoBaseRequest->params = " .. tostringRich(params, 2))--深度2 防止打印内容过多 一般够用
		end
		local request = CrossUnionPkGetCrossGvgInfoBaseRequest.new(params, rpc.SendingPriority.kHigh)
		request:addEventListener(request.succeedEventName, onSucceedHandle)
		request:addEventListener(request.failedEventName, onFailedHandle)
		request:start()
	else
		--测试流程 假数据
		onSucceedHandle(CrossUnionPkGetCrossGvgInfoBaseRequest.getDebugDatas())
	end
end

--成功的默认处理
function CrossUnionPkGetCrossGvgInfoBaseRequest.onSucceedDefault(event)--<<<<< 3. 成功的默认处理 do someting
	if SystemManager.debug then
		print("CrossUnionPkGetCrossGvgInfoBaseRequest->event = " .. tostringRich(event))
	end
end

--失败默认处理
function CrossUnionPkGetCrossGvgInfoBaseRequest.onFailedDefault(event)
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
function CrossUnionPkGetCrossGvgInfoBaseRequest.getDebugDatas()
	local testEvt = {data = {}}

	testEvt.data =  {}
	
	-- Info = {}
	testEvt.data.groupId = 1
	testEvt.data.out = false
	
	
	-- table.insert(testEvt.data, Info)  

	return testEvt
end