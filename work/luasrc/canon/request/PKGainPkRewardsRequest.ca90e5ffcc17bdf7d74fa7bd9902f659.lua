--------------------------------------------------------------------------------
-- PKGainPkRewardsRequest.lua - 比武请求领奖
-- author: litong.sun
-- date: 2014-03-07
--------------------------------------------------------------------------------

require "canon.request.BaseRequest"

PKGainPkRewardsRequest = class(BaseRequest)

function PKGainPkRewardsRequest:ctor()
	self.endpoint = "gainPkRewards"
end

function PKGainPkRewardsRequest:onSuccess( data )
	self:dispatchEvent(Event.new(RequestNotifyEnum.PKGainPkRewardsSucceed, data))
end

function PKGainPkRewardsRequest:onError( error )
	self:dispatchEvent(Event.new(RequestNotifyEnum.PKGainPkRewardsFailed, error))
end
