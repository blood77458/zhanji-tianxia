--
-- UnionChangeDeclarationRequest.lua
-- Author: zheng.che
-- Date: 2014-03-28 18:36:19
-- 换宣言请求
--
require "canon.request.BaseRequest"

UnionChangeDeclarationRequest = class(BaseRequest)

function UnionChangeDeclarationRequest:ctor()
  self.endpoint = "modifyUnionDeclaration"--<<<<< 1. 修改指令名称 后端提供
end

function UnionChangeDeclarationRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.UnionChangeDeclarationSucceed, data))--<<<<< 2. 修改枚举名称 定义在BaseRequest里 不能重复
end

function UnionChangeDeclarationRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.UnionChangeDeclarationFailed, {retCode = error}))--<<<<< 2
end

-------------------------------------------------------------------静态函数

-- unionId 目标军团id
function UnionChangeDeclarationRequest.sendRequest(declarationMsg, succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
	local function onSucceedHandle(event)
		if succeedCallback then
			succeedCallback(declarationMsg, event)--<<<<< 3
		end
	end 
	local function onFailedHandle(event)
		if failedCallback then
			failedCallback(event)
		end
	end
	local params = {declaration = declarationMsg}--<<<<< 3
	local request = UnionChangeDeclarationRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.UnionChangeDeclarationSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.UnionChangeDeclarationFailed, onFailedHandle)--<<<<< 2
	request:start()
end

--成功的默认处理
function UnionChangeDeclarationRequest.onSucceedDefault(declarationMsg, event)--<<<<< 3
	--print("onSucceedDefault! event = " .. table.tostring(event))
	
	UnionManager.setUnionDeclaration(declarationMsg)
end

--失败默认处理
function UnionChangeDeclarationRequest.onFailedDefault(event)--<<<<< 4. 修改错误码对应逻辑处理
	--print("onFailedDefault!")
	local errorCode = tonumber(event.data.retCode)
	if(errorCode == 716313) then -- User has not joined any union: {0:uid}
		CanonMessageBox:showCommErrorBox(CommErrorCodes.USER_NOT_JOIN_ANY_UNION, nil, nil, nil)
	elseif(errorCode == 716416) then -- User has no privilige to modify declaration: {0:uid}, {1:serverId}, {2:unionId}, {3:title}
		CanonMessageBox:showCommErrorBox(CommErrorCodes.HAS_NO_UNION_PRIVILIGE_MODIFY_DECLARATION, nil, nil, nil)
	elseif(errorCode == 716334) then -- Union declaration is empty: {0:declaration}
		CanonMessageBox:showCommErrorBox(CommErrorCodes.UNION_DECLARATION_IS_EMPTY, nil, nil, nil)
	elseif(errorCode == 716333) then -- Union declaration contains sensitive word: {0:declaration}
		CanonMessageBox:showCommErrorBox(CommErrorCodes.UNION_DECLARATION_CONTAINS_SENSITIVE_WROD, nil, nil, nil)
	elseif(errorCode == 716332) then -- Union declaration is too long: {0:declaration}
		CanonMessageBox:showCommErrorBox(CommErrorCodes.UNION_DECLARATION_TOO_LONG, nil, nil, nil)
	elseif(errorCode == 716340) then -- 包含特殊字符
		CanonMessageBox:showCommErrorBox(CommErrorCodes.STR_HAS_WROWN_WORD, nil, nil, nil)
	else
		CanonMessageBox:showCommUnHandleErrorBox(errorCode)
	end
-- 	USER_NOT_JOIN_ANY_UNION(6313, "User has not joined any union: {0:uid}"),
-- HAS_NO_UNION_PRIVILIGE_MODIFY_DECLARATION(6416, "User has no privilige to modify declaration: {0:uid}, {1:serverId}, {2:unionId}, {3:title}"),
-- UNION_DECLARATION_IS_EMPTY(6334, "Union declaration is empty: {0:declaration}"),
-- UNION_DECLARATION_CONTAINS_SENSITIVE_WROD(6333, "Union declaration contains sensitive word: {0:declaration}"),
-- UNION_DECLARATION_TOO_LONG(6332, "Union declaration is too long: {0:declaration}"),
end