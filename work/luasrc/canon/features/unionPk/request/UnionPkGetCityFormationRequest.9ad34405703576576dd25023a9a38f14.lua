-- UnionPkGetCityFormationRequest.lua
-- 2014-8-27
-- zheng.che
-- 获取军团战阵型信息

require "canon.request.BaseRequest"

UnionPkGetCityFormationRequest = class(BaseRequest)

function UnionPkGetCityFormationRequest:ctor()
  self.endpoint = "getUnionFormation"--<<<<< 1. 修改指令名称 后端提供
  self.succeedEventName = self.endpoint .. "Succeed"
  self.failedEventName = self.endpoint .. "Failed"
end

function UnionPkGetCityFormationRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(self.succeedEventName, data))
end

function UnionPkGetCityFormationRequest:onError( error )
  self:dispatchEvent(Event.new(self.failedEventName, {retCode = error}))
end

-------------------------------------------------------------------静态函数

--发送请求 默认处理 成功返回之后可加额外处理(参数可传nil)
function UnionPkGetCityFormationRequest.sendRequestDefalut(unionCityId, afterSucceedCallback)--<<<<< 3
	local function onSucceed(evt)
		UnionPkGetCityFormationRequest.onSucceedDefault(evt)
		if afterSucceedCallback then
			afterSucceedCallback(evt)
		end
	end
	UnionPkGetCityFormationRequest.sendRequest(unionCityId, onSucceed, UnionPkGetCityFormationRequest.onFailedDefault)
end

--发送请求
function UnionPkGetCityFormationRequest.sendRequest(unionCityId, succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
	local params = {unionCityId = unionCityId}--<<<<< 3

	local function onSucceedHandle(event)
		if succeedCallback then
			event.params = params
			succeedCallback(event)
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
	local request = UnionPkGetCityFormationRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(request.succeedEventName, onSucceedHandle)
	request:addEventListener(request.failedEventName, onFailedHandle)
	request:start()

-- 	--假数据 (格式变了 2014-10-9)
-- 	local uidCount = 1
-- 	local function testCreateFormationData()
-- 		local forwardInfo = {}
-- 		forwardInfo.uid = uidCount
-- 		forwardInfo.userName = "假人" .. uidCount
-- 		forwardInfo.mainCardMeataId = uidCount*10 + 101001

-- 		uidCount = uidCount + 1

-- 		return forwardInfo
-- 	end
-- 	local testData = {}
-- 	testData.sharkUnionCityApply = {
-- 	{unionId=206, unionName="防守军团", wealth=100},
-- 	{unionId=2, unionName="进攻军团1", wealth=100},
-- 	{unionId=3, unionName="进攻军团2", wealth=100}
-- }
-- 	testData.winnerUnionIds = {2}
-- 	testData.unionFormation = {}
-- 	testData.unionFormation.forwardInfo = testCreateFormationData()
-- 	testData.unionFormation.formationHeadInfo = {testCreateFormationData(), testCreateFormationData(), testCreateFormationData()}
-- 	testData.unionFormation.formationMiddleInfo = {testCreateFormationData(), testCreateFormationData()}
-- 	testData.unionFormation.formationTailInfo = {testCreateFormationData()}

-- 	onSucceedHandle({data = testData})
end

--成功的默认处理
function UnionPkGetCityFormationRequest.onSucceedDefault(event)--<<<<< 3
	if SystemManager.debug then
		print("onSucceedDefault! event = " .. table.tostring(event))
		DebugManager.assert(event.data.sharkUnionCityApply[1] ~= nil, "此城池必防守方信息为空, 至少要一个空白军团! cityId = " .. tostringRich(event.params.unionCityId))
	end

end

--失败默认处理
function UnionPkGetCityFormationRequest.onFailedDefault(event)--<<<<< 4. 修改错误码对应逻辑处理
	local errorCode = tonumber(event.data.retCode)
	local function onErrorConfirm(errorCode)
		if errorCode == 716613 then
			--阵型信息不存在
			UnionPkData.setCityErrorTag(event.params.unionCityId, UnionPkConsts.CITY_ERROR_TAG_NO_FORMATION)--记录该城池id 防止再次请求
			return
		end
	end
	local ret = ErrorCodeManager.alert(errorCode, onErrorConfirm)
end