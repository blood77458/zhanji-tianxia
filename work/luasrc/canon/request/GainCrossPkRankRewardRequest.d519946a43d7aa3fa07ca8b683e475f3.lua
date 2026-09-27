require "canon.request.BaseRequest"

--
--GainCrossPkRankRewardRequest
--

GainCrossPkRankRewardRequest = class(BaseRequest)

function GainCrossPkRankRewardRequest:ctor()
  self.endpoint = "gainCrossPkRankReward"
end

function GainCrossPkRankRewardRequest:onSuccess( data )
  self:dispatchEvent(Event.new(RequestNotifyEnum.GainCrossPkRankRewardSucceed, data))
end

function GainCrossPkRankRewardRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.GainCrossPkRankRewardFailed, {retCode = error}))
end

function GainCrossPkRankRewardRequest.sendRequest(succeedCallback, failedCallback, params)
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
	local request = GainCrossPkRankRewardRequest.new(params or {}, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.GainCrossPkRankRewardSucceed, onSucceedHandle)
	request:addEventListener(RequestNotifyEnum.GainCrossPkRankRewardFailed, onFailedHandle)
	request:start()
end

function GainCrossPkRankRewardRequest.onSucceedDefault(event)
  RewardManager:getReward(event.data.rewards)
  AcrossFightManager.gainRankRewardSucceed()
end

function GainCrossPkRankRewardRequest.onFailedDefault(event)
  local errorCode = tonumber(event.data.retCode)
  --print("GainCrossPkRankRewardRequest.onFailedDefault" .. errorCode)
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
  elseif errorCode == 710571 then  --reward gained
		local function closeCanonMessageBox()
    end
    local text = Localization:getInstance():getText("cross_wrong_errorCode5")
    CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
  elseif errorCode == 710569 then  --not in rank
		local function closeCanonMessageBox()
    end
    local text = Localization:getInstance():getText("cross_wrong_errorCode7")
    CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
  else
    local function closeCanonMessageBox()
    end
    local text = Localization:getInstance():getText("defaultError_popupText", {errorCodeId = event.data.retCode})
    CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
  end
end