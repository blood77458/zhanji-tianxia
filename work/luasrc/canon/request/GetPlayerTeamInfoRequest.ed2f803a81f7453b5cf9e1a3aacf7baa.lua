--------------------------------------------------------------------------------
-- GetPlayerTeamInfoRequest.lua - 培养卡片的请求
-- author: fangzhou.long
-- date: 2013-08-14
--------------------------------------------------------------------------------

require "canon.request.BaseRequest"

GetPlayerTeamInfoRequest = class(BaseRequest)

function GetPlayerTeamInfoRequest:ctor()
    self.endpoint = "getPlayerTeamInfo"
end

function GetPlayerTeamInfoRequest:onSuccess( data )
    --DataManager.setPlayerTeamInfo( data )
    self:dispatchEvent( Event.new( RequestNotifyEnum.GetPlayerTeamInfoSucceed, data ) )
end

function GetPlayerTeamInfoRequest:onError( error )
    BaseRequest.onError(self, error)
end