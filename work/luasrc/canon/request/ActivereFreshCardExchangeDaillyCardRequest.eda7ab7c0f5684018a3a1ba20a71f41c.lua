require "canon.request.BaseRequest"

ActivereFreshCardExchangeDaillyCardRequest = class(BaseRequest)



function ActivereFreshCardExchangeDaillyCardRequest:ctor()
  self.endpoint = "refreshCardExchangeDaillyCard"--<<<<< 1. 修改指令名称 后端提供
  self.succeedEventName = self.endpoint .. "Succeed"
  self.failedEventName = self.endpoint .. "Failed"
end

function ActivereFreshCardExchangeDaillyCardRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(self.succeedEventName, data))
end

function ActivereFreshCardExchangeDaillyCardRequest:onError( error )
  self:dispatchEvent(Event.new(self.failedEventName, {retCode = error}))
end

-------------------------------------------------------------------静态函数

--发送请求 默认处理 成功返回之后可加额外处理(参数可传nil)
function ActivereFreshCardExchangeDaillyCardRequest.sendRequestDefalut(Data, afterSucceedCallback)--<<<<< 3
	local function onSucceed(evt)
		ActivereFreshCardExchangeDaillyCardRequest.onSucceedDefault(evt)
		if afterSucceedCallback then
			-- print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~cardExchangeDailyInfoRequest "..evt.data.cardExchangeDailyInfo.exchangeTimes)
			afterSucceedCallback(evt)
			
		end
	end
	ActivereFreshCardExchangeDaillyCardRequest.sendRequest(Data, onSucceed, ActivereFreshCardExchangeDaillyCardRequest.onFailedDefault)
end

--发送请求
--equipData 装备数据
function ActivereFreshCardExchangeDaillyCardRequest.sendRequest(Data, succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
	local params = {useGold = Data.useGold}--<<<<< 3

	-- print("~~~~~~~~~~~~~~~~~~~~~~~~领奖Id~~~~~~~~~~~~~~~~"..tostring(params.useGold))

	local function onSucceedHandle(event)
		if succeedCallback then
			event.params = params
			event.Data = Data

			succeedCallback(event)
		end
	end 
	local function onFailedHandle(event)
		if failedCallback then
			event.params = params
			failedCallback(event)
		end
	end
	if SystemManager.debug then
		print("params = " .. table.tostring(params))
	end
	local request = ActivereFreshCardExchangeDaillyCardRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(request.succeedEventName, onSucceedHandle)
	request:addEventListener(request.failedEventName, onFailedHandle)
	request:start()
end

--成功的默认处理
function ActivereFreshCardExchangeDaillyCardRequest.onSucceedDefault(event)--<<<<< 3
	if SystemManager.debug then
		print("onSucceedDefault! event = " .. table.tostring(event))
	end

	
end

--失败默认处理
function ActivereFreshCardExchangeDaillyCardRequest.onFailedDefault(event)--<<<<< 4. 修改错误码对应逻辑处理
	local errorCode = tonumber(event.data.retCode)
	local function onErrorConfirm(errorCode)
	end
	local ret = ErrorCodeManager.alert(errorCode, onErrorConfirm)
end