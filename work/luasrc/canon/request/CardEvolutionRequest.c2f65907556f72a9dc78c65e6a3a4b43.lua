--卡牌进化Request
require "canon.request.BaseRequest"

CardEvolutionRequest = class(BaseRequest)

function CardEvolutionRequest:ctor(params, priority)
  --参数1：masterId
  --参数2：slaveId
  self.endpoint = "evolveCard"
  self.data = nil
  self.params = params
end

function CardEvolutionRequest:onSuccess( data )
    --Communication:getInstance():putOthers("serverId", self.params.serverId)
  self:dispatchEvent( Event.new( RequestNotifyEnum.CardEvolutionSucceed , data ) )
end

function CardEvolutionRequest:onError(error)
	self:dispatchEvent( Event.new( RequestNotifyEnum.CardEvolutionFailed , error ) )
end
