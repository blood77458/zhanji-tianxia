require "canon.request.BaseRequest"

QuestionActGetStateRequest = class(BaseRequest)

function QuestionActGetStateRequest:ctor()
    self.endpoint = "getQuestionInfo"
end

function QuestionActGetStateRequest:onSuccess( data )
    self:dispatchEvent(Event.new(RequestNotifyEnum.QuestionActGetStateRequestSucceed,data))
end

function QuestionActGetStateRequest:onError( error )
    self:dispatchEvent(Event.new(RequestNotifyEnum.QuestionActGetStateRequestFailed,error))
end