require "hecore.display.CocosObject"
require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "canon.scene.BaseUIScene"
require "canon.scene.BeastScene"
require "canon.panel.ChapterFinishRewardPanel"
require "canon.panel.RouletteRewardPanel"
require "canon.request.ChallengeSkyTowerRequest"

BattleResultPanel = class(Layer)
local visibleSize = CCDirector:sharedDirector():getVisibleSize();

BattleResultType = {
	ARENA_WIN = 0,
	ARENA_LOSE = 1,
	VS_WIN = 2,
	VS_LOSE = 3,
	BATTLE_WIN = 4,
	BATTLE_LOSE = 5,
	AUTOTOWER_WIN = 6,
	ROB_WIN = 7,
	ROB_LOSE = 8,
	BOSS_WIN = 9,
	BOSS_LOSE = 10,
  	MULTI_BOSS_LOSE = 11,
  	MULTI_BOSS_WIN = 12,
  	NEWBABEL_WIN = 13,
	NEWBABEL_LOSE = 14,
	PK_WIN = 15,
	PK_LOSE = 16,
  	ACTIVITY_CONTEND = 17,
  	CROSS_PK = 18,
  	ACTIVITY_WANTED_LOSE = 19,
  	ACTIVITY_WANTED_WIN = 20,
  	CHAPTER_MAP_WIN = 21,
  	CHAPTER_MAP_LOSE = 22,
  	EILTE_WIN = 23,
  	EILTE_LOSE = 24,
  	ACTIVITY_XMAS_LOSE = 25,
  	ACTIVITY_XMAS_WIN = 26,
  	CROSS_PVP_WIN = 27,
  	CROSS_PVP_LOSE = 28,
}

local function doArenaBattleEndRequest(callback)
    local function getArenaMatchedPlayersSucceed(event)
        ArenaManager:sharedManager():resetArenaData(event.data)
                  
        if ArenaManager:sharedManager():whetherRequestForArenaScore() then
          local function gainArenaScoreByRankSucceed(event)
            ArenaManager:sharedManager():cacheGainArenaRankScoreTime()
            RewardManager:getReward({event.data.reward}, true)
            ArenaManager:sharedManager():gainArenaScoreByRank(event.data.reward.amount)
            if callback then
              callback()
            end
          end 
          local function gainArenaScoreByRankFailed(event)
            ArenaManager:sharedManager():cacheGainArenaRankScoreTime()
            if event.data.retCode == 712407 then
                      
            end
            if callback then
              callback()
            end
          end
          local params = {}
          local request = GainArenaScoreByRankRequest.new(params, rpc.SendingPriority.kHigh)
          request:addEventListener(RequestNotifyEnum.GainArenaScoreByRankSucceed, gainArenaScoreByRankSucceed)
          request:addEventListener(RequestNotifyEnum.GainArenaScoreByRankFailed, gainArenaScoreByRankFailed)
          request:start()
        else
          if callback then
            callback()
          end
        end      
    end 
    local function getArenaMatchedPlayersFailed(event)
        if event.data.retCode == 712400 then
        local aContent = Localization:getInstance():getText("arena_levelInsufficient", {num = MetaManager.game_meta.gameSettingConfig.arenaUnlockLevel})
            SuspensionLabel:showContent(self, aContent)
        end
    end
    local params = {}
    local request = GetArenaMatchedPlayersRequest.new(params, rpc.SendingPriority.kHigh)
    request:addEventListener(RequestNotifyEnum.GetArenaMatchedPlayersSucceed, getArenaMatchedPlayersSucceed)--GetArenaMatchedPlayersFailed
    request:addEventListener(RequestNotifyEnum.GetArenaMatchedPlayersFailed, getArenaMatchedPlayersFailed)
    request:start()
end

local function addReplaceSceneButtons( battleResultUI , resultType)
	local function onSelect( evt )
		local btnType = evt.context
		if btnType == 1 then
			if resultType == BattleResultType.ARENA_LOSE then
				local function gotoCardQueueScene()
					Director:sharedDirector():replaceScene(CardQueueScene:create())
				end
				doArenaBattleEndRequest(gotoCardQueueScene)
			else
				Director:sharedDirector():replaceScene(CardQueueScene:create())
			end
		elseif btnType == 3 then
			function getDestinyFightUnlockLevel()
				return MetaManager.getSpiritSettings().unlockLevel
			end
			if getDestinyFightUnlockLevel() > DataManager.getCurrUser().level then
				SuspensionLabel:showContent(Director:sharedDirector():getRunningScene(), Localization:getInstance():getText("destinyBattle_levelInsufficient", {num = getDestinyFightUnlockLevel()}))
				do return end
			end
			Director:sharedDirector():replaceScene(ChallengeEntersScene:create({params = {showPanelName = "destiny"}}))
		elseif btnType == 2 then
			Director:sharedDirector():replaceScene(GachaScene:create())
		elseif btnType == 4 then
			if DataManager.getCurrUser().level < MetaManager.game_meta.gameSettingConfig.beastConfig.beastUnlockLevel then
				SuspensionLabel:showContent(Director:sharedDirector():getRunningScene(), Localization:getInstance():getText("module_needLevel", {num = MetaManager.game_meta.gameSettingConfig.beastConfig.beastUnlockLevel}))
				do return end
			end
			local function doPrerationSucceed(fragmentsInfo)
				local argv = {enterScene="MainMenuScene",returnScene="MainMenuScene",params={fragmentsInfo=fragmentsInfo}}
				Director:sharedDirector():replaceScene(BeastScene:create(argv))
			end
			
			local function doPrerationFailed()
				-- self.isChangeingScene = false
			end
			
			BeastScene.doPreparationBeforeReplaceToBeastScene(doPrerationSucceed, doPrerationFailed)
		end
	end
	for i=1,4 do
		battleResultUI:getChildByName("txt_towerBabel_win4_"..i):getChildByName("txt"):setString(getTextByKey("battleResult_new_lostTips"..i))
		local btn = Button:create(battleResultUI:getChildByName("btn_select"..i))
		btn:addEventListener(Events.kStart, onSelect , i)
	end
end

local function addItemLayerByDrops(battleResultUI , rewardTable , tableViewPosX , tableViewPosY)
	local TABLEVIEW_CELL_TAG = -1000
	local TAG_PIC_REWARD = 100
	local TAG_REWARD_NAME = 101
	local TAG_REWARD_NUM = 102
	local TAG_NORMAL_CARD_SMALL = 103
	local TAG_START = 1000

	local function createDropsTableView(data)
		local RewardCellRenderer = class(TableViewRenderer)
		local COLS_NUM = 4

		-- ¹¹Ôìº¯ÊýÖÐ¼ÆËãcell¸öÊý
  		function RewardCellRenderer:ctor(width, height)
			local rows = 0
    		if #data % COLS_NUM == 0 then
      			rows = #data / COLS_NUM
    		else
      			rows = #data / COLS_NUM + 1
    		end
		    for i = 1, rows do
		      self.list[i] = i
		    end
		    if rows == 0 then
		      self.list = {}
		    end
		end

		-- ¹¹½¨Cell
  		function RewardCellRenderer:buildCell(container)
  			local posX, posY = battleResultUI:getChildByName("battleResult_normal_card_small").refCocosObj:getPosition()
			local size = battleResultUI:getChildByName("battleResult_normal_card_small").refCocosObj:getContentSize()
		    for cols = 1, COLS_NUM do
		    	local builder = LayoutBuilder:createWithContentsOfFile("scene/battleResult_new.json")
		    	local layer = builder:build("sb/reward_item")
		    	layer:getChildByName("normal_card_small"):setTag(TAG_NORMAL_CARD_SMALL)
		    	layer:getChildByName("txt_item_name"):setTag(TAG_REWARD_NAME)
		    	layer:getChildByName("txt_item_name"):getChildByName("txt"):setTag(TAG_REWARD_NAME)
		    	local TxtPosX, TxtPosY = layer:getChildByName("txt_item_name").refCocosObj:getPosition()
				layer:getChildByName("txt_item_name"):setPositionX(TxtPosX-10)
		    	local width = 600
		    	local layerPosX = cols * (width / COLS_NUM) - (width / (COLS_NUM * 2))
		    	layer:setPosition(ccp(layerPosX, self.height * 0.9 - 65)) 
		    	layer:setVisible(false)
		    	layer:getChildByName("normal_card_small"):setVisible(false)
		    	container:addChild(layer)
		    	layer:setTag(TAG_START + cols)
		    end
  		end

  		  -- ÉèÖÃÊý¾Ý
	  	function RewardCellRenderer:setData(rawCocosObj, index)
	    	for cols = 1, COLS_NUM do 
	      		local cellLayer = self:getChildByTag(rawCocosObj, TAG_START + cols)
			  	cellLayer:setVisible(false)
				
	      		local rewardId = index * COLS_NUM + cols
				if rewardId <= #data then
		        	-- ¸ù¾ÝTagÉèÖÃÎÄ±¾
		        	local function setTextByTag(tag, str)
		          		local txt = cellLayer:getChildByTag(tag):getChildByTag(tag)
		          		ViewControlUtil.setLableText(txt, str)
				    end
		        
		        	-- ¸ù¾ÝTagÉèÖÃÊÇ·ñ¿É¼û
				    local function setNodeVisibleByTag(tag, visible)
					    cellLayer:getChildByTag(tag):setVisible(visible)
				    end
					    
		        	-- »ñÈ¡UIÐÅÏ¢
		        	local picPosX, picPosY = cellLayer:getChildByTag(TAG_NORMAL_CARD_SMALL):getPosition()
				    -- local picZOrder = cellLayer:getChildByTag(TAG_PIC_REWARD_BG):getZOrder()
					cellLayer:setVisible(true)
		        	cellLayer:removeChildByTag(TAG_PIC_REWARD, true)
				        
		        	-- »ñÈ¡½±ÀøÐÅÏ¢
					local rewardInfo = rewardTable[rewardId]

					local params = {}
			        params.sourceDisplay = cellLayer:getChildByTag(TAG_NORMAL_CARD_SMALL)
		          	local headCard = CanonGoodIcon.createGoodIconByPackageRewardInfo(rewardInfo, params)
		          	headCard:setPosition(ccp(picPosX, picPosY))
		          	headCard:setTag(TAG_PIC_REWARD)
		          	if rewardInfo.itemType == ResourceEnum.PROP or rewardInfo.itemType == ResourceEnum.MysteriousCoins or 
		          	rewardInfo.itemType == ResourceEnum.ASTRALESSENCE or rewardInfo.itemType == ResourceEnum.ENCHANT_POINT then
			          	local amount = tonumber(rewardInfo.amount)
						if not amount then
							amount = 1
						end
						local amountText = ArtTextField:create("x" .. amount, nil, 25)
						amountText:setAnchorPoint(ccp(1, 0))
						amountText:setPosition(ccp(44, -50))
						headCard:addChild(amountText)
					end
		          	cellLayer:addChild(headCard.refCocosObj, 1000)
		          	headCard:dispose()

		            rewardName = CanonGoodIcon.getGoodNameByPackageRewardInfo(rewardInfo , {withoutAmount = true})

		        	setTextByTag(TAG_REWARD_NAME, rewardName)

				end
			end
	  	end
	  	-- Éú³ÉTableView
		local renderer = RewardCellRenderer.new(580, 180.5)
		local tableView = TableView:create(renderer, 620.8, 333)--400
		tableView:setPosition(ccp(tableViewPosX , tableViewPosY))
		return tableView
	end

	local posX, posY = battleResultUI:getChildByName("battleResult_normal_card_small").refCocosObj:getPosition()
	local size = battleResultUI:getChildByName("battleResult_normal_card_small").refCocosObj:getContentSize()
	local itemLayer = Layer:create()

	if #rewardTable > 0 and #rewardTable <= 4 then
		for k,v in ipairs(rewardTable)
		do
			local builder = LayoutBuilder:createWithContentsOfFile("scene/battleResult_new.json")
		    local layer = builder:build("sb/reward_item")
		    local picPos = layer:getChildByName("normal_card_small"):getPosition()

        	layer:getChildByName("normal_card_small"):removeFromParentAndCleanup(true)
        	-- »ñÈ¡½±ÀøÐÅÏ¢
			local rewardInfo = rewardTable[k]

			local params = {}
	        params.sourceDisplay = layer:getChildByName("normal_card_small")
          	local headCard = CanonGoodIcon.createGoodIconByPackageRewardInfo(rewardInfo, params)
          	headCard:setPosition(ccp(picPos.x ,picPos.y))
          	headCard:setScale(0.85)
          	if rewardInfo.itemType == ResourceEnum.PROP or rewardInfo.itemType == ResourceEnum.MysteriousCoins  or 
		          	rewardInfo.itemType == ResourceEnum.ASTRALESSENCE or rewardInfo.itemType == ResourceEnum.ENCHANT_POINT then
	          	local amount = tonumber(v.amount)
				if not amount then
					amount = 1
				end
				local amountText = ArtTextField:create("x" .. amount, nil, 25)
				amountText:setAnchorPoint(ccp(1, 0))
				amountText:setPosition(ccp(44, -50))
				headCard:addChild(amountText)
			end
          	layer:addChild(headCard, 1000)

            rewardName = CanonGoodIcon.getGoodNameByPackageRewardInfo(rewardInfo , {withoutAmount = true})
            layer:getChildByName("txt_item_name"):getChildByName("txt"):setString(rewardName)
            local TxtPosX, TxtPosY = layer:getChildByName("txt_item_name").refCocosObj:getPosition()
			layer:getChildByName("txt_item_name"):setPositionX(TxtPosX-10)
			print("~~~~~~~~~~~~~~~~~~~~~~1")
			local line = math.floor((k - 1) / 4)
			local row = (k - 1)% 4
			layer:setPosition(ccp(posX + row * (size.width + 40), posY - line * (size.height + 40)))
			itemLayer:addChild(layer)
		end
		battleResultUI:addChild(itemLayer)
	elseif #rewardTable <= 0 then
		return nil
	else
		local tableView = createDropsTableView(rewardTable)
		battleResultUI:addChild(tableView)
	end
end

local SELF = nil;
function BattleResultPanel:ctor()
	SELF = self
	self.resultType = nil
	self.data = nil;
end

local function fightAgain(e)
  local robConsumeEventPoints = DataManager.GameMetaData.battleSettingConfig.robSettingConfig.robConsumeEventPoints
  if CalculationManager.calcComplex_getEPNow() < robConsumeEventPoints - 0.01 then
    SELF.container:showNotEnoughEventPointPanel()
    return
  end
  
  local beastFragmentId = SELF.data.beastFragmentId
  local enemyUid = SELF.data.enemyUid
  local robType = SELF.data.robType
  local robotId = SELF.data.robotId
	local function successCallback(data)
    RewardManager:getReward({{itemType = ResourceEnum.EVENTPOINT, amount = -robConsumeEventPoints}})
    
    local robSucceed = false
    for _, v in pairs(data.rewards) do
      if v.itemType == ResourceEnum.BEAST_FRAGMENT then
        robSucceed = true
        break
      end
    end
    local backType = robSucceed and BattleBackType.kBeastScene or BattleBackType.kRobFragmentScene
    data.beastFragmentId = beastFragmentId
    data.enemyUid = enemyUid
    data.robType = robType
    data.robotId = robotId
    Director:sharedDirector():replaceScene(BattleScene:create(data, backType, BattleEnterEnum.kRobFragmentScene))
  end
  
  local function failureCallback(data)
    if data.retCode == 716018 then
      local function closeCanonMessageBox()
      end
      local text = Localization:getInstance():getText("beastRob_opponentPeace")
      SELF.container.targetInfoPanel = CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
    elseif data.retCode == 710515 then
      SELF.container:showNotEnoughEventPointPanel()
    else
      local function closeCanonMessageBox()
      end
      local text = Localization:getInstance():getText("defaultError_popupText", {errorCodeId = data.retCode})
      SELF.container.targetInfoPanel = CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
    end
  end
  
  RobFragmentScene.doPreparationBeforeReplaceToBattleScene({beastFragmentId = beastFragmentId, enemyUid = enemyUid , robType = robType , robotId = robotId}, successCallback, failureCallback)
end

local function onMoreButtonClick(e)
	local buttonCallback = fightAgain
  buttonCallback(e)
  --[[
	SELF:removeFromParentAndCleanup(true)
	
	UserLevelManager.checkUserLevelUp(function() if buttonCallback then
													buttonCallback(e)
												end
	end)
	if type(SELF.container.setTableViewsEnabled) == "function" then
		SELF.container:setTableViewsEnabled(true)
	end
	SELF = nil;]]
  
end

local function onLeftButtonClick(e)
	local buttonCallback = SELF.leftbuttoncallback

	SELF:removeFromParentAndCleanup(true)
	SELF.container.targetInfoPanel = nil;
  
	local curContext = e.context
  
  
  local function checkChapterFinishRewardCallback()
    
    local function excuteCallback()
      if buttonCallback then
        buttonCallback()
      end
      if type(SELF.container.setTableViewsEnabled) == "function" then
        SELF.container:setTableViewsEnabled(true)
      end
      SELF = nil;
    end
    if SELF.data.showQuery then
      local function backToCityMain(notReset)
        if SELF.container.effectId then
					SimpleAudioEngine:sharedEngine():stopEffect(SELF.container.effectId)
					SELF.container.effectId = nil;
				end
				local argv = {enterScene="BattleScene",returnScene=nil,params={notReset=notReset, nomccomplete = true, newMissionId = SELF.data.newMissionId, showAllFinishedPanel = SELF.data.showAllFinishedPanel}}
        scene = CityMainScene:create(argv)
        Director:sharedDirector():replaceScene(scene)
      end
      local function moveOnInChapterMap()
        excuteCallback()
      end
			
			if curContext == "btn_goon" then
				moveOnInChapterMap()
			else
				local notReset
        if (SELF.resultType == BattleResultType.BATTLE_WIN) and (SELF.data.backType == BattleBackType.kCityMainScene) then
          local aSelectedCountryID
          local aSelectedChapterID
          local aChapterID = math.modf(SELF.data.missionID / 100)
          local aCountryID = math.modf(aChapterID / 100)
          CountryManager:sharedManager():selectCountryID(aCountryID)
          CountryManager:sharedManager():selectChapterID(aChapterID)
          notReset = true
        end
				backToCityMain(notReset)
			end
    else
      excuteCallback()
    end
  end
  
  local function checkChapterFinishReward()
    if not SELF.should_check_finish_reward then
      checkChapterFinishRewardCallback()
      return
    end
    if CountryManager:sharedManager():shouldShowChapterFinishRewardPanel() then
      local aPanel = ChapterFinishRewardPanel:create(SELF.container, CountryManager:sharedManager():getChapterFinishReward(), checkChapterFinishRewardCallback)
      SELF.container:addChild(aPanel)
      aPanel:scaleIn()
    else
      checkChapterFinishRewardCallback()
    end
  end

	UserLevelManager.checkUserLevelUp(checkChapterFinishReward)
end

local function onRightButtonClick(e)
	local buttonCallback = SELF.rightbuttoncallback
	SELF:removeFromParentAndCleanup(true)
	
	UserLevelManager.checkUserLevelUp(function() if buttonCallback then
													buttonCallback()
												end
	end)
	if type(SELF.container.setTableViewsEnabled) == "function" then
		SELF.container:setTableViewsEnabled(true)
	end
	SELF = nil;
end

function BattleResultPanel:show(resultType, data, leftbuttoncallback, rightbuttoncallback, container, should_check_finish_reward)
	self.resultType = resultType
	--print(self.resultType)
	self.data = data
	self.leftbuttoncallback = leftbuttoncallback
	self.rightbuttoncallback = rightbuttoncallback

	if not container then
		self.container = Director:sharedDirector():getRunningScene()
	else
		self.container = container
	end
	self.should_check_finish_reward = should_check_finish_reward
  
	if type(self.container.setTableViewsEnabled) == "function" then
		self.container:setTableViewsEnabled(false)
	end
	
	self.container.targetInfoPanel = self
  
	local s = BattleResultPanel.new()
	s:initLayer()
	self.container:addChild(s)

	Set_ShareData( "ShowBattleResults", 1 )
	return s
end

function BattleResultPanel:showNewArenaWin()
	self.battleResultUI = self.builder:build("battleResult_new_arena_win")
	
	self.battleResultUI:getChildByName("battleResult_icon_arena_bigwin_sb"):setVisible(false)
	self.battleResultUI:getChildByName("battleResult_icon_arena_littlewin_sb"):setVisible(false)
	self.battleResultUI:getChildByName("battleResult_icon_arena_normalwin_sb"):setVisible(false)
	
	local GameMetaData = MetaManager.game_meta
	if self.data.leftHpRate < GameMetaData.battleSettingConfig.victoryLevelFloor then
		self.battleResultUI:getChildByName("battleResult_icon_arena_littlewin_sb"):setVisible(true)
	elseif self.data.leftHpRate > GameMetaData.battleSettingConfig.victoryLevelTop then
		self.battleResultUI:getChildByName("battleResult_icon_arena_bigwin_sb"):setVisible(true)
	else
		self.battleResultUI:getChildByName("battleResult_icon_arena_normalwin_sb"):setVisible(true)
	end
	
	self.battleResultUI:getChildByName("battleResult_txt_arenaranking"):getChildByName("txt_arenaranking"):setString(getTextByKey("arena_arenaTab"))
	self.battleResultUI:getChildByName("battleResult_txt_arena_ranking_R"):getChildByName("txt_arena_ranking_R"):setString(tostring(self.data.sharkArenaRank.rank))
	self.battleResultUI:getChildByName("battleResult_txt_arena_ranking_L"):getChildByName("txt_arena_ranking_L"):setString(tostring(self.data.previousArenaRankInfo.rank))
	self.battleResultUI:getChildByName("battleResult_txt_arenascore"):getChildByName("txt_arenascore"):setString(getTextByKey("battleResult_arenaPoint"))
	local coin = 0
	if type(self.data.rewards) == "table" then
		for k,v in pairs(self.data.rewards)
		do
			if v.itemType == ResourceEnum.COIN then
				coin = tonumber(v.amount) + coin
			end
		end
	end
	local arenaPoint = self.data.selfRewardScore
	if not arenaPoint then
		arenaPoint = 0
	end
	self.battleResultUI:getChildByName("battleResult_txt_arena_score"):getChildByName("txt_arenascore"):setString("+" .. tostring(arenaPoint))
	self.battleResultUI:getChildByName("battleResult_btn_long_yellow"):getChildByName("font"):setString(getTextByKey("yes"))
	
	if self.data.sharkArenaRank.rank == self.data.previousArenaRankInfo.rank then
		self.battleResultUI:getChildByName("battleResult_txt_arenaranking"):setVisible(false)
		self.battleResultUI:getChildByName("battleResult_txt_arena_ranking_L"):setVisible(false)
		self.battleResultUI:getChildByName("battleResult_icon_arrow"):setVisible(false)
		self.battleResultUI:getChildByName("battleResult_txt_arena_ranking_R"):setVisible(false)
		-- local middleBg = self.battleResultUI:getChildByName("battleResult_new_red_bg9_pic")
		-- middleBg:setContentSize(CCSizeMake(middleBg:getContentSize().width, middleBg:getContentSize().height - 90))
		
	end
	
	local btnOK = Button:create(self.battleResultUI:getChildByName("battleResult_btn_long_yellow"))
	btnOK:addEventListener(Events.kStart, onLeftButtonClick, self)	

	--DOUBLE_REWARD_MODIFY
	if Activity_DoubleRewardLayer.getRewardEnableById(Activity_DoubleRewardLayer.MOUDLE_ARENA) then
		--双倍活动已开启
		self.battleResultUI:getChildByName("txt_02"):setVisible(true)
		local addPercent = (Activity_DoubleRewardLayer.getRewardMultipleById(Activity_DoubleRewardLayer.MOUDLE_ARENA) - 1) * 100
		self.battleResultUI:getChildByName("txt_02"):getChildByName("txt"):setString("("..getTextByKey("activity_doublereward_txt2", {num = addPercent.."%"})..")")--双倍活动+{num}
		self.battleResultUI:getChildByName("battleResult_txt_getcoin"):getChildByName("font"):setString("+" .. tostring(coin))
	else
		--正常显示
		self.battleResultUI:getChildByName("txt_02"):setVisible(false)
		self.battleResultUI:getChildByName("battleResult_txt_getcoin"):getChildByName("font"):setString("+" .. tostring(coin))
	end
	
end

function BattleResultPanel:showNewArenaLose()
	self.battleResultUI = self.builder:build("battleResult_new_arena_lose")
	addReplaceSceneButtons(self.battleResultUI , self.resultType)
	
	self.battleResultUI:getChildByName("battleResult_txt_battleResult_infomation"):getChildByName("txt_battleResult_infomation"):setString(getTextByKey("battleResult_lostTips2"))
	self.battleResultUI:getChildByName("battleResult_icon_arena_normallost_sb"):setVisible(false)
	self.battleResultUI:getChildByName("battleResult_icon_arena_littlelost_sb"):setVisible(false)
	self.battleResultUI:getChildByName("battleResult_lbl_lose"):setVisible(false)
	
	local GameMetaData = MetaManager.game_meta
	if self.data.leftHpRate < GameMetaData.battleSettingConfig.victoryLevelFloor then
		self.battleResultUI:getChildByName("battleResult_icon_arena_littlelost_sb"):setVisible(true)
	elseif self.data.leftHpRate > GameMetaData.battleSettingConfig.victoryLevelTop then
		self.battleResultUI:getChildByName("battleResult_lbl_lose"):setVisible(true)
	else
		self.battleResultUI:getChildByName("battleResult_icon_arena_normallost_sb"):setVisible(true)
	end
	self.battleResultUI:getChildByName("battleResult_txt_arenascore"):getChildByName("txt_arenascore"):setString(getTextByKey("battleResult_arenaPoint"))
	
	local arenaPoint = self.data.selfRewardScore
	if not arenaPoint then
		arenaPoint = 0
	end
	self.battleResultUI:getChildByName("battleResult_txt_arena_score"):getChildByName("txt_arenascore"):setString("+" ..tostring(arenaPoint))

	self.battleResultUI:getChildByName("battleResult_btn_long_yellow_sure"):getChildByName("font"):setString(getTextByKey("yes"))
	
	local btnOK = Button:create(self.battleResultUI:getChildByName("battleResult_btn_long_yellow_sure"))
	btnOK:addEventListener(Events.kStart, onLeftButtonClick, self)	
	
	-- self.battleResultUI:getChildByName("battleResult_btn_long_yellow_gostrengthen"):getChildByName("font"):setString(getTextByKey("battleResult_strengthen"))
	
	-- local btnOK = Button:create(self.battleResultUI:getChildByName("battleResult_btn_long_yellow_gostrengthen"))
	-- btnOK:addEventListener(Events.kStart, onRightButtonClick, self)	
end

function BattleResultPanel:showNewCrossPVPWin()
	self.battleResultUI = self.builder:build("battleResult_new_arena_win2")
	
	self.battleResultUI:getChildByName("battleResult_icon_arena_bigwin_sb"):setVisible(false)
	self.battleResultUI:getChildByName("battleResult_icon_arena_littlewin_sb"):setVisible(false)
	self.battleResultUI:getChildByName("battleResult_icon_arena_normalwin_sb"):setVisible(false)
	
	local GameMetaData = MetaManager.game_meta
	if self.data.leftHpRate < GameMetaData.battleSettingConfig.victoryLevelFloor then
		self.battleResultUI:getChildByName("battleResult_icon_arena_littlewin_sb"):setVisible(true)
	elseif self.data.leftHpRate > GameMetaData.battleSettingConfig.victoryLevelTop then
		self.battleResultUI:getChildByName("battleResult_icon_arena_bigwin_sb"):setVisible(true)
	else
		self.battleResultUI:getChildByName("battleResult_icon_arena_normalwin_sb"):setVisible(true)
	end
	
	self.battleResultUI:getChildByName("battleResult_txt_arenaranking"):getChildByName("txt_arenaranking"):setString(getTextByKey("arena_arenaTab"))
	self.battleResultUI:getChildByName("battleResult_txt_arena_ranking_R"):getChildByName("txt_arena_ranking_R"):setString(tostring(self.data.currenRank))
	self.battleResultUI:getChildByName("battleResult_txt_arena_ranking_L"):getChildByName("txt_arena_ranking_L"):setString(tostring(self.data.beforeRank))
	self.battleResultUI:getChildByName("battleResult_txt_arenascore"):getChildByName("txt_arenascore"):setString(getTextByKey("crossArena_activeScore"))
	self.battleResultUI:getChildByName("battleResult_txt_arenascore2"):getChildByName("txt_arenascore"):setString(getTextByKey("crossArena_battleScore"))
	local coin = 0
	if type(self.data.rewards) == "table" then
		for k,v in pairs(self.data.rewards)
		do
			if v.itemType == ResourceEnum.COIN then
				coin = tonumber(v.amount) + coin
			end
		end
	end
	local activeScore = self.data.activeScore
	if not activeScore then
		activeScore = 0
	end
	local battleScore = self.data.battleScore
	if not battleScore then
		battleScore = 0
	end
	self.battleResultUI:getChildByName("battleResult_txt_arena_score"):getChildByName("txt_arenascore"):setString("+" .. tostring(activeScore))
	self.battleResultUI:getChildByName("battleResult_txt_arena_score2"):getChildByName("txt_arenascore"):setString("+" .. tostring(battleScore))
	self.battleResultUI:getChildByName("battleResult_btn_long_yellow"):getChildByName("font"):setString(getTextByKey("yes"))
	
	if self.data.currenRank == self.data.beforeRank then
		self.battleResultUI:getChildByName("battleResult_txt_arenaranking"):setVisible(false)
		self.battleResultUI:getChildByName("battleResult_txt_arena_ranking_L"):setVisible(false)
		self.battleResultUI:getChildByName("battleResult_icon_arrow"):setVisible(false)
		self.battleResultUI:getChildByName("battleResult_txt_arena_ranking_R"):setVisible(false)
		-- local middleBg = self.battleResultUI:getChildByName("battleResult_new_red_bg9_pic")
		-- middleBg:setContentSize(CCSizeMake(middleBg:getContentSize().width, middleBg:getContentSize().height))
		
	end
	
	local btnOK = Button:create(self.battleResultUI:getChildByName("battleResult_btn_long_yellow"))
	btnOK:addEventListener(Events.kStart, onLeftButtonClick, self)	

	--DOUBLE_REWARD_MODIFY
	-- if Activity_DoubleRewardLayer.getRewardEnableById(Activity_DoubleRewardLayer.MOUDLE_ARENA) then
	-- 	--双倍活动已开启
	-- 	self.battleResultUI:getChildByName("txt_02"):setVisible(true)
	-- 	local addPercent = (Activity_DoubleRewardLayer.getRewardMultipleById(Activity_DoubleRewardLayer.MOUDLE_ARENA) - 1) * 100
	-- 	self.battleResultUI:getChildByName("txt_02"):getChildByName("txt"):setString("("..getTextByKey("activity_doublereward_txt2", {num = addPercent.."%"})..")")--双倍活动+{num}
	-- 	self.battleResultUI:getChildByName("battleResult_txt_getcoin"):getChildByName("font"):setString("+" .. tostring(coin))
	-- else
	-- 	--正常显示
		self.battleResultUI:getChildByName("txt_02"):setVisible(false)
		self.battleResultUI:getChildByName("battleResult_txt_getcoin"):getChildByName("font"):setString("+" .. tostring(coin))
	-- end
	
end

function BattleResultPanel:showNewCrossPVPLose()
	self.battleResultUI = self.builder:build("battleResult_arena_lose2")
	-- addReplaceSceneButtons(self.battleResultUI , self.resultType)
	
	-- self.battleResultUI:getChildByName("battleResult_txt_battleResult_infomation"):getChildByName("txt_battleResult_infomation"):setString(getTextByKey("battleResult_lostTips2"))
	self.battleResultUI:getChildByName("battleResult_icon_arena_normallost_sb"):setVisible(false)
	self.battleResultUI:getChildByName("battleResult_icon_arena_littlelost_sb"):setVisible(false)
	self.battleResultUI:getChildByName("battleResult_lbl_lose"):setVisible(false)
	self.battleResultUI:getChildByName("battleResult_icon_coinevent"):setVisible(false)
	self.battleResultUI:getChildByName("battleResult_txt_getcoin"):setVisible(false)
	self.battleResultUI:getChildByName("txt_02"):setVisible(false)
	
	local GameMetaData = MetaManager.game_meta
	if self.data.leftHpRate < GameMetaData.battleSettingConfig.victoryLevelFloor then
		self.battleResultUI:getChildByName("battleResult_icon_arena_littlelost_sb"):setVisible(true)
	elseif self.data.leftHpRate > GameMetaData.battleSettingConfig.victoryLevelTop then
		self.battleResultUI:getChildByName("battleResult_lbl_lose"):setVisible(true)
	else
		self.battleResultUI:getChildByName("battleResult_icon_arena_normallost_sb"):setVisible(true)
	end

	local activeScore = self.data.activeScore
	if not activeScore then
		activeScore = 0
	end
	local battleScore = self.data.battleScore
	if not battleScore then
		battleScore = 0
	end
	self.battleResultUI:getChildByName("battleResult_txt_arena_score"):getChildByName("txt_arenascore"):setString("+" .. tostring(activeScore))
	self.battleResultUI:getChildByName("battleResult_txt_arena_score2"):getChildByName("txt_arenascore"):setString("" .. tostring(battleScore))
	self.battleResultUI:getChildByName("battleResult_btn_long_yellow_sure"):getChildByName("font"):setString(getTextByKey("yes"))

	self.battleResultUI:getChildByName("battleResult_txt_arenaranking"):getChildByName("txt_arenaranking"):setString(getTextByKey("arena_arenaTab"))
	self.battleResultUI:getChildByName("battleResult_txt_arena_ranking_R"):getChildByName("txt_arena_ranking_R"):setString(tostring(self.data.currenRank))
	self.battleResultUI:getChildByName("battleResult_txt_arena_ranking_L"):getChildByName("txt_arena_ranking_L"):setString(tostring(self.data.beforeRank))
	self.battleResultUI:getChildByName("battleResult_txt_arenascore"):getChildByName("txt_arenascore"):setString(getTextByKey("crossArena_activeScore"))
	self.battleResultUI:getChildByName("battleResult_txt_arenascore2"):getChildByName("txt_arenascore"):setString(getTextByKey("crossArena_battleScore"))
	
	local btnOK = Button:create(self.battleResultUI:getChildByName("battleResult_btn_long_yellow_sure"))
	btnOK:addEventListener(Events.kStart, onLeftButtonClick, self)	

	if self.data.currenRank == self.data.beforeRank then
		self.battleResultUI:getChildByName("battleResult_txt_arenaranking"):setVisible(false)
		self.battleResultUI:getChildByName("battleResult_txt_arena_ranking_L"):setVisible(false)
		self.battleResultUI:getChildByName("battleResult_icon_arrow"):setVisible(false)
		self.battleResultUI:getChildByName("battleResult_txt_arena_ranking_R"):setVisible(false)
		--local middleBg = self.battleResultUI:getChildByName("other_gery9_l_panel")
		--middleBg:setContentSize(CCSizeMake(middleBg:getContentSize().width, middleBg:getContentSize().height - 90))
	end
	
	-- self.battleResultUI:getChildByName("battleResult_btn_long_yellow_gostrengthen"):getChildByName("font"):setString(getTextByKey("battleResult_strengthen"))
	
	-- local btnOK = Button:create(self.battleResultUI:getChildByName("battleResult_btn_long_yellow_gostrengthen"))
	-- btnOK:addEventListener(Events.kStart, onRightButtonClick, self)	
end

function BattleResultPanel:showNewVSWin()
	self.battleResultUI = self.builder:build("battleRsult_new_vs_win")
	
	self.battleResultUI:getChildByName("txt_anything_info"):getChildByName("txt"):setString(getTextByKey("battleResult_alreadyFought"))
	self.battleResultUI:getChildByName("txt_friend_point"):getChildByName("txt"):setString(getTextByKey("battleResult_friendshipPoint"))
	self.battleResultUI:getChildByName("battleResult_icon_vs_bigwin_sb"):setVisible(false)
	self.battleResultUI:getChildByName("battleResult_icon_vs_littlewin_sb"):setVisible(false)
	self.battleResultUI:getChildByName("battleResult_icon_vs_normalwin_sb"):setVisible(false)
	
	local GameMetaData = MetaManager.game_meta
	if self.data.leftHpRate < GameMetaData.battleSettingConfig.victoryLevelFloor then
		self.battleResultUI:getChildByName("battleResult_icon_vs_littlewin_sb"):setVisible(true)
	elseif self.data.leftHpRate > GameMetaData.battleSettingConfig.victoryLevelTop then
		self.battleResultUI:getChildByName("battleResult_icon_vs_bigwin_sb"):setVisible(true)
	else
		self.battleResultUI:getChildByName("battleResult_icon_vs_normalwin_sb"):setVisible(true)
	end
	
	self.battleResultUI:getChildByName("battleResult_btn_long_yellow"):getChildByName("font"):setString(getTextByKey("yes"))
	
	local friendShipAmount = 0
	if type(self.data.rewards) == "table" then
		for k,v in pairs(self.data.rewards)
		do
			if v.itemType == ResourceEnum.FRIENDPOINT then
				friendShipAmount = tonumber(v.amount)
				break;
			end
		end
	end
	
	if friendShipAmount > 0 then
		self.battleResultUI:getChildByName("txt_anything_info"):setVisible(false)
		self.battleResultUI:getChildByName("battleResult_txt_towerwin"):getChildByName("txt"):setString("+" .. tostring(friendShipAmount))
	else
		self.battleResultUI:getChildByName("txt_friend_point"):setVisible(false)
		self.battleResultUI:getChildByName("battleResult_txt_towerwin"):setVisible(false)
	end
	
	local btnOK = Button:create(self.battleResultUI:getChildByName("battleResult_btn_long_yellow"))
	btnOK:addEventListener(Events.kStart, onLeftButtonClick, self)	
end

function BattleResultPanel:showNewVSLose()
	self.battleResultUI = self.builder:build("battleResult_new_vs_lose")
	addReplaceSceneButtons(self.battleResultUI , self.resultType)
	
	self.battleResultUI:getChildByName("txt_anything_info"):getChildByName("txt"):setString(getTextByKey("battleResult_alreadyFought"))
	self.battleResultUI:getChildByName("txt_friend_point"):getChildByName("txt"):setString(getTextByKey("battleResult_friendshipPoint"))
	self.battleResultUI:getChildByName("battleResult_icon_vs_littlelost_sb"):setVisible(false)
	self.battleResultUI:getChildByName("battleResult_icon_vs_normallost_sb"):setVisible(false)
	self.battleResultUI:getChildByName("battleResult_lbl_lose"):setVisible(false)
	
	local GameMetaData = MetaManager.game_meta
	if self.data.leftHpRate < GameMetaData.battleSettingConfig.victoryLevelFloor then
		self.battleResultUI:getChildByName("battleResult_icon_vs_littlelost_sb"):setVisible(true)
	elseif self.data.leftHpRate > GameMetaData.battleSettingConfig.victoryLevelTop then
		self.battleResultUI:getChildByName("battleResult_lbl_lose"):setVisible(true)
	else
		self.battleResultUI:getChildByName("battleResult_icon_vs_normallost_sb"):setVisible(true)
	end
	
	self.battleResultUI:getChildByName("battleResult_btn_long_yellow_sure"):getChildByName("font"):setString(getTextByKey("yes"))
	
	local friendShipAmount = 0
	if type(self.data.rewards) == "table" then
		for k,v in pairs(self.data.rewards)
		do
			if v.itemType == ResourceEnum.FRIENDPOINT then
				friendShipAmount = tonumber(v.amount)
				break;
			end
		end
	end
	
	if friendShipAmount > 0 then
		self.battleResultUI:getChildByName("txt_anything_info"):setVisible(false)
		self.battleResultUI:getChildByName("battleResult_txt_towerwin"):getChildByName("txt"):setString("+" .. tostring(friendShipAmount))
	else
		self.battleResultUI:getChildByName("txt_friend_point"):setVisible(false)
		self.battleResultUI:getChildByName("battleResult_txt_towerwin"):setVisible(false)
	end
	
	local btnOK = Button:create(self.battleResultUI:getChildByName("battleResult_btn_long_yellow_sure"))
	btnOK:addEventListener(Events.kStart, onLeftButtonClick, self)	
end

function BattleResultPanel:showNewAutoTowerWin()
	self.battleResultUI = self.builder:build("battleResult_new_towerwin")
	
	self.battleResultUI:getChildByName("battleResult_txt_townwin_L"):getChildByName("txt"):setString(getTextByKey("babel_autoResultTitle1"))
	self.battleResultUI:getChildByName("battleResult_txt_townwin_R"):getChildByName("txt"):setString(getTextByKey("babel_autoResultTitle2"))
	self.battleResultUI:getChildByName("battleResult_txt_towerwin"):getChildByName("txt"):setString(tostring(self.data.towerFloor))
	self.battleResultUI:getChildByName("battleResult_txt_gettrophy"):getChildByName("txt_gettrophy"):setString(getTextByKey("battleResult_acquire"))
	self.battleResultUI:getChildByName("txt_none"):getChildByName("txt"):setString(getTextByKey("battleResult_none"))
	
	local baseCoin = 0
	
	local dropItemTable = {}
	
	if type(self.data.rewards) == "table" then
		for k, v in pairs(self.data.rewards)
		do
			if v.itemType == ResourceEnum.COIN then
				baseCoin = baseCoin + tonumber(v.amount)
			elseif v.itemType == ResourceEnum.CARD then
				local canonCard = getHeadIconCanonCardByMetaId( v.metaId)
				table.insert(dropItemTable, canonCard)
			elseif v.itemType == ResourceEnum.EQUIP then
				local canonItem = CanonItem:create()
				canonItem:loadByMetaId(v.metaId)
				canonItem:setScale(130 / 144)
				table.insert(dropItemTable, canonItem)
			elseif v.itemType == ResourceEnum.PROP then
				local canonItem = CanonItem:create()
				canonItem:loadByMetaId(v.metaId)
				canonItem:setScale(130 / 144)
				local amount = tonumber(v.amount)
				if not amount then
					amount = 1
				end
				local amountText = ArtTextField:create("x" .. amount, nil, 25)
				amountText:setAnchorPoint(ccp(1, 0))
				amountText:setPosition(ccp(35, -50))
				canonItem:addChild(amountText)
				table.insert(dropItemTable, canonItem)
			elseif v.itemType == ResourceEnum.BEAST_FRAGMENT then
				local canonItem = CanonItem:create()
				local fragmentSprite = Sprite:create("#" .. MetaManager.beast_fragment[v.metaId].icon .. ".png")
				fragmentSprite:setScale(130 / fragmentSprite:getContentSize().width)
				canonItem:addChild(fragmentSprite)
				canonItem:setScale(130 / 144)
				table.insert(dropItemTable, canonItem)
			end
		end
	end
	
	local vipCoin = 0
	if type(self.data.vipRewards) == "table" then
		for k, v in pairs(self.data.vipRewards)
		do
			if v.itemType == ResourceEnum.COIN then
				vipCoin = vipCoin + tonumber(v.amount)
			end
		end
	end
	
	self.battleResultUI:getChildByName("battleResult_txt_getcoin"):getChildByName("font"):setString("+" .. baseCoin)
	local vipLevel = tonumber(DataManager.getCurrUser().vipLevel)
	if vipCoin <= 0 then
		self.battleResultUI:getChildByName("txt_vipbouns"):setVisible(false)
	else
		self.battleResultUI:getChildByName("txt_vipbouns"):getChildByName("txt"):setString("(VIP" .. tostring(vipLevel) .. "+" .. vipCoin .. ")")
	end
	
	self.battleResultUI:getChildByName("battleResult_normal_card_small"):setVisible(false)
	self.battleResultUI:getChildByName("battleResult_bg_card"):setVisible(false)
	self.battleResultUI:getChildByName("battleResult_frame_card"):setVisible(false)
	local posX, posY = self.battleResultUI:getChildByName("battleResult_normal_card_small").refCocosObj:getPosition()
	local size = self.battleResultUI:getChildByName("battleResult_normal_card_small").refCocosObj:getContentSize()
	
	for k,v in ipairs(dropItemTable)
	do
		local line = math.floor((k - 1) / 4)
		local row = (k - 1)% 4
		v:setPosition(ccp(posX + row * (size.width + 40), posY - line * (size.height + 40)))
		self.battleResultUI:addChild(v)
	end
	
	local middlePixielHeight = 0
	if #dropItemTable == 0 then
		middlePixielHeight = -250
	else
		self.battleResultUI:getChildByName("txt_none"):setVisible(false)
		middlePixielHeight = (math.floor((#dropItemTable - 1) / 4) - 1) * (size.height + 40)
	end
	
	local middleBg = self.battleResultUI:getChildByName("battleResult_new_red_bg9_pic")
	middleBg:setContentSize(CCSizeMake(middleBg:getContentSize().width, middleBg:getContentSize().height + middlePixielHeight))

	-- self.battleResultUI:getChildByName("battleResult_btn_long_yellow"):setPositionY(self.battleResultUI:getChildByName("battleResult_btn_long_yellow"):getPositionY() - middlePixielHeight)
	
	self.battleResultUI:getChildByName("battleResult_btn_long_yellow"):getChildByName("font"):setString(getTextByKey("yes"))
	
	local btnOK = Button:create(self.battleResultUI:getChildByName("battleResult_btn_long_yellow"))
	btnOK:addEventListener(Events.kStart, onLeftButtonClick, self)	
end

function BattleResultPanel:showNewBattleWin(doubleRewardMoudle)
	if self.data.showQuery and self.data.newMissionId then
		self.battleResultUI = self.builder:build("battleResult_new_win_normal2")
	elseif self.data.showQuery and not self.data.newMissionId then
		self.battleResultUI = self.builder:build("battleResult_new_win_normal3")
	else
		self.battleResultUI = self.builder:build("battleResult_new_win_normal")
	end
	
	self.battleResultUI:getChildByName("battleResult_icon_battle_normalwin_sb"):setVisible(false)
	self.battleResultUI:getChildByName("battleResult_icon_battle_bigwin_sb"):setVisible(false)
	self.battleResultUI:getChildByName("battleResult_icon_battle_littlewin_sb"):setVisible(false)
	
	self.battleResultUI:getChildByName("battleResult_frame_card"):setVisible(false)
	self.battleResultUI:getChildByName("battleResult_normal_card_small"):setVisible(false)
	self.battleResultUI:getChildByName("battleResult_bg_card"):setVisible(false)
	self.battleResultUI:getChildByName("boss_reward_item"):setVisible(false)
	
	self.battleResultUI:getChildByName("battleResult_lbl_parameter_add_R_coin"):setVisible(false)
	self.battleResultUI:getChildByName("battleResult_lbl_parameter_add_L_coin"):setVisible(false)
	self.battleResultUI:getChildByName("battleResult_lbl_parameter_add_up"):setVisible(false)
	self.battleResultUI:getChildByName("battleResult_lbl_parameter_add_R_coin_exp"):setVisible(false)
	self.battleResultUI:getChildByName("battleResult_lbl_parameter_add_L_coin_exp"):setVisible(false)
	self.battleResultUI:getChildByName("battleResult_lbl_parameter_add_down"):setVisible(false)
	self.battleResultUI:getChildByName("txt_anything_info"):setVisible(false)
	
	local GameMetaData = MetaManager.game_meta
	if self.data.leftHpRate < GameMetaData.battleSettingConfig.victoryLevelFloor then
		self.battleResultUI:getChildByName("battleResult_icon_battle_littlewin_sb"):setVisible(true)
	elseif self.data.leftHpRate > GameMetaData.battleSettingConfig.victoryLevelTop then
		self.battleResultUI:getChildByName("battleResult_icon_battle_bigwin_sb"):setVisible(true)
	else
		self.battleResultUI:getChildByName("battleResult_icon_battle_normalwin_sb"):setVisible(true)
	end
	
	self.battleResultUI:getChildByName("battleResult_txt_gettrophy"):getChildByName("txt_gettrophy"):setString(getTextByKey("battleResult_acquire"))
	self.battleResultUI:getChildByName("txt_none"):getChildByName("txt"):setString(getTextByKey("battleResult_none"))

	local baseCoin = 0
	local qteCoin = 0
	local baseExp = 0
	local qteExp = 0
	local vipCoin = 0
	
	local dropItemTable = {}
	local ItemRewardTable = {}
	
	if type(self.data.rewards) == "table" then
		for k, v in pairs(self.data.rewards)
		do
			if v.itemType == ResourceEnum.COIN then
				baseCoin = baseCoin + tonumber(v.amount)
			elseif v.itemType == ResourceEnum.EXP then
				baseExp = baseExp + tonumber(v.amount)
			elseif v.itemType == ResourceEnum.CARD then
				table.insert(ItemRewardTable, v)
			elseif v.itemType == ResourceEnum.EQUIP then
				table.insert(ItemRewardTable, v)
			elseif v.itemType == ResourceEnum.PROP then
				table.insert(ItemRewardTable, v)
			elseif v.itemType == ResourceEnum.BEAST_FRAGMENT then
				table.insert(ItemRewardTable, v)
			elseif v.itemType == ResourceEnum.CARD_FRAGMENT then
				table.insert(ItemRewardTable, v)
			elseif v.itemType == ResourceEnum.EQUIP_FRAGMENT then
				table.insert(ItemRewardTable, v)
			elseif v.itemType == ResourceEnum.MysteriousCoins then
				table.insert(ItemRewardTable, v)
			elseif v.itemType == ResourceEnum.ENCHANT_POINT then
				table.insert(ItemRewardTable, v)
			elseif v.itemType == ResourceEnum.ASTRALESSENCE then
				table.insert(ItemRewardTable, v)
			end
		end
	end
	
	if type(self.data.qteRewards) == "table" then
		for k, v in pairs(self.data.qteRewards)
		do
			if v.itemType == ResourceEnum.COIN then
				qteCoin = qteCoin + tonumber(v.amount)
			elseif v.itemType == ResourceEnum.EXP then
				qteExp = qteExp + tonumber(v.amount)
			end
		end
	end
	
	if type(self.data.vipRewards) == "table" then
		for k, v in pairs(self.data.vipRewards)
		do
			if v.itemType == ResourceEnum.COIN then
				vipCoin = vipCoin + tonumber(v.amount)
			end
		end
	end

	--add by zheng.che @ 2014-11-4 原"vip奖励银币"数值要加入到"基础奖励银币"数值里 因为现在vip处改为显示百分比 (qte不变)
	baseCoin = baseCoin + vipCoin

	local qteCoinPosX, qteCoinPosY = self.battleResultUI:getChildByName("battleResult_lbl_parameter_add_down").refCocosObj:getPosition()
	
	local numberLabel
	if qteCoin > 0 then
		numberLabel = CCLabelAtlas:create("." .. tostring(qteCoin), "battle/pic/number_blue.png", 25, 41, 46)
		numberLabel:setPosition(ccp(qteCoinPosX + 60, qteCoinPosY + 5))--解决基本奖励是5位数时 破甲数字重叠问题 右移10->60 modified by zheng.che @ 2014-11-7
		numberLabel:setAnchorPoint( ccp(0, 1) )
		local numberLabel_co = CocosObject.new(numberLabel)
		self.battleResultUI:addChild(numberLabel_co)
		self.qteCoinLabel = numberLabel_co
	end

	-- vip 加成
	local vipLevel = tonumber(DataManager.getCurrUser().vipLevel)
	local vipSetting = MetaManager.vip_setting
	local vipAddPercent = tonumber(vipSetting[vipLevel].coinsByFightAdd)

	if vipAddPercent > 0 then
		if self.qteCoinLabel then
			self.qteCoinLabel:setPositionX(self.qteCoinLabel:getPositionX() - 8)
		end
		self.battleResultUI:getChildByName("txt_vipbouns"):getChildByName("txt"):setString("(VIP" .. tostring(vipLevel) .. "+" .. vipAddPercent*100 .."%".. ")")
	else
		self.battleResultUI:getChildByName("txt_vipbouns"):setVisible(false)
	end

	local middlePixielHeight = 0
	local middleBg = self.battleResultUI:getChildByName("battleResult_new_red_bg9_pic")

	-- 多倍活动加成
	--DOUBLE_REWARD_MODIFY
	if doubleRewardMoudle and Activity_DoubleRewardLayer.getRewardEnableById(doubleRewardMoudle) then
		--双倍活动已开启
		self.battleResultUI:getChildByName("txt_02"):setVisible(true)
		local addPercent = (Activity_DoubleRewardLayer.getRewardMultipleById(doubleRewardMoudle) - 1) * 100
		self.battleResultUI:getChildByName("txt_02"):getChildByName("txt"):setString("("..getTextByKey("activity_doublereward_txt2", {num = addPercent.."%"})..")")--双倍活动+{num}
		-- vip 加成未显示
		if vipAddPercent <= 0 then
			self.battleResultUI:getChildByName("txt_02"):setPositionX(self.battleResultUI:getChildByName("txt_vipbouns"):getPositionX())
		end

		self.battleResultUI:getChildByName("battleResult_txt_getcoin"):getChildByName("font"):setString("+" .. baseCoin)
	else
		--正常显示
		self.battleResultUI:getChildByName("txt_02"):setVisible(false)
		self.battleResultUI:getChildByName("battleResult_txt_getcoin"):getChildByName("font"):setString("+" .. baseCoin)
	end
		
	if baseExp == 0 then
		self.battleResultUI:getChildByName("battleResult_txt_exp_font"):setVisible(false)
		self.battleResultUI:getChildByName("battleResult_txt_getexp"):setVisible(false)
		self.battleResultUI:getChildByName("battleResult_txt_level"):setVisible(false)
		self.battleResultUI:getChildByName("battleResult_txt_icon_playerExp_num"):setVisible(false)
		self.battleResultUI:getChildByName("battleResult_icon_playerExp"):setVisible(false)
		self.battleResultUI:getChildByName("battleResult_icon_hone_exp"):setVisible(false)
		self.battleResultUI:getChildByName("battleResult_bg_home_common"):setVisible(false)
		local Yoffset = 0
		if self.data.showQuery then
			middlePixielHeight = middlePixielHeight -60
			Yoffset = 30
		else
			middlePixielHeight = middlePixielHeight -100
			Yoffset = 50
		end
		self.battleResultUI:getChildByName("txt_vipbouns"):setPositionY(self.battleResultUI:getChildByName("txt_vipbouns"):getPositionY() + Yoffset)
		self.battleResultUI:getChildByName("txt_02"):setPositionY(self.battleResultUI:getChildByName("txt_02"):getPositionY() + Yoffset)
		self.battleResultUI:getChildByName("battleResult_icon_coinevent"):setPositionY(self.battleResultUI:getChildByName("battleResult_icon_coinevent"):getPositionY() + Yoffset)
		self.battleResultUI:getChildByName("battleResult_txt_getcoin"):setPositionY(self.battleResultUI:getChildByName("battleResult_txt_getcoin"):getPositionY() + Yoffset)
		self.battleResultUI:getChildByName("battleResult_lbl_parameter_add_down"):setPositionY(self.battleResultUI:getChildByName("battleResult_lbl_parameter_add_down"):getPositionY() + Yoffset)
		self.battleResultUI:getChildByName("battleResult_lbl_parameter_add_L_coin_exp"):setPositionY(self.battleResultUI:getChildByName("battleResult_lbl_parameter_add_L_coin_exp"):getPositionY() + Yoffset)
		self.battleResultUI:getChildByName("battleResult_lbl_parameter_add_R_coin_exp"):setPositionY(self.battleResultUI:getChildByName("battleResult_lbl_parameter_add_R_coin_exp"):getPositionY() + Yoffset)

		--解决没有exp的时候 破甲奖励银币文字上下错位问题 add by zheg.che @ 2014-11-7
		if numberLabel then
			numberLabel:setPositionY(numberLabel:getPositionY() + Yoffset)
		end
	else
		self.battleResultUI:getChildByName("battleResult_txt_getexp"):getChildByName("font"):setString("+" .. tostring(baseExp))
		local qteExpPosX, qteExpPosY = self.battleResultUI:getChildByName("battleResult_lbl_parameter_add_up").refCocosObj:getPosition()
		if qteExp > 0 then
			local numberLabel = CCLabelAtlas:create("." .. tostring(qteExp), "battle/pic/number_blue.png", 25, 41, 46)
			numberLabel:setPosition(ccp(qteExpPosX + 50, qteExpPosY + 5))--解决基本奖励是5位数时 破甲数字重叠问题 右移50 modified by zheng.che @ 2014-11-7
			numberLabel:setAnchorPoint( ccp(0, 1) )
			local numberLabel_co = CocosObject.new(numberLabel)
			self.battleResultUI:addChild(numberLabel_co)
		end
		
		local curUserInfo = DataManager.getCurrUser()
		local curExp = curUserInfo.exp
		local fullExp = MetaManager.user_level[curUserInfo.level].exp

		local oldLevel = curUserInfo.level
		local totalAchieveExp = tonumber(qteExp) + tonumber(baseExp)
		local totalNeedExp = tonumber(curExp)
		local oldfullExp = fullExp
		while totalAchieveExp > totalNeedExp do
			totalNeedExp = totalNeedExp + MetaManager.user_level[oldLevel - 1].exp
			oldLevel = oldLevel - 1
			oldfullExp = MetaManager.user_level[oldLevel].exp
		end
		local oldExp = totalNeedExp - totalAchieveExp

		local expPercentage = tonumber(oldExp) / tonumber(oldfullExp) * 100
		self.battleResultUI:getChildByName("battleResult_txt_icon_playerExp_num"):getChildByName("font"):setString(tostring(oldExp) .. "/" .. tostring(oldfullExp))
		self.battleResultUI:getChildByName("battleResult_txt_level"):getChildByName("txt_level"):setString("Lv." .. oldLevel)
		local progress = ProgressBar:create(self.battleResultUI:getChildByName("battleResult_icon_playerExp"))
		self.progress = progress
		self.progress:setPercentage(expPercentage)

		local tempLayer = Layer:create()
		tempLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
		local function onTouch(event, x, y)
			if event == CCTOUCHBEGAN then
				return true
			else
				return
			end
		end
		tempLayer:registerScriptTouchHandler(onTouch, false, -100, true)
		tempLayer:setTouchEnabled(true)
		self.container:addChild(tempLayer)

		local function onPlayLvUpAnim( )
			tempLayer:removeFromParentAndCleanup(true)
			local levelLabel = self.battleResultUI:getChildByName("battleResult_txt_level"):getChildByName("txt_level")
		    local expLabel = self.battleResultUI:getChildByName("battleResult_txt_icon_playerExp_num"):getChildByName("font")
		    local expBar = self.progress
		    doUIActionForAddedExp(levelLabel, expLabel, expBar, nil)
		end 

	  	local actionArray = CCArray:create()
		actionArray:addObject(CCDelayTime:create(0.5))
		actionArray:addObject(CCCallFuncN:create(onPlayLvUpAnim))
		self:runAction(CCSequence:create(actionArray))	

	end
	
	self.battleResultUI:getChildByName("battleResult_pattern_formation_line"):setPositionY(self.battleResultUI:getChildByName("battleResult_pattern_formation_line"):getPositionY() - middlePixielHeight)
	self.battleResultUI:getChildByName("battleResult_txt_gettrophy"):setPositionY(self.battleResultUI:getChildByName("battleResult_txt_gettrophy"):getPositionY() - middlePixielHeight)
	self.battleResultUI:getChildByName("txt_none"):setPositionY(self.battleResultUI:getChildByName("txt_none"):getPositionY() - middlePixielHeight)
	self.battleResultUI:getChildByName("battleResult_normal_card_small"):setPositionY(self.battleResultUI:getChildByName("battleResult_normal_card_small"):getPositionY() - middlePixielHeight)
	
	local posX, posY = self.battleResultUI:getChildByName("battleResult_normal_card_small").refCocosObj:getPosition()
	local size = self.battleResultUI:getChildByName("battleResult_normal_card_small").refCocosObj:getContentSize()

	--解决奖励多于4个 并且此时没有exp奖励(满级)时 两行奖励显示位置过低出框问题 SK-3816 add by zheng.che @ 2014-11-7
	addItemLayerByDrops(self.battleResultUI , ItemRewardTable, 53, 266 - middlePixielHeight)

	
	-- for k,v in ipairs(dropItemTable)
	-- do
	-- 	local line = math.floor((k - 1) / 4)
	-- 	local row = (k - 1)% 4
	-- 	v:setPosition(ccp(posX + row * (size.width + 40), posY - line * (size.height + 40)))
	-- 	itemLayer:addChild(v)
	-- end

	if #ItemRewardTable == 0 then
		middlePixielHeight = middlePixielHeight - 250
	elseif #ItemRewardTable > 0 and #ItemRewardTable <= 4 then
		self.battleResultUI:getChildByName("txt_none"):setVisible(false)
		local itemHeight = (#ItemRewardTable > 8) and 8 or #ItemRewardTable
		middlePixielHeight = middlePixielHeight + (math.floor((itemHeight - 1) / 4) - 1) * 164.5
	else
		self.battleResultUI:getChildByName("txt_none"):setVisible(false)
		local itemHeight = (#ItemRewardTable > 8) and 8 or #ItemRewardTable
		middlePixielHeight = middlePixielHeight + (math.floor((itemHeight - 1) / 4) - 1) * 164.5 - 40
	end
	
	--middleBg:setContentSize(CCSizeMake(middleBg:getContentSize().width, middleBg:getContentSize().height + middlePixielHeight))
	
	if self.data.showQuery then
		local text = ""
		if SELF.data.newMissionId then
			text = Localization:getInstance():getText("stage_stageClearedTxt", {stagename = CountryManager:sharedManager():getMissionName(SELF.data.newMissionId)})
		end
		self.battleResultUI:getChildByName("txt_cy_1"):getChildByName("txt"):setString(text)
		
		self.battleResultUI:getChildByName("battleResult_btn_chapterSelect"):getChildByName("txt"):setString(getTextByKey("stage_backToSelectBtn"))
		local btnOK = Button:create(self.battleResultUI:getChildByName("battleResult_btn_chapterSelect"))
		btnOK:addEventListener(Events.kStart, onLeftButtonClick, self)	
		-- self.battleResultUI:getChildByName("battleResult_btn_chapterSelect"):setPositionY(self.battleResultUI:getChildByName("battleResult_btn_chapterSelect"):getPositionY() - middlePixielHeight)
		
		self.battleResultUI:getChildByName("battleResult_btn_goon"):getChildByName("txt"):setString(getTextByKey("stageRemind_continueBtn"))
		local btnOK = Button:create(self.battleResultUI:getChildByName("battleResult_btn_goon"))
		btnOK:addEventListener(Events.kStart, onLeftButtonClick, "btn_goon")	
		-- self.battleResultUI:getChildByName("battleResult_btn_goon"):setPositionY(self.battleResultUI:getChildByName("battleResult_btn_goon"):getPositionY() - middlePixielHeight)
	else
		self.battleResultUI:getChildByName("battleResult_btn_long_yellow"):getChildByName("font"):setString(getTextByKey("yes"))
		local btnOK = Button:create(self.battleResultUI:getChildByName("battleResult_btn_long_yellow"))
		btnOK:addEventListener(Events.kStart, onLeftButtonClick, self)	
		-- self.battleResultUI:getChildByName("battleResult_btn_long_yellow"):setPositionY(self.battleResultUI:getChildByName("battleResult_btn_long_yellow"):getPositionY() - middlePixielHeight)
	end
	

end

function BattleResultPanel:showNewBattleLose()
	self.battleResultUI = self.builder:build("battleRsult_new_lose_normal")
	addReplaceSceneButtons(self.battleResultUI , self.resultType)
	
	self.battleResultUI:getChildByName("battleResult_txt_battleResult_infomation"):getChildByName("txt_battleResult_infomation"):setString(getTextByKey("battleResult_lostTips2"))
	self.battleResultUI:getChildByName("battleResult_txt_battleResult_information_title"):getChildByName("txt_battleResult_information_title"):setString(getTextByKey("battleResult_lostTips1"))
	
	self.battleResultUI:getChildByName("battleResult_icon_battle_littlelost_sb"):setVisible(false)
	self.battleResultUI:getChildByName("battleResult_icon_battle_normallost_sb"):setVisible(false)
	self.battleResultUI:getChildByName("battleResult_lbl_lose"):setVisible(false)
	
	local GameMetaData = MetaManager.game_meta
	if self.data.leftHpRate < GameMetaData.battleSettingConfig.victoryLevelFloor then
		self.battleResultUI:getChildByName("battleResult_icon_battle_littlelost_sb"):setVisible(true)
	elseif self.data.leftHpRate > GameMetaData.battleSettingConfig.victoryLevelTop then
		self.battleResultUI:getChildByName("battleResult_lbl_lose"):setVisible(true)
	else
		self.battleResultUI:getChildByName("battleResult_icon_battle_normallost_sb"):setVisible(true)
	end
	
	local btnOK = Button:create(self.battleResultUI:getChildByName("battleResult_btn_long_yellow_sure"))
	btnOK:addEventListener(Events.kStart, onLeftButtonClick, self)	
	
	self.battleResultUI:getChildByName("battleResult_btn_long_yellow_sure"):getChildByName("font"):setString(getTextByKey("yes"))
	-- self.battleResultUI:getChildByName("battleResult_btn_long_yellow_gostrengthen"):getChildByName("font"):setString(getTextByKey("battleResult_strengthen"))
	
	-- local btnOK = Button:create(self.battleResultUI:getChildByName("battleResult_btn_long_yellow_gostrengthen"))
	-- btnOK:addEventListener(Events.kStart, onRightButtonClick, self)	
end

function BattleResultPanel:showNewRobWin()
	self.battleResultUI = self.builder:build("battleResult_new_win_rob")
	
	self.battleResultUI:getChildByName("battleResult_icon_battle_bigwin_sb"):setVisible(false)
	self.battleResultUI:getChildByName("battleResult_icon_battle_littlewin_sb"):setVisible(false)
	self.battleResultUI:getChildByName("battleResult_icon_battle_normalwin_sb"):setVisible(false)
	self.battleResultUI:getChildByName("battleResult_lbl_parameter_add_R_coin"):setVisible(false)
	self.battleResultUI:getChildByName("battleResult_lbl_parameter_add_L_coin"):setVisible(false)
	self.battleResultUI:getChildByName("battleResult_lbl_parameter_add_up"):setVisible(false)
	
	self.battleResultUI:getChildByName("txt_none"):setVisible(false)
	
	local GameMetaData = MetaManager.game_meta
	if self.data.leftHpRate < GameMetaData.battleSettingConfig.victoryLevelFloor then
		self.battleResultUI:getChildByName("battleResult_icon_battle_littlewin_sb"):setVisible(true)
	elseif self.data.leftHpRate > GameMetaData.battleSettingConfig.victoryLevelTop then
		self.battleResultUI:getChildByName("battleResult_icon_battle_bigwin_sb"):setVisible(true)
	else
		self.battleResultUI:getChildByName("battleResult_icon_battle_normalwin_sb"):setVisible(true)
	end
	
	local coin = 0
	local beastFragmentData = nil 
	if type(self.data.rewards) == "table" then
		for k,v in pairs(self.data.rewards)
		do
			if v.itemType == ResourceEnum.COIN then
				coin = tonumber(v.amount) + coin
			elseif v.itemType == ResourceEnum.BEAST_FRAGMENT then
				beastFragmentData = v
			end
		end
	end
	
	self.battleResultUI:getChildByName("boss_reward_item"):setVisible(false)
	
	self.battleResultUI:getChildByName("battleResult_btn_long_yellow"):getChildByName("font"):setString(getTextByKey("yes"))
	self.battleResultUI:getChildByName("battleResult_btn_long_yellow_mid"):getChildByName("font"):setString(getTextByKey("yes"))
	self.battleResultUI:getChildByName("battleResult_btn_long_yellow_more"):getChildByName("font"):setString(getTextByKey("beastRob_repeatBtn"))
	
	
	if beastFragmentData then
		self.battleResultUI:getChildByName("battleResult_btn_long_yellow"):setVisible(false)
		self.battleResultUI:getChildByName("battleResult_btn_long_yellow_more"):setVisible(false)
		self.battleResultUI:getChildByName("boss_reward_item"):setVisible(true)
		self.battleResultUI:getChildByName("txt_anything_info"):setVisible(false)
		self.battleResultUI:getChildByName("boss_reward_item"):getChildByName("txt_item_quantity"):setVisible(false)
		self.battleResultUI:getChildByName("boss_reward_item"):getChildByName("frame_card"):setVisible(false)
		self.battleResultUI:getChildByName("boss_reward_item"):getChildByName("normal_card_small"):setVisible(false)
		self.battleResultUI:getChildByName("boss_reward_item"):getChildByName("bg_card"):setVisible(false)
		
		local posX, posY = self.battleResultUI:getChildByName("boss_reward_item"):getChildByName("normal_card_small").refCocosObj:getPosition()
		local size = self.battleResultUI:getChildByName("boss_reward_item"):getChildByName("normal_card_small").refCocosObj:getContentSize()
		local function getBeastFragmentSpriteByBeastInfo(data)
			return "#" .. MetaManager.beast_fragment[data.metaId].icon .. ".png"
		end
		local fragmentSprite = Sprite:create(getBeastFragmentSpriteByBeastInfo(beastFragmentData))
		fragmentSprite:setScale(130 / fragmentSprite:getContentSize().width)
		fragmentSprite:setPosition(ccp(posX, posY))
		self.battleResultUI:getChildByName("boss_reward_item"):addChild(fragmentSprite)		
		
		print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~2")
		local TxtPosX, TxtPosY = self.battleResultUI:getChildByName("boss_reward_item"):getChildByName("txt_item_name").refCocosObj:getPosition()
		self.battleResultUI:getChildByName("boss_reward_item"):getChildByName("txt_item_name"):setPositionX(TxtPosX-5)
		self.battleResultUI:getChildByName("boss_reward_item"):getChildByName("txt_item_name"):getChildByName("txt"):setString(BeastScene.getBeastFragmentNameByData(beastFragmentData))
		
		local btnOK = Button:create(self.battleResultUI:getChildByName("battleResult_btn_long_yellow_mid"))
		btnOK:addEventListener(Events.kStart, onLeftButtonClick, self)	
	elseif self.data.enemyHasFragment then
		self.battleResultUI:getChildByName("battleResult_btn_long_yellow_mid"):setVisible(false)
		self.battleResultUI:getChildByName("battleResult_txt_gettrophy"):setVisible(false)
		self.battleResultUI:getChildByName("txt_anything_info"):getChildByName("txt"):setString(getTextByKey("beastRob_failure"))
		local btnOK = Button:create(self.battleResultUI:getChildByName("battleResult_btn_long_yellow"))
		btnOK:addEventListener(Events.kStart, onLeftButtonClick, self)	
		local btnOK = Button:create(self.battleResultUI:getChildByName("battleResult_btn_long_yellow_more"))
		btnOK:addEventListener(Events.kStart, onMoreButtonClick, self)	
	else
		self.battleResultUI:getChildByName("battleResult_txt_gettrophy"):setVisible(false)
		self.battleResultUI:getChildByName("battleResult_btn_long_yellow"):setVisible(false)
		self.battleResultUI:getChildByName("battleResult_btn_long_yellow_more"):setVisible(false)
		self.battleResultUI:getChildByName("txt_anything_info"):getChildByName("txt"):setString(getTextByKey("beastRob_noFragment"))
		local btnOK = Button:create(self.battleResultUI:getChildByName("battleResult_btn_long_yellow_mid"))
		btnOK:addEventListener(Events.kStart, onLeftButtonClick, self)	
	end

	--DOUBLE_REWARD_MODIFY
	if Activity_DoubleRewardLayer.getRewardEnableById(Activity_DoubleRewardLayer.MOUDLE_BEAST) then
		--双倍活动已开启
		self.battleResultUI:getChildByName("txt_02"):setVisible(true)
		local addPercent = (Activity_DoubleRewardLayer.getRewardMultipleById(Activity_DoubleRewardLayer.MOUDLE_BEAST) - 1) * 100
		self.battleResultUI:getChildByName("txt_02"):getChildByName("txt"):setString("("..getTextByKey("activity_doublereward_txt2", {num = addPercent.."%"})..")")--双倍活动+{num}
		self.battleResultUI:getChildByName("battleResult_txt_getcoin"):getChildByName("font"):setString("+" .. tostring(coin))
	else
		--正常显示
		self.battleResultUI:getChildByName("txt_02"):setVisible(false)
		self.battleResultUI:getChildByName("battleResult_txt_getcoin"):getChildByName("font"):setString("+" .. tostring(coin))
	end
	
	self.battleResultUI:getChildByName("battleResult_txt_gettrophy"):getChildByName("txt_gettrophy"):setString(getTextByKey("battleResult_acquire"))
	
end

function BattleResultPanel:showNewRobLose()
	self.battleResultUI = self.builder:build("battleRsult_new_lose_rob")
	addReplaceSceneButtons(self.battleResultUI , self.resultType)
	
	self.battleResultUI:getChildByName("battleResult_txt_battleResult_infomation"):getChildByName("txt_battleResult_infomation"):setString(getTextByKey("battleResult_lostTips2"))
	
	self.battleResultUI:getChildByName("battleResult_icon_battle_littlelost_sb"):setVisible(false)
	self.battleResultUI:getChildByName("battleResult_icon_battle_normallost_sb"):setVisible(false)
	self.battleResultUI:getChildByName("battleResult_lbl_lose"):setVisible(false)
	
	local GameMetaData = MetaManager.game_meta
	if self.data.leftHpRate < GameMetaData.battleSettingConfig.victoryLevelFloor then
		self.battleResultUI:getChildByName("battleResult_icon_battle_littlelost_sb"):setVisible(true)
	elseif self.data.leftHpRate > GameMetaData.battleSettingConfig.victoryLevelTop then
		self.battleResultUI:getChildByName("battleResult_lbl_lose"):setVisible(true)
	else
		self.battleResultUI:getChildByName("battleResult_icon_battle_normallost_sb"):setVisible(true)
	end
	
	local btnOK = Button:create(self.battleResultUI:getChildByName("battleResult_btn_long_yellow_sure"))
	btnOK:addEventListener(Events.kStart, onLeftButtonClick, self)	
	
	self.battleResultUI:getChildByName("battleResult_btn_long_yellow_sure"):getChildByName("font"):setString(getTextByKey("yes"))
	-- self.battleResultUI:getChildByName("battleResult_btn_long_yellow_gostrengthen"):getChildByName("font"):setString(getTextByKey("battleResult_strengthen"))
	
	-- local btnOK = Button:create(self.battleResultUI:getChildByName("battleResult_btn_long_yellow_gostrengthen"))
	-- btnOK:addEventListener(Events.kStart, onRightButtonClick, self)	
	
	local coin = 0
	if type(self.data.requsites) == "table" then
		for k,v in pairs(self.data.requsites)
		do
			if v.itemType == ResourceEnum.COIN then
				coin = tonumber(v.amount) + coin
			end
		end
	end
	self.battleResultUI:getChildByName("battleResult_txt_getcoin"):getChildByName("font"):setString(tostring(coin))
end

function BattleResultPanel:showGeneralBossPanel()

	local pos = self.battleResultUI:getChildByName("battleResult_txt_bossdamege1"):getPosition()
	self.battleResultUI:getChildByName("battleResult_txt_bossdamege1"):setPosition(ccp(pos.x-88,pos.y))
	pos = self.battleResultUI:getChildByName("battleResult_txt_bossdamege2"):getPosition()
	self.battleResultUI:getChildByName("battleResult_txt_bossdamege2"):setPosition(ccp(pos.x-88,pos.y))
	pos = self.battleResultUI:getChildByName("battleResult_txt_bossdamege_font"):getPosition()
	self.battleResultUI:getChildByName("battleResult_txt_bossdamege_font"):setPosition(ccp(pos.x-88,pos.y))

	self.battleResultUI:getChildByName("battleResult_txt_bossdamege1"):getChildByName("txt"):setString(getTextByKey("worldBoss_battleResultDamage1"))
	self.battleResultUI:getChildByName("battleResult_txt_bossdamege2"):getChildByName("txt"):setString(getTextByKey("worldBoss_battleResultDamage2"))
	local damage = 0
	if self.data.totalDamage then
		damage = self.data.totalDamage
	end
	self.battleResultUI:getChildByName("battleResult_txt_bossdamege_font"):getChildByName("txt"):setString(tostring(damage))
	
	local baseCoin = 0
	
	local dropItemTable = {}
	
	if type(self.data.rewards) == "table" then
		for k, v in pairs(self.data.rewards)
		do
			if v.itemType == ResourceEnum.COIN then
				baseCoin = baseCoin + tonumber(v.amount)
			elseif v.itemType == ResourceEnum.CARD then
				local canonCard = getHeadIconCanonCardByMetaId( v.metaId)
				table.insert(dropItemTable, canonCard)
			elseif v.itemType == ResourceEnum.EQUIP then
				local canonItem = CanonItem:create()
				canonItem:loadByMetaId(v.metaId)
				canonItem:setScale(130 / 144)
				table.insert(dropItemTable, canonItem)
			elseif v.itemType == ResourceEnum.PROP then
				local canonItem = CanonItem:create()
				canonItem:loadByMetaId(v.metaId)
				canonItem:setScale(130 / 144)
				local amount = tonumber(v.amount)
				if not amount then
					amount = 1
				end
				local amountText = ArtTextField:create("x" .. amount, nil, 25)
				amountText:setAnchorPoint(ccp(1, 0))
				amountText:setPosition(ccp(35, -50))
				canonItem:addChild(amountText)
				table.insert(dropItemTable, canonItem)
			elseif v.itemType == ResourceEnum.BEAST_FRAGMENT then
				local canonItem = CanonItem:create()
				local fragmentSprite = Sprite:create("#" .. MetaManager.beast_fragment[v.metaId].icon .. ".png")
				fragmentSprite:setScale(130 / fragmentSprite:getContentSize().width)
				canonItem:addChild(fragmentSprite)
				canonItem:setScale(130 / 144)
				table.insert(dropItemTable, canonItem)
			end
		end
	end
	
	self.battleResultUI:getChildByName("battleResult_txt_getcoin"):getChildByName("font"):setString("+" .. baseCoin)
	self.battleResultUI:getChildByName("battleResult_txt_gettrophy"):getChildByName("txt_gettrophy"):setString(getTextByKey("battleResult_acquire"))
	self.battleResultUI:getChildByName("txt_none"):getChildByName("txt"):setString(getTextByKey("battleResult_none"))
	
	self.battleResultUI:getChildByName("battleResult_btn_long_yellow"):getChildByName("font"):setString(getTextByKey("yes"))
	
	local btnOK = Button:create(self.battleResultUI:getChildByName("battleResult_btn_long_yellow"))
	btnOK:addEventListener(Events.kStart, onLeftButtonClick, self)	
	
	
	self.battleResultUI:getChildByName("battleResult_normal_card_small"):setVisible(false)
	
	local posX, posY = self.battleResultUI:getChildByName("battleResult_normal_card_small").refCocosObj:getPosition()
	local size = self.battleResultUI:getChildByName("battleResult_normal_card_small").refCocosObj:getContentSize()
	
	for k,v in ipairs(dropItemTable)
	do
		local line = math.floor((k - 1) / 4)
		local row = (k - 1)% 4
		v:setPosition(ccp(posX + row * (size.width + 40) + 220, posY - line * (size.height + 40) - 60))
		self.battleResultUI:addChild(v)
	end

	local middlePixielHeight = 0
	if #dropItemTable == 0 then
		middlePixielHeight = -30
	else
		self.battleResultUI:getChildByName("txt_none"):setVisible(false)
		middlePixielHeight = (math.floor((#dropItemTable - 1) / 4)) * (size.height + 40)
	end
	local middleBg = self.battleResultUI:getChildByName("battleResult_new_red_bg9_pic")
	middleBg:setContentSize(CCSizeMake(middleBg:getContentSize().width, middleBg:getContentSize().height + middlePixielHeight))
	

	-- self.battleResultUI:getChildByName("battleResult_btn_long_yellow"):setPositionY(self.battleResultUI:getChildByName("battleResult_btn_long_yellow"):getPositionY() - middlePixielHeight)
	--]]
end

function BattleResultPanel:showNewBossWin()
	self.battleResultUI = self.builder:build("battleRsult_boss_win")
	
	self.battleResultUI:getChildByName("battleResult_txt_bossdamege3"):getChildByName("txt"):setString(getTextByKey("worldBoss_battleResultKill"))
	self:showGeneralBossPanel()
	
end

function BattleResultPanel:showNewBossLose()
	self.battleResultUI = self.builder:build("battleRsult_boss_result")
	self:showGeneralBossPanel()	
end

function BattleResultPanel:showMultiBossWin()
  self.battleResultUI = self.builder:build("battleResult_monster_nian_over")
  
  self.battleResultUI:getChildByName("txt_bossdamege1"):getChildByName("txt"):setString(getTextByKey("activityNian_battleResult_Txt1"))
  self.battleResultUI:getChildByName("txt_bossdamege_font"):getChildByName("txt"):setString(tostring(self.data.damage))
  self.battleResultUI:getChildByName("txt_bossdamege2"):getChildByName("txt"):setString(getTextByKey("activityNian_battleResult_Txt2"))
  self.battleResultUI:getChildByName("txt_bossdamege3"):getChildByName("txt"):setString(getTextByKey("activityNian_battleResult_winTxt"))
  local aDisplay = self.battleResultUI:getChildByName("normal_card_small")
  aDisplay:setVisible(false)
  local aIconDisplay = Sprite:create("Item/Picture/prop_tail0.png")
  aIconDisplay:setPositionX(aDisplay:getPositionX())
  aIconDisplay:setPositionY(aDisplay:getPositionY())
  aIconDisplay:setScale(0.5)
  self.battleResultUI:addChildAt(aIconDisplay, 10)
  self.battleResultUI:getChildByName("txt_bossdamege4"):getChildByName("txt"):setString(string.format("+%d", self.data.pointReward))
  self.battleResultUI:getChildByName("battleResult_txt_gettrophy"):getChildByName("txt_gettrophy"):setString(getTextByKey("battleResult_acquire"))
  
	local dropItemTable = {}
	if type(self.data.rewards) == "table" then
		for k, v in pairs(self.data.rewards)
		do
			if v.itemType == ResourceEnum.CARD then
				local canonCard = getHeadIconCanonCardByMetaId( v.metaId)
				table.insert(dropItemTable, canonCard)
			elseif v.itemType == ResourceEnum.EQUIP then
				local canonItem = CanonItem:create()
				canonItem:loadByMetaId(v.metaId)
				canonItem:setScale(130 / 144)
				table.insert(dropItemTable, canonItem)
			elseif v.itemType == ResourceEnum.PROP then
				local canonItem = CanonItem:create()
				canonItem:loadByMetaId(v.metaId)
				canonItem:setScale(130 / 144)
				local amount = tonumber(v.amount)
				if not amount then
					amount = 1
				end
				local amountText = ArtTextField:create("x" .. amount, nil, 25)
				amountText:setAnchorPoint(ccp(1, 0))
				amountText:setPosition(ccp(35, -50))
				canonItem:addChild(amountText)
				table.insert(dropItemTable, canonItem)
			end
		end
	end
  self.battleResultUI:getChildByName("battleResult_normal_card_small"):setVisible(false)
	local posX, posY = self.battleResultUI:getChildByName("battleResult_normal_card_small").refCocosObj:getPosition()
	local size = self.battleResultUI:getChildByName("battleResult_normal_card_small").refCocosObj:getContentSize()
  for k,v in ipairs(dropItemTable)
	do
		local line = math.floor((k - 1) / 4)
		local row = (k - 1)% 4
		v:setPosition(ccp(posX + row * (size.width + 40), posY - line * (size.height + 40)))
		self.battleResultUI:addChild(v)
	end
  
  self.battleResultUI:getChildByName("battleResult_btn_long_yellow"):getChildByName("font"):setString(getTextByKey("yes"))
  local btnOK = Button:create(self.battleResultUI:getChildByName("battleResult_btn_long_yellow"))
  btnOK:addEventListener(Events.kStart, onLeftButtonClick, self)
end

function BattleResultPanel:showMultiBossLose()
  self.battleResultUI = self.builder:build("battleResult_monster_nian_on")
  
  self.battleResultUI:getChildByName("txt_bossdamege1"):getChildByName("txt"):setString(getTextByKey("activityNian_battleResult_Txt1"))
  self.battleResultUI:getChildByName("txt_bossdamege_font"):getChildByName("txt"):setString(tostring(self.data.damage))
  self.battleResultUI:getChildByName("txt_bossdamege2"):getChildByName("txt"):setString(getTextByKey("activityNian_battleResult_Txt2"))
  self.battleResultUI:getChildByName("txt_bossdamege3"):getChildByName("txt"):setString(getTextByKey("activityNian_battleResult_loseTxt"))
  local aDisplay = self.battleResultUI:getChildByName("normal_card_small")
  aDisplay:setVisible(false)
  local aIconDisplay = Sprite:create("Item/Picture/prop_tail0.png")
  aIconDisplay:setPositionX(aDisplay:getPositionX())
  aIconDisplay:setPositionY(aDisplay:getPositionY())
  aIconDisplay:setScale(0.5)
  self.battleResultUI:addChildAt(aIconDisplay, 10)
  self.battleResultUI:getChildByName("txt_bossdamege4"):getChildByName("txt"):setString(string.format("+%d", self.data.pointReward))
  
  self.battleResultUI:getChildByName("battleResult_btn_long_yellow"):getChildByName("font"):setString(getTextByKey("yes"))
  local btnOK = Button:create(self.battleResultUI:getChildByName("battleResult_btn_long_yellow"))
  btnOK:addEventListener(Events.kStart, onLeftButtonClick, self)	
end

function BattleResultPanel:showNewBabelWin()
	self.battleResultUI = self.builder:build("battleRsult_new_towerBabel_win")
	
	local victoryStarsBonus = 1
	
	self.battleResultUI:getChildByName("battleResult_icon_vs_bigwin_sb"):setVisible(false)
	self.battleResultUI:getChildByName("battleResult_icon_vs_littlewin_sb"):setVisible(false)
	self.battleResultUI:getChildByName("battleResult_icon_vs_normalwin_sb"):setVisible(false)
	
	local GameMetaData = MetaManager.game_meta
	if self.data.leftHpRate < GameMetaData.battleSettingConfig.victoryLevelFloor then
		self.battleResultUI:getChildByName("battleResult_icon_vs_littlewin_sb"):setVisible(true)
		victoryStarsBonus = 1
	elseif self.data.leftHpRate > GameMetaData.battleSettingConfig.victoryLevelTop then
		self.battleResultUI:getChildByName("battleResult_icon_vs_bigwin_sb"):setVisible(true)
		victoryStarsBonus = 3
	else
		self.battleResultUI:getChildByName("battleResult_icon_vs_normalwin_sb"):setVisible(true)
		victoryStarsBonus = 2
	end
	
	self.battleResultUI:getChildByName("txt_towerBabel_win_other2"):getChildByName("txt"):setString(tostring(victoryStarsBonus) .. "X" .. self.data.selectDifficult)
	self.battleResultUI:getChildByName("txt_towerBabel_win_other"):getChildByName("txt"):setString(getTextByKey("skyTower_difficulty_star"))
	self.battleResultUI:getChildByName("txt_towerBabel_lose_value"):getChildByName("txt"):setString(tostring(self.data.currTotalStars))
	self.battleResultUI:getChildByName("txt_towerBabel_win4"):getChildByName("txt"):setString(getTextByKey("skyTower_battleResult_starSum"))
	self.battleResultUI:getChildByName("txt_towerBabel_winm_1"):getChildByName("txt"):setString(getTextByKey("skyTower_battleResult_top1"))
	self.battleResultUI:getChildByName("txt_towerBabel_winm_2"):getChildByName("txt"):setString(getTextByKey("skyTower_battleResult_top2"))

	if not self.data.clearNewBabel then
		self.battleResultUI:getChildByName("txt_towerBabel_winm_1"):setVisible(false)
		self.battleResultUI:getChildByName("txt_towerBabel_winm_2"):setVisible(false)
	end
	
	self.battleResultUI:getChildByName("battleResult_btn_long_yellow"):getChildByName("font"):setString(getTextByKey("yes"))
	local btnOK = Button:create(self.battleResultUI:getChildByName("battleResult_btn_long_yellow"))
	btnOK:addEventListener(Events.kStart, onLeftButtonClick, self)
	
	local textLine = 1
	local rewardLeftAmount
	local buffLeftAmount
	for i = self.data.currFloor, table.getn(MetaManager.sky_tower_level) do
		if not rewardLeftAmount and (MetaManager.sky_tower_level[i].haveReward == 1) then
			rewardLeftAmount = i - self.data.currFloor
		end
		if not buffLeftAmount and MetaManager.sky_tower_level[i + 1] and (MetaManager.sky_tower_level[i + 1].haveBuff == 1) then
			buffLeftAmount = i - self.data.currFloor
		end
		if buffLeftAmount and rewardLeftAmount then
			break;
		end
	end
	
	local function setAttentionText(text1, text2, text3)
		local text1Name = "txt_towerBabel_win1"
		local text2Name = "txt_towerBabel_win2"
		local text3Name = "txt_towerBabel_win3"
		if textLine > 1 then
			text1Name = text1Name .. "_" .. textLine
			text2Name = text2Name .. "_" .. textLine
			text3Name = text3Name .. "_" .. textLine
		end
		self.battleResultUI:getChildByName(text1Name):getChildByName("txt"):setString(text1)
		self.battleResultUI:getChildByName(text2Name):getChildByName("txt"):setString(text2)
		self.battleResultUI:getChildByName(text3Name):getChildByName("txt"):setString(text3)
		textLine = textLine + 1
	end
	
	if rewardLeftAmount then
		setAttentionText(getTextByKey("skyTower_battleResult_reward1"), tostring(rewardLeftAmount), getTextByKey("skyTower_battleResult_reward2"))
	end
	
	if buffLeftAmount then
		setAttentionText(getTextByKey("skyTower_battleResult_buff1"), tostring(buffLeftAmount), getTextByKey("skyTower_battleResult_buff2"))
	end
	
	if self.data.firstTimeBigWin then
		setAttentionText(getTextByKey("skyTower_battleResult_skip1"), tostring(self.data.currFloor), getTextByKey("skyTower_battleResult_skip2"))
	end
	
	local middlePixielHeight = (textLine - 4) * 65
	
	if self.data.clearNewBabel then
		self.battleResultUI:getChildByName("txt_towerBabel_winm_1"):setPositionY(self.battleResultUI:getChildByName("txt_towerBabel_winm_1"):getPositionY() - middlePixielHeight - 20)
		self.battleResultUI:getChildByName("txt_towerBabel_winm_2"):setPositionY(self.battleResultUI:getChildByName("txt_towerBabel_winm_2"):getPositionY() - middlePixielHeight - 20)
		middlePixielHeight = middlePixielHeight + 100
	end
	
	local middleBg = self.battleResultUI:getChildByName("battleResult_new_red_bg9_pic")
	middleBg:setContentSize(CCSizeMake(middleBg:getContentSize().width, middleBg:getContentSize().height + middlePixielHeight))
	
	self.battleResultUI:getChildByName("battleResult_btn_long_yellow"):setPositionY(self.battleResultUI:getChildByName("battleResult_btn_long_yellow"):getPositionY() - middlePixielHeight)

	while textLine < 4 do
		setAttentionText("", "", "")
	end
end

function BattleResultPanel:showNewBabelLose()
	self.battleResultUI = self.builder:build("battleRsult_new_towerBabel_lose")
		
	self.battleResultUI:getChildByName("battleResult_icon_battle_littlelost_sb"):setVisible(false)
	self.battleResultUI:getChildByName("battleResult_icon_battle_normallost_sb"):setVisible(false)
	self.battleResultUI:getChildByName("battleResult_lbl_lose"):setVisible(false)
	self.battleResultUI:getChildByName("battleResult_btn_long_yellow_sure"):setVisible(false)
	
	local GameMetaData = MetaManager.game_meta
	if self.data.leftHpRate < GameMetaData.battleSettingConfig.victoryLevelFloor then
		self.battleResultUI:getChildByName("battleResult_icon_battle_littlelost_sb"):setVisible(true)
	elseif self.data.leftHpRate > GameMetaData.battleSettingConfig.victoryLevelTop then
		self.battleResultUI:getChildByName("battleResult_lbl_lose"):setVisible(true)
	else
		self.battleResultUI:getChildByName("battleResult_icon_battle_normallost_sb"):setVisible(true)
	end

	local function onToBottom( evt )
		local function onToBottomSucceed( data )
			-- onLeftButtonClick(evt)
			local function onGetSkyTowerInfoSucceed( success )
				onLeftButtonClick(evt)
			end
			generalSendGetSkyTowerInfoRequest(onGetSkyTowerInfoSucceed , nil , nil)
		end
		local function onToBottomFailed( data )
			-- body
		end
		local request = ResetClimbTowerRequest.new( {type = 0}, rpc.SendingPriority.kHigh )
		request:addEventListener( RequestNotifyEnum.ResetClimbTowerSucceed, onToBottomSucceed )
		request:addEventListener( RequestNotifyEnum.ResetClimbTowerFailed, onToBottomFailed )
		request:start()
	end

	local function onContinueClimb( evt )
		local function onContinueClimbSucceed( data )
			-- onRightButtonClick(evt)
			local function onGetSkyTowerInfoSucceed( success )
				onRightButtonClick(evt)
			end
			generalSendGetSkyTowerInfoRequest(onGetSkyTowerInfoSucceed , nil , nil)
		end
		local function onContinueClimbFailed( data )
		end
		local request = ResetClimbTowerRequest.new( {type = 1}, rpc.SendingPriority.kHigh )
		request:addEventListener( RequestNotifyEnum.ResetClimbTowerSucceed, onContinueClimbSucceed )
		request:addEventListener( RequestNotifyEnum.ResetClimbTowerFailed, onContinueClimbFailed )
		request:start()
	end
	
	self.battleResultUI:getChildByName("btn_new1"):getChildByName("font"):setString(getTextByKey("skyTower_battleChoose1"))
	local toBottom = Button:create(self.battleResultUI:getChildByName("btn_new1"))
	toBottom:addEventListener(Events.kStart, onToBottom, self)	

	self.battleResultUI:getChildByName("btn_new2"):getChildByName("font"):setString(getTextByKey("skyTower_battleChoose2"))
	local continueClimb = Button:create(self.battleResultUI:getChildByName("btn_new2"))
	continueClimb:addEventListener(Events.kStart, onContinueClimb, self)	
	
	self.battleResultUI:getChildByName("txt_towerBabel_lose1"):getChildByName("txt"):setString(getTextByKey("babel_presentFloor"))
	self.battleResultUI:getChildByName("txt_towerBabel_lose2"):getChildByName("txt"):setString(getTextByKey("skyTower_battleResult_starSum"))
	self.battleResultUI:getChildByName("txt_towerBabel_lose_value1"):getChildByName("txt"):setString(Localization:getInstance():getText("babel_floor", {num = self.data.currFloor}))
	self.battleResultUI:getChildByName("txt_towerBabel_lose_value2"):getChildByName("txt"):setString(tostring(self.data.currTotalStars))
	self.battleResultUI:getChildByName("txt_failed_info"):getChildByName("txt"):setString(getTextByKey("skyTower_battleChooseRule"))
	
end

function BattleResultPanel:showPKWin()
	self.battleResultUI = self.builder:build("battleResult_new_arena_win")
	
	self.battleResultUI:getChildByName("battleResult_icon_arena_bigwin_sb"):setVisible(false)
	self.battleResultUI:getChildByName("battleResult_icon_arena_littlewin_sb"):setVisible(false)
	self.battleResultUI:getChildByName("battleResult_icon_arena_normalwin_sb"):setVisible(false)
	
	local GameMetaData = MetaManager.game_meta
	if self.data.leftHpRate < GameMetaData.battleSettingConfig.victoryLevelFloor then
		self.battleResultUI:getChildByName("battleResult_icon_arena_littlewin_sb"):setVisible(true)
	elseif self.data.leftHpRate > GameMetaData.battleSettingConfig.victoryLevelTop then
		self.battleResultUI:getChildByName("battleResult_icon_arena_bigwin_sb"):setVisible(true)
	else
		self.battleResultUI:getChildByName("battleResult_icon_arena_normalwin_sb"):setVisible(true)
	end
	
	local rank = PKScene.getPKInfo().rank or 0
	self.battleResultUI:getChildByName("battleResult_txt_arenaranking"):getChildByName("txt_arenaranking"):setString(getTextByKey("pk_session_rank"))
	self.battleResultUI:getChildByName("battleResult_txt_arena_ranking_R"):getChildByName("txt_arena_ranking_R"):setString(rank)
	self.battleResultUI:getChildByName("battleResult_txt_arena_ranking_L"):getChildByName("txt_arena_ranking_L"):setString(self.data.prevRank or 0)
	self.battleResultUI:getChildByName("battleResult_txt_arenascore"):getChildByName("txt_arenascore"):setString(getTextByKey("pk_session_points"))
	self.battleResultUI:getChildByName("battleResult_icon_coinevent"):setVisible(false)
	self.battleResultUI:getChildByName("battleResult_txt_getcoin"):setVisible(false)
	self.battleResultUI:getChildByName("battleResult_txt_arena_score"):getChildByName("txt_arenascore"):setString("+" .. (self.data.gainScore or 0))
	self.battleResultUI:getChildByName("battleResult_btn_long_yellow"):getChildByName("font"):setString(getTextByKey("yes"))

	if rank == self.data.prevRank then
		self.battleResultUI:getChildByName("battleResult_txt_arenaranking"):setVisible(false)
		self.battleResultUI:getChildByName("battleResult_txt_arena_ranking_L"):setVisible(false)
		self.battleResultUI:getChildByName("battleResult_icon_arrow"):setVisible(false)
		self.battleResultUI:getChildByName("battleResult_txt_arena_ranking_R"):setVisible(false)

		local middleBg = self.battleResultUI:getChildByName("battleResult_new_red_bg9_pic")
		middleBg:setContentSize(CCSizeMake(middleBg:getContentSize().width, middleBg:getContentSize().height - 90))
	end

	local btnOK = Button:create(self.battleResultUI:getChildByName("battleResult_btn_long_yellow"))
	btnOK:addEventListener(Events.kStart, onLeftButtonClick, self)	
end

function BattleResultPanel:showPKLose()
	self.battleResultUI = self.builder:build("battleResult_new_arena_lose")
	addReplaceSceneButtons(self.battleResultUI , self.resultType)

	self.battleResultUI:getChildByName("battleResult_txt_battleResult_infomation"):getChildByName("txt_battleResult_infomation"):setString(getTextByKey("battleResult_lostTips2"))
	self.battleResultUI:getChildByName("battleResult_txt_battleResult_infomation"):setPositionY(732)
	self.battleResultUI:getChildByName("battleResult_icon_arena_normallost_sb"):setVisible(false)
	self.battleResultUI:getChildByName("battleResult_icon_arena_littlelost_sb"):setVisible(false)
	self.battleResultUI:getChildByName("battleResult_lbl_lose"):setVisible(false)

	local GameMetaData = MetaManager.game_meta
	if self.data.leftHpRate < GameMetaData.battleSettingConfig.victoryLevelFloor then
		self.battleResultUI:getChildByName("battleResult_icon_arena_littlelost_sb"):setVisible(true)
	elseif self.data.leftHpRate > GameMetaData.battleSettingConfig.victoryLevelTop then
		self.battleResultUI:getChildByName("battleResult_lbl_lose"):setVisible(true)
	else
		self.battleResultUI:getChildByName("battleResult_icon_arena_normallost_sb"):setVisible(true)
	end

	self.battleResultUI:getChildByName("battleResult_txt_arenascore"):setVisible(false)
	self.battleResultUI:getChildByName("battleResult_txt_arena_score"):setVisible(false)
	self.battleResultUI:getChildByName("battleResult_btn_long_yellow_sure"):getChildByName("font"):setString(getTextByKey("yes"))

	local btnOK = Button:create(self.battleResultUI:getChildByName("battleResult_btn_long_yellow_sure"))
	btnOK:addEventListener(Events.kStart, onLeftButtonClick, self)	
end

function BattleResultPanel:showActivityContend()
  self.battleResultUI = self.builder:build("battleResult_fight_for_soul_over")
  
  self.battleResultUI:getChildByName("txt_result_message1"):getChildByName("txt"):setString(getTextByKey("activity_contend_damage"))
  local damagNum = -self.container.finalEnemyHPChange
  if damagNum > self.container.enemyMaxHp then
    damagNum = self.container.enemyMaxHp
  end
  self.battleResultUI:getChildByName("txt_bossdamege4"):getChildByName("txt"):setString(string.format("%d", damagNum))
  self.battleResultUI:getChildByName("txt_result_message2"):getChildByName("txt"):setString(getTextByKey("activity_contend_silver"))
  local coin = 0
	if type(self.data.rewards) == "table" then
		for k,v in pairs(self.data.rewards) do
			if v.itemType == ResourceEnum.COIN then
				coin = tonumber(v.amount) + coin
			end
		end
	end
  self.battleResultUI:getChildByName("txt_bossdamege5"):getChildByName("txt"):setString(string.format("%d", coin))
  self.battleResultUI:getChildByName("battleResult_txt_gettrophy"):getChildByName("txt_gettrophy"):setString(getTextByKey("battleResult_acquire"))
  
  self.battleResultUI:getChildByName("battleResult_btn_long_yellow"):getChildByName("font"):setString(getTextByKey("yes"))
  local btnOK = Button:create(self.battleResultUI:getChildByName("battleResult_btn_long_yellow"))
	btnOK:addEventListener(Events.kStart, onLeftButtonClick, self)
  
  local dropItemTable = {}
  local ItemRewardTable = {}
  if type(self.data.rewards) == "table" then
		for k, v in pairs(self.data.rewards)
		do
			if v.itemType == ResourceEnum.CARD then
				table.insert(ItemRewardTable, v)
			elseif v.itemType == ResourceEnum.EQUIP then
				table.insert(ItemRewardTable, v)
			elseif v.itemType == ResourceEnum.PROP then
				table.insert(ItemRewardTable, v)
			elseif v.itemType == ResourceEnum.CARD_FRAGMENT then
	        	table.insert(ItemRewardTable, v)
	      	elseif v.itemType == ResourceEnum.EQUIP_FRAGMENT then
	        	table.insert(ItemRewardTable, v)
			end
		end
	end

  self.battleResultUI:getChildByName("txt_none"):getChildByName("txt"):setString(getTextByKey("battleResult_none"))
  self.battleResultUI:getChildByName("battleResult_normal_card_small"):setVisible(false)
  local posX, posY = self.battleResultUI:getChildByName("battleResult_normal_card_small").refCocosObj:getPosition()
  local size = self.battleResultUI:getChildByName("battleResult_normal_card_small").refCocosObj:getContentSize()

  local middlePixielHeight = 0
  local middlePixielHeightbtn = 0
	if #ItemRewardTable == 0 then
		middlePixielHeight = middlePixielHeight -250
	elseif #ItemRewardTable > 0 and #ItemRewardTable <= 4 then
		self.battleResultUI:getChildByName("txt_none"):setVisible(false)
		local itemHeight = (#ItemRewardTable > 8) and 8 or #ItemRewardTable
		middlePixielHeight = middlePixielHeight + (math.floor((itemHeight - 1) / 4) - 1) * 164.5
	else
		self.battleResultUI:getChildByName("txt_none"):setVisible(false)
		local itemHeight = (#ItemRewardTable > 8) and 8 or #ItemRewardTable
		middlePixielHeight = middlePixielHeight + (math.floor((itemHeight - 1) / 4) - 1) * 164.5
		middlePixielHeight = middlePixielHeight/3*10
		middlePixielHeightbtn = -30
	end
	local middleBg = self.battleResultUI:getChildByName("battleResult_new_red_bg9_pic")
	middleBg:setContentSize(CCSizeMake(middleBg:getContentSize().width, middleBg:getContentSize().height + middlePixielHeight))
    
    
	self.battleResultUI:getChildByName("battleResult_btn_long_yellow"):setPositionY(self.battleResultUI:getChildByName("battleResult_btn_long_yellow"):getPositionY() + middlePixielHeightbtn)

	addItemLayerByDrops(self.battleResultUI , ItemRewardTable, 50, 240-middlePixielHeight)
end

function BattleResultPanel:showCrossPk()
  self.battleResultUI = self.builder:build("battleResult_across_fight_over")
  
  local winUserInfo, loseUserInfo
  if self.data.whetherWin then
    winUserInfo = self.data.userinfo1
    loseUserInfo = self.data.userinfo2
  else
    winUserInfo = self.data.userinfo2
    loseUserInfo = self.data.userinfo1
  end
  local serverNumber1 = tonumber(string.sub(tostring(winUserInfo.uid), -4, -1))
  local serverNumber2 = tonumber(string.sub(tostring(loseUserInfo.uid), -4, -1))
  if __IOS then
    self.battleResultUI:getChildByName("txt_across_fight_1"):getChildByName("txt"):setString(Localization:getInstance():getText("cross_list_text", {num1 = serverNumber1}))
    self.battleResultUI:getChildByName("txt_across_fight_2"):getChildByName("txt"):setString(Localization:getInstance():getText("cross_list_text", {num1 = serverNumber2}))
  else
    self.battleResultUI:getChildByName("txt_across_fight_1"):getChildByName("txt"):setString(Localization:getInstance():getText("cross_list_android", {num1 = serverNumber1}))
    self.battleResultUI:getChildByName("txt_across_fight_2"):getChildByName("txt"):setString(Localization:getInstance():getText("cross_list_android", {num1 = serverNumber2}))
  end
  
  self.battleResultUI:getChildByName("name1"):getChildByName("txt_arenascore"):setString(winUserInfo.nickName)
  self.battleResultUI:getChildByName("name2"):getChildByName("txt_arenascore"):setString(loseUserInfo.nickName)

	self.battleResultUI:getChildByName("battleResult_btn_long_yellow"):getChildByName("font"):setString(getTextByKey("yes"))

	local btnOK = Button:create(self.battleResultUI:getChildByName("battleResult_btn_long_yellow"))
	btnOK:addEventListener(Events.kStart, onLeftButtonClick, self)	
end

function BattleResultPanel:initLayer()
	BattleResultPanel.super.initLayer(self)    
  
  self.data.rewards = self.data.rewards or {}
  local temp = {}
  if not self.data.rewards then
  	self.data.rewards = {}
  end
  for _, v in ipairs(self.data.rewards) do
    if v.itemType == ResourceEnum.CARD_FRAGMENT or v.itemType == ResourceEnum.EQUIP_FRAGMENT then
      local aAmount = v.amount
      v.amount = 1
      for i = 1, aAmount do
        table.insert(temp, v)
      end
    else
      table.insert(temp, v)
    end
  end
  self.data.rewards = temp

  	--DOUBLE_REWARD_MODIFY
  	local doubleRewardMoudle = nil
	
	self.builder = LayoutBuilder:createWithContentsOfFile("scene/battleResult_new.json")
	self.builder.useArtLabelTTF = true
	if self.resultType == BattleResultType.ARENA_WIN then
		--DOUBLE_REWARD_MODIFY
		if Activity_DoubleRewardLayer.getRewardEnableById(Activity_DoubleRewardLayer.MOUDLE_ARENA) then
			--双倍活动已开启
			doubleRewardMoudle = Activity_DoubleRewardLayer.MOUDLE_ARENA
		end
		self:showNewArenaWin()
	elseif self.resultType == BattleResultType.ARENA_LOSE then
		self:showNewArenaLose()
	elseif self.resultType == BattleResultType.VS_WIN then
		self:showNewVSWin()
	elseif self.resultType == BattleResultType.VS_LOSE then
		self:showNewVSLose()
	elseif self.resultType == BattleResultType.BATTLE_WIN then
		self:showNewBattleWin(nil)
	elseif self.resultType == BattleResultType.BATTLE_LOSE then
		self:showNewBattleLose()
	elseif self.resultType == BattleResultType.AUTOTOWER_WIN then
		self:showNewAutoTowerWin()
	elseif self.resultType == BattleResultType.ROB_WIN then
		--DOUBLE_REWARD_MODIFY
		if Activity_DoubleRewardLayer.getRewardEnableById(Activity_DoubleRewardLayer.MOUDLE_BEAST) then
			--双倍活动已开启
			doubleRewardMoudle = Activity_DoubleRewardLayer.MOUDLE_BEAST
		end
		self:showNewRobWin()
	elseif self.resultType == BattleResultType.ROB_LOSE then
		self:showNewRobLose()
	elseif self.resultType == BattleResultType.BOSS_WIN then
		self:showNewBossWin()
	elseif self.resultType == BattleResultType.BOSS_LOSE then
		self:showNewBossLose()
  	elseif self.resultType == BattleResultType.MULTI_BOSS_WIN then
		self:showMultiBossWin()
  	elseif self.resultType == BattleResultType.MULTI_BOSS_LOSE then
		self:showMultiBossLose()
  	elseif self.resultType == BattleResultType.NEWBABEL_WIN then
		self:showNewBabelWin()
	elseif self.resultType == BattleResultType.NEWBABEL_LOSE then
		self:showNewBabelLose()
	elseif self.resultType == BattleResultType.PK_WIN then
		--DOUBLE_REWARD_MODIFY
		if Activity_DoubleRewardLayer.getRewardEnableById(Activity_DoubleRewardLayer.MOUDLE_PK) then
			--双倍活动已开启
			doubleRewardMoudle = Activity_DoubleRewardLayer.MOUDLE_PK
		end
		self:showPKWin()
	elseif self.resultType == BattleResultType.PK_LOSE then
		self:showPKLose()
  	elseif self.resultType == BattleResultType.ACTIVITY_CONTEND then
		self:showActivityContend()
  	elseif self.resultType == BattleResultType.CROSS_PK then
		self:showCrossPk()
	elseif self.resultType == BattleResultType.ACTIVITY_WANTED_WIN then
		self:showNewBattleWin(nil)
	elseif self.resultType == BattleResultType.ACTIVITY_WANTED_LOSE then
		self:showNewBattleLose()
	elseif self.resultType == BattleResultType.ACTIVITY_XMAS_WIN then
		self:showNewBattleWin(nil)
	elseif self.resultType == BattleResultType.ACTIVITY_XMAS_LOSE then
		self:showNewBattleLose()
	elseif self.resultType == BattleResultType.CHAPTER_MAP_WIN then
		--DOUBLE_REWARD_MODIFY
		if Activity_DoubleRewardLayer.getRewardEnableById(Activity_DoubleRewardLayer.MOUDLE_CHAPTERS) then
			--双倍活动已开启
			doubleRewardMoudle = Activity_DoubleRewardLayer.MOUDLE_CHAPTERS
		end
		self:showNewBattleWin(doubleRewardMoudle)
	elseif self.resultType == BattleResultType.CHAPTER_MAP_LOSE then
		self:showNewBattleLose()
	elseif self.resultType == BattleResultType.EILTE_WIN then
		--DOUBLE_REWARD_MODIFY
		if Activity_DoubleRewardLayer.getRewardEnableById(Activity_DoubleRewardLayer.MOUDLE_EILTE) then
			--双倍活动已开启
			doubleRewardMoudle = Activity_DoubleRewardLayer.MOUDLE_EILTE
		end
		self:showNewBattleWin(doubleRewardMoudle)
	elseif self.resultType == BattleResultType.EILTE_LOSE then
		self:showNewBattleLose()
	elseif self.resultType == BattleResultType.CROSS_PVP_WIN then
		self:showNewCrossPVPWin()
	elseif self.resultType == BattleResultType.CROSS_PVP_LOSE then
		self:showNewCrossPVPLose()
	end
	
	--print("self.data.robRewards = " .. tostringRich(self.data.robRewards))
	if self.data.robRewards and self.data.robRewards[1] then--modified by zheng.che @ 2014-11-4 解决对方没有银币时无奖励情况崩溃问题
		local function onShowRouletteReward()
			RouletteRewardPanel:show(self.container, self.data.robRewards[1], doubleRewardMoudle)
			self.battleResultUI:setTouchEnabled(true)
		end
		
		self.battleResultUI:setTouchEnabled(false)
		local actionArray = CCArray:create()
		actionArray:addObject(CCDelayTime:create(0.5))
		actionArray:addObject(CCCallFuncN:create(onShowRouletteReward))
		self:runAction(CCSequence:create(actionArray))		
	end

	self.battleResultUI:setPosition(ccp(0, -50))
	self:addChild(self.battleResultUI)
	
end

function BattleResultPanel:destroy()
end
