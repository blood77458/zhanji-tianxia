-- UnionPkMemberApplyRequest.lua
-- 2014-8-19
-- zheng.che
-- 团员报名指定城池

UnionPkMemberApplyRequest = class(BaseRequest)

function UnionPkMemberApplyRequest:ctor()
  self.endpoint = "userApplyUnionCity"--<<<<< 1. 修改指令名称 后端提供
  self.succeedEventName = self.endpoint .. "Succeed"
  self.failedEventName = self.endpoint .. "Failed"
end

function UnionPkMemberApplyRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(self.succeedEventName, data))
end

function UnionPkMemberApplyRequest:onError( error )
  self:dispatchEvent(Event.new(self.failedEventName, {retCode = error}))
end

-------------------------------------------------------------------静态函数

--发送请求 默认处理 成功返回之后可加额外处理(参数可传nil)
function UnionPkMemberApplyRequest.sendRequestDefalut(unionCityId, afterSucceedCallback)--<<<<< 3
	local function onSucceed(evt)
		UnionPkMemberApplyRequest.onSucceedDefault(evt)
		if afterSucceedCallback then
			afterSucceedCallback(evt)
		end
	end
	UnionPkMemberApplyRequest.sendRequest(unionCityId, onSucceed, UnionPkMemberApplyRequest.onFailedDefault)
end

--发送请求
function UnionPkMemberApplyRequest.sendRequest(unionCityId, succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
	local params = {unionCityId = unionCityId}--<<<<< 3

	local function onSucceedHandle(event)
		if succeedCallback then
			event.params = params
			succeedCallback(event)--<<<<< 3
		end
	end 
	local function onFailedHandle(event)
		if failedCallback then
			event.params = params
			failedCallback(event)
		end
	end
	if SystemManager.debug then
		print("params = " .. table.tostring(params))
	end
	local request = UnionPkMemberApplyRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(request.succeedEventName, onSucceedHandle)
	request:addEventListener(request.failedEventName, onFailedHandle)
	request:start()
end

--成功的默认处理
function UnionPkMemberApplyRequest.onSucceedDefault(event)--<<<<< 3
	if SystemManager.debug then
		print("onSucceedDefault! event = " .. table.tostring(event))
	end

	--刷新玩家军团战版本信息
	UnionPkUtils.refreshVersion()
	--设定报名的city编号
	UnionManager.setChallengeCityId(event.params.unionCityId)

	--通知报名成功
	UnionManager.eventDispatcher:dispatchEvent(Event.new(UnionPkConsts.UNIONPK_USER_APPLY_CITY_UPDATE))
end

--失败默认处理
function UnionPkMemberApplyRequest.onFailedDefault(event)--<<<<< 4. 修改错误码对应逻辑处理
	local errorCode = tonumber(event.data.retCode)
	local function onErrorConfirm(errorCode)
		if errorCode == 716635 then
			--当前玩家所在军团是此城池守方 报名时没有任何挑战者
			UnionPkData.setCityErrorTag(event.params.unionCityId, UnionPkConsts.CITY_ERROR_TAG_NO_CHALLENGER)--记录该城池id 防止再次请求
			return
		end
	end
	local ret = ErrorCodeManager.alert(errorCode, onErrorConfirm)
end