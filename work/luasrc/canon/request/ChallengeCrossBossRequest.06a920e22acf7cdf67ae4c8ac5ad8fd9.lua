require "canon.request.BaseRequest"

ChallengeCrossBossRequest = class(BaseRequest)

--获取世界boss信息
function ChallengeCrossBossRequest:ctor(params, priority)
	self.endpoint = "challengeCrossBoss"
	self.data = nil
	self.params = params
end

function ChallengeCrossBossRequest:onSuccess( data )
  self:dispatchEvent( Event.new( RequestNotifyEnum.ChallengeCrossBossSucceed , data ) )
end

function ChallengeCrossBossRequest:onError(error)
  self:dispatchEvent( Event.new( RequestNotifyEnum.ChallengeCrossBossFailed , error ) )
end

function ChallengeCrossBossRequest.sendRequest(Data, succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
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
	local request = ChallengeCrossBossRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.ChallengeCrossBossSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.ChallengeCrossBossFailed, onFailedHandle)--<<<<< 2
	request:start()
end