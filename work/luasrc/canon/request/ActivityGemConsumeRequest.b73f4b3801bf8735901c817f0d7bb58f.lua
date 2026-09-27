require "canon.request.BaseRequest"

GainGemConsumeRewardsRequest = class(BaseRequest)
GetGemConsumeInfoRequest = class(BaseRequest)

function GainGemConsumeRewardsRequest:ctor(params, priority)
	self.endpoint = "gainGemConsumeRewards"
	self.data = nil
	self.params = params
end

function GainGemConsumeRewardsRequest:onSuccess( data )
  self:dispatchEvent( Event.new( RequestNotifyEnum.GainGemConsumeRewardsSucceed , data ) )
end

function GainGemConsumeRewardsRequest:onError(error)
  BaseRequest.onError(self, error)
end

function GetGemConsumeInfoRequest:ctor(params, priority)
	self.endpoint = "getGemConsumeInfo"
	self.data = nil
	self.params = params
end

function GetGemConsumeInfoRequest:onSuccess( data )
  self:dispatchEvent( Event.new( RequestNotifyEnum.GetGemConsumeInfoSucceed , data ) )
end

function GetGemConsumeInfoRequest:onError(error)
  BaseRequest.onError(self, error)
end