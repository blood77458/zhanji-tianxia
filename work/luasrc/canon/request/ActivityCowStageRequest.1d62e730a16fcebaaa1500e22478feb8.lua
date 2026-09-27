--------------------------------------------------------------------------------
-- ActivityCowStageRequest.lua - 牧场大战活动相关请求
-- author: dang chao
-- date: 2013-10-04
--------------------------------------------------------------------------------

require "canon.request.BaseRequest"

ChallengeCowStageRequest = class(BaseRequest)
GetCowStageInfoRequest = class(BaseRequest)
--挑战牧场
function ChallengeCowStageRequest:ctor(params, priority)
	self.endpoint = "challengeCowStage"
	self.data = nil
	self.params = params
end

function ChallengeCowStageRequest:onSuccess( data )
  self:dispatchEvent( Event.new( RequestNotifyEnum.ChallengeCowStageSucceed , data ) )
end

function ChallengeCowStageRequest:onError(error)
  self:dispatchEvent( Event.new( RequestNotifyEnum.ChallengeCowStageFailed , error ) )
end
--获得牧场信息
function GetCowStageInfoRequest:ctor(params, priority)
	self.endpoint = "getCowStageInfo"
	self.data = nil
	self.params = params
end

function GetCowStageInfoRequest:onSuccess( data )
  self:dispatchEvent( Event.new( RequestNotifyEnum.GetCowStageInfoSucceed , data ) )
end

function GetCowStageInfoRequest:onError(error)
  BaseRequest.onError(self, error)
end