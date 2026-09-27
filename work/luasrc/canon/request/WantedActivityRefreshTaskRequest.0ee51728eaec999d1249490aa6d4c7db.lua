require "canon.request.BaseRequest"

WantedActivityRefreshTaskRequest = class(BaseRequest)

function WantedActivityRefreshTaskRequest:ctor()
    self.endpoint = "refreshWanted"
end

function WantedActivityRefreshTaskRequest:onSuccess( data )
    self:dispatchEvent(Event.new(RequestNotifyEnum.WantedActivityRefreshTaskRequestSucceed,data))
end

function WantedActivityRefreshTaskRequest:onError( error )
    self:dispatchEvent(Event.new(RequestNotifyEnum.WantedActivityRefreshTaskRequestFailed,error))
end