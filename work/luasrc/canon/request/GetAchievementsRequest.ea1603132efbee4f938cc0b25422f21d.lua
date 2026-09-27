require "canon.request.BaseRequest"

--
-- GetAchievementsRequest
--

GetAchievementsRequest = class(BaseRequest)

function GetAchievementsRequest:ctor()
  self.endpoint = "getAchievements"
end

function GetAchievementsRequest:onSuccess( data )
  self:dispatchEvent(Event.new(RequestNotifyEnum.GetAchievementsSucceed, data))
end

function GetAchievementsRequest:onError( error )
	--Failed
  self:dispatchEvent(Event.new(RequestNotifyEnum.GetAchievementsFailed, {retCode = error}))
  BaseRequest.onError(self, error)
end