-- GainDailyAchieveRequest.lua
-- 2014-9-25
-- zheng.che
-- 获取每日成就信息

require "canon.request.BaseRequest"

GainDailyAchieveRequest = class(BaseRequest)

function GainDailyAchieveRequest:ctor()
  self.endpoint = "gainDailyAchieveReward"--<<<<< 1. 修改指令名称 后端提供
  self.succeedEventName = self.endpoint .. "Succeed"
  self.failedEventName = self.endpoint .. "Failed"
end

function GainDailyAchieveRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(self.succeedEventName, data))
end

function GainDailyAchieveRequest:onError( error )
  self:dispatchEvent(Event.new(self.failedEventName, {retCode = error}))
end

-------------------------------------------------------------------静态函数

--发送请求 默认处理 成功返回之后可加额外处理(参数可传nil)
function GainDailyAchieveRequest.sendRequestDefalut(achieveId, afterSucceedCallback)--<<<<< 3
	local function onSucceed(evt)
		GainDailyAchieveRequest.onSucceedDefault(evt)
		if afterSucceedCallback then
			afterSucceedCallback(evt)
		end
	end
	GainDailyAchieveRequest.sendRequest(achieveId, onSucceed, GainDailyAchieveRequest.onFailedDefault)
end

--发送请求
function GainDailyAchieveRequest.sendRequest(achieveId, succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
	local params = {achieveId = achieveId}--<<<<< 3

	local function onSucceedHandle(event)
		if succeedCallback then
			event.params = params
			succeedCallback(event)--<<<<< 3
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
	local request = GainDailyAchieveRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(request.succeedEventName, onSucceedHandle)
	request:addEventListener(request.failedEventName, onFailedHandle)
	request:start()
end

--成功的默认处理
function GainDailyAchieveRequest.onSucceedDefault(event)--<<<<< 3
	if SystemManager.debug then
		print("onSucceedDefault! event = " .. table.tostring(event))
	end

	--获得奖励
	RewardManager:getReward(event.data.rewards)

    --显示获得的奖励
    local scene = Director:mgr():run()
	local aRewardPanel = RewardReviewPanel:create( scene, {rewardList = event.data.rewards, rewardTitle = Localization:getInstance():getText("activity_newyear_rewardTitle")} )
	scene:addChild(aRewardPanel)
	aRewardPanel:scaleIn()
end

--失败默认处理
function GainDailyAchieveRequest.onFailedDefault(event)--<<<<< 4. 修改错误码对应逻辑处理
	local errorCode = tonumber(event.data.retCode)
	if(errorCode == 710516) then
		self.targetInfoPanel = NewPackageFullPanel:show()
	else
		local function closeCanonMessageBox()
		end
		local text = Localization:getInstance():getText("defaultError_popupText", {errorCodeId = event.data.retCode})
		CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
	end
end