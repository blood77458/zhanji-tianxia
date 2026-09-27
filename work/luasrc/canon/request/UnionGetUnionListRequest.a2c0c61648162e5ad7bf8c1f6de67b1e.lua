--
-- UnionGetUnionListRequest.lua
-- Author: zheng.che
-- Date: 2014-03-17 11:22:44
-- 查询军团列表请求
--
require "canon.request.BaseRequest"

UnionGetUnionListRequest = class(BaseRequest)

function UnionGetUnionListRequest:ctor()
  self.endpoint = "getUnionList"
end

function UnionGetUnionListRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.UnionGetUnionListSucceed, data))
end

function UnionGetUnionListRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.UnionGetUnionListFailed, {retCode = error}))
end

-------------------------------------------------------------------静态函数

-- startNum int 工会排名起始值
-- amount int 工会数量
function UnionGetUnionListRequest.sendRequest(startNum, amount, succeedCallback, failedCallback)
	local function onSucceedHandle(event)
		if succeedCallback then
			succeedCallback(startNum, amount, event)--和默认不一样
		end
	end 
	local function onFailedHandle(event)
		if failedCallback then
			failedCallback(event)
		end
	end
	local params = {startNum = startNum, amount = amount}
	--print("请求军团列表! params = " .. table.tostring(params))
	local request = UnionGetUnionListRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.UnionGetUnionListSucceed, onSucceedHandle)
	request:addEventListener(RequestNotifyEnum.UnionGetUnionListFailed, onFailedHandle)
	request:start()
end

--成功的默认处理
function UnionGetUnionListRequest.onSucceedDefault(startNum, amount, event)
	--print("onSucceedDefault! event = " .. table.tostring(event))
	--消耗资源
end

--失败默认处理
function UnionGetUnionListRequest.onFailedDefault(event)
	--print("onFailedDefault!")
	--无错误码 数据有可能为空
	local errorCode = tonumber(event.data.retCode)
	CanonMessageBox:showCommUnHandleErrorBox(errorCode)

end