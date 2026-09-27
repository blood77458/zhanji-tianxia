--------------------------------------------------------------------------------
-- SaveCardTrainRequest.lua - 保存卡片培养结果的请求
-- author: fangzhou.long
-- date: 2013-08-14
--------------------------------------------------------------------------------

require "canon.request.BaseRequest"

SaveCardTrainRequest = class(BaseRequest)
  
function SaveCardTrainRequest:ctor(params, priority)
	self.endpoint = "saveCardTrain"
  self.data = nil
  self.params = params
end

function SaveCardTrainRequest:onSuccess( data )
  self:dispatchEvent( Event.new( RequestNotifyEnum.SaveCardTrainSucceed , data ) )
end

function SaveCardTrainRequest:onError(error)
	BaseRequest.onError(self, error)
end