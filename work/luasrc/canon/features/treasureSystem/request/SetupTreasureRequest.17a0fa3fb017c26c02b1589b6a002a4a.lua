--------------------------------------------------------------------------------
-- SetupTreasureRequest.lua --装备宝物
-- author: l1ghtsaber
-- date: 2015-7-28
--------------------------------------------------------------------------------

require "canon.request.BaseRequest"

SetupTreasureRequest = class(BaseRequest)

--装备元神
function SetupTreasureRequest:ctor(params, priority)
	self.endpoint = "setupTreasure"
	self.data = nil
	self.params = params
end

function SetupTreasureRequest:onSuccess( data )
  self:dispatchEvent( Event.new( RequestNotifyEnum.EquipSpiritSucceed , data ) )
end

function SetupTreasureRequest:onError(error)
  self:dispatchEvent( Event.new( RequestNotifyEnum.EquipSpiritFailed , error ) )
end

function SetupTreasureRequest.sendRequest(Data, succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
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
	local request = SetupTreasureRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.EquipSpiritSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.EquipSpiritFailed, onFailedHandle)--<<<<< 2
	request:start()
end