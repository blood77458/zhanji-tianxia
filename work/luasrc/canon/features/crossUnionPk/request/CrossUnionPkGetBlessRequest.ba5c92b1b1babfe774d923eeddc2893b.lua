--跨服GvG  祝福请求 
require "canon.request.BaseRequest"
--
CrossUnionPkGetBlessRequest = class(BaseRequest)
--测试状态 仅限内部测试用(一般用于假数据)
CrossUnionPkGetBlessRequest.TEST = false --提测之前请务必改回默认 false !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

function CrossUnionPkGetBlessRequest:ctor()
  self.endpoint = "blessForCrossGVG"--<<<<< 1. 修改指令名称 后端提供
  self.succeedEventName = self.endpoint .. "Succeed"
  self.failedEventName = self.endpoint .. "Failed"
end

function CrossUnionPkGetBlessRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(self.succeedEventName, data))
end

function CrossUnionPkGetBlessRequest:onError( error )
  self:dispatchEvent(Event.new(self.failedEventName, {retCode = error}))
end

-------------------------------------------------------------------静态函数

--发送请求 默认处理 成功返回之后可加额外处理(参数可传nil)
function CrossUnionPkGetBlessRequest.sendRequestDefalut(afterSucceedCallback)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
	local function onSucceed(evt)
		CrossUnionPkGetBlessRequest.onSucceedDefault(evt)
		if afterSucceedCallback then
			afterSucceedCallback(evt)
		end
	end
	CrossUnionPkGetBlessRequest.sendRequest(onSucceed, CrossUnionPkGetBlessRequest.onFailedDefault)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
end

--发送请求
function CrossUnionPkGetBlessRequest.sendRequest(succeedCallback, failedCallback)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
	local params = {}--<<<<< 2. 附加参数转换成后端提供的接口格式

	local function onSucceedHandle(event)
		event.params = params
		if succeedCallback then
			event.params = params
			event.Data = Data
			succeedCallback(event)
		end
	end 
	local function onFailedHandle(event)
		if failedCallback then
			event.params = params
			failedCallback(event)
		end
	end

	if not CrossUnionPkGetBlessRequest.TEST then
		--非测试状态 正常流程
		if SystemManager.debug then
			print("CrossUnionPkGetBlessRequest->params = " .. tostringRich(params, 2))--深度2 防止打印内容过多 一般够用
		end
		local request = CrossUnionPkGetBlessRequest.new(params, rpc.SendingPriority.kHigh)
		request:addEventListener(request.succeedEventName, onSucceedHandle)
		request:addEventListener(request.failedEventName, onFailedHandle)
		request:start()
	else
		--测试流程 假数据
		onSucceedHandle(CrossUnionPkGetBlessRequest.getDebugDatas())
	end
end

--成功的默认处理
function CrossUnionPkGetBlessRequest.onSucceedDefault(event)--<<<<< 3. 成功的默认处理 do someting
	if SystemManager.debug then
		print("CrossUnionPkGetBlessRequest->event = " .. tostringRich(event))
	end
end

--失败默认处理
function CrossUnionPkGetBlessRequest.onFailedDefault(event)
	local errorCode = tonumber(event.data.retCode)
	local function onErrorConfirm(errorCode)
		if errorCode == 716313 then
			--玩家没加入任何军团 返回主界面
			local scene = Director:mgr():run()
			scene:replaceScene(MainMenuScene)
		end
	end
	local ret = ErrorCodeManager.alert(errorCode, onErrorConfirm)
end
-- <request>
-- 	</request>
-- 	<response>
-- 		<list code="rewards" ref="Reward" desc="祝福获得的奖励内容" />
-- 	</response>


--获得测试用假数据--<<<<< 4. 根据需要填写测试假数据 用完删除  报名不需要假数据
function CrossUnionPkGetBlessRequest.getDebugDatas()
	local testEvt = {data = {}}
	--奖励
	-- <property code="itemType" type="int" desc="类型" />
	-- <property code="metaId" type="int" desc="物品id" />
	-- <property code="id" type="int" desc="db存储id" />
	-- <property code="amount" type="long" desc="数量" />
	-- <property code="level" type="int" desc="卡牌/装备等的等级" />
	-- <property code="exp" type="long" desc="卡牌/装备等的经验" />
	local Reward = nil
	testEvt.data.rewards =  {}
	--  "itemType": 7,
    -- "metaId": 400093,
    -- "id": 0,
    -- "amount": 10,
    -- "level": 0,
    -- "exp": 0
	Reward = {}
	Reward.itemType = 7
	Reward.metaId = 400093
	Reward.id = 0
	Reward.amount = 10
	Reward.level = 0
	Reward.exp = 0
	table.insert(testEvt.data.rewards, Reward)  

	return testEvt
end