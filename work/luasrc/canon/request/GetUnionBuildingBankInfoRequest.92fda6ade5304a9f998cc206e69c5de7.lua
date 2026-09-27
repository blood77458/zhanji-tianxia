require "canon.request.BaseRequest"

--
-- GetUnionBuildingBankInfoRequest
--

GetUnionBuildingBankInfoRequest = class(BaseRequest)

function GetUnionBuildingBankInfoRequest:ctor()
  self.endpoint = "getUnionBuildingBankInfo"
end

function GetUnionBuildingBankInfoRequest:onSuccess( data )
  self:dispatchEvent(Event.new(RequestNotifyEnum.GetUnionBuildingBankInfoSucceed, data))
end

function GetUnionBuildingBankInfoRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.GetUnionBuildingBankInfoFailed, {retCode = error}))
end

function GetUnionBuildingBankInfoRequest.sendRequest(succeedCallback, failedCallback, params)
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
	local request = GetUnionBuildingBankInfoRequest.new(params or {}, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.GetUnionBuildingBankInfoSucceed, onSucceedHandle)
	request:addEventListener(RequestNotifyEnum.GetUnionBuildingBankInfoFailed, onFailedHandle)
	request:start()
end

function GetUnionBuildingBankInfoRequest.onSucceedDefault(event)
  UnionManager.setBankLevel(event.data.level)
end

function GetUnionBuildingBankInfoRequest.onFailedDefault(event)
  local errorCode = tonumber(event.data.retCode)
  if(errorCode == 716313) then -- User has not joined any union: {0:uid}
		CanonMessageBox:showCommErrorBox(CommErrorCodes.USER_NOT_JOIN_ANY_UNION, nil, nil, nil)
  else
    local function closeCanonMessageBox()
    end
    local text = Localization:getInstance():getText("defaultError_popupText", {errorCodeId = event.data.retCode})
    CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
  end
end