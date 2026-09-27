require "canon.request.BaseRequest"

--
--GetCrossPkCapacityRequest
--

GetCrossPkCapacityRequest = class(BaseRequest)

function GetCrossPkCapacityRequest:ctor()
  self.endpoint = "getCrossPkCapacity"
end

function GetCrossPkCapacityRequest:onSuccess( data )
  self:dispatchEvent(Event.new(RequestNotifyEnum.GetCrossPkCapacitySucceed, data))
end

function GetCrossPkCapacityRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.GetCrossPkCapacityFailed, {retCode = error}))
end

function GetCrossPkCapacityRequest.sendRequest(succeedCallback, failedCallback, params)
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
	local request = GetCrossPkCapacityRequest.new(params or {}, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.GetCrossPkCapacitySucceed, onSucceedHandle)
	request:addEventListener(RequestNotifyEnum.GetCrossPkCapacityFailed, onFailedHandle)
	request:start()
end

function GetCrossPkCapacityRequest.onSucceedDefault(event)
  AcrossFightManager.setCapacityList(event.data.crossPkUserCapacities)
end

function GetCrossPkCapacityRequest.onFailedDefault(event)
  local errorCode = tonumber(event.data.retCode)
  --print("GetCrossPkCapacityRequest.onFailedDefault" .. errorCode)
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
  else
    local function closeCanonMessageBox()
    end
    local text = Localization:getInstance():getText("defaultError_popupText", {errorCodeId = event.data.retCode})
    CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
  end
end