
require "canon.request.BaseRequest"

UploadCrossGvgTeamMirrorRequest = class(BaseRequest)
--测试状态 仅限内部测试用(一般用于假数据)
UploadCrossGvgTeamMirrorRequest.TEST = false --提测之前请务必改回默认 false !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

function UploadCrossGvgTeamMirrorRequest:ctor()
  self.endpoint = "uploadCrossGvgTeamMirror"--<<<<< 1. 修改指令名称 后端提供
  self.succeedEventName = self.endpoint .. "Succeed"
  self.failedEventName = self.endpoint .. "Failed"
end

function UploadCrossGvgTeamMirrorRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(self.succeedEventName, data))
end

function UploadCrossGvgTeamMirrorRequest:onError( error )
  self:dispatchEvent(Event.new(self.failedEventName, {retCode = error}))
end

-------------------------------------------------------------------静态函数

--发送请求 默认处理 成功返回之后可加额外处理(参数可传nil)
function UploadCrossGvgTeamMirrorRequest.sendRequestDefalut(afterSucceedCallback)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
	local function onSucceed(evt)
		UploadCrossGvgTeamMirrorRequest.onSucceedDefault(evt)
		if afterSucceedCallback then
			afterSucceedCallback(evt)
		end
	end
	UploadCrossGvgTeamMirrorRequest.sendRequest(onSucceed, UploadCrossGvgTeamMirrorRequest.onFailedDefault)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
end

--发送请求
function UploadCrossGvgTeamMirrorRequest.sendRequest(succeedCallback, failedCallback)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
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

	if not UploadCrossGvgTeamMirrorRequest.TEST then
		--非测试状态 正常流程
		if SystemManager.debug then
			print("UploadCrossGvgTeamMirrorRequest->params = " .. tostringRich(params, 2))--深度2 防止打印内容过多 一般够用
		end
		local request = UploadCrossGvgTeamMirrorRequest.new(params, rpc.SendingPriority.kHigh)
		request:addEventListener(request.succeedEventName, onSucceedHandle)
		request:addEventListener(request.failedEventName, onFailedHandle)
		request:start()
	else
		--测试流程 假数据
		onSucceedHandle(UploadCrossGvgTeamMirrorRequest.getDebugDatas())
	end
end

--成功的默认处理
function UploadCrossGvgTeamMirrorRequest.onSucceedDefault(event)--<<<<< 3. 成功的默认处理 do someting
	if SystemManager.debug then
		print("UploadCrossGvgTeamMirrorRequest->event = " .. tostringRich(event))
	end

	CrossUnionPkData.setTeamMirrorRemind(false)
	UnionManager.eventDispatcher:dispatchEvent(Event.new(CrossUnionPkConsts.REFRESH_SHINE_SAVE_TEAM))

	local scene = Director:mgr():run()
	SuspensionLabel:showContent(scene, Localization:getInstance():getText("WGVG_Detail52"))--成功使用奋力一击
end

--失败默认处理
function UploadCrossGvgTeamMirrorRequest.onFailedDefault(event)
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
function UploadCrossGvgTeamMirrorRequest.getDebugDatas()
	local testEvt = {data = {}}

	return testEvt
end