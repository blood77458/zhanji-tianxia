--
-- UnionQuitRequest.lua
-- Author: zheng.che
-- Date: 2014-03-26 11:09:32
-- 退出军团请求
--
require "canon.request.BaseRequest"

UnionQuitRequest = class(BaseRequest)

function UnionQuitRequest:ctor()
  self.endpoint = "quitUnion"--<<<<< 1. 修改指令名称 后端提供
end

function UnionQuitRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.UnionQuitSucceed, data))--<<<<< 2. 修改枚举名称 定义在BaseRequest里 不能重复
end

function UnionQuitRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.UnionQuitFailed, {retCode = error}))--<<<<< 2
end

-------------------------------------------------------------------静态函数

function UnionQuitRequest.sendRequest(succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
	local function onSucceedHandle(event)
		if succeedCallback then
			succeedCallback(event)--<<<<< 3
		end
	end 
	local function onFailedHandle(event)
		if failedCallback then
			failedCallback(event)
		end
	end
	local params = {}--<<<<< 3
	local request = UnionQuitRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.UnionQuitSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.UnionQuitFailed, onFailedHandle)--<<<<< 2
	request:start()
end

--成功的默认处理
function UnionQuitRequest.onSucceedDefault(event)--<<<<< 3
  ChatManager.sendChat({method = MethodDict.QUITUNION, uid = DataManager.getCurrUser().uid, unionId = UnionManager.getUnionId()})
  
	--print("onSucceedDefault! event = " .. table.tostring(event))
	
	local scene = Director:mgr():run()
	SuspensionLabel:showContent(scene, Localization:getInstance():getText("union_player_button_quit_complete", {name = UnionManager.getUnionName()}))--你已退出{name}军团

	UnionManager.setMyUnionData(event.data.sharkUserUnion)

	UnionManager.gotoUnionListScene()
end

--失败默认处理
function UnionQuitRequest.onFailedDefault(event)--<<<<< 4. 修改错误码对应逻辑处理
	--print("onFailedDefault!")
	local errorCode = tonumber(event.data.retCode)
	if(errorCode == 716313) then -- User has not joined any union: {0:uid}
		CanonMessageBox:showCommErrorBox(CommErrorCodes.USER_NOT_JOIN_ANY_UNION, nil, nil, nil)
	elseif(errorCode == 716318) then -- User is manager of union: {0:uid}, {1:unionId
		CanonMessageBox:showCommErrorBox(CommErrorCodes.USER_IS_UNION_MANAGER, nil, nil, nil)
	elseif(errorCode == 716633) then -- 在军团战期间禁止操作
		CanonMessageBox.showTextBox(getTextByKey("UnionWar_error_txt1"), nil)
	else
		CanonMessageBox:showCommUnHandleErrorBox(errorCode)
	end
-- 	USER_NOT_JOIN_ANY_UNION(6313, "User has not joined any union: {0:uid}")
-- USER_IS_UNION_MANAGER(6318, "User is manager of union: {0:uid}, {1:unionId}")

end