--------------------------------------------------------------------------------
-- GetCountdownRewardRequest.lua -- 获取新手礼包请求
-- author: Jiang Yize
-- date: 2013-11-07
--------------------------------------------------------------------------------

require "canon.request.BaseRequest"

GetCountdownRewardRequest = class(BaseRequest)

function GetCountdownRewardRequest:ctor()
  self.endpoint = "getCountdownReward"
end

function GetCountdownRewardRequest:onSuccess(data)
  -- print("GetCountdownReward Success: " .. table.serialize(data))
  self:dispatchEvent(Event.new(RequestNotifyEnum.GetCountdownRewardSucceed, data))
end

function GetCountdownRewardRequest:onError(error)
  self:dispatchEvent(Event.new(RequestNotifyEnum.GetCountdownRewardFailed, error))
end
