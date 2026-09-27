require "hecore.display.CocosObject"
require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "canon.scene.BaseUIScene"
require "canon.scene.CardQueueScene"
require "canon.scene.CardEvolutionScene"
require "canon.scene.BackpackScene"
require "canon.scene.CardComposeScene"
require "canon.scene.FriendScene"
require "canon.scene.EquipUpgradeScene"
require "canon.scene.EquipEvolveScene"
require "canon.scene.SkyTowerMainScene"
require "canon.scene.CardTrainingScene"
require "canon.request.GainTutorialFinishRewardRequest"
require "canon.scene.CityMainScene"
require "canon.scene.ArenaRankScene"
require "canon.scene.ArenaExchangeScene"
require "canon.scene.ArenaReportScene"
require "canon.scene.ArenaRuleScene"
require "canon.models.ArenaManager"
require "canon.data.DataManager"
require "canon.models.RewardManager"
require "canon.request.GetArenaMatchedPlayersRequest"
require "canon.utils.TimeUtil"
require "canon.scene.TestCanonCardScene"
require "canon.scene.CanonCardScene"
require "canon.scene.ConfigScene"
require "canon.scene.ShopScene"
require "canon.scene.BeastScene"
require "canon.scene.CardStrenthenSelectScene"
require "canon.scene.BatchSellScene"
require "canon.scene.MatrixScene"
require "canon.scene.CombineScene"
require "canon.scene.GachaScene"
require "canon.scene.EmailScene"
require "canon.scene.FragmentScene"
require "canon.scene.PKScene"
require "canon.scene.CardRebirthScene"

require "canon.layer.Activity_EatPeachLayer"
require "canon.layer.Activity_WorldBossLayer"
require "canon.layer.Activity_CowstageLayer"
require "canon.scene.EliteMissionScene"
require "canon.scene.ActivityPanelScene"
require "canon.manager.UnionManager"--要定义在BeastScene之后
require "canon.manager.DebugManager"

require "canon.scene.ChallengeEntersScene"

require "canon.scene.RewardScene"
require "canon.panel.CalendarSignInPanel"
require "canon.panel.New_UserContinueLoginShowPanel"
require "canon.panel.AnnouncementPanel"
require "canon.panel.CountdownRewardPanel"
require "canon.request.GetAnnouncementInfoRequest"
require "canon.request.GetHomeInfoRequest"
require "canon.request.GetCountdownRewardRequest"
require "canon.request.GainArenaScoreByRankRequest"
require "canon.customUI.SuspensionLabel"
require "canon.script_and_guide.Script_And_Dialog"

require "canon.constants.ParticlePathConstants"
require "canon.manager.ParticleManager" 
require "canon.manager.DcManager"
require "canon.manager.HomeInfoManager"

require "canon.scene.SecretaryScene"
require "canon.scene.DailyTargetScene"
require "canon.request.GetDailyActiveInfoRequest"
require "canon.request.GetDailyAchieveInfoRequest"
require "canon.request.GainDailyAchieveRequest"
require "canon.manager.ChatManager"

require "canon.data.IosPayment"
require "canon.manager.PassDayManager"

require "canon.scene.SpiritBackPackScene"

require "canon.scene.AcrossFightScene"
require "canon.scene.CompeteScene"
require "canon.manager.ItemManager"
require "canon.manager.SystemManager"
require "canon.manager.FacebookShareManager"
require "canon.panel.OldUserComeBackPanel"
require "canon.panel.LimitRewardPanel"

require "canon.panel.ActivityExchangeDailyPanel"


require "canon.features.crossArena.manager.CrossArenaManager"

local enter_animation_duration = 0.3
local enter_first = true
local gain_reward = false

--鱼组推广码
function getFishInviteCode()
	local fishInviteCode = nil
	if isGooglePlayTW() or isTWHE() then
	  local gameInitData = DataManager.getGameInitData()
	  if gameInitData.fishInviteCode ~= nil then
		fishInviteCode = gameInitData.fishInviteCode
	  end
	end 
	return fishInviteCode
end

MainMenuScene = class(BaseUIScene)


local visibleSize = CCDirector:sharedDirector():getVisibleSize();
g_homeInfo = nil
g_curSceneEnum = nil

function MainMenuScene:setTableViewsEnabled(v)
	self.tableUI:setTouchEnabled(v)
end

function MainMenuScene:setUserTouchEnabled(isEnable)
	 self:setTableViewsEnabled(isEnable)
	 self:setTouchEnabled(isEnable)
end

function MainMenuScene:ctor()
	g_previousPlayerFateStatus = DataManager.getGameInitData().sharkUserExtend.cardGroupInterworking
  self.curSceneEnum = SceneEnum.MainMenuScene
  g_curSceneEnum = SceneEnum.MainMenuScene
	self.title = "HOME"
    self.tableUI = nil
    self.targetInfoPanel = nil
    local text_home_cardEnhanceBtn = getTextByKey("home_cardEnhanceBtn")
    local text_home_cardEvolveBtn = getTextByKey("home_cardEvolveBtn")
    --local text_home_equipEnhanceBtn = getTextByKey("home_equipEnhanceBtn")
    --local text_home_equipEvolveBtn = getTextByKey("home_equipEvolveBtn")
    local text_home_rewardBtn = getTextByKey("home_rewardBtn")
    --local text_home_guildBtn = getTextByKey("home_guildBtn")
    local text_home_friendBtn = getTextByKey("home_friendBtn")
    local text_home_galleryBtn = getTextByKey("home_galleryBtn")
    local text_home_mailboxBtn = getTextByKey("home_mailboxBtn")
    local text_home_inventoryBtn = getTextByKey("home_inventoryBtn")
    local text_home_optionsBtn = getTextByKey("home_optionsBtn")
	local text_home_train = getTextByKey("cardTrain_levellow")
	local text_home_equip = getTextByKey("bag_EquipmentTag")
	local text_home_synthetize = getTextByKey("home_synthetizeBtn")
	local home_fragmentBtn = getTextByKey("home_fragmentBtn")
	local text_home_cardRebirthBtn = getTextByKey("home_sacrificeBtn")
	local text_home_spirit = getTextByKey("home_spiritBtn")
	local text_home_treasure = getTextByKey("Treasure_titel_4")

	--过滤可培养卡牌 add by czh @ 2014-8-18
    local function filterTrainCardFunc( cardList )
    	--print("11111111111")
        local result = {}
        for k,card in pairs(cardList) do
			--print("card.metaId = " .. tostringRich(card.metaId))
			if ItemManager.checkCardTypeCanTrain(card.metaId) then
				--卡牌类型允许培养
				table.insert(result,card)
			end
		end
        return result
    end

	if isXiaomiAndroid() then
    Set_ShareData( "isXiaomiAndroid", 1 )--传递给新手引导
		self.entryListData = {
			-- {title="小米",pic='icon_home_mi0000',callback = CardComposeScene,name = "xiaomi"}, --小米
		  --{title=text_home_cardEnhanceBtn,pic='mainmenu_scene_icon_home_cardEnhance_sb0000',callback = CardComposeScene,name = "CardCompose"},
		  --{title=text_home_cardEvolveBtn,pic='mainmenu_scene_icon_home_cardEvolve_sb0000',callback = CardEvolutionScene,name = "CardEvolution"},
		  {title=text_home_equip,pic='mainmenu_scene_icon_home_guild_sb0000',callback = BackpackScene,name = "Equip", argv = {params = {isCardTrain = false, tabIndex = BAGCATEGORY.equip}}},
		  --{title=text_home_train,pic='mainmenu_scene_icon_home_reward_sb0000',callback = BackpackScene,name = "Train", argv = {params = {filterFunc = filterTrainCardFunc, filter=BACKPACK_FILTER.CARD, isCardTrain = true}}},
		  --{title=text_home_inventoryBtn,pic='mainmenu_scene_icon_home_inventory_sb0000',callback = BackpackScene,name = "Backpack", argv = {params = {isCardTrain = false}}},
		  {title=text_home_friendBtn,pic='mainmenu_scene_icon_home_friend_sb0000',callback = FriendScene,name = "Friend"},
		  {title=text_home_mailboxBtn,pic='mainmenu_scene_icon_home_mailbox_sb0000',callback = EmailScene,name = "Email"},
		  {title=text_home_spirit,pic='icon_home_elesoul0000',callback = SpiritBackPackScene,name = "SpiritBackPack"},
		  {title=text_home_treasure,pic='icon_home_treasure0000',callback = TreasureBackpackScene,name = "TreasureBackpack"},
		  {title=home_fragmentBtn,pic='icon_soul0000',callback=FragmentScene,name = "SoulRefine"},
		  {title=text_home_cardRebirthBtn,pic='icon_home_therefined0000',callback=CardRebirthScene,name = "CardRebirth"},
		  {title=text_home_synthetize,pic='icon_home_book_combine0000',callback = CombineScene,name = "Combine"},
		  {title=text_home_galleryBtn,pic='mainmenu_scene_icon_home_gallery_sb0000',callback = CanonCardScene,name = "CanonCard"},
		  {title=text_home_optionsBtn,pic='mainmenu_scene_icon_home_option_sb0000',callback=ConfigScene,name = "Option"},
		}
		
	else
    Set_ShareData( "isXiaomiAndroid", 0 )--传递给新手引导
		self.entryListData = {
		  --{title=text_home_cardEnhanceBtn,pic='mainmenu_scene_icon_home_cardEnhance_sb0000',callback = CardComposeScene,name = "CardCompose"},
		  --{title=text_home_cardEvolveBtn,pic='mainmenu_scene_icon_home_cardEvolve_sb0000',callback = CardEvolutionScene,name = "CardEvolution"},
		  {title=text_home_equip,pic='mainmenu_scene_icon_home_guild_sb0000',callback = BackpackScene,name = "Equip", argv = {params = {isCardTrain = false, tabIndex = BAGCATEGORY.equip}}},
		  --{title=text_home_train,pic='mainmenu_scene_icon_home_reward_sb0000',callback = BackpackScene,name = "Train", argv = {params = {filterFunc = filterTrainCardFunc, filter=BACKPACK_FILTER.CARD, isCardTrain = true}}},
		  --{title=text_home_inventoryBtn,pic='mainmenu_scene_icon_home_inventory_sb0000',callback = BackpackScene,name = "Backpack", argv = {params = {isCardTrain = false}}},
		  {title=text_home_friendBtn,pic='mainmenu_scene_icon_home_friend_sb0000',callback = FriendScene,name = "Friend"},
		  {title=text_home_mailboxBtn,pic='mainmenu_scene_icon_home_mailbox_sb0000',callback = EmailScene,name = "Email"},
		  {title=text_home_spirit,pic='icon_home_elesoul0000',callback = SpiritBackPackScene,name = "SpiritBackPack"},
		  {title=text_home_treasure,pic='icon_home_treasure0000',callback = TreasureBackpackScene,name = "TreasureBackpack"}, -- todo
		  {title=home_fragmentBtn,pic='icon_soul0000',callback=FragmentScene,name = "SoulRefine"},
		  {title=text_home_cardRebirthBtn,pic='icon_home_therefined0000',callback=CardRebirthScene,name ="CardRebirth"},
		  {title=text_home_synthetize,pic='icon_home_book_combine0000',callback = CombineScene,name = "Combine"},
		  {title=text_home_galleryBtn,pic='mainmenu_scene_icon_home_gallery_sb0000',callback = CanonCardScene,name = "CanonCard"},
		  {title=text_home_optionsBtn,pic='mainmenu_scene_icon_home_option_sb0000',callback=ConfigScene,name = "Option"},
		}
	end
	
	
	
end


function MainMenuScene:create()
  local s = MainMenuScene.new()
  s:initScene()
  return s
end

function MainMenuScene:getAdvPicByMeta(meta)
		if nil == meta then
			return nil
		end
	  if meta.name == "eatPeach" then
		  if not g_homeInfo or not g_homeInfo.eatPeachStatus then
			  return nil
		  end
	  elseif meta.name == "cow" then
		  if not g_homeInfo or not g_homeInfo.cowStageStatus then
			  return nil
		  end
	  elseif meta.name == "continueLogin" then
		  if not New_UserContinueLoginShowPanel:enable()  then
			  return nil
		  end
	  elseif meta.name == "firstPay" then
		  if not HomeInfoManager.getChargeRewardStatus() then
			  return nil
		  end
	  elseif meta.name == "worldBoss" then
		  if not MaintenanceManager.isActivityOpen(DataManager.GameMetaData.activityWorldBossConfig.featureName) then
			  return nil
		  end
	  elseif meta.name == "gachaPoints" then
		  if not MaintenanceManager.isActivityOpen("activityGachaPointsPanel")  then
			  return nil
		  end
	  elseif meta.name == "levelRace" then
		  if not MaintenanceManager.isActivityOpen("activityLevelRacePanel")  then
			  return nil
		  end
	  elseif meta.name == "newyear" then
		  if not MaintenanceManager.isActivityOpen("activityNewyearPanel")  then
			  return nil
		  end
	  elseif meta.name == "freeGacha" then
	  	
		  if HomeInfoManager.getFreeGachaStatus() <= 0 then
			  return nil
		  end
	  elseif meta.name == "fortuneNow" then
		  if not MaintenanceManager.isActivityOpen("fortuneNow")  then
			  return nil
		  end
	  elseif meta.name == "exchangeDaily" then
	  	
		  if not MaintenanceManager.isActivityOpen("exchangeDaily")  then
			return nil
		  end

	  end

	  local spt = Sprite:create("pic/" .. meta.picId)
	  spt:setPosition(ccp(360, -99))
	  if meta.name == "happyfish_invitecode" and getFishInviteCode() then
		local inviteLabel = CCLabelTTF:create(getFishInviteCode(),"Arial", 30)
		inviteLabel:setPosition(ccp(300,70))
		inviteLabel:setColor(ccc3(0,71,157))
		spt:addChild(CocosObject.new(inviteLabel))
	  end
	  return spt
end

function getPaymentInfo()    --获取充值列表并且进行一些转换
	local productIds = {}
	for k,data in pairs(MetaManager.getPaymentExchangeConfig()) do
		if data.onSale then
			table.insert(productIds, data.id)
		end
	end
    print("________________________")
    print(table.tostring(productIds))
    print("________________________")
    if isGooglePlayTW() then
         GspBridge.getGooglePlayGoodsList(productIds)
    elseif isPlatformIos() or isIosTW() then
    	IosPaymentLua:getInstance():getValidSkuList(productIds)
    end	
end

function MainMenuScene:onInit()
  self.activityEnableTips = ActivityPanelScene.getOriginalTipDict()
  self.activityCount = 0
  self.activityParticleInfos = ActivityPanelScene.getOriginalParticleDict()
  ActivityPanelScene.setStatusInfo()
  
  getPaymentInfo()
  
  --self.curShowText = false
  
  DcManager.openUserOnlineActivity()

  if __IOS then
  	recordAchievement(1, 100, false)
  end
  
  -- 测试HomeInfoManager
  print("TEST HOMEINFOMANAGER")
  print(HomeInfoManager.getFreeGachaStatus())
  print(HomeInfoManager.getChargeRewardStatus())
  
  local List1 = {}
    List1[8] = GuideConfig.kRisk3
  if ( not IsGuideExecuted(List1[8]) ) then --新手引导 (暂时屏蔽)
    if (_G.Guide_JudgeInEachFrameSchedule==nil) and (Get_ShareData("New_User_Guide_Running")~=1) then
      CCDirector:sharedDirector():getTouchDispatcher():setDispatchEvents( false )
      Set_ShareData( "NewUserGuide_Not_Finished", 1 )
    end
  end

  GachaScene.preloadAd()

  local userData = DataManager.getCurrUser()
  BaseUIScene.initBackGround(self)
  local builder = LayoutBuilder:createWithContentsOfFile("scene/mainmenu_scene_new.json")
  self.mainUI = builder:build("mainmenu_scene_home")
  

  local spt = nil
  local fishInviteCode = getFishInviteCode()
    ---限时充值
   ---倒计时的调度器
  local function CreateCountDownByAD(BMlabel,index,ADsp) --最后一个参数是广告的精灵
  	-- print("________________________________index = "..index)
	  local LimitRewardList = Activity_rechargeLayer:getLimitRewardList()
	  --时间戳
	  local rechargeData = Activity_rechargeLayer.getRechargeData()
	  local registrationTime = rechargeData.times
	 
	  local TotalTimes = registrationTime +  LimitRewardList[index].limitTime*60*60
	   
	  self.cdLabelComponent = CdLabelComponent:create()

	  local function onTimeTick1(remainedSec)
	    local formatedTimeStr = TimeUtil.formatTime(remainedSec)
	    BMlabel:setString(tostring(formatedTimeStr))
	  end


	  local  function onTimeComplete1()
	    print("倒计时结束")
	      
	    if self.cdLabelComponent then
		    self.cdLabelComponent:stop()
		    self.cdLabelComponent = nil
		end
	    local  judgeVariable = Activity_rechargeLayer.JudgeDisplayAdvertising( )
	    local isInApple = isInAppleReview()
	    if judgeVariable > 0 and not isInApple  then
	    	if judgeVariable == 1 then
	    		self.mainUI:getChildByName("home_main"):getChildByName("icon_home_active"):removeChildren(true)
			    ADsp = Sprite:create("pic/LimitRewardAD.png")
			    ADsp:setPosition(ccp(360, -105))
		        self.mainUI:getChildByName("home_main"):getChildByName("icon_home_active"):addChild(ADsp)
		    else
		    	-- print("_____________________________________开始新的倒计时1"..Activity_rechargeLayer.CurrentJudgeCountdown())
		    	if Activity_rechargeLayer.CurrentJudgeCountdown() ~= 4 then
			    	CreateCountDownByAD(BMlabel,Activity_rechargeLayer.CurrentJudgeCountdown(),ADsp)
			    else
                   onTimeComplete1()

			    end

		    	-- print("_____________________________________开始新的倒计时2")
		    end
	    else
	    	self.mainUI:getChildByName("home_main"):getChildByName("icon_home_active"):removeChildren(true)
		    self.oldAdvSprite = nil
		    self.nextAdvCount = 1
		    self.newAdvSprite = self:nextAdvPicture()
		    self.mainUI:getChildByName("home_main"):getChildByName("icon_home_active"):addChild(self.newAdvSprite)
		    local function changeAdvScheFunc()
		    	self:changeAdv()
	        end
		    self.changeAdvFunc = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(changeAdvScheFunc, 6, false)
	    end
    end

   
	self.cdLabelComponent:setCallback(onTimeTick1, onTimeComplete1)
	-- print("当前的时间#########"..TimeUtil.getServerTimeSeconds())
	self.cdLabelComponent:setTargetTime(TotalTimes)
	self.cdLabelComponent:start()
	-- body
  end
  local function geneRewardParticle(sp)
      self.rewardParticles = ParticleManager.geneParticle(ParticlePathConstants.FxStarline, ccp(350,120), 1, 1000, sp)
      local particleMoveArray = CCArray:create()
      local particleMoveTime = 0.4
      particleMoveArray:addObject(CCMoveBy:create(particleMoveTime, ccp(210, 0)))
      particleMoveArray:addObject(CCMoveBy:create(particleMoveTime, ccp(0, -53)))
      particleMoveArray:addObject(CCMoveBy:create(particleMoveTime, ccp(-210, 0)))
      particleMoveArray:addObject(CCMoveBy:create(particleMoveTime, ccp(0, 53)))
      self.rewardParticles:runAction(CCRepeatForever:create(CCSequence:create(particleMoveArray)))
  end
  
  
  local  judgeVariable = Activity_rechargeLayer.JudgeDisplayAdvertising( )
  -- print("_____________________________________判断是可以显示广告 "..tostringRich(judgeVariable))
  local isInApple = isInAppleReview()
  
	if judgeVariable > 0 and not isInApple then
	     if judgeVariable == 1 then
	        spt = Sprite:create("pic/LimitRewardAD.png")
	     else
	     	
	     	spt = Sprite:create("pic/LimitRewardADCountDown.png")
	     	geneRewardParticle(spt)

	     	local doubleLabel_co = CCLabelBMFont:create("00:00:00", "pic/fnt/limitChargeFnt.fnt")
	        local doubleLabel = CocosObject.new(doubleLabel_co)
		    doubleLabel:setAnchorPoint(ccp(1, 0))
		    doubleLabel:setPosition(ccp(560,70))
		    doubleLabel:setScaleX(1.3)
		    spt:addChild(doubleLabel)
	     	CreateCountDownByAD(doubleLabel_co,Activity_rechargeLayer.CurrentJudgeCountdown(),spt)
	     	-- print("_________________________________________显示什么倒计时  "..Activity_rechargeLayer.CurrentJudgeCountdown())
	    end

  else
       if fishInviteCode == nil then
			if nil == g_curAdvIndex then
				spt = Sprite:create("pic/main_ad_world_boss.png")
			else
				local advMeta = MetaManager.game_meta.adMainUiConfig.adMainUis

				spt = self:getAdvPicByMeta(advMeta[g_curAdvIndex])
				if spt == nil then
					spt = Sprite:create("pic/main_ad_world_boss.png")
				end
			end
	   else
			spt = Sprite:create("pic/main_ad_happyfish_invitecode.png")
			local inviteLabel = CCLabelTTF:create(fishInviteCode,"Arial", 30)
			inviteLabel:setPosition(ccp(300,70))
			inviteLabel:setColor(ccc3(0,71,157))
			spt:addChild(CocosObject.new(inviteLabel))
	   end
	  
  end
  spt:setPosition(ccp(360, -99))
  self.mainUI:getChildByName("home_main"):getChildByName("icon_home_active"):removeChildren(true)
  self.mainUI:getChildByName("home_main"):getChildByName("icon_home_active"):addChild(spt)

  self.mainUI:getChildByName("home_main"):getChildByName("bg_mainmenu_tiao_kanbanMusume"):setTouchEnabled(false)
 
  --local builder = LayoutBuilder:createWithContentsOfFile("scene/mainmenu_scene.json")
  --self.mainUI = builder:build("home")
  
  -- 小图标icon:
  local homeIconsSb = self.mainUI:getChildByName("home_icons")
  if homeIconsSb ~= nil then
    homeIconsSb:getChildByName("btn_home_cardEvolveBtn"):setVisible(false)
    homeIconsSb:getChildByName("btn_home_cardEnhanceBtn"):setVisible(false)
    homeIconsSb:getChildByName("btn_home_inventoryBtn"):setVisible(false)
    homeIconsSb:getChildByName("btn_home_friendBtn"):setVisible(false)
    homeIconsSb:getChildByName("btn_home_mailboxBtn"):setVisible(false)
    homeIconsSb:getChildByName("btn_home_rewardBtn"):setVisible(false)
    homeIconsSb:getChildByName("btn_home_galleryBtn"):setVisible(false)
    homeIconsSb:getChildByName("btn_home_guildBtn"):setVisible(false)
    homeIconsSb:getChildByName("btn_home_optionsBtn"):setVisible(false)    
    homeIconsSb:getChildByName("btn_therefined"):setVisible(false)
    homeIconsSb:setZOrder(1001)
  end
  
  --关卡
  local function onClickCityMain(e)
		--if self.curShowText then
		--	return
		--end
  
		local function showTextFinish()
			self.curShowText = false
			self.mainUI:getChildByName("home_main"):getChildByName("home_lv_t"):getChildByName("frame_home_dialogue"):setVisible(false)
			self.mainUI:getChildByName("home_main"):getChildByName("txt_heroword"):setVisible(false)
			CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry( self.showTextFunc )
			self.showTextFunc = nil
		end
  
    local mon = MetaManager.card_monologue
    local meta = mon[self.mainCard.metaId]
    
    self.mainUI:getChildByName("home_main"):getChildByName("home_lv_t"):getChildByName("frame_home_dialogue"):setVisible(true)
	self.mainUI:getChildByName("home_main"):getChildByName("txt_heroword"):setVisible(true)
  if self.MBHint:isVisible() then
    self.mainUI:getChildByName("home_main"):getChildByName("txt_heroword"):getChildByName("txt"):setString(getTextByKey("activityNian_homeMessage"))
  elseif g_homeInfo and g_homeInfo.unreadMessageNum > 0 then  -- 判断是否有邮件提示
    self.mainUI:getChildByName("home_main"):getChildByName("txt_heroword"):getChildByName("txt"):setString(getTextByKey("monologue_newMail"))
  else
    local randTxt = math.random(1,5)
    if randTxt == 1 then
      self.mainUI:getChildByName("home_main"):getChildByName("txt_heroword"):getChildByName("txt"):setString(getTextByKey(meta.monologue01))
    elseif randTxt == 2 then
      self.mainUI:getChildByName("home_main"):getChildByName("txt_heroword"):getChildByName("txt"):setString(getTextByKey(meta.monologue02))
    elseif randTxt == 3 then
      self.mainUI:getChildByName("home_main"):getChildByName("txt_heroword"):getChildByName("txt"):setString(getTextByKey(meta.monologue03))
    elseif randTxt == 4 then
      self.mainUI:getChildByName("home_main"):getChildByName("txt_heroword"):getChildByName("txt"):setString(getTextByKey(meta.monologue04))
    else
      self.mainUI:getChildByName("home_main"):getChildByName("txt_heroword"):getChildByName("txt"):setString(getTextByKey(meta.monologue05))
    end
  end
	
	if self.showTextFunc then
		CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry( self.showTextFunc )
	end
	self.showTextFunc = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc( showTextFinish, 3, false )
	
    --self.curShowText = true
  end
  
  --演武click
  local function onClickTower(e)
    if AcrossFightManager.isOpen() then
      local function successCallback()
        self:replaceScene(AcrossFightScene)
      end
      AcrossFightScene.enterScene(successCallback)
    else
      print("across fight not open!")
    end
    --[[
    local function Success(event)
      if event ~= nil then
        DataManager.GetBabelInfoData = event.data
        DataManager.GetBabelInfoData._DownloadDataTime = TimeUtil.getServerTimeSeconds()
      end
      self:replaceScene(SkyTowerMainScene)
    end
    local function Failed(event)
      if event.data == 713103 then
        SuspensionLabel:showContent(self, Localization:getInstance():getText("babel_levelInsufficient", {num = MetaManager.game_meta.gameSettingConfig.babelConfig.babelTowerUnlockLevel}))
      end
    end
    
    if (userData.level >= MetaManager.game_meta.gameSettingConfig.babelConfig.babelTowerUnlockLevel) then
      local params = {}
      local getBabelInfoRequest = GetBabelInfoRequest.new(params, rpc.SendingPriority.kHigh)
      getBabelInfoRequest:addEventListener(RequestNotifyEnum.GetBabelInfoSucceed, Success)
      getBabelInfoRequest:addEventListener(RequestNotifyEnum.GetBabelInfoFailed, Failed)
      getBabelInfoRequest:start()
    else
      SuspensionLabel:showContent(self, Localization:getInstance():getText("babel_levelInsufficient", {num = MetaManager.game_meta.gameSettingConfig.babelConfig.babelTowerUnlockLevel}))
    end
    --]]
  end

  --活动
  local function onClickActivity( evt )

        local  judgeVariable = Activity_rechargeLayer.JudgeDisplayAdvertising( )
        local isInApple = isInAppleReview()
        if judgeVariable > 0  and not isInApple  then
        	
            
        	evt.context:replaceScene(ActivityPanelScene, {selectPanelName = "Activity_LimitReward"})
        
        	--[[
        	print("————————————————————————————————————————跳转到限时充值面板")
        	evt.context.LimitRewardPanel = LimitRewardPanel:create(evt.context)
			evt.context.targetInfoPanel = evt.context.LimitRewardPanel
			PopoutManager:sharedManager():popout(evt.context.LimitRewardPanel, kPopoutDir.kScale, true, false , evt.context)
			]]
        else

	        g_curServerTimeStamp = TimeUtil.getServerTimeSeconds()
			if not g_curAdvIndex then
				return
			end
			
			if not self.advMeta then
				return
			end
			
			if not self.advMeta[g_curAdvIndex] then
				return
			end
			
	        if self.advMeta[g_curAdvIndex].name == "worldBoss" then
	              self:replaceScene(ActivityPanelScene, {selectPanelName = "Activity_WorldBoss"})
	        elseif self.advMeta[g_curAdvIndex].name == "cow" then
	              self:replaceScene(ActivityPanelScene, {selectPanelName = "Activity_CowStage"})
	        elseif self.advMeta[g_curAdvIndex].name == "eatPeach" then
	              self:replaceScene(ActivityPanelScene, {selectPanelName = "Activity_EatPeach"})
	        elseif self.advMeta[g_curAdvIndex].name == "continueLogin" then
	              self:replaceScene(ActivityPanelScene, {selectPanelName = "Activity_ContinueLogin"})
	        elseif self.advMeta[g_curAdvIndex].name == "firstPay" then
	              self:replaceScene(ActivityPanelScene, {selectPanelName = "Activity_ChargeReward"})     
	        elseif self.advMeta[g_curAdvIndex].name == "gachaPoints" then
	              self:replaceScene(ActivityPanelScene, {selectPanelName = "Activity_GachaPoints"})
	        elseif self.advMeta[g_curAdvIndex].name == "levelRace" then
	              self:replaceScene(ActivityPanelScene, {selectPanelName = "Activity_LevelRace"})
	        elseif self.advMeta[g_curAdvIndex].name == "newyear" then
	              self:replaceScene(ActivityPanelScene, {selectPanelName = "Activity_NewyearRecharge"})
	        elseif self.advMeta[g_curAdvIndex].name == "freeGacha" then
				  self:replaceScene(GachaScene, {returnScene = "MainMenuScene"})
			elseif self.advMeta[g_curAdvIndex].name == "fortuneNow" then
	              self:replaceScene(ActivityPanelScene, {selectPanelName = "Activity_FortuneNow"})
	        elseif self.advMeta[g_curAdvIndex].name == "exchangeDaily" then
	              self:replaceScene(ActivityPanelScene, {selectPanelName = "Activity_ExchangeDaily"})
	        elseif self.advMeta[g_curAdvIndex].name == "treasure" then
	        	-- print("~~~~~~~~~~~~~宝物祭炼")
	        	local currUser = DataManager.getCurrUser()
	        	if TreasureManager.getTreasureUserLevel() > currUser.level then
	        		local aContent = Localization:getInstance():getText("Treasure_tips21")
				    SuspensionLabel:showContent(self, Localization:getInstance():getText("module_needLevel", {num = TreasureManager.getTreasureUserLevel()}))
	        	else
                    self:replaceScene(CardRebirthScene)
	        	end
	              -- 
			elseif self.advMeta[g_curAdvIndex].name == "happyfish_invitecode" then
				  local susLabel = SuspensionLabel:showContent(self, getTextByKey("fish_spread1"))
	              susLabel:setPosition(ccp(360,600))	
	              local fishInviteCode = getFishInviteCode()
	              if __ANDROID then
	                he_log_info("++++++++++++invite code :" .. fishInviteCode)
	                CanonEnvInjector:copyStringToClipboard(fishInviteCode)
	              elseif __IOS then
	              	local pasteboard = UIPasteboard:generalPasteboard()
	              	pasteboard:setString(fishInviteCode)
	              end
	        end
	    end
  end
  
  --竞技场
  local function onClickArena( evt )
    self:callFuncBeforeSceneChange(
      function()
        self:replaceScene(ChallengeEntersScene)
      end
    )
  end
  
	--武道大会
  local function onClickPK()
    self:replaceScene(CompeteScene)
    --[[
    if DataManager.GameMetaData.pkSettingConfig and DataManager.getCurrUser().level < DataManager.GameMetaData.pkSettingConfig.pkUnlockLevel then
      SuspensionLabel:showContent(self, getTextByKey("pk_level_limit"))
      return
    end
    self:replaceScene(PKScene)
    ]]
  end
  
  self.tableUI = self:createEntryList( self.entryListData )
  self.mainUI:getChildByName("home_icons"):addChild(self.tableUI)
  self:addChild(self.mainUI)
  
  self.mainUI:getChildByName("home_main"):getChildByName("txt_heroword"):getChildByName("txt"):setDimensions(CCSizeMake(340,100))
  local pos = self.mainUI:getChildByName("home_main"):getChildByName("txt_heroword"):getPosition()
  self.mainUI:getChildByName("home_main"):getChildByName("txt_heroword"):setPosition( ccp(pos.x + 40, pos.y - 5) )
  
   self.mainUI:getChildByName("home_main"):getChildByName("home_lv_t"):getChildByName("frame_home_dialogue"):setVisible(false)
   self.mainUI:getChildByName("home_main"):getChildByName("txt_heroword"):setVisible(false)
   --self.mainUI:getChildByName("home_main"):getChildByName("txt_heroword"):setVisible(false)
  
	--self.userLevel = DataManager.getCurrUser().level
	self.cardsInfo = DataManager.getCardsData()
	--self.equipsData = DataManager.getEquipsData()
	self.queue = CommonManager.getQueueData()
	self.mainCard = CommonManager.getSubTableByKey(self.cardsInfo,{name = "cardId", value=self.queue[1]})
	local position = self.mainUI:getChildByName("home_main"):getChildByName("icon_home_stage_large"):getPosition()
	local size = self.mainUI:getChildByName("home_main"):getChildByName("icon_home_stage_large"):getContentSize()
	local cardSpriteFrame = getCardSpriteFrame(CommonManager:changeAvatarByCardInfo( self.mainCard ))
	local cardDisplay = CocosObject.new(CCSprite:createWithSpriteFrame(cardSpriteFrame))
	cardDisplay:setPosition(ccp(size.width/2, size.height/2))
	cardDisplay:setScale(2)
	
	self.mainUI:getChildByName("home_main"):getChildByName("icon_home_stage_large"):removeChildren(true)
	
	--self.mainUI:getChildByName("home_main"):getChildByName("home_lv_t"):getChildByName("bgg"):setVisible(false)
	self.mainUI:getChildByName("home_main"):getChildByName("home_lv_t"):getChildByName("common_star_sb"):setVisible(false)
	--主将背景
	local mainActorBG = Sprite:create("pic/bg_home_bg.png")
	mainActorBG:setPosition(ccp(size.width/2, size.height/2))
	mainActorBG:setScale(2.75)
	self.mainUI:getChildByName("home_main"):getChildByName("icon_home_stage_large"):addChild(mainActorBG)
	self.mainUI:getChildByName("home_main"):getChildByName("icon_home_stage_large"):addChild(cardDisplay)
	
	local meta = MetaManager.card_meta[self.mainCard.metaId]
	local cardName = CanonGoodIcon.getCardNameWithoutEvolutionLevel( self.mainCard.metaId )
	local bmpName = BitmapText:create(cardName, "common/card_name.fnt", 0, kCCTextAlignmentLeft)
	bmpName:setAnchorPoint(ccp(0,0.5))
    bmpName:setPosition(ccp( 60, -2 ))
    self.mainUI:getChildByName("home_main"):getChildByName("home_lv_t"):addChild(bmpName)
	--武将等级
	local aNewLabel = ArtLabelTTF:create(tostring(self.mainCard.level), true)
	aNewLabel:setCenterColor(ccc3(255,236,60))
	aNewLabel:setAroundColor(ccc3(96,37,8))
	aNewLabel:setSize(30)
	aNewLabel:construct()
	local aNewLabelSize = aNewLabel:getTextContentSize()
	aNewLabel:setPosition(ccp(350 + aNewLabelSize.width / 2, -4))

	self.mainUI:getChildByName("home_main"):getChildByName("home_lv_t"):addChild(CocosObject.new(aNewLabel))
	--武将稀有度
	local xin_w = 30
	local xin_x = self.mainUI:getChildByName("home_main"):getChildByName("home_lv_t"):getChildByName("common_star_sb"):getPositionX() + xin_w
	for i = 1, meta.rare, 1 do
	  local xin = Sprite:createWithSpriteFrameName("card_xing.png")
	  local pos = ccp( xin_x + xin_w*(i-1), -50)
	  xin:setScale(1.3)
	  xin:setPosition(pos)
	  self.mainUI:getChildByName("home_main"):getChildByName("home_lv_t"):addChild(xin)
	end
	--武将国家
	local fileCountry = "countryCircle_" .. meta.country .. ".png"
	local country = Sprite:createWithSpriteFrameName(fileCountry)
	country:setPosition(ccp(30, -2))
	self.mainUI:getChildByName("home_main"):getChildByName("home_lv_t"):addChild(country)
	
  --关卡
  local btn_home_stage_large = Button:create(self.mainUI:getChildByName("home_main"):getChildByName("icon_home_stage_large"))
  btn_home_stage_large:addEventListener( Events.kStart, onClickCityMain, self )  
  
  --活动
  local btn_home_activity = Button:create(self.mainUI:getChildByName("home_main"):getChildByName("icon_home_active"))
  btn_home_activity:addEventListener( Events.kStart, onClickActivity, self )
  --self.activityParticle = ParticleManager.geneParticle(ParticlePathConstants.FxActivities, ccp(200, 575), 2, 1000, self.mainUI)
  
  --通天塔
  local btn_home_babelTower = Button:create(self.mainUI:getChildByName("home_main"):getChildByName("icon_home_babelTower"))
  btn_home_babelTower:addEventListener( Events.kStart, onClickPK, self )
  --self.mainUI:getChildByName("home_main"):getChildByName("home_lv_babelTower"):getChildByName("txt_home_lv"):getChildByName("txt_home_lv"):setString(getTextByKey("home_unlockLevel"))
  --self.mainUI:getChildByName("home_main"):getChildByName("home_lv_babelTower"):getChildByName("txt_home_lv_num"):getChildByName("font"):setString(MetaManager.game_meta.gameSettingConfig.babelConfig.babelTowerUnlockLevel)
  --if (userData.level >= MetaManager.game_meta.gameSettingConfig.babelConfig.babelTowerUnlockLevel) then
  --  self.mainUI:getChildByName("home_main"):getChildByName("home_lv_babelTower"):setVisible(false)
    --self.babelParticle1 = ParticleManager.geneParticle(ParticlePathConstants.FxFire, ccp(535, 1040), 1, 1000, self.mainUI)
    --self.babelParticle2 = ParticleManager.geneParticle(ParticlePathConstants.FxFire, ccp(685, 1055), 1, 1000, self.mainUI)
    --self.babelParticle3 = ParticleManager.geneParticle(ParticlePathConstants.FxFire, ccp(555, 1105), 1, 1000, self.mainUI)
    --self.babelParticle4 = ParticleManager.geneParticle(ParticlePathConstants.FxFire, ccp(685, 1120), 1, 1000, self.mainUI)
  --end
  
  --竞技场
  local btn_home_arena = Button:create(self.mainUI:getChildByName("home_main"):getChildByName("icon_home_arena"))
  btn_home_arena:addEventListener( Events.kStart, onClickArena, self )
  self.mainUI:getChildByName("home_main"):getChildByName("home_lv_arena"):getChildByName("txt_home_lv"):getChildByName("txt_home_lv"):setString(getTextByKey("home_unlockLevel"))
  self.mainUI:getChildByName("home_main"):getChildByName("home_lv_arena"):getChildByName("txt_home_lv_num"):getChildByName("font"):setString(MetaManager.game_meta.gameSettingConfig.arenaUnlockLevel)
  self.mainUI:getChildByName("home_main"):getChildByName("home_lv_arena"):setVisible(false)
  
  --点击联系客服
  local function onClickGM(evt)
	if __ANDROID then
		CanonEnvInjector:callJira()
	elseif __IOS then
		PlatformMgr:getInstance():showJiraDialog()
	else
		local function gameInitResponse( e )
			DataManager.GameInitData = e.data
		end

		local gameInitRequest = GameInitRequest.new( nil ,rpc.SendingPriority.kNormal )
		gameInitRequest:addEventListener( RequestNotifyEnum.GameInitSucceed, gameInitResponse )
		gameInitRequest:start()
	end
  end
  --联系客服提示UI
  self.GM = Sprite:create("common/GM.png")
  self.GM:setScale(1.05)
  self.GM:setPosition(ccp(665, 970))
  self.btnGM = Button:create(self.GM)  
  self.btnGM:addEventListener(Events.kStart, onClickGM, self)
  self.btnGM:setVisible(false)
  self.btnGM:setEnable(false)
  self.mainUI:addChild(self.GM)
  self.mailPosX = 665
  self.mailPosY = 970
   
  --点击邮件提示
  local function onClickMailHint(evt)
    self:replaceScene(EmailScene)
  end
  
  --邮件提示UI
  local mailHintCC = CCSprite:create("common/MailHint.png")
  self.mailHint = CocosObject.new(mailHintCC)
  self.mailHint:setPosition(ccp(665, 870+25))
  self.btnMailHint = Button:create(self.mailHint)  
  self.btnMailHint:addEventListener(Events.kStart, onClickMailHint, self)
  self.btnMailHint:setVisible(false)
  self.btnMailHint:setEnable(false)
  self.mainUI:addChild(self.mailHint)
  self.mailPosX = 665
  self.mailPosY = 870+25
  
  --[[
  if __IOS or __MAC then
	  local gameInitData = DataManager.getGameInitData()
	  if gameInitData.fishInviteCode ~= nil then
      he_log_info("++++++++++++invite code :" .. gameInitData.fishInviteCode)
		self.HostingCode = ArtLabelTTF:create(getTextByKey("invitationCode") .. ": " .. gameInitData.fishInviteCode)
		self.HostingCode:setTextAnchorPoint(ccp(0,0.5))
		self.HostingCode:setSize(30)
		self.HostingCode:construct()
		self.HostingCode:setPosition(ccp(300,970))
		self.HostingCode:setVisible(false)
		self.mainUI:addChild(CocosObject.new(self.HostingCode))
	  end
  end 
  --]]
  
  --点击年兽提示
  local function onClickMBHint(evt)
    local function successCallback(data)
      local argv = {enterScene="MainMenuScene",returnScene="MainMenuScene",params={selectedTag = MultiplayerBossTagEnum.BossList, data = data}}
      self:replaceScene(MultiplayerBossScene, argv)
    end
    
    local function failureCallback(data)
      if data.retCode == 714520 then
        local function closeCanonMessageBox()
        end
        local text = Localization:getInstance():getText("activityNian_timeOver")
        CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
      else
        local function closeCanonMessageBox()
        end
        local text = Localization:getInstance():getText("defaultError_popupText", {errorCodeId = data.retCode})
        CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
      end
    end
    
    MultiplayerBossScene.doPreparationBeforeEnterMultiplayerBossPanel(successCallback, failureCallback)
  end
  
  --年兽提示UI
  self.MBHint = Sprite:create("common/warning.png")
  self.MBHint:setPosition(ccp(665, 770+50))
  self.btnMBHint = Button:create(self.MBHint)  
  self.btnMBHint:addEventListener(Events.kStart, onClickMBHint, self)
  self.btnMBHint:setVisible(false)
  self.btnMBHint:setEnable(false)
  self.mainUI:addChild(self.MBHint)
  self.MBPosX = 665
  self.MBPosY = 770+50
    
  self:setupCountdownRewardUI(self.mainUI:getChildByName("home_main"):getChildByName("home_countdown_reward") , nil ,true)
  
  --粒子效果
  --self.Particles = {
  --  self.activityParticle,
  --  self.babelParticle1,
  --  self.babelParticle2,
  --  self.babelParticle3,
  --  self.babelParticle4,
  --  self.arenaParticle,
  --}
  --for _, aChild in pairs(self.Particles) do
  --  aChild:setVisible(false)
  --end
  --[[
  if self.rewardParticle and self.rewardParticle.refCocosObj then
    self.rewardParticle:setVisible(false)
  end
  ]]
  BaseUIScene.onInit(self)
  self:setTitleVisible(false)
  self.backDisplay:setVisible(false)
  self.tableUI:reloadData()

  local function getDailyActiveInfoSucceedResponse( evt )
	-- body
	-- print("getDailyActiveInfoSucceedResponse:"..tostringRich(evt.data.dailyActiveInfo))
	-- print("g_homeInfo:"..tostringRich(g_homeInfo))
	DailyTargetScene.tipNum = (g_homeInfo and g_homeInfo.enableGainDailyAchieveRewardNum or 0)
	local argv = {enterScene=nil,returnScene=nil,params={data = evt.data , secretaryTips = (g_homeInfo and g_homeInfo.enableGainDailyActiveRewardNum or 0)}}
	self:replaceScene(SecretaryScene,argv);
  end

  local function getDailyActiveInfoFailedResponse( evt )
  	print(table.serialize(evt.data))
  	-- body
  end
  
  local function onClickTop1( evt )
  	if(DataManager.getCurrUser().level < DataManager.GameMetaData.dailyActiveConfig.levelLimit) then
  		-- SuspensionLabel:showContent(self, getTextByKey("activity_daily_leveltxt"))
  		DailyTargetScene.tipNum = (g_homeInfo and g_homeInfo.enableGainDailyAchieveRewardNum or 0)
  		self:replaceScene(AchievementScene)
  		do return end
  	end
    --SuspensionLabel:showContent(self, getTextByKey("home_maidDisabled"))
    local request = GetDailyActiveInfoRequest.new( {}, rpc.SendingPriority.kHigh )
	request:addEventListener( RequestNotifyEnum.GetDailyActiveInfoSucceed, getDailyActiveInfoSucceedResponse )
	request:addEventListener( RequestNotifyEnum.GetDailyActiveInfoFailed, getDailyActiveInfoFailedResponse )
	request:start()
  end
  
  local function onClickTop2( evt )
    self:replaceScene(ActivityPanelScene)
  end
  
  local function onClickTop3( evt )
	self:replaceScene(RewardScene)
  end
  
  local function onClickTop4( evt )
	self:replaceScene(GachaScene, {returnScene = "MainMenuScene"})
  end
  
  local function onClickTop5( evt )
	self:replaceScene(ShopScene)
  end

  local function onClickTop6( evt )
	if not TreasureManager.isUserLevelEnough() then
	  SuspensionLabel:showContent(self, Localization:getInstance():getText("module_needLevel", {num = TreasureManager.getTreasureUserLevel()})) -- todo
	  return
	end
	self:replaceScene(TreasureGachaScene)
  end
  
  local function onClickChat( evt )
  	print("onClickChat")
    --[[
	local scene = Director:mgr():run()
	local chatPanel = UnionChatContainerPanel:create(scene)
	scene:addChild(chatPanel)
	chatPanel:scaleIn()]]
  local scene = Director:mgr():run()
  local chatPanel = UnionChatContainerPanel:create(scene, {vipSpecial = true})
  PopoutManager:sharedManager():popout(chatPanel, kPopoutDir.kScale, true, false , scene)

  	self.btnChat:setShined(ChatManager.hasUnreadChat())
  	
  end

  --接收到新聊天消息
  local function refreshChatShine(evt)
    self.btnChat:setShined(ChatManager.hasUnreadChat())
  end
  self.refreshChatShine = refreshChatShine
  
  self.topButtons = builder:build("mainmenu_scene_home_icons_up")
  self.topButtons:setPosition(ccp(0,15))
  local button = Button:create(self.topButtons:getChildByName("btn_b1"))  --女神
  button:addEventListener( Events.kStart, onClickTop1, self )
  self.topButtons:getChildByName("btn_b1"):getChildByName("tips_little"):setVisible(false)
  self.topButtons:getChildByName("btn_b1"):getChildByName("txt_font"):setVisible(false)
  
  button = Button:create(self.topButtons:getChildByName("btn_b2"))  --活动
  button:addEventListener( Events.kStart, onClickTop2, self )
  self.topButtons:getChildByName("btn_b2"):getChildByName("tips_little"):setVisible(false)
  self.topButtons:getChildByName("btn_b2"):getChildByName("txt_font"):setVisible(false)
  
  button = Button:create(self.topButtons:getChildByName("btn_b3"))  --奖励
  button:addEventListener( Events.kStart, onClickTop3, self )
  self.topButtons:getChildByName("btn_b3"):getChildByName("tips_little"):setVisible(false)
  self.topButtons:getChildByName("btn_b3"):getChildByName("txt_font"):setVisible(false)
  
  button = Button:create(self.topButtons:getChildByName("btn_b4"))  --求将
  button:addEventListener( Events.kStart, onClickTop4, self )
  self.topButtons:getChildByName("btn_b4"):getChildByName("tips_little"):setVisible(false)
  self.topButtons:getChildByName("btn_b4"):getChildByName("txt_font"):setVisible(false)

  button = Button:create(self.topButtons:getChildByName("btn_b6"))  --宝宝
  button:addEventListener( Events.kStart, onClickTop6, self )
  self.topButtons:getChildByName("btn_b6"):getChildByName("tips_little"):setVisible(false)
  self.topButtons:getChildByName("btn_b6"):getChildByName("txt_font"):setVisible(false)  
  
  button = Button:create(self.topButtons:getChildByName("btn_b5"))  --商城
  button:addEventListener( Events.kStart, onClickTop5, self )

  --聊天
  self.btnChat = Button:create(self.mainUI:getChildByName("btn_chat_tp"))  --聊天
  self.btnChat:addEventListener( Events.kStart, onClickChat, self )
  self.btnChat:setShined(ChatManager.hasUnreadChat())
  NotificationManager:addEventListener(ChatManager.CHAT_MESSAGE_SHOWED,self.refreshChatShine, self)
  NotificationManager:addEventListener(ChatManager.CHAT_TAG_VIEWED,self.refreshChatShine, self)
  
  if isInAppleReview() then
  	self.btnChat:setVisible(false)
  end


  self:addChild(self.topButtons)

  local function notificationHandler(name)
    if("APP_ENTER_FOREGROUND" == name) then -- 重新进入游戏
      --重新获取商品列表
      getPaymentInfo()
    end
  end
  CCNotificationCenter:sharedNotificationCenter():registerScriptObserver(notificationHandler)
end

function MainMenuScene:createEntryList( entryListData )
  --点击事件
  local cellTag = 1024
  local buttonTag = 100
  local function onListItemTouch(e) 
    local index = e.data + 1
    CanonPlayEffect(MusicPathConstants.ButtonTableView)
    if self.entryListData[index].callback ~= nil then
			if self.entryListData[index].name == "Train" and (DataManager.getCurrUser().level<19) then
				SuspensionLabel:showContent(self, Localization:getInstance():getText("cardInfo_TrainLocked"))
			-- elseif 	self.entryListData[index].name == "xiaomi" then
			-- 	openXiaomiMainEnter()
			elseif self.entryListData[index].name == "Combine" and (DataManager.getCurrUser().level < MetaManager.game_meta.gameSettingConfig.itemSynthetizeUnlockLevel) then
				SuspensionLabel:showContent(self, Localization:getInstance():getText("synthetize_levelInsufficient", {num = MetaManager.game_meta.gameSettingConfig.itemSynthetizeUnlockLevel}))
			elseif self.entryListData[index].name == "CardRebirth" and (DataManager.getCurrUser().level < MetaManager.getGameSettingConfig().sacrificeUnlockLevel) then
				SuspensionLabel:showContent(self, Localization:getInstance():getText("module_needLevel", {num = MetaManager.getGameSettingConfig().sacrificeUnlockLevel}))
			elseif self.entryListData[index].name == "SpiritBackPack" and not SpiritManager.isUserLevelEnough() then
				SuspensionLabel:showContent(self, Localization:getInstance():getText("module_needLevel", {num = DataManager.GameMetaData.spiritSettingConfig.unlockLevel}))
			elseif self.entryListData[index].name == "TreasureBackpack" and not TreasureManager.isUserLevelEnough() then
				SuspensionLabel:showContent(self, Localization:getInstance():getText("module_needLevel", {num = TreasureManager.getTreasureUserLevel()}))
			else
				self:replaceScene(self.entryListData[index].callback, self.entryListData[index].argv)
			end
    else
      CCMessageBox("It's not complete yet...","Canon")
    end
    --self.tableUI:reloadData()   
  end
  
  local EntryCell = class(TableViewRenderer)
  function EntryCell:ctor(width, height)
    for i=1,#entryListData do
      self.list[i] = i
    end
  end
  function EntryCell:buildCell(container)
    local layer = Layer:create()
    container:addChild(layer)
    layer:setTag(cellTag)
  end    
  function EntryCell:setData( rawCocosObj, index )
    local cellLayer = self:getChildByTag(rawCocosObj,cellTag)
    cellLayer:removeAllChildrenWithCleanup(true)
    local pic = Sprite:create("#mainmenu_scene_new/"..entryListData[index+1].pic)
    pic:setPosition(ccp(55,27))
    cellLayer:addChild(pic.refCocosObj)
    pic:setTag(buttonTag)
    pic:dispose()
    
    -- 添加首页提示信息
    local function geneTip(num)
      if num and num > 0 then
        local tip = nil
        local numField = TextField:create("" .. num)
        numField:setAnchorPoint(ccp(0.5, 0.5))
        numField:setFontSize(28)
        numField:setDimensions(CCSizeMake(50, 0))
        numField:setHorizontalAlignment(kCCTextAlignmentCenter)
        if num >= 100 then
          tip = Sprite:create(UI_RES_PATH.."/mainmenu_scene_new/mainmenu_scene_tips_big.png")
          numField:setPosition(ccp(35, 23))
        else 
          tip = Sprite:create(UI_RES_PATH.."/mainmenu_scene_new/mainmenu_scene_tips_little.png")
          numField:setPosition(ccp(24, 23))
        end 
        tip:setPosition(ccp(85, 70))
        tip:addChild(numField)
        cellLayer:addChild(tip.refCocosObj)
        tip:dispose()
      end
    end
    
    if g_homeInfo then
      if entryListData[index + 1].name == "Friend" then 
        geneTip(g_homeInfo.invitedNum)
      end
      if entryListData[index + 1].name == "Reward" then
        geneTip(g_homeInfo.rewardNum)
      end
      if entryListData[index + 1].name == "Email" then
        geneTip(g_homeInfo.unreadMessageNum)
      end
    end
      
    -- local _,text  = ViewControlUtil.buildArtLabel(nil, entryListData[index+1].title, ccc3(250, 230, 170), ccc3(60, 0, 0))
    -- text:setSize(24)
    -- text:setPosition(ccp(55,0))
    -- cellLayer:addChild(text)
  end
  
  local renderer = EntryCell.new(110, 100)
  local entry = TableView:create(renderer, 680, 140, cellTag, buttonTag)
  entry:setDirection(kCCScrollViewDirectionHorizontal)
  entry:setPageEnabled(true)
  entry:addEventListener(DisplayEvents.kTouchItem, onListItemTouch , self)
  local entryListIcon = self.mainUI:getChildByName("home_icons")
  --entry:setPosition(ccp( entryListIcon:getPositionX()+20, entryListIcon:getPositionY()-entryListIcon:getGroupBounds().size.height-40))
  entry:setPosition(ccp(22, -130))
  entry:setZOrder(1001)
	return entry    
end

function MainMenuScene:dispose()
	
	self.mainUI:getChildByName("home_main"):getChildByName("icon_home_active"):removeChildren(true)
	NotificationManager:removeEventListener(ChatManager.CHAT_MESSAGE_SHOWED, self.refreshChatShine)
	NotificationManager:removeEventListener(ChatManager.CHAT_TAG_VIEWED, self.refreshChatShine)
  --[[
  if self.onUpdateRewardUIFunc then
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.onUpdateRewardUIFunc)
  end
  ]]
	self.curSceneEnum = nil;
	g_curSceneEnum = nil
  if self.changeAdvFunc then
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.changeAdvFunc)
  end
  
  if self.showTextFunc then
	CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry( self.showTextFunc )
  end
  
  if self.cdLabelComponent then
  	self.cdLabelComponent:stop()
  end
 
  
  
  
  MainMenuScene.super.dispose(self)
end

function MainMenuScene:doEnterAnimation()
  self:setTableViewsEnabled(false)
  self:preEnterAnimation()
  self:startEnterAnimation()
  self:setTableViewsEnabled(true)
end

function MainMenuScene:preEnterAnimation()
  BaseUIScene.preEnterAnimation(self)
  --print("__MainMenuScene:preEnterAnimation")
  CanonPlayBackgroundMusic("music/background.mp3", true)
end

local function TryNextGuide()
	local List1 = {}
	List1[1] = GuideConfig.kEnterGame
	List1[2] = GuideConfig.kGachaN
	List1[3] = GuideConfig.kOn
	List1[4] = GuideConfig.kRisk1
	List1[5] = GuideConfig.kCardUpgrade
	List1[6] = GuideConfig.kRisk2
	List1[7] = GuideConfig.kCardEvol
	List1[8] = GuideConfig.kRisk3
	List1[9] = GuideConfig.kGift
	List1[10] = GuideConfig.kEquipWear

	for Index1 = 1, 8 do
		if ( not IsGuideExecuted( List1[Index1] ) ) then
			_G.Guide_Index_Now = Index1

			if Index1 >= 8 then
				Set_ShareData( "Need_To_Show_Gifts", 1 )
			end

			ExeNewGuide( List1[Index1] )
			return true
		end
	end
	return false
end

local function OnOneGuideFinished()
	if Get_ShareData("New_User_Guide_Running") == 1 then
		return
	end
	if g_curGuide ~= nil or Get_ShareData("Guide_Save_State") == 0 then --判断，如果上一个状态还没保存，就在这里保存，以免漏掉
		Set_ShareData( "Guide_Save_State", 0 )
		GlobalScene_globalUpdate()
	end
	if _G.Guide_Index_Now+1 <= 10 and not TryNextGuide() then
		Set_ShareData( "NewUserGuide_Not_Finished", 0 )
		RegisterOnGuideFinishCallback(nil)

		local function Aquire_One_Card( e )
			local rewardInfo = e.data.rewards
			local CurScene = Director.sharedDirector():getRunningScene()
			local RewardPanel1 = GetRewardInfoPanel:create( CurScene, rewardInfo )
			PopoutManager:sharedManager():popout( RewardPanel1, kPopoutDir.kScale, true, false ,CurScene )

			RewardManager:getReward( e.data.rewards )
		end
		local aquireOneCardParams = {}
		local aquireOneCard = GainTutorialFinishRewardRequest.new( aquireOneCardParams, rpc.SendingPriority.kHigh )
		aquireOneCard:addEventListener( RequestNotifyEnum.GainTutorialFinishRewardSucceed, Aquire_One_Card )
		aquireOneCard:start()
	end
end

function MainMenuScene:startEnterAnimation()
  BaseUIScene.startEnterAnimation(self)
  --print("__MainMenuScene:startEnterAnimation")

  local function checkTreasureBox()
	if GuideConfig.kTreasureBox == nil then  --多阵容引导框，只弹一次
		GuideConfig.kTreasureBox = "Guide_TreasureBox"
	end
	if GuideConfig.kTreasure == nil then  --多阵容引导
		GuideConfig.kTreasure = "Guide_Treasure"
	end
	if not IsGuideExecuted(GuideConfig.kTreasureBox) and not IsGuideExecuted(GuideConfig.kTreasure) and
	DataManager.getCurrUser().level >= (TreasureManager.getTreasureUserLevel()) then 
	  	local newBox = UserUnlockContentBox:create((TreasureManager.getTreasureUserLevel()),nil)
	  	PopoutManager:sharedManager():popout(newBox, kPopoutDir.kScale, true, false)
	  	local gameData = DataManager.getGameInitData()
	  	table.insert(gameData.sharkUserExtend.tutorialSteps,{funcName = "Guide_TreasureBox",step = 1})
	  	DataManager.setGameInitData(gameData)
        local params = {funcName = "Guide_TreasureBox",step = 1}
        local request = RecordTutorialStepRequest.new( params, rpc.SendingPriority.kHigh )
        request:start()
    else
    	--添加下一个新手引导框
	end
  end

  local function checkMultiLineupBox()
	if GuideConfig.kMultiLineupBox == nil then  --多阵容引导框，只弹一次
		GuideConfig.kMultiLineupBox = "Guide_MultiLineupBox"
	end
	if GuideConfig.kMultiLineup == nil then  --多阵容引导
		GuideConfig.kMultiLineup = "Guide_MultiLineup"
	end
	if not IsGuideExecuted(GuideConfig.kMultiLineupBox) and not IsGuideExecuted(GuideConfig.kMultiLineup) and
	DataManager.getCurrUser().level >= (MetaManager.game_meta.gameSettingConfig.lineupUnlockLevel or 43) then 
	  	local newBox = UserUnlockContentBox:create((MetaManager.game_meta.gameSettingConfig.lineupUnlockLevel or 43),checkTreasureBox)
	  	PopoutManager:sharedManager():popout(newBox, kPopoutDir.kScale, true, false)
	  	local gameData = DataManager.getGameInitData()
	  	table.insert(gameData.sharkUserExtend.tutorialSteps,{funcName = "Guide_MultiLineupBox",step = 1})
	  	DataManager.setGameInitData(gameData)
        local params = {funcName = "Guide_MultiLineupBox",step = 1}
        local request = RecordTutorialStepRequest.new( params, rpc.SendingPriority.kHigh )
        request:start()
    else
    	checkTreasureBox()
	end
  end

  local function checkCrossPVP()
  	if GuideConfig.kCrossPVP == nil then  
		GuideConfig.kCrossPVP = "Guide_CrossPVP"
	end
	if GuideConfig.kCrossPVPBox == nil then  --多阵容引导
		GuideConfig.kCrossPVPBox = "Guide_CrossPVPBox"
	end
	local ret = false
	if not IsGuideExecuted(GuideConfig.kCrossPVP) and not IsGuideExecuted(GuideConfig.kCrossPVPBox) and 
	DataManager.getCurrUser().level >= 50 and CrossArenaManager.checkPVPIsOpen() then
		ret = true
	end
	return ret
  end

  local function enterActionFinished()
    self:nodeAnimationFinished()

    --pop panel function 
    local function popPanelFinish(para)
	    self.targetInfoPanel = nil
		if para == "ContinueLoginGotoActivityPanel" then
			--如果是从七日连登回来，则跳转到活动面板
			getHomeInfo()
			self:replaceScene(ActivityPanelScene, {selectPanelName = "Activity_ContinueLoginNew"})
		else
			getHomeInfo()
			if (DataManager.getCurrUser().level >= MetaManager.getGameSettingConfig().sacrificeUnlockLevel) and (not DataManager.getGameInitData().sharkUserExtend.enchantStepReward) then
				if not IsGuideExecuted(GuideConfig.kSacrifice) then
					if not sacrifice_already_showed then
						sacrifice_already_showed = true
						local newBox = UserUnlockContentBox:create(MetaManager.getGameSettingConfig().sacrificeUnlockLevel, checkMultiLineupBox)
						PopoutManager:sharedManager():popout(newBox, kPopoutDir.kScale, true, false)
					end
				else
					local rewardPanel = EnchantGuideRewardPanel:create(self)
					PopoutManager:sharedManager():popout(rewardPanel, kPopoutDir.kScale, true, false , self)
				end
			else --不弹祭炼时判断是否弹出多阵容引导框	
				if checkCrossPVP() then--跨服pvp引导框，只弹一次
					local newBox = UserUnlockContentBox:create(50,nil)
				  	PopoutManager:sharedManager():popout(newBox, kPopoutDir.kScale, true, false)
				  	local gameData = DataManager.getGameInitData()
				  	table.insert(gameData.sharkUserExtend.tutorialSteps,{funcName = "Guide_CrossPVP",step = 1})
				  	DataManager.setGameInitData(gameData)
			        local params = {funcName = "Guide_CrossPVP",step = 1}
			        local request = RecordTutorialStepRequest.new( params, rpc.SendingPriority.kHigh )
			        request:start()
				else
					checkMultiLineupBox()
				end			
			end
		end
    end 
	
	
	local function popContinueLoginPanel()
	
	local isInApple = isInAppleReview()	
	if not isInApple then
	    if Activity_rechargeLayer.showGuidePanel and (Activity_rechargeLayer.JudgeDisplayAdvertising( ) > 0) then
	                popPanelFinish()
	    		Activity_rechargeLayer.showGuidePanel = false
	    		local limitRewardPanel = LimitRewardPanel:create(self)
				self.targetInfoPanel = limitRewardPanel
				PopoutManager:sharedManager():popout(limitRewardPanel, kPopoutDir.kScale, true, false , self)
	     elseif MaintenanceManager.isActivityOpen("exchangeDaily") and Activity_ExchangeDailyLayer.showGuidePanel then
	     	Activity_ExchangeDailyLayer.showGuidePanel = false
	     	local ExchangeDailyPanel = ActivityExchangeDailyPanel:create(self)
			self.targetInfoPanel = ExchangeDailyPanel
			PopoutManager:sharedManager():popout(ExchangeDailyPanel, kPopoutDir.kScale, true, false , self)
	     else
	      g_curServerTimeStamp = TimeUtil.getServerTimeSeconds()
		  local isEnable, remainDays, todayFrom1970 = shouldPopContinueLoginPanelToday(g_curServerTimeStamp) 
	      if isEnable then
	        self.targetInfoPanel = New_UserContinueLoginShowPanel:create( self,remainDays,todayFrom1970,popPanelFinish)
	        PopoutManager:sharedManager():popout(self.targetInfoPanel , kPopoutDir.kScale, true, false ,self)
	        gain_reward = true
	      else
	        popPanelFinish()
	      end
	    end 
	else
	    popPanelFinish() 
	end
    end
	
	--check whether pop facebookshare box
	local function popFacebookSharePanel()
		local shareInfo = localStorage.getShouldFacebbookShareInfo(   ) 
		if FacebookShareManager.isOpenFacebookShareFunc() and shareInfo ~= "" and shareInfo.shareId and shareInfo.shareId ~= "" then
			--分享facebook功能
			local curScene = Director.sharedDirector():getRunningScene()
			local sharePanel = FacebookShareTriggerPanel:create( curScene,shareInfo.shareId,shareInfo.shareText,popContinueLoginPanel )
			PopoutManager:sharedManager():popout( sharePanel, kPopoutDir.kScale, true, false ,curScene )
			--FacebookShareManager.setFacebookShareId(shareInfo.shareId)
			--FacebookShareManager.setFacebookShareCallback(popContinueLoginPanel)
			--临时弹框
			--CanonMessageBox:Show(getTextByKey("shareFacebook balabala"), ShowMessageType.ShowText, ShowButtonType.ID_OK_CANCEL, 40, gotoShareFacebook, cancelShareFacebook)
		else
			popContinueLoginPanel()
		end
	end
	
    local function popSigninPanel()

      g_curServerTimeStamp = TimeUtil.getServerTimeSeconds()
	    if not isUserSigninToday(g_curServerTimeStamp) and CalendarSignInPanel:enable(g_curServerTimeStamp) then
            self.targetInfoPanel = CalendarSignInPanel:create( self ,nil,CalendarSignInType.popPanel,popFacebookSharePanel)
		    PopoutManager:sharedManager():popout(self.targetInfoPanel , kPopoutDir.kScale, true, false ,self)
            gain_reward = true
	    else
        popFacebookSharePanel()
      end 
    end 
    
    local function popAnnouncementPanel()
      local announcementData = nil      
      local function getAnnouncementInfoFinish(responseData)
        announcementData = responseData.data.announcementItemMetas
        if announcementData and table.maxn(announcementData) > 0 and not isInAppleReview() then
          self.targetInfoPanel = AnnouncementPanel:create(self, announcementData, ShowPanelType.ShowAnnounce, popSigninPanel)
          PopoutManager:sharedManager():popout(self.targetInfoPanel, kPopoutDir.kScale, true, false, self)
        else
          popSigninPanel()
        end
      end
      if enter_first then
        enter_first = false
        local params = {}
        local request = GetAnnouncementInfoRequest.new(params, rpc.SendingPriority.kHigh)
        request:addEventListener(RequestNotifyEnum.GetAnnouncementInfoSucceed, getAnnouncementInfoFinish)
        request:start()        
      else
        popSigninPanel()
      end
    end
	
	local function popOldUserComeBackPanel()
	  if OldUserComeBackPanel:shouldPop() then
        self.targetInfoPanel = OldUserComeBackPanel:create( self ,popAnnouncementPanel)
        PopoutManager:sharedManager():popout(self.targetInfoPanel , kPopoutDir.kScale, true, false ,self)
      else
        popAnnouncementPanel()
      end
	end
	
    --first pop panel
	function popFirstPanel()
		popOldUserComeBackPanel()
	end
	--local isGuideRunning = Get_ShareData( "New_User_Guide_Running")
	--if (isGuideRunning ~= 1) then
	if not IsCurrentNewUserGuideRunning() then
    
    local Now_Run_New_User_Guide = nil
    
    if _G.Global_Guide_Already == nil then --(暂时屏蔽)
        _G.Global_Guide_Already = 1

		Now_Run_New_User_Guide = TryNextGuide()
		if Now_Run_New_User_Guide then
			RegisterOnGuideFinishCallback(OnOneGuideFinished)
		end
    end

    local function Is_NewUserGuide_Run()
      if (not Now_Run_New_User_Guide) and Get_ShareData("New_User_Guide_Running")~=1 then  
        return false
      else
        return true
      end
    end
    
    
    if not Is_NewUserGuide_Run() then
    	if __IOS then
			local needUserWarning = false
			local transactions = SKPaymentQueue:defaultQueue():transactions()
			if (#transactions > 0) then
				for _,v in pairs(transactions) do
					if v:transactionState() == SKPaymentTransactionStatePurchased then
						needUserWarning = true
						break
					end
				end
			end
			if needUserWarning then
				CanonMessageBox.showText(ShowButtonType.ID_OK, "支付遇到问题，请尝试到商城重新点击购买项目(不会重复购买)", nil, 
					{text = getTextByKey("yes"),
	                    callbackFunc = function()
	                        popFirstPanel()
	                	end
	                }, nil)
			else
				popFirstPanel()
			end
		else
			popFirstPanel()
		end
	else
		HeMemDataHolder:setString("savedSortOrder_card" , "")
		HeMemDataHolder:setString("savedSortOrder_equip" , "")
		HeMemDataHolder:setString("savedSortOrder_spirit" , "")
		HeMemDataHolder:setString("notShowInBattleCards" , "")
		HeMemDataHolder:setString("notShowEquipedItems" , "")
		HeMemDataHolder:setString("notShowEquipedSpirits" , "")
		HeMemDataHolder:setInteger("notShowCountryCards" , 0) --显示x国武将的状态，4位二进制
		HeMemDataHolder:setString("savedSortOrder_treasure" , "")
		HeMemDataHolder:setString("notShowEquipedTreasure" , "")
    end
    
	
	  end
  end

  self.UIparts = {
		center = {
			--self.mainUI:getChildByName("home_main"):getChildByName("bg_home"),
			self.mainUI:getChildByName("home_main"):getChildByName("home_lv_t"):getChildByName("frame_home_dialogue"),
			self.mainUI:getChildByName("home_main"):getChildByName("home_lv_t"),
			self.mainUI:getChildByName("home_main"):getChildByName("home_lv_babelTower"),
			self.mainUI:getChildByName("home_main"):getChildByName("home_lv_arena"),
			self.mainUI:getChildByName("home_main"):getChildByName("home_countdown_reward"),
			self.mainUI:getChildByName("home_main"):getChildByName("icon_home_active"),
			self.mainUI:getChildByName("home_main"):getChildByName("icon_home_arena"),
			self.mainUI:getChildByName("home_main"):getChildByName("icon_home_babelTower"),
			self.mainUI:getChildByName("home_main"):getChildByName("icon_home_stage_large"),
			self.mainUI:getChildByName("home_main"):getChildByName("bg_home_w"),
			self.mainUI:getChildByName("home_main"):getChildByName("txt_heroword"),self.mainUI:getChildByName("home_main"):getChildByName("txt_heroword"),
			self.mainUI:getChildByName("home_main"):getChildByName("bg_mainmenu_tiao_kanbanMusume"),
		},
		icons = self.mainUI:getChildByName("home_icons"),
	}
  local aIconsHeight = self.UIparts.icons:getGroupBounds().size.height
  self.UIparts.icons:setPositionY(self.UIparts.icons:getPositionY() - aIconsHeight)
  self.UIparts.icons:runAction(CCMoveBy:create(enter_animation_duration, ccp(0, aIconsHeight)))
    
  for _, aChild in pairs(self.UIparts.center) do
    if aChild.name == "icon_home_active" then             --form left to right
		  aChild:setPositionX(aChild:getPositionX() - visibleSize.width)
      local arr = CCArray:create()
      arr:addObject(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
      arr:addObject(CCCallFunc:create(enterActionFinished))
      aChild:runAction(CCSequence:create(arr))
    elseif (aChild.name == "icon_home_babelTower" 
      or aChild.name == "home_lv_babelTower"
      or aChild.name == "home_lv_arena"
      or aChild.name == "bg_home_w"
      or aChild.name == "home_countdown_reward"
      or aChild.name == "icon_home_arena"
      or aChild.name == "icon_home_babelTower")then
      aChild:setPositionX(aChild:getPositionX() - visibleSize.width)
      aChild:runAction(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
    else
      -- form right to left
      aChild:setPositionX(aChild:getPositionX() + visibleSize.width)
      aChild:runAction(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
    end
  end
end

 

g_isLoadingFlashReleased = false
g_curAdvIndex = nil
function MainMenuScene:sufEnterAnimation()
  BaseUIScene.sufEnterAnimation(self)
  --for _, aChild in pairs(self.Particles) do
    --aChild:setVisible(true)
    --暂时关闭粒子效果
    --aChild:setVisible(false)
  --end
  
  --advertise
  self.advMeta = MetaManager.game_meta.adMainUiConfig.adMainUis
  
  --鱼组推广码
  local fishInviteCode = getFishInviteCode()
  if fishInviteCode ~= nil then
	self.advMeta = {}
	table.insert(self.advMeta,{
								picId = "main_ad_happyfish_invitecode.png",
								name = "happyfish_invitecode",
								displayRule = 1,
								inviteCode = fishInviteCode
								})
  end

  if not g_curAdvIndex then
    g_curAdvIndex = 0
  end


  
  
  
  
  --[[
  if self.rewardParticle and self.rewardParticle.refCocosObj then
    self.rewardParticle:setVisible(true)
  end
  ]]
  --print("__MainMenuScene:sufEnterAnimation")
  --ExeNewGuide(GuideConfig.kEnterGame)
  --ExeNewGuide(GuideConfig.kCardCompos3)
  --ExeNewGuide(GuideConfig.kCardCompos8)
  --ExeNewGuide(GuideConfig.kEquipWear)
  --ExeNewGuide(GuideConfig.kGacha)
  --ExeNewGuide(GuideConfig.kCardEvolution)
  --ExeNewGuide(GuideConfig.kCardEvolution2)
  --ExeNewGuide(GuideConfig.kEquipQuality)
  --ExeNewGuide(GuideConfig.kEquipUpgrade)
  --ExeNewGuide(GuideConfig.kArena)
  --ExeNewGuide(GuideConfig.kElite) 
  
	
	if not g_isLoadingFlashReleased then
		--print("******FlashCacheMgr:getInstance():releateItem(zhudonghua)******")
		FlashCacheMgr:getInstance():releateItem("loading/zhudonghua")
		CCTextureCache:sharedTextureCache():removeTextureForKey("loading/lvbubig.png")
		CCTextureCache:sharedTextureCache():removeTextureForKey("loading/zhangfeibig.png")
		CCTextureCache:sharedTextureCache():removeTextureForKey("loading/sunquanbig.png")
		CCTextureCache:sharedTextureCache():removeTextureForKey("loading/dianweibig.png")
		CCTextureCache:sharedTextureCache():removeTextureForKey("loading/jindutiao.png")
		CCTextureCache:sharedTextureCache():removeTextureForKey("loading/guang.png")
		CCTextureCache:sharedTextureCache():removeTextureForKey("loading/logo.png")
		g_isLoadingFlashReleased = true
	end
  
  local homeInfoTipShow = false
  local function showHomeInfoTip()
    if not self.curSceneEnum then
      return
	  end

    local gameInitData = DataManager.getGameInitData()
    local isRefresh
    if(not gameInitData.sharkUserSecretShop) then
      isRefresh = false
    else
      isRefresh = gameInitData.sharkUserSecretShop.ifListFresh
    end
    if isRefresh then
    	HeMemDataHolder:setInteger("Activity_SecretShopTips" , 1)
    else
    	HeMemDataHolder:setInteger("Activity_SecretShopTips" , 0)
    end
    
    
    local panelNameDict = ActivityPanelScene.getPanelNameDict()
    for k, v in pairs(panelNameDict) do
      local aTipNum, aParticleStatus = v.getTipNum()
      if aTipNum > 0 then
        self.activityCount = self.activityCount + 1
        self.activityEnableTips[k] = aTipNum
      end
      self.activityParticleInfos[k] = aParticleStatus
    end
    
    if self.activityCount > 0 then
        self.topButtons:getChildByName("btn_b2"):getChildByName("tips_little"):setVisible(true)
        self.topButtons:getChildByName("btn_b2"):getChildByName("txt_font"):setVisible(true)
        self.topButtons:getChildByName("btn_b2"):getChildByName("txt_font"):setString("" .. self.activityCount)
    else
      self.topButtons:getChildByName("btn_b2"):getChildByName("tips_little"):setVisible(false)
      self.topButtons:getChildByName("btn_b2"):getChildByName("txt_font"):setVisible(false)
    end
    
	--联系客服
	self.btnGM:setVisible(true)
    self.btnGM:setEnable(true)
    --邮件提示
   
    if g_homeInfo and g_homeInfo.unreadMessageNum > 0 then
      self.btnMailHint:setVisible(true)
      self.btnMailHint:setEnable(true)
    else
      self.btnMailHint:setVisible(false)
      self.btnMailHint:setEnable(false)
    end
    
    if self.activityParticleInfos["Activity_MultiplayerBoss"] then
      self.btnMBHint:setVisible(true)
      self.btnMBHint:setEnable(true)
      if not self.mailHint:isVisible() then
        self.MBHint:setPositionX(self.mailPosX)
        self.MBHint:setPositionY(self.mailPosY)
      else
        self.MBHint:setPositionX(self.MBPosX)
        self.MBHint:setPositionY(self.MBPosY)
      end
    else
      self.btnMBHint:setVisible(false)
      self.btnMBHint:setEnable(false)
    end
	
	if self.HostingCode then
		self.HostingCode:setVisible(true)
	end

    if g_homeInfo and g_homeInfo.rewardNum > 0 then
        self.topButtons:getChildByName("btn_b3"):getChildByName("tips_little"):setVisible(true)
        self.topButtons:getChildByName("btn_b3"):getChildByName("txt_font"):setVisible(true)
        self.topButtons:getChildByName("btn_b3"):getChildByName("txt_font"):setString("" .. g_homeInfo.rewardNum)
    else
      self.topButtons:getChildByName("btn_b3"):getChildByName("tips_little"):setVisible(false)
      self.topButtons:getChildByName("btn_b3"):getChildByName("txt_font"):setVisible(false)
    end
    


    local freeGacha = HomeInfoManager.getFreeGachaStatus()
    if freeGacha > 0 then
        self.topButtons:getChildByName("btn_b4"):getChildByName("tips_little"):setVisible(true)
        self.topButtons:getChildByName("btn_b4"):getChildByName("txt_font"):setVisible(true)
        self.topButtons:getChildByName("btn_b4"):getChildByName("txt_font"):setString("" .. freeGacha)
    else
      self.topButtons:getChildByName("btn_b4"):getChildByName("tips_little"):setVisible(false)
      self.topButtons:getChildByName("btn_b4"):getChildByName("txt_font"):setVisible(false)
    end 

    local freeTreasureGacha = TreasureManager.isFreeGacha() --宝宝角标
    if TreasureManager.isUserLevelEnough() and freeTreasureGacha then 
        self.topButtons:getChildByName("btn_b6"):getChildByName("tips_little"):setVisible(true)
        self.topButtons:getChildByName("btn_b6"):getChildByName("txt_font"):setVisible(true)
        self.topButtons:getChildByName("btn_b6"):getChildByName("txt_font"):setString("" .. 1)
    else
    	self.topButtons:getChildByName("btn_b6"):getChildByName("tips_little"):setVisible(false)
      	self.topButtons:getChildByName("btn_b6"):getChildByName("txt_font"):setVisible(false)
    end
   
    
    local achieveTips = AchievementScene.getTipNum()
    if g_homeInfo and g_homeInfo.enableGainDailyActiveRewardNum > 0 and DataManager.getCurrUser().level >= DataManager.GameMetaData.dailyActiveConfig.levelLimit then
    	achieveTips = achieveTips + g_homeInfo.enableGainDailyActiveRewardNum
    end
    --追加每日目标角标数到累计数量
    if g_homeInfo and g_homeInfo.enableGainDailyAchieveRewardNum > 0 then
    	achieveTips = achieveTips + g_homeInfo.enableGainDailyAchieveRewardNum
    end

    if achieveTips > 0 then
        self.topButtons:getChildByName("btn_b1"):getChildByName("tips_little"):setVisible(true)
        self.topButtons:getChildByName("btn_b1"):getChildByName("txt_font"):setVisible(true)
        self.topButtons:getChildByName("btn_b1"):getChildByName("txt_font"):setString("" .. achieveTips)
    else
      self.topButtons:getChildByName("btn_b1"):getChildByName("tips_little"):setVisible(false)
      self.topButtons:getChildByName("btn_b1"):getChildByName("txt_font"):setVisible(false)
    end
    
    if g_homeInfo and g_homeInfo.freeSpiritRefreshNum then
    	SpiritManager.setFreeRefreshTimes( g_homeInfo.freeSpiritRefreshNum )
    end
    
    

    if not homeInfoTipShow then
      function MainMenuScene:nextAdvPicture()
		self.nextAdvCount = self.nextAdvCount + 1
        g_curAdvIndex = g_curAdvIndex + 1
		if g_curAdvIndex > #self.advMeta then
          g_curAdvIndex = 1
        end
        
        local spt = self:getAdvPicByMeta(self.advMeta[g_curAdvIndex])
        if spt ~= nil then
         
          return spt
        else
        if self.nextAdvCount >= 10 then
          spt = Sprite:create("pic/main_ad_eat_peach.png")
          spt:setPosition(ccp(360, -99))
          return spt
        else
          return self:nextAdvPicture()
        end
        end
      end
    
     function MainMenuScene:changeAdv()
          self.mainUI:getChildByName("home_main"):getChildByName("icon_home_active"):removeChild(self.oldAdvSprite)
          self.mainUI:getChildByName("home_main"):getChildByName("icon_home_active"):removeChild(self.newAdvSprite, false)
          
          self.oldAdvSprite = self.newAdvSprite;
          local arr2 = CCArray:create()
          arr2:addObject(CCFadeOut:create(1))
          self.oldAdvSprite:runAction(CCSequence:create(arr2))
        self.nextAdvCount = 1
          self.newAdvSprite = self:nextAdvPicture()
          local arr = CCArray:create()
            arr:addObject(CCFadeIn:create(1))
            self.newAdvSprite:runAction(CCSequence:create(arr))
          
          self.mainUI:getChildByName("home_main"):getChildByName("icon_home_active"):addChild(self.newAdvSprite)
          self.mainUI:getChildByName("home_main"):getChildByName("icon_home_active"):addChild(self.oldAdvSprite)
      end
      local  judgeVariable = Activity_rechargeLayer.JudgeDisplayAdvertising( )
      if judgeVariable == 0 then 		--------------------
      	self.mainUI:getChildByName("home_main"):getChildByName("icon_home_active"):removeChildren(true)
	    self.oldAdvSprite = nil
	    self.nextAdvCount = 1
	    self.newAdvSprite = self:nextAdvPicture()
	    self.mainUI:getChildByName("home_main"):getChildByName("icon_home_active"):addChild(self.newAdvSprite)
	    local function changeAdvScheFunc()
	    	self:changeAdv()
	    end 
	    self.changeAdvFunc = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(changeAdvScheFunc, 6, false)
      end
      

      if self.tableUI.refCocosObj then
        self.tableUI:reloadData()
      end
      
      homeInfoTipShow = true
    end
  end
	
  
  local tipInfoFlag = 0
  self.hasUnDefeatedBoss = false
  self.ungainedRewardNum = 0
  local getMBTipInfoFinish
  tipInfoShowTime = nil
  local function checkInfoState()
  	
    if tipInfoFlag >= 3 then
      ActivityPanelScene.setStatusInfo(g_homeInfo)

      ActivityPanelScene.setMBStatusInfo(self.hasUnDefeatedBoss, self.ungainedRewardNum)
      showHomeInfoTip()
      tipInfoShowTime = TimeUtil.getYmd()
   
    end
  end
  function getHomeInfo()

  	local function GetAchievementsCallBack(e)
	    DataManager.setSharkAchievements(e.data.sharkAchievement)
	    DataManager.setSharkCardBookAchievements(e.data.cardBookAchievement)
	    tipInfoFlag = tipInfoFlag + 1
	    checkInfoState()
	  
	end
	local function GetAchievementsFailed(e)	    
		tipInfoFlag = tipInfoFlag + 1
	    checkInfoState()
	end

    local getAchievementsRequest = GetAchievementsRequest.new( nil, rpc.SendingPriority.kNormal )
    getAchievementsRequest:addEventListener( RequestNotifyEnum.GetAchievementsSucceed, GetAchievementsCallBack)
    getAchievementsRequest:addEventListener( RequestNotifyEnum.GetAchievementsFailed, GetAchievementsFailed)
    getAchievementsRequest:start()
    

    local function getHomeInfoFinish(responseData)
      g_homeInfo = responseData.data
      tipInfoFlag = tipInfoFlag + 1
      checkInfoState()
     

      --print("responseData = " .. tostringRich(responseData))

		--设置军团相关信息(每个GetHomeInfoRequest成功获得数据之后都应该有以下处理)
		--设置军团兽剩余hp
		UnionManager.setColosseumMonsterCurrentHp(tonumber(responseData.data.unionMonsterHp))
		--设置军团兽逃跑时间
		UnionManager.setColosseumMonsterRunTime(responseData.data.unionMonsterEscapeSeconds)

		--设置 多重好礼活动充值
		Activity_ConsumeRewardsLayer.setRecharges(responseData.data.consumeRewardRecharges or 0)
		--设置 多重好礼已领列表
		Activity_ConsumeRewardsLayer.setGainedIds(responseData.data.consumeRewards or {})

		--派发事件 通知外部更新显示
		UnionManager.eventDispatcher:dispatchEvent(Event.new(UnionManager.COLOSSEUM_BOSS_STATE_UPDATE))
    end
    local function getHomeInfoFailed(event)
      g_homeInfo = nil
      tipInfoFlag = tipInfoFlag + 1
      checkInfoState()
    end
    
    local params = {}
    local request = GetHomeInfoRequest.new(params, rpc.SendingPriority.kHigh)
    request:addEventListener(RequestNotifyEnum.GetHomeInfoSucceed, getHomeInfoFinish)
    request:addEventListener(RequestNotifyEnum.GetHomeInfoFailed, getHomeInfoFailed)
    request:start()
  
    
    getMBTipInfoFinish = function(hasUnDefeatedBoss, ungainedRewardNum)
      tipInfoFlag = tipInfoFlag + 1
      self.hasUnDefeatedBoss = hasUnDefeatedBoss
      self.ungainedRewardNum = ungainedRewardNum
      checkInfoState()
     
    end
    MultiplayerBossScene.getTipInfo(getMBTipInfoFinish)
    
    --解决聊天信息军团按钮无法立刻更新问题 add by zheng.che @ 2014-5-13
    UnionGetMyDataRequest.sendRequest(onGetMyDataSucceed, UnionGetMyDataRequest.onFailedDefault, false) --获得玩家军团相关信息(是否在军团, 军团名等) 不显示loading画面
   
  end
end

function MainMenuScene:doExitAnimation()
  self:preExitAnimation()
  self:startExitAnimation()
end

function MainMenuScene:preExitAnimation()
 
	-- print("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++删除粒子效果")
  if self.rewardParticles then --删除粒子效果
  	-- print("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++删除粒子效果 2")
  	self.rewardParticles:setVisible(false)

    -- print("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++删除粒子效果 3")
	self.rewardParticles:removeFromParentAndCleanup(true)
	-- print("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++删除粒子效果 4")
  end
  BaseUIScene.preExitAnimation(self)
  --print("__MainMenuScene:preExitAnimation")
end

function MainMenuScene:startExitAnimation()
	self.curSceneEnum = nil;
	g_curSceneEnum = nil
  BaseUIScene.startExitAnimation(self)
  --print("__MainMenuScene:startExitAnimation")
  local function enterActionFinished()
    self:nodeAnimationFinished()
  end
  --[[local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.mainUI:runAction(CCSequence:create(arr))]]
  
  --for _, aChild in pairs(self.Particles) do
  --  aChild:setVisible(false)
  --end
  --[[
  if self.rewardParticle and self.rewardParticle.refCocosObj then
    self.rewardParticle:setVisible(false)
  end
  ]]
  self.btnGM:setVisible(false)
  self.btnGM:setEnable(false)
  if self.btnMailHint then   
    self.btnMailHint:setVisible(false)
    self.btnMailHint:setEnable(false)
  end
  if self.btnChat then   
    self.btnChat:setVisible(false)
    self.btnChat:setEnable(false)
  end
  
  if self.btnMBHint then   
    self.btnMBHint:setVisible(false)
    self.btnMBHint:setEnable(false)
  end
  
  if self.HostingCode then
	self.HostingCode:setVisible(false)
  end 
  
  self.mainUI:getChildByName("home_main"):getChildByName("txt_heroword"):setVisible(false)
  self.mainUI:getChildByName("home_main"):getChildByName("home_lv_t"):getChildByName("frame_home_dialogue"):setVisible(false)
  
  for _, aChild in pairs(self.UIparts.center) do
  	if aChild.name == "icon_home_active" then
  		local arr = CCArray:create()
  		arr:addObject(CCDelayTime:create(enter_animation_duration))
  		arr:addObject(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
  		aChild:runAction(CCSequence:create(arr))
  	elseif (aChild.name == "icon_home_babelTower" 
      or aChild.name == "home_lv_babelTower"
      or aChild.name == "home_lv_arena"
      or aChild.name == "home_countdown_reward"
	  or aChild.name == "bg_home_w"
      or aChild.name == "icon_home_arena"
      or aChild.name == "icon_home_babelTower")then
  		local arr = CCArray:create()
  		arr:addObject(CCDelayTime:create(enter_animation_duration))
  		arr:addObject(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
  		aChild:runAction(CCSequence:create(arr))
  	else
  		local arr = CCArray:create()
  		arr:addObject(CCDelayTime:create(enter_animation_duration))
  		arr:addObject(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
  		aChild:runAction(CCSequence:create(arr))
  	end
  end
  
  local aIconsHeight = self.UIparts.icons:getGroupBounds().size.height
  local arr = CCArray:create()
  arr:addObject(CCDelayTime:create(enter_animation_duration))
  arr:addObject(CCMoveBy:create(enter_animation_duration, ccp(0, -aIconsHeight)))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.UIparts.icons:runAction(CCSequence:create(arr))
end

function MainMenuScene:sufExitAnimation()
  BaseUIScene.sufExitAnimation(self)
  --print("__MainMenuScene:sufExitAnimation")
end

function MainMenuScene:back()
  self:replaceScene(LoginScene)
end