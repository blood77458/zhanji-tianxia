require "canon.request.BaseRequest"

SellSpiritRequest = class(BaseRequest)

--卖出元神
function SellSpiritRequest:ctor(params, priority)
	self.endpoint = "sellSpirit"
	self.data = nil
	self.params = params
end

function SellSpiritRequest:onSuccess( data )
  self:dispatchEvent( Event.new( RequestNotifyEnum.SellSpiritSucceed , data ) )
end

function SellSpiritRequest:onError(error)
  self:dispatchEvent( Event.new( RequestNotifyEnum.SellSpiritFailed , error ) )
end

function SellSpiritRequest.sendRequest(Data, succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
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
	local request = SellSpiritRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.SellSpiritSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.SellSpiritFailed, onFailedHandle)--<<<<< 2
	request:start()
end