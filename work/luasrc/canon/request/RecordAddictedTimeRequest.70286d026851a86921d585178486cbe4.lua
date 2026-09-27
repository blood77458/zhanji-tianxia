require "canon.request.BaseRequest"

RecordAddictedTimeRequest = class(BaseRequest)

function RecordAddictedTimeRequest:ctor(params, priority)
	self.endpoint = "recordAddictedTime"
	self.data = nil
	self.params = params
end

function RecordAddictedTimeRequest:onSuccess( data )
  self:dispatchEvent( Event.new( RequestNotifyEnum.RecordAddictedTimeSucceed , data ) )
end

function RecordAddictedTimeRequest:onError(error)
  self:dispatchEvent( Event.new( RequestNotifyEnum.RecordAddictedTimeFailed , error ) )
end