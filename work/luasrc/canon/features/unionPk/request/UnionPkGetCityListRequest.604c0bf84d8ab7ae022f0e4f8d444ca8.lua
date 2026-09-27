-- UnionPkGetCityListRequest.lua
-- 2014-8-11
-- zheng.che
-- 军团战 获得城池列表

require "canon.request.BaseRequest"

UnionPkGetCityListRequest = class(BaseRequest)

function UnionPkGetCityListRequest:ctor()
  self.endpoint = "getUnionCityList"--<<<<< 1. 修改指令名称 后端提供
  self.succeedEventName = self.endpoint .. "Succeed"
  self.failedEventName = self.endpoint .. "Failed"
end

function UnionPkGetCityListRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(self.succeedEventName, data))
end

function UnionPkGetCityListRequest:onError( error )
  self:dispatchEvent(Event.new(self.failedEventName, {retCode = error}))
end

-------------------------------------------------------------------静态函数

--发送请求 默认处理 成功返回之后可加额外处理(参数可传nil)
function UnionPkGetCityListRequest.sendRequestDefalut(afterSucceedCallback)--<<<<< 3
	local function onSucceed(evt)
		UnionPkGetCityListRequest.onSucceedDefault(evt)
		if afterSucceedCallback then
			afterSucceedCallback(evt)
		end
	end
	UnionPkGetCityListRequest.sendRequest(onSucceed, UnionPkGetCityListRequest.onFailedDefault)
end

--发送请求
function UnionPkGetCityListRequest.sendRequest(succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
	local params = {}--<<<<< 3

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
	local request = UnionPkGetCityListRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(request.succeedEventName, onSucceedHandle)
	request:addEventListener(request.failedEventName, onFailedHandle)
	request:start()
end

--成功的默认处理
function UnionPkGetCityListRequest.onSucceedDefault(event)--<<<<< 3
	if SystemManager.debug then
		print("onSucceedDefault! event = " .. table.tostring(event))
	end

	--将已占领成环伺列表 转换为哈希表
	local hash = {}
	for k, v in ipairs(event.data.ownCityIds) do
		hash[v] = true
	end

	UnionPkData.setSmallCityNum(event.data.smallCityNum)
	UnionPkData.setRoundWealth(event.data.roundWealth)
	UnionPkData.setDefenceCityIdsHase(hash)
	UnionPkData.setHistoryTitle(event.data.userTitle)
	UnionPkData.setSignedCity(event.data.challengeCityIds)
	UnionPkData.setFightingCityIds(event.data.fightingCityIds)
	UnionPkData.setUnionWinNumList(event.data.unionWinNum)
	UnionPkData.setAttendBattleNum(event.data.attendBattleNum)
	--通知更新
	UnionPkData.updateForCityList()
end

--失败默认处理
function UnionPkGetCityListRequest.onFailedDefault(event)--<<<<< 4. 修改错误码对应逻辑处理
	local errorCode = tonumber(event.data.retCode)
	local function onErrorConfirm(errorCode)
	end
	local ret = ErrorCodeManager.alert(errorCode, onErrorConfirm)
end