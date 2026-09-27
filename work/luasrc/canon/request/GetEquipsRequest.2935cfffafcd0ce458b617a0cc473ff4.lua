--获取装备

require "canon.request.BaseRequest"

GetEquipsRequest = class(BaseRequest)

function GetEquipsRequest:ctor()
  self.endpoint = "getEquips"
end

function GetEquipsRequest:onSuccess( data )
  local gameInitData = DataManager.getGameInitData()
	gameInitData.sharkEquips = data.sharkEquips or {sharkEquips = {}}
  
	DataManager.setGameInitData(gameInitData)
  self:dispatchEvent(Event.new(RequestNotifyEnum.GetEquipsSucceed,data))    
end

function GetEquipsRequest:onError( error )
  BaseRequest.onError(self, error)
end