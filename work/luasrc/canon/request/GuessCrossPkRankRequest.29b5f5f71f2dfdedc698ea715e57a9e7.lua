require "canon.request.BaseRequest"

--
--GuessCrossPkRankRequest
--

GuessCrossPkRankRequest = class(BaseRequest)

function GuessCrossPkRankRequest:ctor()
  self.endpoint = "guessCrossPkRank"
end

function GuessCrossPkRankRequest:onSuccess( data )
  self:dispatchEvent(Event.new(RequestNotifyEnum.GuessCrossPkRankSucceed, data))
end

function GuessCrossPkRankRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.GuessCrossPkRankFailed, {retCode = error}))
end

function GuessCrossPkRankRequest.sendRequest(succeedCallback, failedCallback, params)
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
	local request = GuessCrossPkRankRequest.new(params or {}, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.GuessCrossPkRankSucceed, onSucceedHandle)
	request:addEventListener(RequestNotifyEnum.GuessCrossPkRankFailed, onFailedHandle)
	request:start()
end

function GuessCrossPkRankRequest.onSucceedDefault(event)
  
end

function GuessCrossPkRankRequest.onFailedDefault(event)
  local errorCode = tonumber(event.data.retCode)
  --print("GuessCrossPkRankRequest.onFailedDefault" .. errorCode)
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
  elseif errorCode == 710564 then  --guess not open
		local function closeCanonMessageBox()
    end
    local text = Localization:getInstance():getText("cross_wrong_errorCode2")
    CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
  elseif errorCode == 710565 then  --already guessed
		local function closeCanonMessageBox()
    end
    local text = Localization:getInstance():getText("cross_wrong_errorCode3")
    CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
  else
    local function closeCanonMessageBox()
    end
    local text = Localization:getInstance():getText("defaultError_popupText", {errorCodeId = event.data.retCode})
    CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
  end
end