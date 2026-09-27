UserLevelManager = class()

function UserLevelManager.checkUserLevelUp( onConfirmedCallback )
	local needLevelup = CanonLevelUpEventTimes and CanonLevelUpEventTimes > 0
	local requestLevelup = nil
	local backTouchBlocked = false
	local targetPanelBackup = nil

	requestLevelup = function()
		local function panelCallback()
			if not g_isInBattleScene and backTouchBlocked then
				--local currentScene = Director:sharedDirector():getRunningScene()
				--currentScene:setTableViewsEnabled(true)
				--currentScene.targetInfoPanel = targetPanelBackup
			end
			
			if onConfirmedCallback and type(onConfirmedCallback) == "function" then
				onConfirmedCallback()
			end
			--[[
			if needLevelup then
				local userData = DataManager.getCurrUser()
				if userData.level >= 5 then
          if IsGuideExecuted(GuideConfig.kRisk3) then --主要新手引导的最后一个执行完后，才执行这个
            ExeNewGuide(GuideConfig.kCardOn)
          end
--					ExeNewGuide(GuideConfig.kGacha) --Not Run Here
				end
			end]]
		end

		if CanonLevelUpEventReady then
			require "canon.request.UpgradeUserRequest"
			--level up 
			local function levelUpCallback()
				--facebook share levelup
				local GameData = DataManager.getGameInitData()
				local userLevel = GameData.sharkUser.level
				FacebookShareManager.facebookShareLevelUp(userLevel,requestLevelup)
				--requestLevelup()
			end

            local function upgradeUserFinish(evt)
              local GameData = DataManager.getGameInitData()
              --补满玩家的体力和精力
              local maxEnergy = MetaManager.game_meta.gameSettingConfig.maxEnergy
              GameData.sharkUser.energyLastUpdateTime = TimeUtil.getServerTimeSeconds()
              GameData.sharkUser.energy = GameData.sharkUser.energy + tonumber(MetaManager.game_meta.gameSettingConfig.energyGainedByLevelUp )
              if (GameData.sharkUser.energy > maxEnergy) then
                GameData.sharkUser.energy = maxEnergy
              end
              local maxEventPoint = MetaManager.game_meta.gameSettingConfig.maxEventPoint
              GameData.sharkUser.eventPointLastUpdateTime = TimeUtil.getServerTimeSeconds()
              GameData.sharkUser.eventPoint = GameData.sharkUser.eventPoint + tonumber(MetaManager.game_meta.gameSettingConfig.eventPointGainedByLevelUp)
              if (GameData.sharkUser.eventPoint > maxEventPoint) then
                GameData.sharkUser.eventPoint = maxEventPoint
              end
              --升级
              --GameData.sharkUser.level = GameData.sharkUser.level + 1
              --通知冲击奖励活动
		      local whetherPassedLevelRaceActivityTime = MaintenanceManager.isActivityAlreadyClose("activityLevelRace")
		      if MaintenanceManager.isActivityOpen("activityLevelRacePanel") and (not whetherPassedLevelRaceActivityTime) then
		        GameData.sharkActivity = GameData.sharkActivity or {}
		        GameData.sharkActivity.lrUserLevel = GameData.sharkUser.level
		      end
		      DataManager.setGameInitData(GameData)
				if not g_isInBattleScene then
					BaseUINotify:dispatchEvent(Event.new(DataChangedNotifyEnum.BaseUISceneDataChanged, nil))
				end

                local upgradePanel = UserLevelupBox:create(evt.data.sharkUser, levelUpCallback)
                if not g_isInBattleScene and not backTouchBlocked then
			    	--local currentScene = Director:sharedDirector():getRunningScene()
					--currentScene:setTableViewsEnabled(false)
					--targetPanelBackup = currentScene.targetInfoPanel
					--currentScene.targetInfoPanel = upgradePanel
					backTouchBlocked = true
			    end
                PopoutManager:sharedManager():popout(upgradePanel, kPopoutDir.kFromTopToTop, false, false)
            end
            local function upgradeUserFailed(error)      
            	local errorCode = tonumber(error.data)
      
      			if(CommErrorCodes.USER_LEVELUP_EVENT_NOT_EXIST.code == errorCode) then 
      				CanonLevelUpEventReady = false
            		CanonMessageBox:showCommErrorBox(CommErrorCodes.USER_LEVELUP_EVENT_NOT_EXIST, nil, nil, panelCallback)
            	else
					panelCallback()
            	end
            end
            local request = UpgradeUserRequest.new( nil, rpc.SendingPriority.kHigh )
            request:addEventListener( RequestNotifyEnum.UpgradeUserSucceed, upgradeUserFinish )
            request:addEventListener( RequestNotifyEnum.UpgradeUserFailed, upgradeUserFailed )
            request:start()
            CanonLevelUpEventReady = false
		else
			panelCallback()
		end
	end

	requestLevelup()
end

function UserLevelManager.isUserLevelUp()
	return CanonLevelUpEventTimes and CanonLevelUpEventTimes > 0
end