require "canon.request.BaseRequest"

WantedActivityChallengeRequest = class(BaseRequest)

function WantedActivityChallengeRequest:ctor()
    self.endpoint = "challengeWanted"
end

function WantedActivityChallengeRequest:onSuccess( data )
    self:dispatchEvent(Event.new(RequestNotifyEnum.WantedActivityChallengeRequestSucceed,data))
end

function WantedActivityChallengeRequest:onError( error )
    self:dispatchEvent(Event.new(RequestNotifyEnum.WantedActivityChallengeRequestFailed,error))
end