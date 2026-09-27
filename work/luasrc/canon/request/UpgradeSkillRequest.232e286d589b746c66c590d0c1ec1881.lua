--------------------------------------------------------------------------------
-- UpgradeSkillRequest.lua - 技能升级的请求
-- author: fangzhou.long
-- date: 2013-08-21
--------------------------------------------------------------------------------

require "canon.request.BaseRequest"

UpgradeSkillRequest = class(BaseRequest)

function UpgradeSkillRequest:ctor(params, priority)
  self.endpoint = "upgradeSkill"
  self.data = nil
  self.params = params
end

function UpgradeSkillRequest:onSuccess( data )
  self:dispatchEvent( Event.new( RequestNotifyEnum.UpgradeSkillSucceed , data ) )
end

function UpgradeSkillRequest:onError(error)
  self:dispatchEvent( Event.new( RequestNotifyEnum.UpgradeSkillFailed , error ) )
end
