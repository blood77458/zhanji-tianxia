--
-- SetSpiritRefreshAutoSaveRequest.lua
-- 元神刷新复选框
--
require "canon.request.BaseRequest"

SetSpiritRefreshAutoSaveRequest = class(BaseRequest)

function SetSpiritRefreshAutoSaveRequest:ctor()
  self.endpoint = "setAutoSave"
end

function SetSpiritRefreshAutoSaveRequest:onSuccess( data )
  self:dispatchEvent(Event.new(RequestNotifyEnum.SetSpiritRefreshAutoSaveSucceed, data))
end

function SetSpiritRefreshAutoSaveRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.SetSpiritRefreshAutoSaveFailed, error))
end