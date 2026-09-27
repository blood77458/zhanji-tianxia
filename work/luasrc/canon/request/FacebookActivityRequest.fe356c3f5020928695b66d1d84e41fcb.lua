--
-- Facebook相关
-- Author: dc
-- Date: 2014-10-11 
--
require "canon.request.BaseRequest"

FacebookRecordTriggerShareRequest = class(BaseRequest)

function FacebookRecordTriggerShareRequest:ctor()
  self.endpoint = "recordGameFbShare"
end

function FacebookRecordTriggerShareRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.ShareFacebookTriggerSucceed, data))
end

function FacebookRecordTriggerShareRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.ShareFacebookTriggerFailed, error))
end

--
ShareFacebookActivityeRequest = class(BaseRequest)

function ShareFacebookActivityeRequest:ctor()
  self.endpoint = "recordActivityFbShare"
end

function ShareFacebookActivityeRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.ShareFacebookActivitySucceed, data))
end

function ShareFacebookActivityeRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.ShareFacebookActivityFailed, error))
end

--
FacebookInviteFriendRequest = class(BaseRequest)

function FacebookInviteFriendRequest:ctor()
  self.endpoint = "inviteFbFriends"
end

function FacebookInviteFriendRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.FacebookInviteFriendSucceed, data))
end

function FacebookInviteFriendRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.FacebookInviteFriendFailed, error))
end

--
FacebookGainActivityRewardRequest = class(BaseRequest)

function FacebookGainActivityRewardRequest:ctor()
  self.endpoint = "gainFbActivityReward"
end

function FacebookGainActivityRewardRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.FacebookGainActivityRewardSucceed, data))
end

function FacebookGainActivityRewardRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.FacebookGainActivityRewardFailed, error))
end