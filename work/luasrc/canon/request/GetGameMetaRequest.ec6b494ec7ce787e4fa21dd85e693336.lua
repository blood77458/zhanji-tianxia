--------------------------------------------------------------------------------
-- GetGameMetaRequest.lua - 获取游戏元配置的请求
-- author: fanzhou.long
-- updated: 2013-08-20
--------------------------------------------------------------------------------

require "canon.request.BaseRequest"
require "canon.data.MetaManager"

GetGameMetaRequest = class(BaseRequest)

function GetGameMetaRequest:ctor()
    self.endpoint = "getMeta"
end

----------------------------------------
--Use
--table.deserialize(HeMemDataHolder:getString("GameMeta"))
--to get the game meta
----------------------------------------
function GetGameMetaRequest:onSuccess( data )
    --print("GameMeta Success: " .. table.tostring(data))
    --HeMemDataHolder:setString("GameMeta", table.serialize(data));
    MetaManager.game_meta = data
    self:dispatchEvent(Event.new(RequestNotifyEnum.GetGameMetaSucceed,data))    
end

function GetGameMetaRequest:onError( error )
    BaseRequest.onError(self, error)
end