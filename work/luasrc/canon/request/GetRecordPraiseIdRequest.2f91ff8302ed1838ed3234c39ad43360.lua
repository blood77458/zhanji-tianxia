require "canon.request.BaseRequest"

GetRecordPraiseIdRequest = class(BaseRequest)

--获取记录点赞id
function GetRecordPraiseIdRequest:ctor(params, priority)
	self.endpoint = "recordPraiseId"
	self.data = nil
	self.params = params
end

function GetRecordPraiseIdRequest:onSuccess( data )
  self:dispatchEvent( Event.new( RequestNotifyEnum.GetRecordPraiseIdSucceed , data ) )
end

function GetRecordPraiseIdRequest:onError(error)
  self:dispatchEvent( Event.new( RequestNotifyEnum.GetRecordPraiseIdFailed , error ) )
end

function GetRecordPraiseIdRequest.sendRequest(Data, succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
	local function onSucceedHandle(event)
		if succeedCallback then
			succeedCallback(Data, event)--<<<<< 3
		end
	end 
	local function onFailedHandle(event)
		if failedCallback then
			failedCallback(event)
		end
	end
	local params = {praiseId = Data}--<<<<< 3
	local request = GetRecordPraiseIdRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.GetRecordPraiseIdSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.GetRecordPraiseIdFailed, onFailedHandle)--<<<<< 2
	request:start()
end