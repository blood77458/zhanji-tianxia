--------------------------------------------------------------------------------
-- UpgradeUserRequest.lua - 用户升级的请求
-- author: fangzhou.long
-- date: 2013-08-21
--------------------------------------------------------------------------------

require "canon.request.BaseRequest"

UpgradeUserRequest = class(BaseRequest)

function UpgradeUserRequest:ctor(params, priority)
  self.endpoint = "upgradeUser"
  self.data = nil
  self.params = params
end

function UpgradeUserRequest:onSuccess( data )
  self:dispatchEvent( Event.new( RequestNotifyEnum.UpgradeUserSucceed , data ) )
end

function UpgradeUserRequest:onError(error)
  self:dispatchEvent( Event.new( RequestNotifyEnum.UpgradeUserFailed , error ) )
end
