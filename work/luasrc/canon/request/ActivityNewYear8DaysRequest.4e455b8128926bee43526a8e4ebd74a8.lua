require "canon.request.BaseRequest"

GainDayRewardRequest = class(BaseRequest)

--gain day reward (the same day)
function GainDayRewardRequest:ctor(params, priority)
	self.endpoint = "gainDayReward"
	self.data = nil
	self.params = params
end

function GainDayRewardRequest:onSuccess( data )
  self:dispatchEvent( Event.new( RequestNotifyEnum.GainDayRewardSucceed , data ) )
end

function GainDayRewardRequest:onError(error)
  self:dispatchEvent( Event.new( RequestNotifyEnum.GainDayRewardFailed , error ) )
end