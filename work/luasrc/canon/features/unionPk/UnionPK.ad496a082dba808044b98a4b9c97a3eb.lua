-- UnionPK.lua
-- zheng.che
-- 2014-7-24
-- 军团战

require "canon.features.unionPk.manager.UnionPkConfig"
require "canon.features.unionPk.manager.UnionPkConsts"
require "canon.features.unionPk.manager.UnionPkData"
require "canon.features.unionPk.manager.UnionPkCityData"
require "canon.features.unionPk.manager.UnionPkUtils"
require "canon.features.unionPk.manager.UnionTitleManager"
require "canon.features.unionPk.manager.UnionPkCheck"
require "canon.features.unionPk.manager.UnionPkTest"

require "canon.features.unionPk.scene.UnionPkScene"



require "canon.features.unionPk.panel.UnionPkCityInfoPopPanel"
require "canon.features.unionPk.panel.UnionCitySignUpInfoPopPanel"
require "canon.features.unionPk.panel.UnionBattleReportPopPanel"
require "canon.features.unionPk.panel.UnionPkCityPowerupPopPanel"
require "canon.features.unionPk.panel.UnionPkChangeFormationPopPanel"
require "canon.features.unionPk.panel.UnionPKMyGuildPopPanel"
require "canon.features.unionPk.panel.UnionPKMyRewardPopPanel"
require "canon.features.unionPk.panel.UnionBattleSettlementPopPanel"
require "canon.features.unionPk.panel.UnionBattleSettlementMiniPopPanel"

require "canon.features.unionPk.request.UnionPkGetCityListRequest"
require "canon.features.unionPk.request.UnionPkGetCityInfoRequest"
require "canon.features.unionPk.request.UnionPkSignAttackRequest"
require "canon.features.unionPk.request.UnionPkMemberApplyRequest"
require "canon.features.unionPk.request.UnionPkGetApplyUnionsRequest"
require "canon.features.unionPk.request.UnionPkGetBattleReportRequest"
require "canon.features.unionPk.request.UnionPkGetBattleReportListRequest"
require "canon.features.unionPk.request.UnionPkGetCityFormationRequest"
require "canon.features.unionPk.request.UnionPkPowerupRequest"
require "canon.features.unionPk.request.UnionPKGetMyGuildInfoRequest"
require "canon.features.unionPk.request.UnionPkExchangeUnionFormationRequest"
require "canon.features.unionPk.request.UnionPkGainUnionBattleRewardRequest"
require "canon.features.unionPk.request.UnionPkGetCityMemberListRequest"

UnionPK = {}

-------------------------------------------------
-- 启动
-------------------------------------------------
function UnionPK.startup()
	UnionPkData.startup()
	UnionPkCityData.startup()
	UnionPkConfig.startup()
	UnionTitleManager.startup()
end

-------------------------------------------------
-- 清除
-------------------------------------------------
function UnionPK.clear()
	UnionPkData.clear()
	UnionPkCityData.clear()
	UnionPkConfig.clear()
	UnionTitleManager.clear()

	--清空版本号为无版本
	UnionManager.setUnionWarVersion(0)
end

-------------------------------------------------
-- 对外接口
-------------------------------------------------

-- 军团战是否存在
function UnionPK.enabled()
	if not UnionPkCheck.isInCorrectServer() then
		return false
	end

	return true
end

--首届是否已开启
function UnionPK.pkStarted(withAlert)
	local maintenanceConfig = MaintenanceManager:findActivityConfig(UnionPkConfig.unionWarFeatureName())
	if (not maintenanceConfig) or (not maintenanceConfig.enable) then
		--配置已关闭
		if withAlert then
			local scene = Director:mgr():run()
			SuspensionLabel:showContent(scene, Localization:getInstance():getText("UnionWar_time_begin2"))--军团战暂未开启
		end
		return false
	end

	local currTime = TimeUtil.getServerTimeSeconds()
	local featureRealMainStartTime = UnionPkUtils.findRealUnionPkMainStartTime()
	-- print("currTime = " .. tostringRich(currTime))
	-- print("featureRealMainStartTime = " .. tostringRich(featureRealMainStartTime))

	if currTime < featureRealMainStartTime then
		if withAlert then
			local scene = Director:mgr():run()
			SuspensionLabel:showContent(scene, TimeUtil.formatDate(featureRealMainStartTime, "UnionWar_supple_time8"))--军团战于{month}月{day}日{hour}:{min}开启，敬请期待。
		end
		return false
	end
	return true
end

--当前是否出于军团战期间 (不包括领奖阶段)
function UnionPK.isInUnionPk()
	local currentTimeLevel = UnionPkData.getCurrTimeLevel()

	if currentTimeLevel == UnionPkConsts.TIME_NONE then
		return false
	end
	
	if currentTimeLevel == UnionPkConsts.TIME_REWARD then
		return false
	end

	return true
end

--进入军团战战场
--battleData 战斗流数据
--cityId 对应城池id
--round 第几轮战斗
function UnionPK.gotoBattleField( battleData , cityId, round)
	UnionPkData.setBattleArgv(cityId, round)
	Director:sharedDirector():replaceScene(BattleScene:create(battleData, BattleBackType.kUnionBattle, BattleEnterEnum.kUnionBattle))
end

-------------------------------------------------
-- 跳转
-------------------------------------------------

--进入军团战场景
function UnionPK.gotoUnionPkScene(callback)
	if SystemManager.debug then
		print("UnionPkConfig.getSettingConfig() = " .. tostringRich(UnionPkConfig.getSettingConfig()))
		print("UnionPkConfig.getRewardConfig() = " .. tostringRich(UnionPkConfig.getRewardConfig()))
		print("UnionPkConfig.getTimeConfig() = " .. tostringRich(UnionPkConfig.getTimeConfig()))
		print("UnionPkConfig.unionWarRewardMeta() = " .. tostringRich(UnionPkConfig.unionWarRewardMeta()))
		-- print("UnionPkConfig.silverBuff() = " .. tostringRich(UnionPkConfig.silverBuff()))
		-- print("UnionPkConfig.goldBuff() = " .. tostringRich(UnionPkConfig.goldBuff()))
		print("UnionManager.getMyUnionInfo() = " .. tostringRich(UnionManager.getMyUnionInfo()))
	end

	local function onAfterSucceed(evt)
		local scene = Director:mgr():run()
		local argv = {params = {}}
		if scene.replaceScene then
			scene:replaceScene(UnionPkScene, argv)
			
		else
			Director:sharedDirector():replaceScene(UnionPkScene:create(argv))
			
		end

		if callback then
			callback()
		end
	end
	UnionPkGetCityListRequest.sendRequestDefalut(onAfterSucceed)
end



--从战场返回军团战场景
function UnionPK.battleBackToUnionPkScene(cityId)
	local function onComplete()
		if cityId ~= nil then
			UnionPK.showCityInfoPanel(cityId)
		end
	end
	UnionPK.gotoUnionPkScene(onComplete)
end

--进入军团成员场景 显示城池里报名成员列表
function UnionPK.gotoUnionMemberSceneWithCityMembers(cityId)
	local function onAfterSucceed(evt)
		local targetMemberList = evt.data.sharkUnionMemberWrappers or {}

		if #targetMemberList <= 0 then
			--没有内容 给提示
			CanonMessageBox.showTextBox(getTextByKey("UnionWar_optimize_error1"), onConfirme)--主公，您的军团暂时无人报名本城池
			return
		end

		local targetTabName = Localization:getInstance():getText("UnionWar_optimize_person1")--报名成员
		UnionManager.gotoUnionMemberSceneByTarget(targetTabName, targetMemberList)
	end
	UnionPkGetCityMemberListRequest.sendRequestDefalut(cityId, onAfterSucceed)
end

-------------------------------------------------
-- 显示ui
-------------------------------------------------

--显示城池信息窗口
function UnionPK.showCityInfoPanel(cityId)
	--UnionPkTest.testShowCityInfoPanel(cityId)
	local function onAfterSucceed(evt)
	    --UnionPkTest.testOpenPowerupPanel(evt.data.sharkUnionCity)
	    --UnionPkTest.testOpenModifyFormationPanel(evt.data.sharkUnionCity)
	    --UnionPkTest.testDelayTimeLevel(UnionPkConsts.TIME_SELECT)
	    --UnionPkTest.testShowCityAtDiffrientTime(cityId)

		local scene = Director:mgr():run()
		scene.targetInfoPanel = UnionPkCityInfoPopPanel:create(scene, evt.data)
		PopoutManager:sharedManager():popout(scene.targetInfoPanel, kPopoutDir.kScale, true, false , scene)

	end
	UnionPkGetCityInfoRequest.sendRequestDefalut(cityId, onAfterSucceed)
end

--显示鼓舞窗口
function UnionPK.showCityPowerupPanel(cityData, callback)
	local function onAfterSucceed(evt)
		if not UnionPkCheck.canEnterBattleFieldPanelByTransformData(evt.data, cityData, true) then
			return
		end

		--校验自己是否已经报过并且身处其中
		if UnionPkCityData.isMyChallengCity(cityData) then
			--已经报名此城池
			if not UnionPkCheck.isInFormation(evt.data.unionFormation) then
				--此城池报名玩家里没我
				local function onConfirme()
					--跳转到城池报名界面(城池信息)
					UnionPK.showCityInfoPanel(cityData.cityId)
				end
				--提示
				CanonMessageBox.showTextBox(getTextByKey("UnionWar_optimize_error"), onConfirme)--主公，您报名参战本城池失败，请退出城池界面重新尝试。
				return
			end
		end

		local scene = Director:mgr():run()
		scene.targetInfoPanel = UnionPkCityPowerupPopPanel:create(scene, cityData, evt.data)
	    PopoutManager:sharedManager():popout(scene.targetInfoPanel, kPopoutDir.kScale, true, false , scene)

	    if callback then
	    	callback()
	    end
	end
	UnionPkGetCityFormationRequest.sendRequestDefalut(cityData.cityId, onAfterSucceed)
end

--显示调整阵型窗口
function UnionPK.showChangeFormationPanel(cityData)
	local function onAfterSucceed(evt)
		local scene = Director:mgr():run()
		if not evt.data.unionFormation then
			SuspensionLabel:showContent(scene, Localization:getInstance():getText("UnionWar_error_txt22"))--您的军团没有人报名本城池团战
			return
		end

		scene.targetInfoPanel = UnionPkChangeFormationPopPanel:create(scene, cityData, evt.data)
	    PopoutManager:sharedManager():popout(scene.targetInfoPanel, kPopoutDir.kScale, true, false , scene)
	end
	UnionPkGetCityFormationRequest.sendRequestDefalut(cityData.cityId, onAfterSucceed)
end