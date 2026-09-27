--------------------------------------------------------------------------------
-- GetPropsRequest.lua - 培养卡片的请求
-- author: fangzhou.long
-- date: 2013-08-14
--------------------------------------------------------------------------------

require "canon.request.BaseRequest"

GetPropsRequest = class(BaseRequest)

function GetPropsRequest:ctor()
  self.endpoint = "getProps"
end

function GetPropsRequest:onSuccess( data )
	local gameInitData = DataManager.getGameInitData()
	gameInitData.sharkProps = data.sharkProps or {sharkProps = {}}
	DataManager.setGameInitData(gameInitData)
  self:dispatchEvent(Event.new(RequestNotifyEnum.GetPropsSucceed,data))    
end

function GetPropsRequest:onError( error )
  BaseRequest.onError(self, error)
end