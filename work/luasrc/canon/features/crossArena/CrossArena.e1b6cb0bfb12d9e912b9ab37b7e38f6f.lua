
require "canon.features.crossArena.manager.CrossArenaTest"
require "canon.features.crossArena.manager.CrossArenaUtils"
require "canon.features.crossArena.manager.CrossArenaCheck"
require "canon.features.crossArena.manager.CrossArenaConsts"

require "canon.features.crossArena.layer.CrossArenaRewardLayer"

require "canon.features.crossArena.panel.CrossArenaRewardReviewPanel"

require "canon.features.crossArena.scene.CrossArenaChanllengeScene"
require "canon.features.crossArena.scene.CrossArenaRewardScene"

require "canon.features.crossArena.request.CrossPvpGetRankInfoRequest"
require "canon.features.crossArena.request.GetCrossPvpInfoRequest"
require "canon.features.crossArena.request.CrossPvpGainBattleRewardRequest"
require "canon.features.crossArena.request.GetCrossPvpReportRequest"
require "canon.features.crossArena.request.GetCrossPvpVideoRequest"
require "canon.features.crossArena.request.CrossPvpActiveRewardRequest"
require "canon.features.crossArena.request.BuyCrossPvpChallengeTimeRequest"


CrossArena = {}

--场景编号
CrossArena.SCENE_CHALLENGE_INDEX 	= 1--挑战时段场景
CrossArena.SCENE_REWARD_INDEX 		= 2--奖励时段场景

-------------------------------------------------
-- 启动
-------------------------------------------------
function CrossArena.startup()
end

-------------------------------------------------
-- 清除
-------------------------------------------------
function CrossArena.clear()
end

-------------------------------------------------
-- 对外接口
-------------------------------------------------

-- 跨服pvp是否存在
function CrossArena.enabled()
	return true
end

-------------------------------------------------
-- 跳转
-------------------------------------------------

--进入跨服pvp主场景
-- sceneIndex 试图进入的场景编号 CrossArena.SCENE_CHALLENGE_INDEX / CrossArena.SCENE_REWARD_INDEX
-- panelIndex 页签编号 不指定为默认页签
function CrossArena.gotoCrossPvpScene(sceneIndex, panelIndex)
	if SystemManager.debug then
		--print("UnionPkConfig.getSettingConfig() = " .. tostringRich(UnionPkConfig.getSettingConfig()))
	end

	if not sceneIndex then
		sceneIndex = CrossArena.SCENE_CHALLENGE_INDEX
	end

	--先请求整体数据
	local function onTotalAfterSucceed(totalEvt)
		if totalEvt.data.phaseIndex == 0 then--战斗阶段
			if sceneIndex ~= CrossArena.SCENE_CHALLENGE_INDEX or panelIndex == nil then
				--在战斗阶段试图进入以外的场景 或者没有指定tab 进入默认tab
				panelIndex = CrossArenaChanllengeScene.TAB_CHALLENGE 
			end

			local function onAfterSucceed(evt)
				local scene = Director:mgr():run()
				scene:replaceScene(CrossArenaChanllengeScene,{enterScene=nil,returnScene=nil,params={panelIndex = panelIndex}})
			end

			if panelIndex == CrossArenaChanllengeScene.TAB_RANK then
				CrossPvpGetRankInfoRequest.sendRequestDefalut(onAfterSucceed)
			elseif panelIndex == CrossArenaChanllengeScene.TAB_NEWS then
				GetCrossPvpReportRequest.sendRequestDefalut(onAfterSucceed)
			else
				onAfterSucceed()
			end
		elseif totalEvt.data.phaseIndex == 1 then--领奖阶段
			if sceneIndex ~= CrossArena.SCENE_REWARD_INDEX or panelIndex == nil then
				--在领奖阶段试图进入以外的场景 或者没有指定tab 进入默认tab
				panelIndex = CrossArenaRewardScene.TAB_REWARD 
			end

			local function onAfterSucceed(evt)
				local scene = Director:mgr():run()
				scene:replaceScene(CrossArenaRewardScene,{enterScene=nil,returnScene=nil,params={panelIndex = panelIndex}})
			end

			if panelIndex == CrossArenaRewardScene.TAB_RANK then
				CrossPvpGetRankInfoRequest.sendRequestDefalut(onAfterSucceed)
			else
				onAfterSucceed()
			end
		end
	end
	GetCrossPvpInfoRequest.sendRequestDefalut(onTotalAfterSucceed)

end

-- 查看目标玩家阵容信息 跳转到阵容场景
-- uid 目标玩家uid
-- enterSceneIndex 进入场景编号
-- enterPanelIndex 切换前所在页面编号
function CrossArena.gotoUserFormationScene(uid, enterSceneIndex, enterPanelIndex,enterNames)
	local myUid = DataManager.getCurrUser().uid
	if uid == myUid then
		--玩家自身
		return
	end
    local enterSceneName = nil
    if enterNames then
    	enterSceneName = enterNames
    else
    	enterSceneName = "CrossArena"
    end
	
	local scene = Director:mgr():run()
	local params = {playerUid = uid}
	local function onGetPlayerTeamInfoCallback( evt )
		local argv = {
			enterScene = enterSceneName,
			returnScene = enterSceneName,
			enterSceneIndex = enterSceneIndex,
			enterPanelIndex = enterPanelIndex,
			params = {
				playerUid = uid,
				playerTeamData = evt.data,
			},
		}
		scene:replaceScene( CardQueueScene, argv )
	end

	local getPlayerTeamInfoRequest = GetPlayerTeamInfoRequest.new(params, rpc.SendingPriority.kHigh)
	getPlayerTeamInfoRequest:addEventListener(RequestNotifyEnum.GetPlayerTeamInfoSucceed, onGetPlayerTeamInfoCallback)
	getPlayerTeamInfoRequest:start()
end

-------------------------------------------------
-- 显示ui
-------------------------------------------------