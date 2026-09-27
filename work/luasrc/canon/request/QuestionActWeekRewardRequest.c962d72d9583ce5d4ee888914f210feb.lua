require "canon.request.BaseRequest"

QuestionActWeekRewardRequest = class(BaseRequest)

function QuestionActWeekRewardRequest:ctor()
    self.endpoint = "getWeekReward"
end

function QuestionActWeekRewardRequest:onSuccess( data )
    self:dispatchEvent(Event.new(RequestNotifyEnum.QuestionActWeekRewardRequestSucceed,data))
end

function QuestionActWeekRewardRequest:onError( error )
    self:dispatchEvent(Event.new(RequestNotifyEnum.QuestionActWeekRewardRequestFailed,error))
end