--------------------------------------------------------------------------------
-- ChallengeEliteRequest.lua - 挑战精英关卡
-- author: xiaojie.bai
-- date: 2013-09-26 20:26
--------------------------------------------------------------------------------

require "canon.request.BaseRequest"
require "canon.request.CommParamConstants"
require "canon.request.CommMethodConstants"

ChallengeEliteRequest = class(BaseRequest)

function ChallengeEliteRequest:ctor()
  self.endpoint = METHOD_CHALLENGEELITE
end

function ChallengeEliteRequest:onSuccess( data )
  --he_log_info(self.endpoint .. " success: " .. table.serialize(data))
  
  self:dispatchEvent(Event.new(RequestNotifyEnum.ChallengeEliteSucceed, data))
end

function ChallengeEliteRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.ChallengeEliteFailed, error))
end