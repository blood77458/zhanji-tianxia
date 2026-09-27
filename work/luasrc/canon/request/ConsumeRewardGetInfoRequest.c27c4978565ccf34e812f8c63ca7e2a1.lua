-- ConsumeRewardGetInfoRequest.lua
-- 2014-12-17
-- zheng.che
-- 多重好礼获取面板信息接口

--<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< 接口定义 后端提供
-- <protocol desc="获得多重好礼信息">
-- 	<request>
-- 	</request>
-- 	<response>
-- 		<property code="recharges" type="int" desc="活动期间充值金币" />
-- 		<list code="rewards" type="int" desc="已领取礼品id" />
-- 	</response>
-- </protocol>

require "canon.request.BaseRequest"

ConsumeRewardGetInfoRequest = class(BaseRequest)

function ConsumeRewardGetInfoRequest:ctor()
  self.endpoint = "getConsumeRewardInfo"--<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< 修改指令名称 后端提供
  self.succeedEventName = self.endpoint .. "Succeed"
  self.failedEventName = self.endpoint .. "Failed"
end

function ConsumeRewardGetInfoRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(self.succeedEventName, data))
end

function ConsumeRewardGetInfoRequest:onError( error )
  self:dispatchEvent(Event.new(self.failedEventName, {retCode = error}))
end

-------------------------------------------------------------------静态函数

--发送请求 默认处理 成功返回之后可加额外处理(参数可传nil)
function ConsumeRewardGetInfoRequest.sendRequestDefalut(afterSucceedCallback)--<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< 如果需要附加参数 从第一个函数参数开始加
	local function onSucceed(evt)
		ConsumeRewardGetInfoRequest.onSucceedDefault(evt)
		if afterSucceedCallback then
			afterSucceedCallback(evt)
		end
	end
	ConsumeRewardGetInfoRequest.sendRequest(onSucceed, ConsumeRewardGetInfoRequest.onFailedDefault)
end

--发送请求
function ConsumeRewardGetInfoRequest.sendRequest(succeedCallback, failedCallback)--<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< 如果需要附加参数 从第一个函数参数开始加
	local params = {}--<<<<<<<<<<<<<<<<<<<<<<<<<< 后端定义的所需参数填到这里

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
	
	local request = ConsumeRewardGetInfoRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(request.succeedEventName, onSucceedHandle)
	request:addEventListener(request.failedEventName, onFailedHandle)
	request:start()

	--succeedCallback({data={coins=111,multiple=3}})
end

--成功的默认处理
function ConsumeRewardGetInfoRequest.onSucceedDefault(event)--<<<<< 3
	if SystemManager.debug then
		print("onSucceedDefault! event = " .. tostringRich(event))
	end

	--更新数据
	Activity_ConsumeRewardsLayer.setRecharges(event.data.recharges)
	Activity_ConsumeRewardsLayer.setGainedIds(event.data.rewards)
end

--失败默认处理
function ConsumeRewardGetInfoRequest.onFailedDefault(event)--<<<<< 4. 修改错误码对应逻辑处理
	local errorCode = tonumber(event.data.retCode)
	local function onErrorConfirm(errorCode)
	end
	local ret = ErrorCodeManager.alert(errorCode, onErrorConfirm)
end