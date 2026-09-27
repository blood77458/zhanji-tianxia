-- ConsumeRewardGainRequest.lua
-- 2014-12-17
-- zheng.che
-- 多重好礼获取面板信息接口

--<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< 接口定义 后端提供
-- <protocol desc="领取多重好礼活动奖励">
-- 	<request>
-- 		<property code="id" type="int" desc="奖励id" />
-- 	</request>
-- 	<response>
-- 		<list code="rewards" ref="Reward" desc="奖励" />
-- 	</response>
-- </protocol>

require "canon.request.BaseRequest"

ConsumeRewardGainRequest = class(BaseRequest)

function ConsumeRewardGainRequest:ctor()
  self.endpoint = "gainConsumeReward"--<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< 修改指令名称 后端提供
  self.succeedEventName = self.endpoint .. "Succeed"
  self.failedEventName = self.endpoint .. "Failed"
end

function ConsumeRewardGainRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(self.succeedEventName, data))
end

function ConsumeRewardGainRequest:onError( error )
  self:dispatchEvent(Event.new(self.failedEventName, {retCode = error}))
end

-------------------------------------------------------------------静态函数

--发送请求 默认处理 成功返回之后可加额外处理(afterSucceedCallback参数可传nil)
function ConsumeRewardGainRequest.sendRequestDefalut(id, afterSucceedCallback)--<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< 如果需要附加参数 从第一个函数参数开始加
	local function onSucceed(evt)
		ConsumeRewardGainRequest.onSucceedDefault(evt)
		if afterSucceedCallback then
			afterSucceedCallback(evt)
		end
	end
	ConsumeRewardGainRequest.sendRequest(id, onSucceed, ConsumeRewardGainRequest.onFailedDefault)
end

--发送请求
function ConsumeRewardGainRequest.sendRequest(id, succeedCallback, failedCallback)--<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< 如果需要附加参数 从第一个函数参数开始加
	local params = {id = id}--<<<<<<<<<<<<<<<<<<<<<<<<<< 后端定义的所需参数填到这里

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
	
	local request = ConsumeRewardGainRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(request.succeedEventName, onSucceedHandle)
	request:addEventListener(request.failedEventName, onFailedHandle)
	request:start()
end

--成功的默认处理
function ConsumeRewardGainRequest.onSucceedDefault(event)
	if SystemManager.debug then
		print("onSucceedDefault! event = " .. table.tostring(event))
	end

	--更新数据
	Activity_ConsumeRewardsLayer.addGainedId(event.params.id)

	--获得奖励
	RewardManager:getReward(event.data.rewards)

    --显示获得的奖励
    local scene = Director:mgr():run()
	local aRewardPanel = RewardReviewPanel:create( scene, {rewardList = event.data.rewards, rewardTitle = Localization:getInstance():getText("activity_newyear_rewardTitle")} )
	scene:addChild(aRewardPanel)
	aRewardPanel:scaleIn()
end

--失败默认处理
function ConsumeRewardGainRequest.onFailedDefault(event)
	local errorCode = tonumber(event.data.retCode)
	local function onErrorConfirm(errorCode)
	end
	local ret = ErrorCodeManager.alert(errorCode, onErrorConfirm)
end