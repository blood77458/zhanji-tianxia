require "canon.request.BaseRequest"

--
-- 跨服Gacha 小玉嫁到 相关
--
--获取活动信息
GetCrossGachaInfoRequest = class(BaseRequest)

function GetCrossGachaInfoRequest:ctor(params, priority)
    self.endpoint = "getCrossGachaInfo"
end

function GetCrossGachaInfoRequest:onSuccess(data)
  --print("getGachaPointsInfo success: " .. table.serialize(data))
  self:dispatchEvent(Event.new(RequestNotifyEnum.GetCrossGachaInfoSucceed, data))
end

function GetCrossGachaInfoRequest:onError(error)
  --BaseRequest.onError(self, error)
  self:dispatchEvent(Event.new(RequestNotifyEnum.GetCrossGachaInfoFailed, {retCode = error}))
end

--领取积分奖励
CrossGachaGainPointRewardRequest = class(BaseRequest)

function CrossGachaGainPointRewardRequest:ctor()
  self.endpoint = "gainCrossGachaPointReward"
end

function CrossGachaGainPointRewardRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.CrossGachaGainPointRewardSucceed, data))
end

function CrossGachaGainPointRewardRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.CrossGachaGainPointRewardFailed, {retCode = error}))
end

--领取排名奖励
CrossGachaGainRankRewardRequest = class(BaseRequest)

function CrossGachaGainRankRewardRequest:ctor()
  self.endpoint = "gainCrossGachaRankAndMysteriousReward"
end

function CrossGachaGainRankRewardRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.CrossGachaGainRankRewardSucceed, data))
end

function CrossGachaGainRankRewardRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.CrossGachaGainRankRewardFailed, {retCode = error}))
end
-------------------------------------------------------------------静态函数

function CrossGachaGainPointRewardRequest.sendRequest(rankRewardId, succeedCallback, failedCallback)
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
	local request = CrossGachaGainPointRewardRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.CrossGachaGainPointRewardSucceed, onSucceedHandle)
	request:addEventListener(RequestNotifyEnum.CrossGachaGainPointRewardFailed, onFailedHandle)
	request:start()
end

--成功的默认处理
function CrossGachaGainPointRewardRequest.onSucceedDefault(event)
	--print("onSucceedDefault!")
end

--失败默认处理
function CrossGachaGainPointRewardRequest.onFailedDefault(event)
	--print("onFailedDefault!")
	if event.data.retCode == 714781 then  --activity closed
		local function closeCanonMessageBox()
			local scene = MainMenuScene.create()
            Director:sharedDirector():replaceScene( scene )
		end
		local text = Localization:getInstance():getText("activity_timeOver")
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

--
function CrossGachaGainRankRewardRequest.sendRequest( succeedCallback, failedCallback)
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
	local request = CrossGachaGainRankRewardRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.CrossGachaGainRankRewardSucceed, onSucceedHandle)
	request:addEventListener(RequestNotifyEnum.CrossGachaGainRankRewardFailed, onFailedHandle)
	request:start()
end

--成功的默认处理
function CrossGachaGainRankRewardRequest.onSucceedDefault(event)
	--print("onSucceedDefault!")
end

--失败默认处理
function CrossGachaGainRankRewardRequest.onFailedDefault(event)
	if event.data.retCode == 714781 then  --activity closed
		local function closeCanonMessageBox()
			local scene = MainMenuScene.create()
            Director:sharedDirector():replaceScene( scene )
		end
		local text = Localization:getInstance():getText("activity_timeOver")
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