require "canon.request.BaseRequest"

SpeakLimitStutasRequest = class(BaseRequest)

--刷新元神副属性
function SpeakLimitStutasRequest:ctor(params, priority)
	self.endpoint = "getUserBanInfo"
	self.data = nil
	self.params = params
end

function SpeakLimitStutasRequest:onSuccess( data )
  self:dispatchEvent( Event.new( RequestNotifyEnum.SpeakLimitStutasSucceed , data ) )
end

function SpeakLimitStutasRequest:onError(error)
  self:dispatchEvent( Event.new( RequestNotifyEnum.SpeakLimitStutasFailed , error ) )
end

function SpeakLimitStutasRequest.sendRequest(Data, succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
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
	local request = SpeakLimitStutasRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.SpeakLimitStutasSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.SpeakLimitStutasFailed, onFailedHandle)--<<<<< 2
	request:start()
end