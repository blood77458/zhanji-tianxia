--
-- TreasureboxPointRewardRequest.lua
-- Author: zheng.che
-- Date: 2014-02-28 16:26:41
--
require "canon.request.BaseRequest"

TreasureboxPointRewardRequest = class(BaseRequest)

function TreasureboxPointRewardRequest:ctor()
  self.endpoint = "gainTreasureboxPointsReward"
end

function TreasureboxPointRewardRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.TreasureboxGainPointRewardSucceed, data))
end

function TreasureboxPointRewardRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.TreasureboxGainPointRewardFailed, {retCode = error}))
end

-------------------------------------------------------------------静态函数

function TreasureboxPointRewardRequest.sendRequest(rankRewardId, succeedCallback, failedCallback)
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
	local params = {id = rankRewardId}
	--print("请求获得积分奖励! params = " .. table.tostring(params))
	local request = TreasureboxPointRewardRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.TreasureboxGainPointRewardSucceed, onSucceedHandle)
	request:addEventListener(RequestNotifyEnum.TreasureboxGainPointRewardFailed, onFailedHandle)
	request:start()
end

--成功的默认处理
function TreasureboxPointRewardRequest.onSucceedDefault(event)
	--print("onSucceedDefault!")
end

--失败默认处理
function TreasureboxPointRewardRequest.onFailedDefault(event)
	--print("onFailedDefault!")
	if event.data.retCode == 714541 then  --activity closed
		local function closeCanonMessageBox()
		end
		local text = Localization:getInstance():getText("activity_error_expired")
		Director:mgr():run().targetInfoPanel = CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
	elseif event.data.retCode == 710516 then  --背包满
		local function closeCanonMessageBox()
		end
		local text = Localization:getInstance():getText("shop_inventoryFull")
		Director:mgr():run().targetInfoPanel = NewPackageFullPanel:show()
	else
		local function closeCanonMessageBox()
		end
		local text = Localization:getInstance():getText("defaultError_popupText", {errorCodeId = event.data.retCode})
		Director:mgr():run().targetInfoPanel = CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
	end
end