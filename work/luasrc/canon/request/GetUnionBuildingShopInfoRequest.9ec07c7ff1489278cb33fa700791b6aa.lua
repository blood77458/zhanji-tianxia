require "canon.request.BaseRequest"

--
-- GetUnionBuildingShopInfoRequest
--

GetUnionBuildingShopInfoRequest = class(BaseRequest)

function GetUnionBuildingShopInfoRequest:ctor()
  self.endpoint = "getUnionBuildingShopInfo"
end

function GetUnionBuildingShopInfoRequest:onSuccess( data )
  self:dispatchEvent(Event.new(RequestNotifyEnum.GetUnionBuildingShopInfoSucceed, data))
end

function GetUnionBuildingShopInfoRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.GetUnionBuildingShopInfoFailed, {retCode = error}))
end

function GetUnionBuildingShopInfoRequest.sendRequest(succeedCallback, failedCallback, params)
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
	local request = GetUnionBuildingShopInfoRequest.new(params or {}, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.GetUnionBuildingShopInfoSucceed, onSucceedHandle)
	request:addEventListener(RequestNotifyEnum.GetUnionBuildingShopInfoFailed, onFailedHandle)
	request:start()
end

function GetUnionBuildingShopInfoRequest.onSucceedDefault(event)
	print("onSucceedDefault! event = " .. table.tostring(event))
  UnionManager.setUnionLevel(event.data.level)
	UnionManager.setShopSpecialInfoList(event.data.specialProps)
	UnionManager.setSpecialBroughtList(event.data.specialShopRecord)--更新已购买清单
end

function GetUnionBuildingShopInfoRequest.onFailedDefault(event)
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