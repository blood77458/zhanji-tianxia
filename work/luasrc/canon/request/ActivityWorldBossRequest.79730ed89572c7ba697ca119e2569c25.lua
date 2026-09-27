--------------------------------------------------------------------------------
-- ActivityCowStageRequest.lua - 世界Boss请求
-- author: silian
--------------------------------------------------------------------------------

require "canon.request.BaseRequest"

GetWorldBossInfoRequest = class(BaseRequest)
function GetWorldBossInfoRequest:ctor(params, priority)
	self.endpoint = "getWorldBossInfo"
	self.data = nil
	self.params = params
end

function GetWorldBossInfoRequest:onSuccess( data )
	self:dispatchEvent( Event.new( RequestNotifyEnum.getWorldBossInfoSuccessd , data ) )
end

function GetWorldBossInfoRequest:onError(error)
	self:dispatchEvent( Event.new( RequestNotifyEnum.getWorldBossInfoFailed , data ) )
	BaseRequest.onError(self, error)
end


ChallengeWorldBossRequest = class(BaseRequest)
function ChallengeWorldBossRequest:ctor(params, priority)
	self.endpoint = "challengeWorldBoss"
	self.data = nil
	self.params = params
end
function ChallengeWorldBossRequest:onSuccess( data )
  self:dispatchEvent( Event.new( RequestNotifyEnum.challengeWorldBossSuccessd , data ) )
end

function ChallengeWorldBossRequest:onError(error)
  --BaseRequest.onError(self, error)
  self:dispatchEvent( Event.new( RequestNotifyEnum.challengeWorldBossFailed , error ) )
end


GainWorldBossRewardsRequest = class(BaseRequest)
function GainWorldBossRewardsRequest:ctor(params, priority)
	self.endpoint = "gainWorldBossRewards"
	self.data = nil
	self.params = params
end
function GainWorldBossRewardsRequest:onSuccess( data )
  self:dispatchEvent( Event.new( RequestNotifyEnum.gainWorldBossRewardsSuccessd , data ) )
end

function GainWorldBossRewardsRequest:onError(error)
  --BaseRequest.onError(self, error)
  self:dispatchEvent( Event.new( RequestNotifyEnum.gainWorldBossRewardsFailed , error ) )
end

InspireInWorldBossRequest = class(BaseRequest)
function InspireInWorldBossRequest:ctor(params, priority)
	self.endpoint = "inspireInWorldBoss"
	self.data = nil
	self.params = params
end
function InspireInWorldBossRequest:onSuccess( data )
  self:dispatchEvent( Event.new( RequestNotifyEnum.inspireInWorldBossSuccessd , data ) )
end

function InspireInWorldBossRequest:onError(error)
  BaseRequest.onError(self, error)
  self:dispatchEvent( Event.new( RequestNotifyEnum.inspireInWorldBossFailed , data ) )
end

SetAutoWorldBossRequest = class(BaseRequest)
function SetAutoWorldBossRequest:ctor(params, priority)
	self.endpoint = "setAutoWorldBoss"
	self.data = nil
	self.params = params
end
function SetAutoWorldBossRequest:onSuccess( data )
  self:dispatchEvent( Event.new( RequestNotifyEnum.setAutoWorldBossSuccessd , data ) )
end

function SetAutoWorldBossRequest:onError(error)
  BaseRequest.onError(self, error)
end
