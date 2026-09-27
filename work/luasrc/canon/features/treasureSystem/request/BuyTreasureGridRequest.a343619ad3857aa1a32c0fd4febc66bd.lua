--------------------------------------------------------------------------------
-- BuyTreasureGridRequest.lua --宝物格子
-- author: l1ghtsaber
-- date: 2015-7-28
--------------------------------------------------------------------------------

require "canon.request.BaseRequest"

BuyTreasureGridRequest = class(BaseRequest)

function BuyTreasureGridRequest:ctor(params, priority)
    self.endpoint = "buyTreasureGrid"--<<<<< 1. 修改指令名称 后端提供
  	self.succeedEventName = self.endpoint .. "Succeed"
  	self.failedEventName = self.endpoint .. "Failed"
end

function BuyTreasureGridRequest:onSuccess( data )
  	self:dispatchEvent(Event.new(self.succeedEventName, data))
end

function BuyTreasureGridRequest:onError(error)
  	self:dispatchEvent(Event.new(self.failedEventName, {retCode = error}))
end

--发送请求 默认处理 成功返回之后可加额外处理(参数可传nil)
function BuyTreasureGridRequest.sendRequestDefalut(afterSucceedCallback)--<<<<< 3
	local function onSucceed(evt)
		BuyTreasureGridRequest.onSucceedDefault(evt)
		if afterSucceedCallback then
			afterSucceedCallback(evt)
		end
	end
	BuyTreasureGridRequest.sendRequest(onSucceed, BuyTreasureGridRequest.onFailedDefault)
end

function BuyTreasureGridRequest.sendRequest(succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
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

	local request = BuyTreasureGridRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(request.succeedEventName, onSucceedHandle)--<<<<< 2
	request:addEventListener(request.failedEventName, onFailedHandle)--<<<<< 2
	request:start()
end

--成功的默认处理
function BuyTreasureGridRequest.onSucceedDefault( e )--<<<<< 3
	local gameInitData = DataManager.getGameInitData()
	gameInitData.sharkUserExtendMore.treasureInfo.buyGridTimes = gameInitData.sharkUserExtendMore.treasureInfo.buyGridTimes + 1
	DataManager.setGameInitData(gameInitData)
	local cost = DataManager.GameMetaData.treasureSettingConfig.treasurePoolExpandCost
	local requisite = {
		amount = tostring(-cost),
		metaId = 0,
		itemType = 2,
		id = 0
	}
	RewardManager:getReward({requisite})
end

--失败默认处理
function BuyTreasureGridRequest.onFailedDefault( e )--<<<<< 4. 修改错误码对应逻辑处理
	print("失败了吧")
	if e.data == 710513 then
		local aPanel = AssistantMessageBoxPanel:create( SELF, AsMessageBoxType.addCoin )
		SELF:addChild(aPanel)
		aPanel:scaleIn()
	else
		CanonMessageBox:showCommUnHandleErrorBox(e.data)
	end
end