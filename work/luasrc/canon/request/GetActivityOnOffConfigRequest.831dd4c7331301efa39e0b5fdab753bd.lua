--------------------------------------------------------------------------------
-- GetActivityOnOffConfigRequest.lua - 得到活动配置请求
-- author: dang chao
-- date: 2013-09-30
--------------------------------------------------------------------------------

require "canon.request.BaseRequest"

GetActivityOnOffConfigRequest = class(BaseRequest)
--get activity config
function GetActivityOnOffConfigRequest:ctor(params, priority)
	self.endpoint = "getMaintenanceMeta"
	self.data = nil
	self.params = params
end

function GetActivityOnOffConfigRequest:onSuccess( data )
  --he_log_info(self.endpoint .. " success: " .. table.serialize(data))
  
  self:dispatchEvent( Event.new( RequestNotifyEnum.GetActivityOnOffConfigSucceed , data ) )
end

function GetActivityOnOffConfigRequest:onError(error)
  BaseRequest.onError(self, error)
end