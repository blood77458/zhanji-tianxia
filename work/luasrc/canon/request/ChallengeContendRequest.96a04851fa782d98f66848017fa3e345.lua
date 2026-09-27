require "canon.request.BaseRequest"

--
-- ChallengeContendRequest
--

ChallengeContendRequest = class(BaseRequest)

function ChallengeContendRequest:ctor()
  self.endpoint = "challengeContend"
end

function ChallengeContendRequest:onSuccess( data )
  self:dispatchEvent(Event.new(RequestNotifyEnum.ChallengeContendSucceed, data))
end

function ChallengeContendRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.ChallengeContendFailed, {retCode = error}))
end

function ChallengeContendRequest.sendRequest(succeedCallback, failedCallback, params)
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
	local request = ChallengeContendRequest.new(params or {}, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.ChallengeContendSucceed, onSucceedHandle)
	request:addEventListener(RequestNotifyEnum.ChallengeContendFailed, onFailedHandle)
	request:start()
end

function ChallengeContendRequest.onSucceedDefault(event)
  
end

function ChallengeContendRequest.onFailedDefault(event)
  if event.data.retCode == 716801 then    --bag full
    -- local aContent = Localization:getInstance():getText("shop_inventoryFull")
    -- SuspensionLabel:showContent(Director:mgr():run(), aContent)
    NewPackageFullPanel:show()
  elseif (event.data.retCode == 716802) or (event.data.retCode == 716803) then
    --challenge num limit
    local aContent = Localization:getInstance():getText("activity_contend_runout")
    SuspensionLabel:showContent(Director:mgr():run(), aContent)
  elseif event.data.retCode == 716806 then  --activity not open
    local aContent = Localization:getInstance():getText("activity_contend_close")
    SuspensionLabel:showContent(Director:mgr():run(), aContent)
  else
    local function closeCanonMessageBox()
    end
    local text = Localization:getInstance():getText("defaultError_popupText", {errorCodeId = event.data.retCode})
    CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
  end
end