-- CrossUnionPk.lua
-- geng.men
-- 2015-4-14
-- 跨服GVG

--manager
-- require "canon.manager.UnionManager"
require "canon.features.crossUnionPk.manager.CrossUnionPkCheck"
require "canon.features.crossUnionPk.manager.CrossUnionPkConfig"
require "canon.features.crossUnionPk.manager.CrossUnionPkConsts"
require "canon.features.crossUnionPk.manager.CrossUnionPkData"
require "canon.features.crossUnionPk.manager.CrossUnionPkTest"
require "canon.features.crossUnionPk.manager.CrossUnionPkUtils"
require "canon.features.crossUnionPk.manager.CrossUnionPkTimeLevel"
--CrossUnionPkTimeLevel
--request
require "canon.features.crossUnionPk.request.GetCrossGvgInfoRequest"
require "canon.features.crossUnionPk.request.CrossUnionPkGetKnockoutInfoRequest"
require "canon.features.crossUnionPk.request.CrossUnionPkGetBattleReportRequest"
require "canon.features.crossUnionPk.request.ExchangeGvgFormationRequest"
require "canon.features.crossUnionPk.request.InspireCrossGvgRequest"
require "canon.features.crossUnionPk.request.CrossUnionPkGetGroupReportsRequest"
require "canon.features.crossUnionPk.request.UploadCrossGvgTeamMirrorRequest"
require "canon.features.crossUnionPk.request.CrossUnionPkCheckFiredStatueRequest"

require "canon.features.crossUnionPk.request.CrossUnionPkGetApplyRequest"
require "canon.features.crossUnionPk.request.CrossUnionPkGetBlessRequest"
require "canon.features.crossUnionPk.request.CrossUnionPkGetBlessInFoRequest"
require "canon.features.crossUnionPk.request.CrossUnionPkGetKnockoutReward"
require "canon.features.crossUnionPk.request.CrossUnionPkGetCrossGvgInfoBaseRequest"
require "canon.features.crossUnionPk.request.CrossUnionPkGetGroupRankScoreRequest"
require "canon.features.crossUnionPk.request.CrossUnionPkGroupBattleRequest"
require "canon.features.crossUnionPk.request.CrossUnionPkcrossGvgCanMindApplyRequest"
require "canon.features.crossUnionPk.request.GetCrossGvgGroupInfoRequest"

--CrossUnionPkGetCrossGvgInfoBaseRequest
--scene
require "canon.features.crossUnionPk.scene.CrossUnionPKTeamAdjustScene"
require "canon.features.crossUnionPk.scene.CrossUnionPkKnockoutScene"
require "canon.features.crossUnionPk.scene.CrossUnionPKLoginScene"
require "canon.features.crossUnionPk.scene.CrossUnionPkMemberSelectScene"
require "canon.features.crossUnionPk.scene.CrossUnionPKBlessingScene"

--panel
require "canon.features.crossUnionPk.panel.CrossUnionPkGroupReportsPanel"
require "canon.features.crossUnionPk.panel.CrossUnionPkUpdatePanel"
require "canon.features.crossUnionPk.panel.CrossUnionPkGroupRankPanel"
require "canon.features.crossUnionPk.panel.CrossUnionPkBattleResultPanel"
require "canon.features.crossUnionPk.panel.CrossUnionPkServerPanel"


CrossUnionPk = {}

-------------------------------------------------
-- 启动
-------------------------------------------------
function CrossUnionPk.startup()
	CrossUnionPkData.startup()
end

-------------------------------------------------
-- 清除
-------------------------------------------------
function CrossUnionPk.clear()
	CrossUnionPkData.clear()
end

-------------------------------------------------
-- 对外接口
-------------------------------------------------

-- 跨服军团战是否存在
function CrossUnionPk.enabled()
	if not CrossUnionPkCheck.isInCorrectServer() then
		return false
	end

	return true
end

-------------------------------------------------
-- 跳转
-------------------------------------------------

-- 进入淘汰赛场景
-- withCheck 需要检查时间段是否正确 (比如战斗结束后返回此场景但时间已过)
function CrossUnionPk.gotoKnockoutScene(withCheck)
	if withCheck then
		--校验时间段是否合法
		if not CrossUnionPkCheck.canEnterKouckoutScene() then
			--禁止进入淘汰赛场景 那么 改为进入gvg主场景
			CrossUnionPk.gotoCrossLoginUnionPkScene()
			return
		end
	end

	local function onAfterSuccessed(evt)
		local scene = Director:mgr():run()
		if scene.replaceScene then
			scene:replaceScene(CrossUnionPkKnockoutScene, evt.data)
		else
			Director:sharedDirector():replaceScene(CrossUnionPkKnockoutScene:create(evt.data))
		end
	end
	CrossUnionPkGetKnockoutInfoRequest.sendRequestDefalut(onAfterSuccessed)
end

function CrossUnionPk.gotoCrossLoginUnionPkScene()
	-- local function onAfterSuccessed(evt)
	-- 	local scene = Director:mgr():run()
	-- 	scene:replaceScene(CrossUnionPKLoginScene, evt.data)
	-- end 

	local argv = {}
	argv = {enterScene="UnionScene",returnScene="UnionScene",params={}}
	local scene = Director:mgr():run()
	local TimeLevel = CrossUnionPkUtils.findCurrentTimeLevel()
	-- print("~~~~~~~~~~~~~~~CrossUnionPkConfig.getGVGRewardMetas() = "..tostringRich(CrossUnionPkConfig.getGVGRewardMetas()))
	-- print("~~~~~~~~~~~~~~~~TimeLevel = "..tostringRich(TimeLevel))
	local serverId = DataManager.getServerid()
	local uid = DataManager.getGameInitData().sharkUser.uid
	local level = DataManager.getGameInitData().sharkUser.level
	local time  = TimeUtil.getServerTimeSeconds()
	local des = "WGVG"
	 if TimeLevel == CrossUnionPkConsts.TIME_WORSHIP then
	 	DcManager.sendDCActionInfo(serverId,uid,level,time,des,"zhufu")
	-- 	print("祝福天师，啦啦")
		local function SucceedResponse(evt)
	    --获取祝福帝王的个人信息
	    
	        argv.data = evt.data

	        -- print("~~~~~~~~~~~~~~evt.data = "..tostringRich(evt.data))
		    if scene.replaceScene then
			    scene:replaceScene(CrossUnionPKBlessingScene,argv)
			else
				Director:sharedDirector():replaceScene(CrossUnionPKBlessingScene:create(argv))
			end
	    end
		CrossUnionPkGetBlessInFoRequest.sendRequestDefalut(SucceedResponse)
	
	else
		DcManager.sendDCActionInfo(serverId,uid,level,time,des,"jinrujuntuanzhan")
		local function SucceedResponse(evt)
			argv.data = evt.data
			UnionManager.setGainCrossUnionWarInunionApplyCrossGvg(evt.data.unionApplyCrossGvg)
			UnionManager.setGainCrossUnionWarInselfApplyCrossGvg(evt.data.selfApplyCrossGvg)
			UnionManager.setGainCrossUnionWarIncrossGvgVersion(evt.data.crossGvgVersion)
			UnionManager.setGainCrossUnionWarInselfQuitCrossGvg(evt.data.selfQuitCrossGvg)
			if scene.replaceScene then
			    scene:replaceScene(CrossUnionPKLoginScene,argv)
			else
				Director:sharedDirector():replaceScene(CrossUnionPKLoginScene:create(argv))
			end
		end
		CrossUnionPkGetCrossGvgInfoBaseRequest.sendRequestDefalut(SucceedResponse)
	
	end
	
end

function CrossUnionPk.gotoTeamAdjustScene(withCheck)
	if withCheck then
		--校验时间段是否合法
		if not CrossUnionPkCheck.canEnterTeamAdjustScene() then
			--禁止进入小组赛场景 那么 改为进入gvg主场景
			CrossUnionPk.gotoCrossLoginUnionPkScene()
			return
		end
	end
	local function onAfterSuccessed(evt)
		local scene = Director:mgr():run()
		if scene.replaceScene then
			scene:replaceScene(CrossUnionPKTeamAdjustScene)
		else
			Director:sharedDirector():replaceScene(CrossUnionPKTeamAdjustScene:create())
		end
	end
	GetCrossGvgInfoRequest.sendRequestDefalut(onAfterSuccessed)
end

function CrossUnionPk.gotoMemberSelectScene()
	local scene = Director:mgr():run()
	scene:replaceScene(CrossUnionPkMemberSelectScene)
end

--进战场接口
function CrossUnionPk.gotoBattleField( battleData, battleSubType , params)
	CrossUnionPkData.setBattleSubType(battleSubType)
	Director:sharedDirector():replaceScene(BattleScene:create(battleData, params.BattleBackType, params.BattleEnterEnum))
end

-------------------------------------------------
-- 弹窗
-------------------------------------------------

--弹出小组赛战报窗口
function CrossUnionPk.popGroupReport()
	local function onAfterSucceed(evt)
		local scene = Director:mgr():run()
		scene.targetInfoPanel = CrossUnionPkGroupReportsPanel:create(evt.data)
	    PopoutManager:sharedManager():popout(scene.targetInfoPanel, kPopoutDir.kScale, true, false , scene)
	end
	CrossUnionPkGetGroupReportsRequest.sendRequestDefalut(onAfterSucceed)
end

--弹出小组赛排名窗口
function CrossUnionPk.popGroupRankPanel()
	local function onAfterSucceed(evt)
		local scene = Director:mgr():run()
		scene.targetInfoPanel = CrossUnionPkGroupRankPanel:create(evt.data)
	    PopoutManager:sharedManager():popout(scene.targetInfoPanel, kPopoutDir.kScale, true, false , scene)
	end
	CrossUnionPkGetGroupRankScoreRequest.sendRequestDefalut(onAfterSucceed)
end

-- 弹出战斗结算面板
-- battleType 战斗类型 详见CrossUnionPkConsts
-- battleData 战斗数据
-- currentPoint 变换的积分数量
-- changePoint 当前积分
function CrossUnionPk.popBattleResultPanel(battleType, battleData, currentPoint, changePoint)
	local scene = Director:mgr():run()
	scene.targetInfoPanel = CrossUnionPkBattleResultPanel:create(battleType, battleData, currentPoint, changePoint)
	PopoutManager:sharedManager():popout(scene.targetInfoPanel, kPopoutDir.kScale, true, false , scene)
end

--弹出服务器分组面板
function CrossUnionPk.popServerInfoPanel()
	local function onAfterSucceed(evt)
		local scene = Director:mgr():run()
		scene.targetInfoPanel = CrossUnionPkServerPanel:create(evt.data)
	    PopoutManager:sharedManager():popout(scene.targetInfoPanel, kPopoutDir.kScale, true, false , scene)
	end
	GetCrossGvgGroupInfoRequest.sendRequestDefalut(nil ,onAfterSucceed)
end

-------------------------------------------------
-- 查询
-------------------------------------------------

--是否有呼吸灯
function CrossUnionPk.ResetLight()
 local TimeLevel = CrossUnionPkUtils.findCurrentTimeLevel()
  -- print("~~~~~~~~~~~~~~~~~~~~~~TimeLevel = "..TimeLevel)
  local IDentity = UnionManager.getMyTitle() --这个是判断职务
  CrossUnionPkCheck.canManagerLight(IDentity,TimeLevel)
end


--首届是否已开启
function CrossUnionPk.pkStarted(withAlert)
	local maintenanceConfig = MaintenanceManager:findActivityConfig(CrossUnionPkConfig.unionWarFeatureName())
	if (not maintenanceConfig) or (not maintenanceConfig.enable) then
		--配置已关闭
		if withAlert then
			local scene = Director:mgr():run()
			SuspensionLabel:showContent(scene, Localization:getInstance():getText("UnionWar_time_begin2"))--军团战暂未开启
		end
		return false
	end

	local currTime = TimeUtil.getServerTimeSeconds()
	local featureRealMainStartTime = CrossUnionPkUtils.findRealUnionPkMainStartTime()
	local startTime,endTime = CrossUnionPkUtils.findTImeLevelStartAndEndTime(CrossUnionPkConsts.TIME_WORSHIP)
	-- print("currTime = " .. tostringRich(currTime))
	-- print("featureRealMainStartTime = " .. tostringRich(featureRealMainStartTime))

	if currTime < featureRealMainStartTime or currTime > endTime then
		if withAlert then
			local scene = Director:mgr():run()
			SuspensionLabel:showContent(scene, TimeUtil.formatDate(featureRealMainStartTime, "WGVG_Detail59"))--军团战于{month}月{day}日{hour}:{min}开启，敬请期待。
		end
		return false
	end 
	return true
end


function CrossUnionPk.getEndTime(timeLevel)
	local startTime, endTime = CrossUnionPkUtils.findTImeLevelStartAndEndTime(timeLevel)
	return 	endTime
end
