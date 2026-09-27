--
-- UnionDissolveRequest.lua
-- Author: zheng.che
-- Date: 2014-03-20 16:26:27
-- 解散军团请求
--

require "canon.request.BaseRequest"

UnionDissolveRequest = class(BaseRequest)

function UnionDissolveRequest:ctor()
  self.endpoint = "dissolveUnion"--<<<<< 1. 修改指令名称 后端提供
end

function UnionDissolveRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.UnionDissolveSucceed, data))--<<<<< 2. 修改枚举名称 定义在BaseRequest里 不能重复
end

function UnionDissolveRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.UnionDissolveFailed, {retCode = error}))--<<<<< 2
end

-------------------------------------------------------------------静态函数

function UnionDissolveRequest.sendRequest(succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
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
	local request = UnionDissolveRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.UnionDissolveSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.UnionDissolveFailed, onFailedHandle)--<<<<< 2
	request:start()
end

--成功的默认处理
function UnionDissolveRequest.onSucceedDefault(event)--<<<<< 3
	--print("onSucceedDefault! event = " .. table.tostring(event))

	--更新军团信息
	UnionManager.setUnionData(event.data.sharkUnion)
	--更新玩家军团信息
	UnionManager.setMyUnionData(event.data.sharkUserUnion)

	-- --解散成功后 返回主界面
	-- local scene = Director:mgr():run()
	-- scene:replaceScene(MainMenuScene)
end

--失败默认处理
function UnionDissolveRequest.onFailedDefault(event)--<<<<< 4. 修改错误码对应逻辑处理
	--print("onFailedDefault!")
	local errorCode = tonumber(event.data.retCode)
	if(errorCode == 716313) then -- User has not joined any union: {0:uid}
		CanonMessageBox:showCommErrorBox(CommErrorCodes.USER_NOT_JOIN_ANY_UNION, nil, nil, nil)
	elseif(errorCode == 716317) then -- User is not manager of union: {0:uid}
		CanonMessageBox:showCommErrorBox(CommErrorCodes.USER_NOT_UNION_MANAGER, nil, nil, nil)
	elseif(errorCode == 716316) then -- Union can not be dissolved due to level: {0:serverId}, {1:unionId}, {2:level}
		CanonMessageBox:showCommErrorBox(CommErrorCodes.UNION_CANONT_DISSOLVE_FOR_LEVEL, {num = UnionManager.getDissolveForbidLevel()}, nil, nil)
	elseif(errorCode == 716322) then -- Union can not be dissolved due to multiple members: {0:serverId}, {1:unionId}, {2:viceManager}, {3:eliteMember}, {4:member}
		CanonMessageBox:showCommErrorBox(CommErrorCodes.UNION_CANNOT_DISSOLVE_FOR_MULTIPLE_MEMBERS, nil, nil, nil)
	elseif(errorCode == 716633) then -- 在军团战期间禁止操作
		CanonMessageBox.showTextBox(getTextByKey("UnionWar_error_txt1"), nil)
	else
		CanonMessageBox:showCommUnHandleErrorBox(errorCode)
	end
-- 	USER_NOT_JOIN_ANY_UNION(6313, "User has not joined any union: {0:uid}")
-- USER_NOT_UNION_MANAGER(6317, "User is not manager of union: {0:uid}")
-- UNION_CANONT_DISSOLVE_FOR_LEVEL(6316, "Union can not be dissolved due to level: {0:serverId}, {1:unionId}, {2:level}")
-- UNION_CANNOT_DISSOLVE_FOR_MULTIPLE_MEMBERS(6322, "Union can not be dissolved due to multiple members: {0:serverId}, {1:unionId}, {2:viceManager}, {3:eliteMember}, {4:member}")
end