--------------------------------------------------------------------------------
-- CardTrainingRequest.lua - 培养卡片的请求
-- author: fangzhou.long
-- date: 2013-08-14
--------------------------------------------------------------------------------

require "canon.request.BaseRequest"

CardTrainingRequest = class(BaseRequest)

function CardTrainingRequest:ctor(params, priority)
	self.endpoint = "trainCard"
  self.data = nil
  self.params = params
end

function CardTrainingRequest:onSuccess( data )
  self:dispatchEvent( Event.new( RequestNotifyEnum.TrainCardSucceed , data ) )
end

function CardTrainingRequest:onError(error)
	self:dispatchEvent( Event.new( RequestNotifyEnum.TrainCardFailed , error ) )
end
