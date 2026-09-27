require "canon.request.BaseRequest"

DistributeBonusRequest = class(BaseRequest)

--分配红包，区分好友和军团
function DistributeBonusRequest:ctor(params, priority)
	self.endpoint = "distributeBonus"
	self.data = nil
	self.params = params
end

function DistributeBonusRequest:onSuccess( data )
  self:dispatchEvent( Event.new( RequestNotifyEnum.DistributeBonusSucceed , data ) )
end

function DistributeBonusRequest:onError(error)
  self:dispatchEvent( Event.new( RequestNotifyEnum.DistributeBonusFailed , error ) )
end

function DistributeBonusRequest.sendRequest(Data, succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
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
	local request = DistributeBonusRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.DistributeBonusSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.DistributeBonusFailed, onFailedHandle)--<<<<< 2
	request:start()
end