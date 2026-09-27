require "canon.request.BaseRequest"

--
--GetCrossPkReportRequest
--

GetCrossPkReportRequest = class(BaseRequest)

function GetCrossPkReportRequest:ctor()
  self.endpoint = "getCrossPkReport"
end

function GetCrossPkReportRequest:onSuccess( data )
  self:dispatchEvent(Event.new(RequestNotifyEnum.GetCrossPkReportSucceed, data))
end

function GetCrossPkReportRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.GetCrossPkReportFailed, {retCode = error}))
end

function GetCrossPkReportRequest.sendRequest(succeedCallback, failedCallback, params)
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
	local request = GetCrossPkReportRequest.new(params or {}, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.GetCrossPkReportSucceed, onSucceedHandle)
	request:addEventListener(RequestNotifyEnum.GetCrossPkReportFailed, onFailedHandle)
	request:start()
end

function GetCrossPkReportRequest.onSucceedDefault(event)
  
end

function GetCrossPkReportRequest.onFailedDefault(event)
  local errorCode = tonumber(event.data.retCode)
  --print("GetCrossPkReportRequest.onFailedDefault" .. errorCode)
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
  elseif errorCode == 710574 then  --wrong time
		local function closeCanonMessageBox()
    end
    local text = Localization:getInstance():getText("cross_wrong_errorCode9")
    CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
  else
    local function closeCanonMessageBox()
    end
    local text = Localization:getInstance():getText("defaultError_popupText", {errorCodeId = event.data.retCode})
    CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
  end
end