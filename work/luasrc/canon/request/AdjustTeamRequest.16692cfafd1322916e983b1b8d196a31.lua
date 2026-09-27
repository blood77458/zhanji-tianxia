--------------------------------------------------------------------------------
-- AdjustTeamRequest.lua -- 调整队列请求
-- author: Jiang Yize
-- date: 2013-11-19
--------------------------------------------------------------------------------

require "canon.request.BaseRequest"

AdjustTeamRequest = class(BaseRequest)

function AdjustTeamRequest:ctor(params, priority)
	self.endpoint = "adjustTeam"
	self.data = nil
	self.params = params
end

function AdjustTeamRequest:onSuccess(data)
  self:dispatchEvent(Event.new(RequestNotifyEnum.AdjustTeamSucceed, data))
end

function AdjustTeamRequest:onError(error)
  self:dispatchEvent(Event.new(RequestNotifyEnum.AdjustTeamFailed, error))
end
