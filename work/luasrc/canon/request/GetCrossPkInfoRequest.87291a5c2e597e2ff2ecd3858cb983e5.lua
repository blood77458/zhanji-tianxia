require "canon.request.BaseRequest"

--
--GetCrossPkInfoRequest
--

GetCrossPkInfoRequest = class(BaseRequest)

function GetCrossPkInfoRequest:ctor()
  self.endpoint = "getCrossPkInfo"
end

function GetCrossPkInfoRequest:onSuccess( data )
  self:dispatchEvent(Event.new(RequestNotifyEnum.GetCrossPkInfoSucceed, data))
end

function GetCrossPkInfoRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.GetCrossPkInfoFailed, {retCode = error}))
end

function GetCrossPkInfoRequest.sendRequest(succeedCallback, failedCallback, params)
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
	local request = GetCrossPkInfoRequest.new(params or {}, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.GetCrossPkInfoSucceed, onSucceedHandle)
	request:addEventListener(RequestNotifyEnum.GetCrossPkInfoFailed, onFailedHandle)
	request:start()
end

function GetCrossPkInfoRequest.onSucceedDefault(event)
  --print(table.tostring(event.data.crossPkGroupInfo))
  AcrossFightManager.resetCrossPKInfo(event.data.crossPkGroupInfo)
end

function GetCrossPkInfoRequest.onFailedDefault(event)
  local errorCode = tonumber(event.data.retCode)
  --print("GetCrossPkInfoRequest.onFailedDefault" .. errorCode)
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