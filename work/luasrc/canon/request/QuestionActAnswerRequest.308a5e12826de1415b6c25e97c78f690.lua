require "canon.request.BaseRequest"

QuestionActAnswerRequest = class(BaseRequest)

function QuestionActAnswerRequest:ctor()
    self.endpoint = "answerQuestion"
end

function QuestionActAnswerRequest:onSuccess( data )
    self:dispatchEvent(Event.new(RequestNotifyEnum.QuestionActAnswerRequestSucceed,data))
end

function QuestionActAnswerRequest:onError( error )
    self:dispatchEvent(Event.new(RequestNotifyEnum.QuestionActAnswerRequestFailed,error))
end