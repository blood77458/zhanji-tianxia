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

InspireCrossGvgRequest = class(BaseRequest)
--测试状态 仅限内部测试用(一般用于假数据)
InspireCrossGvgRequest.TEST = false --提测之前请务必改回默认 false !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

function InspireCrossGvgRequest:ctor()
  self.endpoint = "inspireCrossGvg"--<<<<< 1. 修改指令名称 后端提供
  self.succeedEventName = self.endpoint .. "Succeed"
  self.failedEventName = self.endpoint .. "Failed"
end

function InspireCrossGvgRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(self.succeedEventName, data))
end

function InspireCrossGvgRequest:onError( error )
  self:dispatchEvent(Event.new(self.failedEventName, {retCode = error}))
end

-------------------------------------------------------------------静态函数

--发送请求 默认处理 成功返回之后可加额外处理(参数可传nil)
function InspireCrossGvgRequest.sendRequestDefalut(params , afterSucceedCallback)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
	local function onSucceed(evt)
		InspireCrossGvgRequest.onSucceedDefault(evt)
		if afterSucceedCallback then
			afterSucceedCallback(evt)
		end
	end
	InspireCrossGvgRequest.sendRequest(params,onSucceed, InspireCrossGvgRequest.onFailedDefault)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
end

--发送请求
function InspireCrossGvgRequest.sendRequest(params,succeedCallback, failedCallback)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
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

	if not InspireCrossGvgRequest.TEST then
		--非测试状态 正常流程
		if SystemManager.debug then
			print("InspireCrossGvgRequest->params = " .. tostringRich(params, 2))--深度2 防止打印内容过多 一般够用
		end
		local request = InspireCrossGvgRequest.new(params, rpc.SendingPriority.kHigh)
		request:addEventListener(request.succeedEventName, onSucceedHandle)
		request:addEventListener(request.failedEventName, onFailedHandle)
		request:start()
	else
		--测试流程 假数据
		onSucceedHandle(InspireCrossGvgRequest.getDebugDatas())
	end
end

--成功的默认处理
function InspireCrossGvgRequest.onSucceedDefault(event)--<<<<< 3. 成功的默认处理 do someting
	if SystemManager.debug then
		print("InspireCrossGvgRequest->event = " .. tostringRich(event))
	end

		--增加攻防数 同时扣钱 提示
	local buffId = event.params.type
	CrossUnionPkData.increaseSelfInspireNum( buffId )
	if buffId == 2 then
		--银币鼓舞
		CrossUnionPkData.setCoinInspireValue(CrossUnionPkData.getCoinInspireValue() + 1)
		RewardManager:getReward({{itemType = ResourceEnum.COIN, amount = (-UnionPkConfig.silverBuffCost() or 0)}})

		local scene = Director:mgr():run()
		SuspensionLabel:showContent(scene, Localization:getInstance():getText("UnionWar_battle_success1"))--成功使用银币鼓舞
	elseif buffId == 1 then
		--金币鼓舞
		CrossUnionPkData.setGemInspireValue(CrossUnionPkData.getGemInspireValue() + 1)
		RewardManager:getReward({{itemType = ResourceEnum.GEMS, amount = (-UnionPkConfig.goldBuffCost() or 0)}})

		local scene = Director:mgr():run()
		SuspensionLabel:showContent(scene, Localization:getInstance():getText("UnionWar_battle_success2"))--成功使用金币鼓舞
	else
		--奋力一击
		CrossUnionPkData.setStriveInspireNum(CrossUnionPkData.getStriveInspireNum() + 1)
		RewardManager:getReward({{itemType = ResourceEnum.GEMS, amount = (-UnionPkConfig.striveCost() or 0)}})
		
		local scene = Director:mgr():run()
		SuspensionLabel:showContent(scene, Localization:getInstance():getText("UnionWar_battle_success3"))--成功使用奋力一击
	end
end

--失败默认处理
function InspireCrossGvgRequest.onFailedDefault(event)
	local errorCode = tonumber(event.data.retCode)
	local function onErrorConfirm(errorCode)
		if errorCode == 716313 then
			--玩家没加入任何军团 返回主界面
			local scene = Director:mgr():run()
			scene:replaceScene(MainMenuScene)
		elseif errorCode == 717002 then
			--金币鼓舞超过上限 刷新鼓舞次数
			UnionManager.eventDispatcher:dispatchEvent(Event.new(CrossUnionPkConsts.NEED_REFRESH_TEAM_ADJUST_SCENE))
		end
	end
	local ret = ErrorCodeManager.alert(errorCode, onErrorConfirm)
end


--获得测试用假数据--<<<<< 4. 根据需要填写测试假数据 用完删除
function InspireCrossGvgRequest.getDebugDatas()
	local testEvt = {data = {}}

	return testEvt
end