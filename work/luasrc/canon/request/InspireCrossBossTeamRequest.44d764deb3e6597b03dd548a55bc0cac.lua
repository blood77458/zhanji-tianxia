require "canon.request.BaseRequest"

InspireCrossBossTeamRequest = class(BaseRequest)

--获取世界boss信息
function InspireCrossBossTeamRequest:ctor(params, priority)
	self.endpoint = "inspireCrossBossTeam"
	self.data = nil
	self.params = params
end

function InspireCrossBossTeamRequest:onSuccess( data )
  self:dispatchEvent( Event.new( RequestNotifyEnum.InspireCrossBossTeamSucceed , data ) )
end

function InspireCrossBossTeamRequest:onError(error)
  self:dispatchEvent( Event.new( RequestNotifyEnum.InspireCrossBossTeamFailed , error ) )
end

function InspireCrossBossTeamRequest.sendRequest(Data, succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
	local function onSucceedHandle(event)
		if succeedCallback then
			succeedCallback(event)--<<<<< 3
		end
	end 
	local function onFailedHandle(event)
		if failedCallback then
			failedCallback(event)
		end
	end
	local params = Data--<<<<< 3
	local request = InspireCrossBossTeamRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.InspireCrossBossTeamSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.InspireCrossBossTeamFailed, onFailedHandle)--<<<<< 2
	request:start()
end