require "canon.request.BaseRequest"

--
--GainCrossPkGuessRewardRequest
--

GainCrossPkGuessRewardRequest = class(BaseRequest)

function GainCrossPkGuessRewardRequest:ctor()
  self.endpoint = "gainCrossPkGuessReward"
end

function GainCrossPkGuessRewardRequest:onSuccess( data )
  self:dispatchEvent(Event.new(RequestNotifyEnum.GainCrossPkGuessRewardSucceed, data))
end

function GainCrossPkGuessRewardRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.GainCrossPkGuessRewardFailed, {retCode = error}))
end

function GainCrossPkGuessRewardRequest.sendRequest(succeedCallback, failedCallback, params)
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
	local request = GainCrossPkGuessRewardRequest.new(params or {}, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.GainCrossPkGuessRewardSucceed, onSucceedHandle)
	request:addEventListener(RequestNotifyEnum.GainCrossPkGuessRewardFailed, onFailedHandle)
	request:start()
end

function GainCrossPkGuessRewardRequest.onSucceedDefault(event)
  RewardManager:getReward(event.data.rewards)
  AcrossFightManager.gainGuessRewardSucceed()
end

function GainCrossPkGuessRewardRequest.onFailedDefault(event)
  local errorCode = tonumber(event.data.retCode)
  --print("GainCrossPkGuessRewardRequest.onFailedDefault" .. errorCode)
  if errorCode == 710560 or errorCode == 710561 then --not open
		local function closeCanonMessageBox()
    end
    local text = Localization:getInstance():getText("cross_wrong_errorCode1")
    CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
  elseif errorCode == 710562 or errorCode == 710563 then --wrong time
		local function closeCanonMessageBox()
    end
    local text = Localization:getInstance():getText("cross_wrong_errorCode10")
    CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
  elseif errorCode == 710566 then  --reward not open
		local function closeCanonMessageBox()
    end
    local text = Localization:getInstance():getText("cross_wrong_errorCode4")
    CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
  elseif errorCode == 710572 then  --reward gained
		local function closeCanonMessageBox()
    end
    local text = Localization:getInstance():getText("cross_wrong_errorCode5")
    CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
  elseif errorCode == 710573 then  --not guessed
		local function closeCanonMessageBox()
    end
    local text = Localization:getInstance():getText("cross_wrong_errorCode8")
    CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
  else
    local function closeCanonMessageBox()
    end
    local text = Localization:getInstance():getText("defaultError_popupText", {errorCodeId = event.data.retCode})
    CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
  end
end