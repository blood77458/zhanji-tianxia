--------------------------------------------------------------------------------
-- ActivityEatPeachRequest.lua - 吃桃补充体力活动相关请求
-- author: dang chao
-- date: 2013-09-30
--------------------------------------------------------------------------------

require "canon.request.BaseRequest"

GetEatPeachInfoRequest = class(BaseRequest)
EatPeachRequest = class(BaseRequest)
--get eat peach info
function GetEatPeachInfoRequest:ctor(params, priority)
	self.endpoint = "getEatPeachInfo"
	self.data = nil
	self.params = params
end

function GetEatPeachInfoRequest:onSuccess( data )
  self:dispatchEvent( Event.new( RequestNotifyEnum.GetEatPeachInfoSucceed , data ) )
end

function GetEatPeachInfoRequest:onError(error)
  BaseRequest.onError(self, error)
end
-- eat peach 
function EatPeachRequest:ctor(params, priority)
	self.endpoint = "eatPeach"
	self.data = nil
	self.params = params
end

function EatPeachRequest:onSuccess( data )
  self:dispatchEvent( Event.new( RequestNotifyEnum.EatPeachSucceed , data ) )
end

function EatPeachRequest:onError(error)
  self:dispatchEvent( Event.new( RequestNotifyEnum.EatPeachFailed , error ) )
end