--
-- ItemSacrificeRequest.lua
-- Author: litong.sun
-- Date: 2014-04-21
-- 武将祭炼
--
require "canon.request.BaseRequest"

ItemSacrificeRequest = class(BaseRequest)

function ItemSacrificeRequest:ctor()
  self.endpoint = "sacrificeItem"
end

function ItemSacrificeRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.ItemSacrificeSucceed, data))
end

function ItemSacrificeRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.ItemSacrificeFailed, error))
end
