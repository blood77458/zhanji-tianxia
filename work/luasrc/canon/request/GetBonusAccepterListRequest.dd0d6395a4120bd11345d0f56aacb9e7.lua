require "canon.request.BaseRequest"

GetBonusAccepterListRequest = class(BaseRequest)

--分配红包，区分好友和军团
function GetBonusAccepterListRequest:ctor(params, priority)
	self.endpoint = "getBonusAccepterList"
	self.data = nil
	self.params = params
end

function GetBonusAccepterListRequest:onSuccess( data )
  self:dispatchEvent( Event.new( RequestNotifyEnum.GetBonusAccepterListSucceed , data ) )
end

function GetBonusAccepterListRequest:onError(error)
  self:dispatchEvent( Event.new( RequestNotifyEnum.GetBonusAccepterListFailed , error ) )
end

function GetBonusAccepterListRequest.sendRequest(Data, succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
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
	local request = GetBonusAccepterListRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.GetBonusAccepterListSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.GetBonusAccepterListFailed, onFailedHandle)--<<<<< 2
	request:start()
end