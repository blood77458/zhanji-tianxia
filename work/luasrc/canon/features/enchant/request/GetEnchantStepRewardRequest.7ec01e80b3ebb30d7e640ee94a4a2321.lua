-- GetEnchantStepRewardRequest
-- 2015-1-6
-- jet.zhao
-- 附灵引导奖励接口

-- <protocol desc="完成装备附灵新手引导">
-- 	<request>
-- 	</request>
-- 	<response>
-- 	</response>
-- </protocol>

require "canon.request.BaseRequest"

GetEnchantStepRewardRequest = class(BaseRequest)

function GetEnchantStepRewardRequest:ctor()
  self.endpoint = "getEnchantStepReward"--<<<<< 1. 修改指令名称 后端提供
  self.succeedEventName = self.endpoint .. "Succeed"
  self.failedEventName = self.endpoint .. "Failed"
end

function GetEnchantStepRewardRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(self.succeedEventName, data))
end

function GetEnchantStepRewardRequest:onError( error )
  self:dispatchEvent(Event.new(self.failedEventName, {retCode = error}))
end

-------------------------------------------------------------------静态函数

--发送请求 默认处理 成功返回之后可加额外处理(参数可传nil)
function GetEnchantStepRewardRequest.sendRequestDefalut(equipData, afterSucceedCallback)--<<<<< 3
	local function onSucceed(evt)
		GetEnchantStepRewardRequest.onSucceedDefault(evt)
		if afterSucceedCallback then
			afterSucceedCallback(evt)
		end
	end
	GetEnchantStepRewardRequest.sendRequest(equipData, onSucceed, GetEnchantStepRewardRequest.onFailedDefault)
end

--发送请求
function GetEnchantStepRewardRequest.sendRequest(equipData, succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
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
	local request = GetEnchantStepRewardRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(request.succeedEventName, onSucceedHandle)
	request:addEventListener(request.failedEventName, onFailedHandle)
	request:start()
end

--成功的默认处理
function GetEnchantStepRewardRequest.onSucceedDefault(event)--<<<<< 3
	--print(table.tostring(event.data.rewards))
	for _, aReward in pairs(event.data.rewards) do
		if aReward.itemType == ResourceEnum.EQUIP then
			aReward.enchantLevel = DataManager.GameMetaData.enchantTotalConfig.enchantLevel
			break
		end
	end
	RewardManager:getReward(event.data.rewards)
	local gameInitData = DataManager.getGameInitData()
	gameInitData.sharkUserExtend.enchantStepReward = true
	DataManager.setGameInitData(gameInitData)
end

--失败默认处理
function GetEnchantStepRewardRequest.onFailedDefault(event)--<<<<< 4. 修改错误码对应逻辑处理
	local errorCode = tonumber(event.data.retCode)
	local function onErrorConfirm(errorCode)
	end
	local ret = ErrorCodeManager.alert(errorCode, onErrorConfirm)
end