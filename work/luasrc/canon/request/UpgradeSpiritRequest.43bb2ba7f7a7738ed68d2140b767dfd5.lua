require "canon.request.BaseRequest"

UpgradeSpiritRequest = class(BaseRequest)

--强化元神
function UpgradeSpiritRequest:ctor(params, priority)
	self.endpoint = "upgradeSpirit"
	self.data = nil
	self.params = params
end

function UpgradeSpiritRequest:onSuccess( data )
  self:dispatchEvent( Event.new( RequestNotifyEnum.UpgradeSpiritSucceed , data ) )
end

function UpgradeSpiritRequest:onError(error)
  self:dispatchEvent( Event.new( RequestNotifyEnum.UpgradeSpiritFailed , error ) )
end

function UpgradeSpiritRequest.sendRequest(Data, succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
	local function onSucceedHandle(event)
		if succeedCallback then
			succeedCallback(Data , event)--<<<<< 3
		end
	end 
	local function onFailedHandle(event)
		if failedCallback then
			failedCallback(event)
		end
	end
	local params = Data--<<<<< 3
	local request = UpgradeSpiritRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.UpgradeSpiritSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.UpgradeSpiritFailed, onFailedHandle)--<<<<< 2
	request:start()
end