require "canon.request.BaseRequest"

--
-- ReceiveUnionWageRequest
--

ReceiveUnionWageRequest = class(BaseRequest)

function ReceiveUnionWageRequest:ctor()
  self.endpoint = "receiveUnionWage"
end

function ReceiveUnionWageRequest:onSuccess( data )
  self:dispatchEvent(Event.new(RequestNotifyEnum.ReceiveUnionWageSucceed, data))
end

function ReceiveUnionWageRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.ReceiveUnionWageFailed, {retCode = error}))
end

function ReceiveUnionWageRequest.sendRequest(succeedCallback, failedCallback, params)
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
	local request = ReceiveUnionWageRequest.new(params or {}, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.ReceiveUnionWageSucceed, onSucceedHandle)
	request:addEventListener(RequestNotifyEnum.ReceiveUnionWageFailed, onFailedHandle)
	request:start()
end

function ReceiveUnionWageRequest.onSucceedDefault(event)
  RewardManager:getReward(event.data.rewards)
end

function ReceiveUnionWageRequest.onFailedDefault(event)
  if event.data.retCode == 710516 then
    local aContent = Localization:getInstance():getText("union_shop_item_buy_not_satisfied2")
    -- SuspensionLabel:showContent(Director:mgr():run(), aContent)
    NewPackageFullPanel:show()
  elseif event.data.retCode == 716370 then
    local aContent = Localization:getInstance():getText("union_shop_item_buy_not_satisfied2")
    -- SuspensionLabel:showContent(Director:mgr():run(), aContent)
    NewPackageFullPanel:show()
  elseif event.data.retCode == 716372 then
    local aContent = Localization:getInstance():getText("union_bank_salary_get_button_finish")
    SuspensionLabel:showContent(Director:mgr():run(), aContent)
  elseif event.data.retCode == 716371 then
    local aContent = Localization:getInstance():getText("EC_RECEIVE_UNION_WAGE")
    SuspensionLabel:showContent(Director:mgr():run(), aContent)
  else
    local function closeCanonMessageBox()
    end
    local text = Localization:getInstance():getText("defaultError_popupText", {errorCodeId = event.data.retCode})
    CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
  end
end