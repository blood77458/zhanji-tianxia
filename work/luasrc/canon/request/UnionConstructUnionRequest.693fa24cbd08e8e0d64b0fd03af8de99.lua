--
-- UnionConstructUnionRequest.lua
-- Author: silian.xiang
-- Date: 2014-03-28 11:57:41
-- 建设
--
require "canon.request.BaseRequest"

UnionConstructUnionRequest = class(BaseRequest)

function UnionConstructUnionRequest:ctor()
  self.endpoint = "constructUnion"
end

function UnionConstructUnionRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.UnionConstructUnionSucceed, data))
end

function UnionConstructUnionRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.UnionConstructUnionFailed, {retCode = error}))
end

-------------------------------------------------------------------静态函数

function UnionConstructUnionRequest.sendRequest(constructType, succeedCallback, failedCallback)
	local function onSucceedHandle(event)
		if succeedCallback then
			succeedCallback(constructType, event)--<<<<< 3
		end
	end 
	local function onFailedHandle(event)
		if failedCallback then
			failedCallback(event)
		end
	end
	
	local params = {constructType = constructType}
	local request = UnionConstructUnionRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.UnionConstructUnionSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.UnionConstructUnionFailed, onFailedHandle)--<<<<< 2
	request:start()
end

--成功的默认处理
function UnionConstructUnionRequest.onSucceedDefault(constructType, event)--<<<<< 3
	--print("onSucceedDefault! event = " .. table.tostring(event))

	--扣除金币 or 银币
	local needNum = UnionManager.getBuildCostNum(constructType)
	local isGem = UnionManager.isGemBuild(constructType)
	local costType
	if isGem then
		costType = ResourceEnum.GEMS
	else
		costType = ResourceEnum.COIN
	end
	RewardManager:getReward({{itemType = costType, amount = (-needNum or 0)}})

	--今日建设总次数+1
	UnionManager.addTodayBuildTotalTimes()
end

--失败默认处理
function UnionConstructUnionRequest.onFailedDefault(event)
	local errorCode = tonumber(event.data.retCode)
	if errorCode == SHARK_ERROCODE_ORIGH + 6359 then
		CanonMessageBox:showCommErrorBox(CommErrorCodes.UNION_DECLARATION_IS_EMPTY, nil, nil, nil)
	elseif errorCode == SHARK_ERROCODE_ORIGH + 513 then
		local aPanel = MessageBoxPanel:create(Director:mgr():run(), MessageBoxType.kGemLimit)
		Director:mgr():run():addChild(aPanel)
		aPanel:scaleIn()
	elseif errorCode == SHARK_ERROCODE_ORIGH + 512 then
		local aPanel = MessageBoxPanel:create(Director:mgr():run(), MessageBoxType.kCoinLimit)
		Director:mgr():run():addChild(aPanel)
		aPanel:scaleIn()
	elseif errorCode == SHARK_ERROCODE_ORIGH + 6374 then
		local maxTimes = UnionManager.DonatMaxTimes()
		SuspensionLabel:showContent(Director:mgr():run(), Localization:getInstance():getText("union_build_today_max_remind", {num = maxTimes}))--军团每天最多只能建设{num}次

		--此情况触发应导致次数更新到已满
		UnionManager.setTodayBuildTotalTimes(TimeUtil.getServerTimeSeconds(), maxTimes)
	else
		CanonMessageBox:showCommUnHandleErrorBox(errorCode)
	end
	--UNION_BUILDING_HALL_CONSTRUCT_REACH_UPPER(6374, "Union building hall construct times reach upper: {0:uid}, {1:currConstructTimes}, {2:maxConstructTimes}"),
end