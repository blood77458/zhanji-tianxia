-- CrossUnionPkCheckFiredStatueRequest.lua
-- 2015-5-11
-- zheng.che
-- 获得踢人之前获得被踢玩家当前状态

-- <request>
-- 		<property code="firedUid" type="long" desc="准备踢的玩家uid" />
-- 	</request>
-- 	<response>
-- 		<property code="status" type="int" desc="踢人之前获得被踢玩家当前状态，0-可踢，1-已报名，2-已上阵" />
-- 	</response>

require "canon.request.BaseRequest"

CrossUnionPkCheckFiredStatueRequest = class(BaseRequest)
--测试状态 仅限内部测试用(一般用于假数据)
CrossUnionPkCheckFiredStatueRequest.TEST = false --提测之前请务必改回默认 false !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

function CrossUnionPkCheckFiredStatueRequest:ctor()
  self.endpoint = "getFiredUnionMemberStatus"--<<<<< 1. 修改指令名称 后端提供
  self.succeedEventName = self.endpoint .. "Succeed"
  self.failedEventName = self.endpoint .. "Failed"
end

function CrossUnionPkCheckFiredStatueRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(self.succeedEventName, data))
end

function CrossUnionPkCheckFiredStatueRequest:onError( error )
  self:dispatchEvent(Event.new(self.failedEventName, {retCode = error}))
end

-------------------------------------------------------------------静态函数

--发送请求 默认处理 成功返回之后可加额外处理(参数可传nil)
--firedUid 准备踢的玩家uid
function CrossUnionPkCheckFiredStatueRequest.sendRequestDefalut(firedUid, afterSucceedCallback)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
	local function onSucceed(evt)
		CrossUnionPkCheckFiredStatueRequest.onSucceedDefault(evt)
		if afterSucceedCallback then
			afterSucceedCallback(evt)
		end
	end
	CrossUnionPkCheckFiredStatueRequest.sendRequest(firedUid, onSucceed, CrossUnionPkCheckFiredStatueRequest.onFailedDefault)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
end

--发送请求
function CrossUnionPkCheckFiredStatueRequest.sendRequest(firedUid, succeedCallback, failedCallback)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
	local params = {firedUid = firedUid}--<<<<< 2. 附加参数转换成后端提供的接口格式

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

	if not CrossUnionPkCheckFiredStatueRequest.TEST then
		--非测试状态 正常流程
		if SystemManager.debug then
			print("CrossUnionPkCheckFiredStatueRequest->params = " .. tostringRich(params, 2))--深度2 防止打印内容过多 一般够用
		end
		local request = CrossUnionPkCheckFiredStatueRequest.new(params, rpc.SendingPriority.kHigh)
		request:addEventListener(request.succeedEventName, onSucceedHandle)
		request:addEventListener(request.failedEventName, onFailedHandle)
		request:start()
	else
		--测试流程 假数据
		onSucceedHandle(CrossUnionPkCheckFiredStatueRequest.getDebugDatas())
	end
end

--成功的默认处理
function CrossUnionPkCheckFiredStatueRequest.onSucceedDefault(event)--<<<<< 3. 成功的默认处理 do someting
	if SystemManager.debug then
		print("CrossUnionPkCheckFiredStatueRequest->event = " .. tostringRich(event))
	end
end

--失败默认处理
function CrossUnionPkCheckFiredStatueRequest.onFailedDefault(event)
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
function CrossUnionPkCheckFiredStatueRequest.getDebugDatas()
	local outline
	--local testEvt = {data = {status = 0}}
	local testEvt = {data = {status = 1}}
	--local testEvt = {data = {status = 2}}

	return testEvt
end