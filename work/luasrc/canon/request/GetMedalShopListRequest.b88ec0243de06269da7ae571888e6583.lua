--------------------------------------------------------------------------------
-- GetMedalShopListRequest.lua --获得商品
-- author: l1ghtsaber
-- date: 2015-7-28
--------------------------------------------------------------------------------

require "canon.request.BaseRequest"

GetMedalShopListRequest = class(BaseRequest)

function GetMedalShopListRequest:ctor(params, priority)
    self.endpoint = "getMedalShopList"--<<<<< 1. 修改指令名称 后端提供
  	self.succeedEventName = self.endpoint .. "Succeed"
  	self.failedEventName = self.endpoint .. "Failed"
end

function GetMedalShopListRequest:onSuccess( data )
  	self:dispatchEvent(Event.new(self.succeedEventName, data))
end

function GetMedalShopListRequest:onError(error)
  	self:dispatchEvent(Event.new(self.failedEventName, {retCode = error}))
end

--发送请求 默认处理 成功返回之后可加额外处理(参数可传nil)
function GetMedalShopListRequest.sendRequestDefalut(afterSucceedCallback,afterFailedCallback)--<<<<< 3
	local function onSucceed(evt)
		GetMedalShopListRequest.onSucceedDefault(evt)
		if afterSucceedCallback then
			afterSucceedCallback(evt)
		end
	end
	local function onFailed(evt)
		GetMedalShopListRequest.onFailedDefault(evt)
		if afterFailedCallback then
			afterFailedCallback(evt)
		end
	end
	GetMedalShopListRequest.sendRequest(onSucceed, onFailed)
end

function GetMedalShopListRequest.sendRequest(succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
	local params = nil--<<<<< 3

	local function onSucceedHandle(event)
		if succeedCallback then
			event.params = params
			succeedCallback(event)--<<<<< 3
		end
	end 
	local function onFailedHandle(event)
		if failedCallback then
			event.params = params
			failedCallback(event)
		end
	end

	local request = GetMedalShopListRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(request.succeedEventName, onSucceedHandle)--<<<<< 2
	request:addEventListener(request.failedEventName, onFailedHandle)--<<<<< 2
	request:start()
end

--成功的默认处理
function GetMedalShopListRequest.onSucceedDefault( e )--<<<<< 3
	--成功不需要处理啊 
end

--失败默认处理
function GetMedalShopListRequest.onFailedDefault( e )--<<<<< 4. 修改错误码对应逻辑处理
	if e.data == 710513 then
		local aPanel = AssistantMessageBoxPanel:create( SELF, AsMessageBoxType.addCoin )
		SELF:addChild(aPanel)
		aPanel:scaleIn()
	else
		CanonMessageBox:showCommUnHandleErrorBox(e.data)
	end
end