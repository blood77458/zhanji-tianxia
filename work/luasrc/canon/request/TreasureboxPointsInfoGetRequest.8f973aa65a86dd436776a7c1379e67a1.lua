--
-- TreasureboxPointsInfoGetRequest.lua
-- Author: zheng.che
-- Date: 2014-02-27 17:14:32
--
require "canon.request.BaseRequest"

TreasureboxPointsInfoGetRequest = class(BaseRequest)

function TreasureboxPointsInfoGetRequest:ctor(params, priority, forbidLoading)
	self.endpoint = "getTreasureboxPointsInfo"
	if forbidLoading then
		self.showLoading = false
		self.enableTouch = true
		self.needRetry = false
	end
end

function TreasureboxPointsInfoGetRequest:onSuccess( data )  
	self:dispatchEvent(Event.new(RequestNotifyEnum.TreasureboxPointsInfoGetSucceed, data))
end

function TreasureboxPointsInfoGetRequest:onError( error )
	self:dispatchEvent(Event.new(RequestNotifyEnum.TreasureboxPointsInfoGetFailed, {retCode = error}))
end

-------------------------------------------------------------------静态函数

-- forbidLoading 是否禁止显示读取画面
function TreasureboxPointsInfoGetRequest.sendRequest(forbidLoading, succeedCallback, failedCallback)
	local function onSucceedHandle(event)
		if succeedCallback then
			succeedCallback(event)
		end
	end 
	local function onFailedHandle(event)
		if failedCallback then
			failedCallback(event)
		end
	end
	local params = {}
	local request = TreasureboxPointsInfoGetRequest.new(params, rpc.SendingPriority.kHigh, forbidLoading)
	request:addEventListener(RequestNotifyEnum.TreasureboxPointsInfoGetSucceed, onSucceedHandle)
	request:addEventListener(RequestNotifyEnum.TreasureboxPointsInfoGetFailed, onFailedHandle)
	request:start()
end

--成功的默认处理
function TreasureboxPointsInfoGetRequest.onSucceedDefault(event)
	--print("onSucceedDefault!")
end

--失败默认处理
function TreasureboxPointsInfoGetRequest.onFailedDefault(event)
	--print("onFailedDefault!")
	if event.data.retCode == 714541 then  --activity closed
		local function closeCanonMessageBox()
		end
		local text = Localization:getInstance():getText("activity_error_expired")
		Director:mgr():run().targetInfoPanel = CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
	else
		local function closeCanonMessageBox()
		end
		local text = Localization:getInstance():getText("defaultError_popupText", {errorCodeId = event.data.retCode})
		Director:mgr():run().targetInfoPanel = CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
	end
end