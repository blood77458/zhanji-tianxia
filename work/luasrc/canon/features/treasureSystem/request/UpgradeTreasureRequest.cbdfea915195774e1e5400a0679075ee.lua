require "canon.request.BaseRequest"

--宝物强化
-- UpgradeTreasureRequest
--
UpgradeTreasureRequest = class(BaseRequest)
--测试状态 仅限内部测试用(一般用于假数据)
UpgradeTreasureRequest.TEST = false --提测之前请务必改回默认 false !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

function UpgradeTreasureRequest:ctor()
  self.endpoint = "upgradeTreasure"--<<<<< 1. 修改指令名称 后端提供
  self.succeedEventName = self.endpoint .. "Succeed"
  self.failedEventName = self.endpoint .. "Failed"
end

function UpgradeTreasureRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(self.succeedEventName, data))
end

function UpgradeTreasureRequest:onError( error )
  self:dispatchEvent(Event.new(self.failedEventName, {retCode = error}))
end

-------------------------------------------------------------------静态函数

--发送请求 默认处理 成功返回之后可加额外处理(参数可传nil)
function UpgradeTreasureRequest.sendRequestDefalut(Data,afterSucceedCallback)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
	local function onSucceed(evt)
		UpgradeTreasureRequest.onSucceedDefault(evt)
		if afterSucceedCallback then
			afterSucceedCallback(evt)
		end
	end
	UpgradeTreasureRequest.sendRequest(Data, onSucceed, UpgradeTreasureRequest.onFailedDefault)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
end

--发送请求
function UpgradeTreasureRequest.sendRequest(Data, succeedCallback, failedCallback)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
	local params = {oneClick = Data.oneclick,treasureId = Data.treasureIds }--<<<<< 2. 附加参数转换成后端提供的接口格式
    -- print("~~~~~~~~~~~~~~~~~Data.treasureIds = "..tostringRich(Data.treasureIds))
    local function onSucceedHandle(event)
		if succeedCallback then
			event = event or {}
			event.treasureId = params.treasureId
            event.oneClick = params.oneClick
			succeedCallback(event)
		end
	end 
	local function onFailedHandle(event)
		if failedCallback then
			failedCallback(event)
		end
	end
	
	if not UpgradeTreasureRequest.TEST then
		--非测试状态 正常流程
		if SystemManager.debug then
			print("UpgradeTreasureRequest->params = " .. tostringRich(params, 2))--深度2 防止打印内容过多 一般够用
		end

		local request = UpgradeTreasureRequest.new(params or {}, rpc.SendingPriority.kHigh)
		request:addEventListener(request.succeedEventName, onSucceedHandle)
		request:addEventListener(request.failedEventName, onFailedHandle)
		request:start()
	else
		--测试流程 假数据
		onSucceedHandle(UpgradeTreasureRequest.getDebugDatas())
	end
end

--成功的默认处理
function UpgradeTreasureRequest.onSucceedDefault(event)--<<<<< 3. 成功的默认处理 do someting
	if SystemManager.debug then
		print("UpgradeTreasureRequest->event = " .. tostringRich(event))
	end
end

--失败默认处理
function UpgradeTreasureRequest.onFailedDefault(event)
	local errorCode = tonumber(event.data.retCode)
	 local function closeCanonMessageBox()
  	end
	local text = Localization:getInstance():getText("defaultError_popupText", {errorCodeId = event.data.retCode})
	CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
end



--获得测试用假数据--<<<<< 4. 根据需要填写测试假数据 用完删除  报名不需要假数据
function UpgradeTreasureRequest.getDebugDatas()
	local testEvt = {data = {}}
	  

	return testEvt
end
