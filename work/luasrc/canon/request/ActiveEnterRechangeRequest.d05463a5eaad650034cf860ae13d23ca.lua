require "canon.request.BaseRequest"

ActiveEnterRechangeRequest = class(BaseRequest)

--获取世界boss信息
function ActiveEnterRechangeRequest:ctor(params, priority)
	self.endpoint = "getLimitReward"
	self.data = nil
	self.params = params
end

function ActiveEnterRechangeRequest:onSuccess( data )
  self:dispatchEvent( Event.new( RequestNotifyEnum.GetActiveEnterRechangeSucceed , data ) )
end

function ActiveEnterRechangeRequest:onError(error)
  self:dispatchEvent( Event.new( RequestNotifyEnum.GetActiveEnterRechangeSucceed , error ) )
end

function ActiveEnterRechangeRequest.sendRequest(Data, succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
	local function onSucceedHandle(event)
		print("成功")
		if succeedCallback then
			
			succeedCallback(event)--<<<<< 3
		end
	end 
	local function onFailedHandle(event)
		print("失敗")
		if failedCallback then

			failedCallback(event)
		end
	end
	local params = Data--<<<<< 3
	local request = ActiveEnterRechangeRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.GetActiveEnterRechangeSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.GetActiveEnterRechangeFailed, onFailedHandle)--<<<<< 2
	request:start()
end