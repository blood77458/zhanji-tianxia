require "canon.request.BaseRequest"

--
-- GetUnionBuildingHallInfoRequest
--

GetUnionBuildingHallInfoRequest = class(BaseRequest)

function GetUnionBuildingHallInfoRequest:ctor()
  self.endpoint = "getUnionBuildingHallInfo"
end

function GetUnionBuildingHallInfoRequest:onSuccess( data )
  self:dispatchEvent(Event.new(RequestNotifyEnum.GetUnionBuildingHallInfoSucceed, data))
end

function GetUnionBuildingHallInfoRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.GetUnionBuildingHallInfoFailed, {retCode = error}))
end

function GetUnionBuildingHallInfoRequest.sendRequest(succeedCallback, failedCallback, params)
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
	local request = GetUnionBuildingHallInfoRequest.new(params or {}, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.GetUnionBuildingHallInfoSucceed, onSucceedHandle)
	request:addEventListener(RequestNotifyEnum.GetUnionBuildingHallInfoFailed, onFailedHandle)
	request:start()
end

function GetUnionBuildingHallInfoRequest.onSucceedDefault(event)
	--print("event = " .. table.tostring(event))

	--设置建设次数和时间
	UnionManager.setTodayBuildTotalTimes(event.data.lastestConstructSeconds, event.data.constructTimesToday)
end

function GetUnionBuildingHallInfoRequest.onFailedDefault(event)
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