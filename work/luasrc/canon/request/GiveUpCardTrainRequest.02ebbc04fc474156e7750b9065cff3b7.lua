--------------------------------------------------------------------------------
-- GiveUpCardTrainRequest.lua - 放弃卡片培养的请求
-- author: fangzhou.long
-- date: 2013-08-14
--------------------------------------------------------------------------------

require "canon.request.BaseRequest"

GiveUpCardTrainRequest = class(BaseRequest)

function GiveUpCardTrainRequest:ctor(params, priority)
	self.endpoint = "giveUpCardTrain"
  self.data = nil
  self.params = params
end

function GiveUpCardTrainRequest:onSuccess( data )
  self:dispatchEvent( Event.new( RequestNotifyEnum.GiveUpCardTrainSucceed , data ) )
end

function GiveUpCardTrainRequest:onError(error)
	BaseRequest.onError(self, error)
end