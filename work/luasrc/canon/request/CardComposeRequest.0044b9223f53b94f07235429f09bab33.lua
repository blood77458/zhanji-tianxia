--卡牌合成Request
require "canon.request.BaseRequest"

CardComposeRequest = class(BaseRequest)

function CardComposeRequest:ctor(params, priority)
    --参数1：masterId
    --参数2：slaveIds
	self.endpoint = "upgradeCard"
    self.data = nil
    self.params = params
end

function CardComposeRequest:onSuccess( data )
    --print(table.tostring(data))
    self:dispatchEvent( Event.new( RequestNotifyEnum.CardComposeSucceed , data ) )
end

function CardComposeRequest:onError(error)
	self:dispatchEvent(Event.new(RequestNotifyEnum.CardComposeFailed, error))
end
