--------------------------------------------------------------------------------
-- RefreshMedalShopRequest.lua --刷新勋章商城
-- author: l1ghtsaber
-- date: 2015-7-28
--------------------------------------------------------------------------------

require "canon.request.BaseRequest"

RefreshMedalShopRequest = class(BaseRequest)

function RefreshMedalShopRequest:ctor(params, priority)
    self.endpoint = "refreshMedalShop"--<<<<< 1. 修改指令名称 后端提供
  	self.succeedEventName = self.endpoint .. "Succeed"
  	self.failedEventName = self.endpoint .. "Failed"
end

function RefreshMedalShopRequest:onSuccess( data )
  	self:dispatchEvent(Event.new(self.succeedEventName, data))
end

function RefreshMedalShopRequest:onError(error)
  	self:dispatchEvent(Event.new(self.failedEventName, {retCode = error}))
end

--发送请求 默认处理 成功返回之后可加额外处理(参数可传nil)
function RefreshMedalShopRequest.sendRequestDefalut(afterSucceedCallback, afterFailedCallback)--<<<<< 3
	local function onSucceed(evt)
		RefreshMedalShopRequest.onSucceedDefault(evt)
		if afterSucceedCallback then
			afterSucceedCallback(evt)
		end
	end
	local function onFailed(evt)
		RefreshMedalShopRequest.onFailedDefault(evt)
		if afterFailedCallback then
			afterFailedCallback(evt)
		end
	end
	RefreshMedalShopRequest.sendRequest(onSucceed, onFailed)
end

function RefreshMedalShopRequest.sendRequest(succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
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

	local request = RefreshMedalShopRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(request.succeedEventName, onSucceedHandle)--<<<<< 2
	request:addEventListener(request.failedEventName, onFailedHandle)--<<<<< 2
	request:start()
end

--成功的默认处理
function RefreshMedalShopRequest.onSucceedDefault( e )--<<<<< 3
end

--失败默认处理
function RefreshMedalShopRequest.onFailedDefault( e )--<<<<< 4. 修改错误码对应逻辑处理
	CanonMessageBox:showCommUnHandleErrorBox(e.data)
end