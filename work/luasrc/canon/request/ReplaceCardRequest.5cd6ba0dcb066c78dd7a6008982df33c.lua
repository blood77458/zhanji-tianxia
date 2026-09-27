--------------------------------------------------------------------------------
-- ReplaceCardRequest.lua - 重整队列的请求
-- author: fangzhou.long
-- date: 2013-08-27
--------------------------------------------------------------------------------

require "canon.request.BaseRequest"

ReplaceCardRequest = class(BaseRequest)

function ReplaceCardRequest:ctor(params, priority)
	self.endpoint = "replaceCard"
	self.data = nil
	self.params = params
end

function ReplaceCardRequest:onSuccess( data )
  self:dispatchEvent( Event.new( RequestNotifyEnum.ReplaceCardSucceed , data ) )
end

function ReplaceCardRequest:onError(error)
  self:dispatchEvent( Event.new( RequestNotifyEnum.ReplaceCardFailed , error ) )
end
