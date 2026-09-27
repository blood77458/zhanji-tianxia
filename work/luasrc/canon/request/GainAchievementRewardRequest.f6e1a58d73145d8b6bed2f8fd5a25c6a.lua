require "canon.request.BaseRequest"

--
-- GainAchievementRewardRequest
--

GainAchievementRewardRequest = class(BaseRequest)

function GainAchievementRewardRequest:ctor()
  self.endpoint = "gainAchievementReward"
end

function GainAchievementRewardRequest:onSuccess( data )
  self:dispatchEvent(Event.new(RequestNotifyEnum.GainAchievementRewardSucceed, data))
end

function GainAchievementRewardRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.GainAchievementRewardFailed, {retCode = error}))
end

function GainAchievementRewardRequest.sendRequest(succeedCallback, failedCallback, params)
	local function onSucceedHandle(event)
		if succeedCallback then
			succeedCallback(event)
		end
	end 
	local function onFailedHandle(event)
		if failedCallback then
			failedCallback(event)
		end
	end
	local request = GainAchievementRewardRequest.new(params or {}, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.GainAchievementRewardSucceed, onSucceedHandle)
	request:addEventListener(RequestNotifyEnum.GainAchievementRewardFailed, onFailedHandle)
	request:start()
end

function GainAchievementRewardRequest.onSucceedDefault(event)
  
end

function GainAchievementRewardRequest.onFailedDefault(event)
  local errorCode = tonumber(event.data.retCode)
  if(errorCode == 6494) then
		local function closeCanonMessageBox()
    end
    local text = Localization:getInstance():getText("achieve_task_failed")
    CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
  else
    local function closeCanonMessageBox()
    end
    local text = Localization:getInstance():getText("defaultError_popupText", {errorCodeId = event.data.retCode})
    CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
  end
end