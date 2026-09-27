require "canon.request.BaseRequest"

QuestionActDailyRewardRequest = class(BaseRequest)

function QuestionActDailyRewardRequest:ctor()
    self.endpoint = "getQuestionDailyReward"
end

function QuestionActDailyRewardRequest:onSuccess( data )
    self:dispatchEvent(Event.new(RequestNotifyEnum.QuestionActDailyRewardRequestSucceed,data))
end

function QuestionActDailyRewardRequest:onError( error )
    self:dispatchEvent(Event.new(RequestNotifyEnum.QuestionActDailyRewardRequestFailed,error))
end