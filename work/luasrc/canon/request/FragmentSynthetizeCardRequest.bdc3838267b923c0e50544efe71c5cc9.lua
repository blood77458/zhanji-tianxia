--
-- FragmentSynthetizeCardRequest 卡牌碎片合成
-- Author: czh
-- Date: 2014-02-14 17:16:38
--
require "canon.request.BaseRequest"

FragmentSynthetizeCardRequest = class(BaseRequest)

function FragmentSynthetizeCardRequest:ctor()
  self.endpoint = "synthetizeCard"
end

function FragmentSynthetizeCardRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.FragmentSynthetizeCardSucceed, data))
end

function FragmentSynthetizeCardRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.FragmentSynthetizeCardFailed, error))
end