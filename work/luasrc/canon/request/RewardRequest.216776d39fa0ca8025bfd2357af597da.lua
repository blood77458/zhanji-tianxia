--------------------------------------------------------------------------------
-- RewardRequest.lua - all request related requeset
-- author: dang chao
-- date: 2013-09-22
--------------------------------------------------------------------------------

require "canon.request.BaseRequest"

GetRewardListRequest = class(BaseRequest)
GetSingleRewardRequest = class(BaseRequest)
GetAllRewardRequest = class(BaseRequest)
GetCurMonthRewardListRequest = class(BaseRequest)
GetSigninRewardRequest = class(BaseRequest)
GetLoginRewardRequest = class(BaseRequest)
GetContinueLoginRewardRequest = class(BaseRequest)
GainContinueLoginRewardRequestV2 = class(BaseRequest)
--get reward list
function GetRewardListRequest:ctor(params, priority)
	self.endpoint = "getRewardList"
	self.data = nil
	self.params = params
end

function GetRewardListRequest:onSuccess( data )
  self:dispatchEvent( Event.new( RequestNotifyEnum.GetRewardListSucceed , data ) )
end

function GetRewardListRequest:onError(error)
  BaseRequest.onError(self, error)
end
--get single reward
function GetSingleRewardRequest:ctor(params, priority)
	self.endpoint = "pickUpReward"
	self.data = nil
	self.params = params
end

function GetSingleRewardRequest:onSuccess( data )
  self:dispatchEvent( Event.new( RequestNotifyEnum.GetSingleRewardSucceed , data ) )
end

function GetSingleRewardRequest:onError(error)
  BaseRequest.onError(self, error)
end
--get all reward
function GetAllRewardRequest:ctor(params, priority)
	self.endpoint = "pickUpAllReward"
	self.data = nil
	self.params = params
end

function GetAllRewardRequest:onSuccess( data )
  self:dispatchEvent( Event.new( RequestNotifyEnum.GetAllRewardSucceed , data ) )
end

function GetAllRewardRequest:onError(error)
  BaseRequest.onError(self, error)
end
--get current month reward list
function GetCurMonthRewardListRequest:ctor(params, priority)
	self.endpoint = "getMonthlyLoginRewardMeta"
	self.data = nil
	self.params = params
end

function GetCurMonthRewardListRequest:onSuccess( data )
  self:dispatchEvent( Event.new( RequestNotifyEnum.GetCurMonthRewardMetaSucceed , data ) )
end

function GetCurMonthRewardListRequest:onError(error)
  BaseRequest.onError(self, error)
end
--get signin reward
function GetSigninRewardRequest:ctor(params, priority)
	self.endpoint = "getSignInReward"
	self.data = nil
	self.params = params
end

function GetSigninRewardRequest:onSuccess( data )
  self:dispatchEvent( Event.new( RequestNotifyEnum.GetSigninRewardSucceed , data ) )
end

function GetSigninRewardRequest:onError(error)
  --BaseRequest.onError(self, error)
  self:dispatchEvent( Event.new( RequestNotifyEnum.GetSigninRewardFailed , {retCode = error} ) )
end
--get login reward
function GetLoginRewardRequest:ctor(params, priority)
	self.endpoint = "getLoginReward"
	self.data = nil
	self.params = params
end

function GetLoginRewardRequest:onSuccess( data )
  self:dispatchEvent( Event.new( RequestNotifyEnum.GetLoginRewardSucceed , data ) )
end

function GetLoginRewardRequest:onError(error)
  --BaseRequest.onError(self, error)
  self:dispatchEvent( Event.new( RequestNotifyEnum.GetLoginRewardFailed , {retCode = error} ) )
end
--get continue login reward
function GetContinueLoginRewardRequest:ctor(params, priority)
	self.endpoint = "getContinuousLoginReward"
	self.data = nil
	self.params = params
end

function GetContinueLoginRewardRequest:onSuccess( data )
  self:dispatchEvent( Event.new( RequestNotifyEnum.GetContinueLoginRewardSucceed , data ) )
end

function GetContinueLoginRewardRequest:onError(error)
  --BaseRequest.onError(self, error)
  self:dispatchEvent( Event.new( RequestNotifyEnum.GetContinueLoginRewardFailed , {retCode = error} ) )
end

--new Continue 7 days login reward
function GainContinueLoginRewardRequestV2:ctor(params, priority)
	self.endpoint = "gainContinuousLoginRewardV2"
	self.data = nil
	self.params = params
end

function GainContinueLoginRewardRequestV2:onSuccess( data )
  self:dispatchEvent( Event.new( RequestNotifyEnum.GainContinueLoginRewardV2Succeed , data ) )
end

function GainContinueLoginRewardRequestV2:onError(error)
  --BaseRequest.onError(self, error)
  self:dispatchEvent( Event.new( RequestNotifyEnum.GainContinueLoginRewardV2Failed , {retCode = error} ) )
end