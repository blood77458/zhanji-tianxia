require "canon.request.BaseRequest"

--
-- LockCardRequest
--

LockCardRequest = class(BaseRequest)

function LockCardRequest:ctor()
  self.endpoint = "lockCard"
end

function LockCardRequest:onSuccess( data )
  self:dispatchEvent(Event.new(RequestNotifyEnum.LockCardSucceed, data))
end

function LockCardRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.LockCardFailed, {retCode = error}))
end

function LockCardRequest.sendRequest(succeedCallback, failedCallback, params)
	local function onSucceedHandle(event)
		if succeedCallback then
			event = event or {}
			event.cardId = params.cardId
			succeedCallback(event)
		end
	end 
	local function onFailedHandle(event)
		if failedCallback then
			failedCallback(event)
		end
	end
	local request = LockCardRequest.new(params or {}, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.LockCardSucceed, onSucceedHandle)
	request:addEventListener(RequestNotifyEnum.LockCardFailed, onFailedHandle)
	request:start()
end

function LockCardRequest.onSucceedDefault(event)
	local cardsData = DataManager.getCardsData()
	local aCardData = CommonManager.getSubTableByKey(cardsData, {name = "cardId", value = event.cardId})
	aCardData.lock = not aCardData.lock
	DataManager.setCardsData(cardsData)
end

function LockCardRequest.onFailedDefault(event)
    local function closeCanonMessageBox()
  	end
	local text = Localization:getInstance():getText("defaultError_popupText", {errorCodeId = event.data.retCode})
	CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
end

