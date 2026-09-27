require "canon.request.BaseRequest"

--卡牌装备全部强化
-- UpgradeEquipForOneCardRequest
--
UpgradeEquipForOneCardRequest = class(BaseRequest)
--测试状态 仅限内部测试用(一般用于假数据)
UpgradeEquipForOneCardRequest.TEST = false --提测之前请务必改回默认 false !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

function UpgradeEquipForOneCardRequest:ctor()
  self.endpoint = "upgradeEquipForOneCard"--<<<<< 1. 修改指令名称 后端提供
  self.succeedEventName = self.endpoint .. "Succeed"
  self.failedEventName = self.endpoint .. "Failed"
end

function UpgradeEquipForOneCardRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(self.succeedEventName, data))
end

function UpgradeEquipForOneCardRequest:onError( error )
  self:dispatchEvent(Event.new(self.failedEventName, {retCode = error}))
end

-------------------------------------------------------------------静态函数

--发送请求 默认处理 成功返回之后可加额外处理(参数可传nil)
function UpgradeEquipForOneCardRequest.sendRequestDefalut(Data,afterSucceedCallback)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
	local function onSucceed(evt)
		UpgradeEquipForOneCardRequest.onSucceedDefault(evt)
		if afterSucceedCallback then
			afterSucceedCallback(evt)
		end
	end
	UpgradeEquipForOneCardRequest.sendRequest(Data, onSucceed, UpgradeEquipForOneCardRequest.onFailedDefault)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
end

--发送请求
function UpgradeEquipForOneCardRequest.sendRequest(Data, succeedCallback, failedCallback)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
	local params = {equipIds = Data}--<<<<< 2. 附加参数转换成后端提供的接口格式
    print("~~~~~~~~~~~~~~~~~Data.EquipIds = "..tostringRich(Data))
    local function onSucceedHandle(event)
		if succeedCallback then
			event = event or {}
			event.equipIds = params.equipIds
            
			succeedCallback(event)
		end
	end 
	local function onFailedHandle(event)
		if failedCallback then
			failedCallback(event)
		end
	end
	
	if not UpgradeEquipForOneCardRequest.TEST then
		--非测试状态 正常流程
		if SystemManager.debug then
			print("UpgradeEquipForOneCardRequest->params = " .. tostringRich(params, 2))--深度2 防止打印内容过多 一般够用
		end

		local request = UpgradeEquipForOneCardRequest.new(params or {}, rpc.SendingPriority.kHigh)
		request:addEventListener(request.succeedEventName, onSucceedHandle)
		request:addEventListener(request.failedEventName, onFailedHandle)
		request:start()
	else
		--测试流程 假数据
		onSucceedHandle(UpgradeEquipForOneCardRequest.getDebugDatas())
	end
end

--成功的默认处理
function UpgradeEquipForOneCardRequest.onSucceedDefault(event)--<<<<< 3. 成功的默认处理 do someting
	if SystemManager.debug then
		print("UpgradeEquipForOneCardRequest->event = " .. tostringRich(event))
	end
end

--失败默认处理
function UpgradeEquipForOneCardRequest.onFailedDefault(event)
	local errorCode = tonumber(event.data.retCode)
	 local function closeCanonMessageBox()
  	end
	local text = Localization:getInstance():getText("defaultError_popupText", {errorCodeId = event.data.retCode})
	CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
end



--获得测试用假数据--<<<<< 4. 根据需要填写测试假数据 用完删除  报名不需要假数据
function UpgradeEquipForOneCardRequest.getDebugDatas()
	local testEvt = {data = {}}
	  

	return testEvt
end
