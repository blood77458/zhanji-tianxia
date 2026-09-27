--
-- ItemRebirthRequest.lua
-- Author: litong.sun
-- Date: 2014-04-21
-- 武将重生
--
require "canon.request.BaseRequest"

ItemRebirthRequest = class(BaseRequest)

function ItemRebirthRequest:ctor()
  self.endpoint = "rebirthItem"
end

function ItemRebirthRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.ItemRebirthSucceed, data))
end

function ItemRebirthRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.ItemRebirthFailed, error))
end
