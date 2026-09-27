require "canon.request.BaseRequest"

--
--GainCrossPkServerRewardRequest
--

GainCrossPkServerRewardRequest = class(BaseRequest)

function GainCrossPkServerRewardRequest:ctor()
  self.endpoint = "gainCrossPkServerReward"
end

function GainCrossPkServerRewardRequest:onSuccess( data )
  self:dispatchEvent(Event.new(RequestNotifyEnum.GainCrossPkServerRewardSucceed, data))
end

function GainCrossPkServerRewardRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.GainCrossPkServerRewardFailed, {retCode = error}))
end

function GainCrossPkServerRewardRequest.sendRequest(succeedCallback, failedCallback, params)
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
	local request = GainCrossPkServerRewardRequest.new(params or {}, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.GainCrossPkServerRewardSucceed, onSucceedHandle)
	request:addEventListener(RequestNotifyEnum.GainCrossPkServerRewardFailed, onFailedHandle)
	request:start()
end

function GainCrossPkServerRewardRequest.onSucceedDefault(event)
  RewardManager:getReward(event.data.rewards)
  AcrossFightManager.gainServerRewardSucceed()
end

function GainCrossPkServerRewardRequest.onFailedDefault(event)
  local errorCode = tonumber(event.data.retCode)
  --print("GainCrossPkServerRewardRequest.onFailedDefault" .. errorCode)
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
  elseif errorCode == 710567 then  --reward gained
		local function closeCanonMessageBox()
    end
    local text = Localization:getInstance():getText("cross_wrong_errorCode5")
    CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
  elseif errorCode == 710568 then  --server not winner
		local function closeCanonMessageBox()
    end
    local text = Localization:getInstance():getText("cross_wrong_errorCode6")
    CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
  else
    local function closeCanonMessageBox()
    end
    local text = Localization:getInstance():getText("defaultError_popupText", {errorCodeId = event.data.retCode})
    CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
  end
end