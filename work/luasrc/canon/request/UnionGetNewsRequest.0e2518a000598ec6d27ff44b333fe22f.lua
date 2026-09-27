--
-- UnionGetNewsRequest.lua
-- Author: zheng.che
-- Date: 2014-04-03 16:49:53
-- 获得军团动态请求
--
require "canon.request.BaseRequest"

UnionGetNewsRequest = class(BaseRequest)

function UnionGetNewsRequest:ctor()
  self.endpoint = "getUnionNewsList"--<<<<< 1. 修改指令名称 后端提供
end

function UnionGetNewsRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.UnionGetNewsSucceed, data))--<<<<< 2. 修改枚举名称 定义在BaseRequest里 不能重复
end

function UnionGetNewsRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.UnionGetNewsFailed, {retCode = error}))--<<<<< 2
end

-------------------------------------------------------------------静态函数

function UnionGetNewsRequest.sendRequest(succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
	local function onSucceedHandle(event)
		if succeedCallback then
			succeedCallback(event)
		end
	end 
	local function onFailedHandle(event)
		if failedCallback then
			failedCallback(event)
		end
	end
	local params = {}--<<<<< 3
	local request = UnionGetNewsRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.UnionGetNewsSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.UnionGetNewsFailed, onFailedHandle)--<<<<< 2
	request:start()
end

--成功的默认处理
function UnionGetNewsRequest.onSucceedDefault(event)
	--UnionPkTest.testChangeNewsInfo(event.data)--伪造数据

	if SystemManager.debug then
		local temp_sharkUnionNewsWrappers = event.data.sharkUnionNewsWrappers
		event.data.sharkUnionNewsWrappers = {}
		print("onSucceedDefault! event = " .. table.tostring(event))
		event.data.sharkUnionNewsWrappers = temp_sharkUnionNewsWrappers
		if #event.data.sharkUnionNewsWrappers >= 1 then
			print("onSucceedDefault! event.data.sharkUnionNewsWrappers[1] = " .. table.tostring(event.data.sharkUnionNewsWrappers[1]))
			event.data.sharkUnionNewsWrappers = {event.data.sharkUnionNewsWrappers[1]}
		end
	end

	--设置不同列表里每一项的类型
	for i, v in ipairs(event.data.sharkUnionNewsWrappers) do
		v.newsType = UnionManager.NEWS_TYPE_NORMAL
	end
	for i, v in ipairs(event.data.unionWarNewsWrappers) do
		v.newsType = UnionManager.NEWS_TYPE_PK
	end

	--对获得的两个列表进行合并处理
	local totalList = table.union(event.data.unionWarNewsWrappers, event.data.sharkUnionNewsWrappers)


	--设置成员列表
	UnionManager.setNewses(totalList)
end

--失败默认处理
function UnionGetNewsRequest.onFailedDefault(event)--<<<<< 4. 修改错误码对应逻辑处理
	--print("onFailedDefault!")
	local errorCode = tonumber(event.data.retCode)
	if(errorCode == 716313) then -- User has not joined any union: {0:uid}
		CanonMessageBox:showCommErrorBox(CommErrorCodes.USER_NOT_JOIN_ANY_UNION, nil, nil, nil)
	else
		CanonMessageBox:showCommUnHandleErrorBox(errorCode)
	end
	-- USER_NOT_JOIN_ANY_UNION(6313, "User has not joined any union: {0:uid}"),
end