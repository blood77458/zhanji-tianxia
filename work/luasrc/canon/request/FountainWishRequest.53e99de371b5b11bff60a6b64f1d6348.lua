-- FountainWishRequest.lua
-- 2014-12-17
-- zheng.che
-- 许愿池许愿接口

--<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< 接口定义 后端提供
-- <protocol desc="许愿池许愿">
--     <request>
--     </request>
--     <response>
--         <property code="coins" type="int" desc="基础银币获得" />
--         <property code="multiple" type="int" desc="暴击倍数" />
--     </response>
-- </protocol>

require "canon.request.BaseRequest"

FountainWishRequest = class(BaseRequest)

function FountainWishRequest:ctor()
  self.endpoint = "wishing"--<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< 修改指令名称 后端提供
  self.succeedEventName = self.endpoint .. "Succeed"
  self.failedEventName = self.endpoint .. "Failed"
end

function FountainWishRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(self.succeedEventName, data))
end

function FountainWishRequest:onError( error )
  self:dispatchEvent(Event.new(self.failedEventName, {retCode = error}))
end

-------------------------------------------------------------------静态函数

--发送请求 默认处理 成功返回之后可加额外处理(参数可传nil)
function FountainWishRequest.sendRequestDefalut(afterSucceedCallback)--<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< 如果需要附加参数 从第一个函数参数开始加
	local function onSucceed(evt)
		FountainWishRequest.onSucceedDefault(evt)
		if afterSucceedCallback then
			afterSucceedCallback(evt)
		end
	end
	FountainWishRequest.sendRequest(onSucceed, FountainWishRequest.onFailedDefault)
end

--发送请求
function FountainWishRequest.sendRequest(succeedCallback, failedCallback)--<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< 如果需要附加参数 从第一个函数参数开始加
	local params = {}--<<<<< 3

	local function onSucceedHandle(event)
		if succeedCallback then
			event.params = params
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
	
	local request = FountainWishRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(request.succeedEventName, onSucceedHandle)
	request:addEventListener(request.failedEventName, onFailedHandle)
	request:start()

	--succeedCallback({data={coins=111,multiple=3}})
end

--成功的默认处理
function FountainWishRequest.onSucceedDefault(event)--<<<<< 3
	if SystemManager.debug then
		print("onSucceedDefault! event = " .. table.tostring(event))
	end

	--扣金币 如果需要
	local todayTimes = DailyDataManager.getWishings()--今日许愿次数
	local needGold = Activity_FountainLayer.getCost(todayTimes + 1)--下一次许愿所需金币数量
	RewardManager:getReward({{itemType = ResourceEnum.GEMS, amount = (-needGold or 0)}})

	--加银币
	local totalAddCoin = event.data.coins * event.data.multiple
	RewardManager:getReward({{itemType = ResourceEnum.COIN, amount = (totalAddCoin or 0)}})

	--更新次数
	DailyDataManager.setWishings(todayTimes + 1)
end

--失败默认处理
function FountainWishRequest.onFailedDefault(event)--<<<<< 4. 修改错误码对应逻辑处理
	local errorCode = tonumber(event.data.retCode)
	local function onErrorConfirm(errorCode)
	end
	local ret = ErrorCodeManager.alert(errorCode, onErrorConfirm)
end