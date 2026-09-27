--
-- UnionBuildingUpgradeRequest.lua
-- Author: zheng.che
-- Date: 2014-03-28 11:57:41
-- 升级建筑请求
--
require "canon.request.BaseRequest"

UnionBuildingUpgradeRequest = class(BaseRequest)

function UnionBuildingUpgradeRequest:ctor()
  self.endpoint = "upgradeUnionBuilding"--<<<<< 1. 修改指令名称 后端提供
end

function UnionBuildingUpgradeRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.UnionBuildingUpgradeSucceed, data))--<<<<< 2. 修改枚举名称 定义在BaseRequest里 不能重复
end

function UnionBuildingUpgradeRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.UnionBuildingUpgradeFailed, {retCode = error}))--<<<<< 2
end

-------------------------------------------------------------------静态函数

function UnionBuildingUpgradeRequest.sendRequest(buildingId, succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
	local function onSucceedHandle(event)
		if succeedCallback then
			succeedCallback(buildingId, event)--<<<<< 3
		end
	end 
	local function onFailedHandle(event)
		if failedCallback then
			failedCallback(event)
		end
	end
	local params = {unionBuildingId = buildingId}--<<<<< 3
	local request = UnionBuildingUpgradeRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.UnionBuildingUpgradeSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.UnionBuildingUpgradeFailed, onFailedHandle)--<<<<< 2
	request:start()

	--succeedCallback(buildingId, {})--测试升级动画 unionUpgradeTest
end

--成功的默认处理
function UnionBuildingUpgradeRequest.onSucceedDefault(buildingId, event)--<<<<< 3
	if SystemManager.debug then
		print("onSucceedDefault! event = " .. table.tostring(event))
	end

	--去掉消耗
	local currentNum = UnionManager.getUnionWealth()
	local needCost = UnionManager.getBuildingUpgradeCost(buildingId)
	UnionManager.setUnionWealth(currentNum - needCost)

	--更新军团等级
	UnionManager.setBuildingLevel(buildingId, event.data.currLevel)

	--通知建筑升级 (显示升级动画用)
	local evt = Event.new(UnionManager.EVENT_BUILDING_LEVELUP)
	evt.buildingId = buildingId
	UnionManager.eventDispatcher:dispatchEvent(evt)
end

--失败默认处理
function UnionBuildingUpgradeRequest.onFailedDefault(event)--<<<<< 4. 修改错误码对应逻辑处理
	--print("onFailedDefault!")
	local errorCode = tonumber(event.data.retCode)
	if(errorCode == 716420) then -- User has no privilige to upgrade union building: {0:uid}, {1:serverId}, {2:unionId}, {3:title}
		CanonMessageBox:showCommErrorBox(CommErrorCodes.HAS_NO_UNION_PRIVILIGE_UPGRAGE_UNION_BUILDING, nil, nil, nil)
	elseif(errorCode == 716353) then -- Union building reach max level: {0:currBuildingLevel}, {1:maxLevel}, {2:serverId}, {3:unionId}
		CanonMessageBox:showCommErrorBox(CommErrorCodes.UNION_BUILDING_REACH_MAX_LEVEL, nil, nil, nil)
	elseif(errorCode == 716357) then -- Union building level is bigger than union level: {0:unionBuildingType}, {1:unionBuildingLevel}, {2:unionLevel}, {3:serverId}, {4:unionId}")
		CanonMessageBox:showCommErrorBox(CommErrorCodes.UNION_BUILDING_LEVEL_BIGGER_THAN_UNION_LEVEL, nil, nil, nil)
	elseif(errorCode == 716338) then -- Union wealth is not enough: {0:serverId}, {1:unionId}, {2:currWealth}, {3:needWealth}
		CanonMessageBox:showCommErrorBox(CommErrorCodes.UNION_WEALTH_NOT_ENOUGH, nil, nil, nil)
	elseif(errorCode == 716313) then
		CanonMessageBox:showCommErrorBox(CommErrorCodes.USER_NOT_JOIN_ANY_UNION, nil, nil, nil)
	elseif(errorCode == 716331) then -- Union is in dissolve status: {0:uid}, {1:unionId}
		CanonMessageBox:showCommErrorBox(CommErrorCodes.UNION_IN_DISSOLVE_STATUS, nil, nil, nil)
	else
		CanonMessageBox:showCommUnHandleErrorBox(errorCode)
	end
-- 	HAS_NO_UNION_PRIVILIGE_UPGRAGE_UNION_BUILDING(6420, "User has no privilige to upgrade union building: {0:uid}, {1:serverId}, {2:unionId}, {3:title}"),
-- UNION_BUILDING_REACH_MAX_LEVEL(6353, "Union building reach max level: {0:currBuildingLevel}, {1:maxLevel}, {2:serverId}, {3:unionId}"),
-- UNION_BUILDING_LEVEL_BIGGER_THAN_UNION_LEVEL(6357, "Union building level is bigger than union level: {0:unionBuildingType}, {1:unionBuildingLevel}, {2:unionLevel}, {3:serverId}, {4:unionId}")
-- UNION_BUILDING_TYPE_UNSUPPORT(6358, "Union building type unsupport: {0:unionBuildingType}"),
-- UNION_WEALTH_NOT_ENOUGH(6338, "Union wealth is not enough: {0:serverId}, {1:unionId}, {2:currWealth}, {3:needWealth}"),
-- UNION_IN_DISSOLVE_STATUS(6331, "Union is in dissolve status: {0:uid}, {1:unionId}"),
end