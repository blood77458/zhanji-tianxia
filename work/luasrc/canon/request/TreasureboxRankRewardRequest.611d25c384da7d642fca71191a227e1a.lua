--
-- TreasureboxRankRewardRequest.lua
-- Author: zheng.che
-- Date: 2014-02-27 18:05:36
--
require "canon.request.BaseRequest"

TreasureboxRankRewardRequest = class(BaseRequest)

function TreasureboxRankRewardRequest:ctor()
  self.endpoint = "gainTreasureboxPointsRankReward"
end

function TreasureboxRankRewardRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.TreasureboxGainRankRewardSucceed, data))
end

function TreasureboxRankRewardRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.TreasureboxGainRankRewardFailed, {retCode = error}))
end

-------------------------------------------------------------------静态函数

function TreasureboxRankRewardRequest.sendRequest(succeedCallback, failedCallback)
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
	local request = TreasureboxRankRewardRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.TreasureboxGainRankRewardSucceed, onSucceedHandle)
	request:addEventListener(RequestNotifyEnum.TreasureboxGainRankRewardFailed, onFailedHandle)
	request:start()
end

--成功的默认处理
function TreasureboxRankRewardRequest.onSucceedDefault(event)
	--print("onSucceedDefault!")
end

--失败默认处理
function TreasureboxRankRewardRequest.onFailedDefault(event)
	--print("onFailedDefault!")
	if event.data.retCode == 714543 then  --activity closed
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