-- UnionPkCityData.lua
-- 2014-7-28
-- zheng.che
-- 城池信息

UnionPkCityData = {}

-- <bean desc="城池信息">
-- 	<property code="cityId" type="int" desc="城池id" />
-- 	<property code="unionId" type="int" desc="占领的军团id，没有时为0" />
-- 	<property code="unionName" type="String" desc="军团名称" />
-- 	<property code="occupyNum" type="int" desc="当前占领的军团连续占领次数" />
-- 	<property code="userPosition" type="int" desc="当前uid的军团职位" />
-- 	<property code="report" type="boolean" desc="当前uid的军团是否报名该城池" />
-- 	<property code="successfulBid" type="boolean" desc="当前uid的军团是否竞标成功该城池" />
-- 	<property code="challengeCityNum" type="int" desc="玩家所在军团的挑战城池数" />
-- 	<property code="ownCityNum" type="int" desc="玩家所在军团的占领军团数" />
-- 	<property code="applyNum" type="int" desc="报名该城池的军团数量" />
-- unionLevel 军团等级
-- </bean>

-------------------------------------------------
-- 操作
-------------------------------------------------
function UnionPkCityData.startup()
	
end
function UnionPkCityData.clear()
end

-------------------------------------------------
-- check
-------------------------------------------------

--是否有军团防守
function UnionPkCityData.haveCaptureUnion(cityData)
	local unionId = cityData.unionId
	if unionId == 0 then
		--防守军团不存在
		return false
	end
	return true
end

-------------------------------------------------
-- other
-------------------------------------------------

--获得军团显示名称
function UnionPkCityData.getCaptureUnionShowName(cityData)
	if UnionPkCityData.haveCaptureUnion(cityData) then
		return cityData.unionName
	end
	return Localization:getInstance():getText("UnionWar_sign_none")--无
end

--自己军团是否某城池的防守方
function UnionPkCityData.myUnionIsDefencer(cityData)
	-- local myUnionId = UnionManager.getMyUnionId()

	-- if UnionManager.isInUnion() then
	-- 	--不在军团里
	-- 	return false
	-- end

	-- if myUnionId ~= cityData.cityId then
	-- 	--id不匹配
	-- 	return false
	-- end

	-- return true

	--改用城池列表信息里的防守信息分辨
	return UnionPkData.cityIsInMyDefence(cityData.cityId)
end

--查询当前玩家是否已报名加入此城池对战
function UnionPkCityData.isMyChallengCity(cityData)
	return UnionPkCityData.isMyChallengCityById(cityData.cityId)
end

--查询当前玩家是否已报名加入此城池对战
function UnionPkCityData.isMyChallengCityById(cityId)
	if cityId ~= UnionManager.getChallengeCityId() then
		return false
	end
	return true
end