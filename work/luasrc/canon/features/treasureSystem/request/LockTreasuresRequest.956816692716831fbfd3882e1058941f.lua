require "canon.request.BaseRequest"

--宝物锁定
-- LockTreasuresRequest
--
LockTreasuresRequest = class(BaseRequest)
--测试状态 仅限内部测试用(一般用于假数据)
LockTreasuresRequest.TEST = false --提测之前请务必改回默认 false !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

function LockTreasuresRequest:ctor()
  self.endpoint = "lockTreasure"--<<<<< 1. 修改指令名称 后端提供
  self.succeedEventName = self.endpoint .. "Succeed"
  self.failedEventName = self.endpoint .. "Failed"
end

function LockTreasuresRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(self.succeedEventName, data))
end

function LockTreasuresRequest:onError( error )
  self:dispatchEvent(Event.new(self.failedEventName, {retCode = error}))
end

-------------------------------------------------------------------静态函数

--发送请求 默认处理 成功返回之后可加额外处理(参数可传nil)
function LockTreasuresRequest.sendRequestDefalut(Data,afterSucceedCallback)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
	local function onSucceed(evt)
		LockTreasuresRequest.onSucceedDefault(evt)
		if afterSucceedCallback then
			afterSucceedCallback(evt)
		end
	end
	LockTreasuresRequest.sendRequest(Data, onSucceed, LockTreasuresRequest.onFailedDefault)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
end

--发送请求
function LockTreasuresRequest.sendRequest(Data, succeedCallback, failedCallback)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
	local params = {type = Data.types,treasureId = Data.treasureIds }--<<<<< 2. 附加参数转换成后端提供的接口格式
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
	
	if not LockTreasuresRequest.TEST then
		--非测试状态 正常流程
		if SystemManager.debug then
			print("LockTreasuresRequest->params = " .. tostringRich(params, 2))--深度2 防止打印内容过多 一般够用
		end

		local request = LockTreasuresRequest.new(params or {}, rpc.SendingPriority.kHigh)
		request:addEventListener(request.succeedEventName, onSucceedHandle)
		request:addEventListener(request.failedEventName, onFailedHandle)
		request:start()
	else
		--测试流程 假数据
		onSucceedHandle(LockTreasuresRequest.getDebugDatas())
	end
end

--成功的默认处理
function LockTreasuresRequest.onSucceedDefault(event)--<<<<< 3. 成功的默认处理 do someting
	if SystemManager.debug then
		print("LockTreasuresRequest->event = " .. tostringRich(event))
	end
    local treasuresData = DataManager.getTreasuresData()
	local aTreasuresData , key = CommonManager.getSubTableByKey(treasuresData, {name = "treasureId", value = event.treasureId})
	print("aTreasuresData = " .. tostringRich(aTreasuresData.lock))
	aTreasuresData.lock = not aTreasuresData.lock
	DataManager.setTreasuresData(treasuresData)
	

end

--失败默认处理
function LockTreasuresRequest.onFailedDefault(event)
	local errorCode = tonumber(event.data.retCode)
	 local function closeCanonMessageBox()
  	end
	local text = Localization:getInstance():getText("defaultError_popupText", {errorCodeId = event.data.retCode})
	CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
end



--获得测试用假数据--<<<<< 4. 根据需要填写测试假数据 用完删除  报名不需要假数据
function LockTreasuresRequest.getDebugDatas()
	local testEvt = {data = {}}
	  

	return testEvt
end
