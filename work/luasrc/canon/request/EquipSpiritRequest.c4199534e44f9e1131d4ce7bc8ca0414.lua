require "canon.request.BaseRequest"

EquipSpiritRequest = class(BaseRequest)

--装备元神
function EquipSpiritRequest:ctor(params, priority)
	self.endpoint = "equipSpirit"
	self.data = nil
	self.params = params
end

function EquipSpiritRequest:onSuccess( data )
  self:dispatchEvent( Event.new( RequestNotifyEnum.EquipSpiritSucceed , data ) )
end

function EquipSpiritRequest:onError(error)
  self:dispatchEvent( Event.new( RequestNotifyEnum.EquipSpiritFailed , error ) )
end

function EquipSpiritRequest.sendRequest(Data, succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
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
	local request = EquipSpiritRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.EquipSpiritSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.EquipSpiritFailed, onFailedHandle)--<<<<< 2
	request:start()
end