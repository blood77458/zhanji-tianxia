require "canon.request.BaseRequest"

--
-- BuyUnionPropRequest
--

BuyUnionPropRequest = class(BaseRequest)

function BuyUnionPropRequest:ctor()
  self.endpoint = "buyUnionProp"
end

function BuyUnionPropRequest:onSuccess( data )
  self:dispatchEvent(Event.new(RequestNotifyEnum.BuyUnionPropSucceed, data))
end

function BuyUnionPropRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.BuyUnionPropFailed, {retCode = error}))
end

function BuyUnionPropRequest.sendRequest(succeedCallback, failedCallback, params)
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
	local request = BuyUnionPropRequest.new(params or {}, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.BuyUnionPropSucceed, onSucceedHandle)
	request:addEventListener(RequestNotifyEnum.BuyUnionPropFailed, onFailedHandle)
	request:start()
end

function BuyUnionPropRequest.onSucceedDefault(event)
  
end

function BuyUnionPropRequest.onFailedDefault(event)
  if event.data.retCode == 710516 then
    local aContent = Localization:getInstance():getText("union_shop_item_buy_not_satisfied2")
    -- SuspensionLabel:showContent(Director:mgr():run(), aContent)
    NewPackageFullPanel:show()
  elseif event.data.retCode == 716370 then
    local aContent = Localization:getInstance():getText("union_shop_item_buy_not_satisfied1")
    SuspensionLabel:showContent(Director:mgr():run(), aContent)
  elseif event.data.retCode == 716366 then  --special prop time limit
    local aContent = Localization:getInstance():getText("union_shop_item_buy_not_satisfied3")
    SuspensionLabel:showContent(Director:mgr():run(), aContent)
  elseif event.data.retCode == 716367 then  --special prop not on sale
    local aContent = Localization:getInstance():getText("union_shop_item_buy_not_satisfied4")
    SuspensionLabel:showContent(Director:mgr():run(), aContent)
  elseif event.data.retCode == 716365 then  --normal prop time limit
    local aContent = Localization:getInstance():getText("union_shop_item_buy_not_satisfied5")
    SuspensionLabel:showContent(Director:mgr():run(), aContent)
  elseif event.data.retCode == 716373 then  --rare prop only buy once 
    local aContent = Localization:getInstance():getText("EC_BUY_UNION_PROP")
    SuspensionLabel:showContent(Director:mgr():run(), aContent)
  elseif(errorCode == 716313) then -- User has not joined any union: {0:uid}
    CanonMessageBox:showCommErrorBox(CommErrorCodes.USER_NOT_JOIN_ANY_UNION, nil, nil, nil)
  else
    local function closeCanonMessageBox()
    end
    local text = Localization:getInstance():getText("defaultError_popupText", {errorCodeId = event.data.retCode})
    CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
  end
end