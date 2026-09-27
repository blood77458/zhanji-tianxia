require "canon.request.BaseRequest"

--宝物升星
-- EvolveTreasureRequest
--
EvolveTreasureRequest = class(BaseRequest)
--测试状态 仅限内部测试用(一般用于假数据)
EvolveTreasureRequest.TEST = false --提测之前请务必改回默认 false !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

function EvolveTreasureRequest:ctor()
  self.endpoint = "evolveTreasure"--<<<<< 1. 修改指令名称 后端提供
  self.succeedEventName = self.endpoint .. "Succeed"
  self.failedEventName = self.endpoint .. "Failed"
end

function EvolveTreasureRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(self.succeedEventName, data))
end

function EvolveTreasureRequest:onError( error )
  self:dispatchEvent(Event.new(self.failedEventName, {retCode = error}))
end

-------------------------------------------------------------------静态函数

--发送请求 默认处理 成功返回之后可加额外处理(参数可传nil)
function EvolveTreasureRequest.sendRequestDefalut(Data,afterSucceedCallback)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
	local function onSucceed(evt)
		EvolveTreasureRequest.onSucceedDefault(evt)
		if afterSucceedCallback then
			afterSucceedCallback(evt)
		end
	end
	EvolveTreasureRequest.sendRequest(Data, onSucceed, EvolveTreasureRequest.onFailedDefault)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
end

--发送请求
function EvolveTreasureRequest.sendRequest(Data, succeedCallback, failedCallback)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
	local params = {treasureId = Data.treasureIds }--<<<<< 2. 附加参数转换成后端提供的接口格式
    -- print("~~~~~~~~~~~~~~~~~Data.treasureIds = "..tostringRich(Data.treasureIds))
    local function onSucceedHandle(event)
		if succeedCallback then
			event = event or {}
			event.treasureId = params.treasureId
            succeedCallback(event)
		end
	end 
	local function onFailedHandle(event)
		if failedCallback then
			failedCallback(event)
		end
	end
	
	if not EvolveTreasureRequest.TEST then
		--非测试状态 正常流程
		if SystemManager.debug then
			print("EvolveTreasureRequest->params = " .. tostringRich(params, 2))--深度2 防止打印内容过多 一般够用
		end

		local request = EvolveTreasureRequest.new(params or {}, rpc.SendingPriority.kHigh)
		request:addEventListener(request.succeedEventName, onSucceedHandle)
		request:addEventListener(request.failedEventName, onFailedHandle)
		request:start()
	else
		--测试流程 假数据
		onSucceedHandle(EvolveTreasureRequest.getDebugDatas())
	end
end

--成功的默认处理
function EvolveTreasureRequest.onSucceedDefault(event)--<<<<< 3. 成功的默认处理 do someting
	if SystemManager.debug then
		print("EvolveTreasureRequest->event = " .. tostringRich(event))
	end
end

--失败默认处理
function EvolveTreasureRequest.onFailedDefault(event)
	local errorCode = tonumber(event.data.retCode)
	 local function closeCanonMessageBox()
  	end
	local text = Localization:getInstance():getText("defaultError_popupText", {errorCodeId = event.data.retCode})
	CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
end


--[[
<property code="treasureId" type="int" desc="宝物ID" />
	<property code="metaId" type="int" desc="宝物配置ID" />
	<property code="level" type="int" desc="宝物等级" />
	<property code="cardId" type="int" desc="宝物所在卡牌ID" />
	<property code="addPotential" type="int" desc="潜力值加成" />
	<property code="addGemPotential" type="int" desc="金币获得额外潜力加成" />
	<property code="usedPotential" type="int" desc="已使用的潜力值" />
	<property code="lock" type="boolean" desc="宝物锁" />
]]
--获得测试用假数据--<<<<< 4. 根据需要填写测试假数据 用完删除  报名不需要假数据
function EvolveTreasureRequest.getDebugDatas()
	local testEvt = {data = {}}
	testEvt.data.sharkTreasure = {}

	testEvt.data.sharkTreasure.treasureId = 1
	testEvt.data.sharkTreasure.metaId = 281012
	testEvt.data.sharkTreasure.level = 45
	testEvt.data.sharkTreasure.cardId = 0
	testEvt.data.sharkTreasure.addPotential = 0
	testEvt.data.sharkTreasure.addGemPotential = 0
	testEvt.data.sharkTreasure.usedPotential = 0
	testEvt.data.sharkTreasure.lock = false
    return testEvt
end
