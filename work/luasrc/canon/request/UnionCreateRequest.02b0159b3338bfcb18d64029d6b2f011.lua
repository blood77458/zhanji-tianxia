--
-- UnionCreateRequest.lua
-- Author: zheng.che
-- Date: 2014-03-13 16:54:47
-- 创建军团请求
--
require "canon.request.BaseRequest"

UnionCreateRequest = class(BaseRequest)

function UnionCreateRequest:ctor()
  self.endpoint = "createUnion"
end

function UnionCreateRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.UnionCreateSucceed, data))
end

function UnionCreateRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.UnionCreateFailed, {retCode = error}))
end

-------------------------------------------------------------------静态函数

-- costType int 消耗资源类型编号
-- unionName string 军团名称
function UnionCreateRequest.sendRequest(costType, unionName, succeedCallback, failedCallback)
	local function onSucceedHandle(event)
		if succeedCallback then
			succeedCallback(costType, unionName, event)--和默认不一样
		end
	end 
	local function onFailedHandle(event)
		if failedCallback then
			failedCallback(event)
		end
	end

	local defaultNotice = Localization:getInstance():getText("union_notice_innit")--欢迎大家来到战姬天下！
	local defaultDeclaration = Localization:getInstance():getText("union_notice_declaration")--欢迎大家来到战姬天下！

	local params = {coinType = costType, unionName = unionName, declaration = defaultDeclaration, notice = defaultNotice}
	--print("params = " .. table.tostring(params))
	local request = UnionCreateRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.UnionCreateSucceed, onSucceedHandle)
	request:addEventListener(RequestNotifyEnum.UnionCreateFailed, onFailedHandle)
	request:start()
end

--成功的默认处理
function UnionCreateRequest.onSucceedDefault(costType, unionName, event)
	--print("onSucceedDefault! event = " .. table.tostring(event))

	--扣除金币 or 银币
	local needNum = UnionManager.getCreateCostNum(costType)
	RewardManager:getReward({{itemType = costType, amount = (-needNum or 0)}})

	--更新军团信息
	UnionManager.setUnionData(event.data.sharkUnion)

	--跳转
	UnionManager.gotoUnionScene()
  
  ChatManager.sendChat({method = MethodDict.JOINUNION, uid = DataManager.getCurrUser().uid, unionId = event.data.sharkUnion.unionId})
end

--失败默认处理
function UnionCreateRequest.onFailedDefault(event)
	--print("onFailedDefault!")
	local errorCode = tonumber(event.data.retCode)
	if(errorCode == 716300) then -- User has already joined a union: {0:uid}
		CanonMessageBox:showCommErrorBox(CommErrorCodes.USER_JOINED_UNION, nil, nil, nil)
	elseif(errorCode == 716301) then -- User is in union cold time: {0:uid}
		CanonMessageBox:showCommErrorBox(CommErrorCodes.USER_IN_UNION_COLD, nil, nil, nil)
	elseif(errorCode == 716302) then -- User level is not fit union: {0:uid}, {1:userLevel}
		CanonMessageBox:showCommErrorBox(CommErrorCodes.USER_LEVEL_NOT_FIT_UNION, {num = UnionManager.unionMinLevel()}, nil, nil)
	elseif(errorCode == 710512) then -- Coin is not enough: {0:uid}, {1:currCoin}, {2:needCoin}
		local aPanel = MessageBoxPanel:create(Director:mgr():run(), MessageBoxType.kCoinLimit)
		Director:mgr():run():addChild(aPanel)
		aPanel:scaleIn()
	elseif(errorCode == 710513) then -- Gold is not enough: {0:uid}, {1:currGold}, {2:needGold}
		local aPanel = MessageBoxPanel:create(Director:mgr():run(), MessageBoxType.kGemLimit)
		Director:mgr():run():addChild(aPanel)
		aPanel:scaleIn()
	elseif(errorCode == 716304) then -- Union name is null
		CanonMessageBox:showCommErrorBox(CommErrorCodes.UNION_NAME_IS_NULL, nil, nil, nil)
	elseif(errorCode == 716305) then -- Union name contain nusupport char: {0:nickName}
		CanonMessageBox:showCommErrorBox(CommErrorCodes.UNION_NAME_IS_INVALID, nil, nil, nil)
	elseif(errorCode == 716306) then -- 
		CanonMessageBox:showCommErrorBox(CommErrorCodes.UNION_NAME_IS_TOOSHORT, nil, nil, nil)
	elseif(errorCode == 716307) then -- Union name is too long: {0:nickName}
		CanonMessageBox:showCommErrorBox(CommErrorCodes.UNION_NAME_IS_TOOLONG, nil, nil, nil)
	elseif(errorCode == 716309) then -- Union name contains sensitive word: {0:nickname}
		CanonMessageBox:showCommErrorBox(CommErrorCodes.UNION_NAME_CONTIAN_SENSITIVE_WORD, nil, nil, nil)
	elseif(errorCode == 716308) then -- Union name is exist: {0:nickName}
		CanonMessageBox:showCommErrorBox(CommErrorCodes.UNION_NAME_IS_EXIST, nil, nil, nil)
	else
		CanonMessageBox:showCommUnHandleErrorBox(errorCode)
	end
-- 	USER_JOINED_UNION(6300, "User has already joined a union: {0:uid}")
-- USER_IN_UNION_COLD(6301, "User is in union cold time: {0:uid}")
-- USER_LEVEL_NOT_FIT_UNION(6302, "User level is not fit union: {0:uid}, {1:userLevel}")
-- UNION_CREATE_COINTYPE_UNSUPPORT(6303, "Coin type of create union is not support: {0:uid}, {1:coinType}"),
-- REQUISITE_COIN_NOT_ENOUGH(512, "Coin is not enough: {0:uid}, {1:currCoin}, {2:needCoin}")
-- REQUISITE_GEM_NOT_ENOUGH(513, "Gold is not enough: {0:uid}, {1:currGold}, {2:needGold}")
-- UNION_NAME_IS_NULL(6304, "Union name is null"),
-- UNION_NAME_IS_INVALID(6305, "Union name contain nusupport char: {0:nickName}")
-- UNION_NAME_IS_TOOSHORT(6306, "Union name is too short: {0:nickName}")
-- UNION_NAME_IS_TOOLONG(6307, "Union name is too long: {0:nickName}")
-- UNION_NAME_CONTIAN_SENSITIVE_WORD(6309, "Union name contains sensitive word: {0:nickname}")
-- UNION_NAME_IS_EXIST(6308, "Union name is exist: {0:nickName}")
end