--------------------------------------------------------------------------------
-- GetAnnouncementInfoRequest.lua -- 获取公告信息请求
-- author: Jiang Yize
-- date: 2013-10-18
--------------------------------------------------------------------------------

require "canon.request.BaseRequest"

GetAnnouncementInfoRequest = class(BaseRequest)

function GetAnnouncementInfoRequest:ctor()
  self.endpoint = "getAnnouncementInfo"
end

function GetAnnouncementInfoRequest:onSuccess(data)
  -- print("GetAnnouncementInfo Success: " .. table.serialize(data))
  self:dispatchEvent(Event.new(RequestNotifyEnum.GetAnnouncementInfoSucceed, data))
end

function GetAnnouncementInfoRequest:onError(error)
  BaseRequest.onError(self, error)
end
