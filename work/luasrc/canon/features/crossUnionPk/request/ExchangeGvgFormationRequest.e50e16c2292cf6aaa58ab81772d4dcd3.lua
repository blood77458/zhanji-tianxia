-- <?xml version="1.0" encoding="UTF-8"?>
-- <protocol desc="调整阵型">
-- 	<request>
-- 		<property code="override" type="boolean" desc="是否强制覆盖" />
-- 		<property code="unionId" type="int" desc="军团id" />
-- 		<property code="serverId" type="int" desc="服务器" />
-- 		<property code="version" type="int" desc="阵型版本号" />
-- 		<property code="forwardUid" type="long" desc="单挑战玩家id" />
-- 		<list code="headUids" type="long" desc="阵首玩家id" />
-- 		<list code="middleUids" type="long" desc="阵中玩家id" />
-- 		<list code="tailUids" type="long" desc="阵尾玩家id" />
-- 	</request>
-- 	<response>
-- 	</response>
-- </protocol>

require "canon.request.BaseRequest"

ExchangeGvgFormationRequest = class(BaseRequest)
--测试状态 仅限内部测试用(一般用于假数据)
ExchangeGvgFormationRequest.TEST = false --提测之前请务必改回默认 false !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

function ExchangeGvgFormationRequest:ctor()
  self.endpoint = "exchangeGvgFormation"--<<<<< 1. 修改指令名称 后端提供
  self.succeedEventName = self.endpoint .. "Succeed"
  self.failedEventName = self.endpoint .. "Failed"
end

function ExchangeGvgFormationRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(self.succeedEventName, data))
end

function ExchangeGvgFormationRequest:onError( error )
  self:dispatchEvent(Event.new(self.failedEventName, {retCode = error}))
end

-------------------------------------------------------------------静态函数

--发送请求 默认处理 成功返回之后可加额外处理(参数可传nil)
function ExchangeGvgFormationRequest.sendRequestDefalut(params , afterSucceedCallback)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
	local function onSucceed(evt)
		ExchangeGvgFormationRequest.onSucceedDefault(evt)
		if afterSucceedCallback then
			afterSucceedCallback(evt)
		end
	end
	ExchangeGvgFormationRequest.sendRequest(params, onSucceed, ExchangeGvgFormationRequest.onFailedDefault)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
end

--发送请求
function ExchangeGvgFormationRequest.sendRequest(params,succeedCallback, failedCallback)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
	local params = params--<<<<< 2. 附加参数转换成后端提供的接口格式
	if tonumber(params.forwardUid) == 0 then
		local scene = Director:mgr():run()
		SuspensionLabel:showContent(scene, Localization:getInstance():getText("UnionWar_wrong_txt2"))--阵型调整失败，阵容内未设置单挑武将，请进行设置
		return
	end

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

	if not ExchangeGvgFormationRequest.TEST then
		--非测试状态 正常流程
		if SystemManager.debug then
			print("ExchangeGvgFormationRequest->params = " .. tostringRich(params, 2))--深度2 防止打印内容过多 一般够用
		end
		local request = ExchangeGvgFormationRequest.new(params, rpc.SendingPriority.kHigh)
		request:addEventListener(request.succeedEventName, onSucceedHandle)
		request:addEventListener(request.failedEventName, onFailedHandle)
		request:start()
	else
		--测试流程 假数据
		onSucceedHandle(ExchangeGvgFormationRequest.getDebugDatas())
	end
end

--成功的默认处理
function ExchangeGvgFormationRequest.onSucceedDefault(event)--<<<<< 3. 成功的默认处理 do someting
	if SystemManager.debug then
		print("ExchangeGvgFormationRequest->event = " .. tostringRich(event))
	end

	CrossUnionPkData.setTeamAdjustLightOn(false)
	UnionManager.eventDispatcher:dispatchEvent(Event.new(CrossUnionPkConsts.REFRESH_SHINE_SAVE_TEAM))

	local scene = Director:mgr():run()
	SuspensionLabel:showContent(scene, Localization:getInstance():getText("WGVG_Detail72"))--成功使用奋力一击
end

--失败默认处理
function ExchangeGvgFormationRequest.onFailedDefault(event)
	local errorCode = tonumber(event.data.retCode)
	if errorCode == 717010 then---需要强制覆盖
		CanonMessageBox.showText(
		        ShowButtonType.ID_OK_CANCEL,
		        getTextByKey("WGVG_Detail25"),
		        {
		            text = getTextByKey("yes"),
		            callbackFunc = function()
		                local function onAfterSucceed(evt)
							UnionManager.eventDispatcher:dispatchEvent(Event.new(CrossUnionPkConsts.NEED_REFRESH_TEAM_ADJUST_SCENE))
						end
						local params = CrossUnionPkData.getUploadTeamParams(true)
						ExchangeGvgFormationRequest.sendRequestDefalut(params ,onAfterSucceed)
		            end
		        }
		    )
		return
	end
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
function ExchangeGvgFormationRequest.getDebugDatas()
	local testEvt = {data = {}}

	return testEvt
end