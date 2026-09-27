--
-- FragmentSynthetizeCard 卡牌碎片合成
-- Author: czh
-- Date: 2014-02-14 17:16:38
--
require "canon.request.BaseRequest"

FragmentSynthetizeCard = class(BaseRequest)

function FragmentSynthetizeCard:ctor()
  self.endpoint = "synthetizeCard"
end

function FragmentSynthetizeCard:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.FragmentSynthetizeCardSucceed, data))
end

function FragmentSynthetizeCard:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.FragmentSynthetizeCardFailed, error))
end