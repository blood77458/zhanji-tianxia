require "hecore.EventDispatcher"
require "hecore.display.CocosObject"
require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"
require "canon.scene.LoadingScene"
require "canon.panel.MainActorPanel"
require "canon.models.RewardManager"
require "canon.models.CalculationManager"
require "canon.request.GetMissionCompleteInfoRequest"
require "canon.panel.UserLevelupBox"
require "canon.models.UserLevelManager"
require "canon.constants.MusicPathConstants"
require "canon.script_and_guide.NewUserGuide"
require "canon.request.GetSharkBeastFragments"
require "canon.request.GetSharkBeastsRequest"
require "canon.panel.AntiAddictionReminderPanel"
require "canon.panel.CountDownRewardNewPanel"
require "canon.panel.UnionBottomMenuPanel"
require "canon.request.GainMondayRewardRequest"

--UI相关事件
UI_NOTIFY_EVENT_ENUM = {
	SCENE_CLEAR = "SCENE_CLEAR",	--通知清除场景 无参数
}

g_BaseUISceneObject = nil
g_BaseUISceneExpBar = {}
BaseUINotify = EventDispatcher.new()



BaseUIScene = class(Scene)
local visibleSize = CCDirector:sharedDirector():getVisibleSize()

local enter_animation_duration = 0.2

----------------------------------------
-- Scene代码
----------------------------------------
--TODO 应该使用SceneManager来进行统一管理场景切换
SceneEnum = {
	BaseUIScene = 0,
	MainMenuScene = 1,
	CardQueueScene = 2,
	CityMainScene = 3,
	GachaScene = 4,
	ChallengeEntersScene = 5,
	ShiLiScene = 6,
	-- 商城 5
	-- 势力 6
	ChapterMapScene = 7,
	SkyTowerMainScene = 8,
	FriendScene = 9,
	FriendQueueScene = 10,
	ArenaRankScene = 11,
	ShopScene = 12,
	BeastScene = 13,
	MultiplayerBossScene = 14,
	NewBabelRankScene = 15,
	PKScene = 16,
	UnionScene = 17,
	UnionMemberListScene = 18,
	UnionListScene = 19,
	UnionShopScene = 20,
	UnionBankScene = 21,
	UnionHallScene = 22,
	UnionInfomationScene = 23,
	BackpackScene = 24,
	AcrossFightScene = 25,
	UnionNewsScene = 26,
	UnionColosseumScene = 27,
	MatrixScene = 28,
	ActivityScene = 29,
	UnionPkScene = 30,
	ActivitySceneToCrossBoss = 31,
}

--场景大类枚举(主要影响主菜单的显示)
SceneMenuTypeEnum = {
	BASE = 1,	--基础类型
	UNION = 2,	--军团类型
}

function BaseUIScene:ctor()
	self.targetScene = nil
    self.targetInfoPanel = nil
    self.title=""
    self.ignoreAction = nil
    self.bg_home_menu_top = nil
    self.btn_home_menu_title = nil
    self.backDisplay = nil
	self.progress = nil
	self.touchDisableSetTimes = 0
	self.baseUITimer = 0
	self.exit_animation_duration = 0.1
	self.isChangeingScene = false

end

function BaseUIScene:create()
  self.curSceneEnum = SceneEnum.BaseUIScene
  self.baseUITimer = 0
  local s = BaseUIScene.new()
  s:initScene()
  return s
end

----------------------------------------
-- 用于关闭当前Scene中所有TableView触摸事件的方法，供子类需覆盖setTableViewsEnabledInner方法
----------------------------------------
function BaseUIScene:setTableViewsEnabled(v)
	if (v) then
		self.touchDisableSetTimes = self.touchDisableSetTimes - 1
	    if (self.touchDisableSetTimes <= 0) then
	      self:setTableViewsEnabledInner(v)
	    end
	else
		self.touchDisableSetTimes = self.touchDisableSetTimes + 1
    	self:setTableViewsEnabledInner(v)
	end
end

function BaseUIScene:setTableViewsEnabledInner(v)
	-- 被子类继承
  he_log_warning("not implement by subClass")
end

----------------------------------------
-- 用于提供点击下排一级导航按钮前的函数调用以判断是否能跳转，供子类覆盖
----------------------------------------
function BaseUIScene:callFuncBeforeSceneChange( aReplaceFunc )
	if (not self.targetInfoPanel) and not self.isChangeingScene then
	    self.isChangeingScene = true
		aReplaceFunc()
	else
		he_log_warning("targetInfoPanel isn't nil, the replace action was intercepted")
	end
end

function BaseUIScene:replaceScene(Scene, argumentList)
	if self.disposed then
		--在有baseUI的情况下 如果当前baseUI里没有list 表示已经被清除 即已经执行过replaceScene 因此放弃本操作 add by zheng.che @ 2015-4-1(不是玩笑)
		--(此问题会导致崩溃 一天内出现32次 猜测可能原因是网络交互时没屏蔽住玩家操作导致在replaceScene时已经在切换从而某些资源已dispose)
		he_log_warning("BaseUIScene is already disposed can't replaceScene! ")
		return
	end

	--正确流程↓

	self.nodeActionCount = 0
	--通知清除场景
	BaseUINotify:dispatchEvent(Event.new(UI_NOTIFY_EVENT_ENUM.SCENE_CLEAR))
	--在切换场景前 UI堆栈清空 以防在列表中出现不受控制的UI add by zheng.che
	UiStackManager.clear()
    
	self.targetScene = Scene
    
    self.argumentList = argumentList
    
    self:doExitAnimation()
	
	-- 新手引导
	FireReplaceSceneEvent()
end

local function onBackClick( evt )
	local curScene = evt.context
  CanonPlayEffect(MusicPathConstants.ButtonBack)
	curScene:callFuncBeforeSceneChange(
		function ()
			curScene:back()
		end
	)
end

local broadcast_current_position
local broadcast_original_position
local broadcast_duration
local broadcast_content
local broadcast_total_duration
local broadcast_speed = 2 * visibleSize.width / 20

local function updateUI(ee)
	local GameMetaData = MetaManager.game_meta
	local userData = DataManager.getCurrUser()
	if (not g_BaseUISceneObject) then
		he_log_warning("Last scene didn't dispose as expect .. "..self.curSceneEnum .. ":" .. self.title)
		return
	end
	if (not g_BaseUISceneObject.list) then
		he_log_warning("An scheduler didn't dispose as expect.")
		return
	end
	
	--playerName
	g_BaseUISceneObject:getChildByName("home_menu_title"):getChildByName("txt_home_playerName"):getChildByName("txt_home_playerName"):setString( userData.nickName)
	--Energy
	local energy,_,_,_,maxEnergy = CalculationManager.calcComplex_getEnergyNow()
	g_BaseUISceneObject:getChildByName("home_menu_title"):getChildByName("txt_home_energy_L_num"):getChildByName("font"):setString( energy .. "/" .. maxEnergy)
	-- local anAngel = 180*(energy / maxEnergy)-180
	-- anAngel = (anAngel>0) and 0 or anAngel
	--g_BaseUISceneObject:getChildByName("home_menu_title"):getChildByName("icon_home_stamina"):setRotation(anAngel)
	g_BaseUISceneObject.staminaProgress:setPercentage((energy/maxEnergy) * 100)
	--EventPoint
	local ep,_,_,_,maxEP = CalculationManager.calcComplex_getEPNow()
	g_BaseUISceneObject:getChildByName("home_menu_title"):getChildByName("txt_home_energy_R_num"):getChildByName("font"):setString( ep .. "/" .. maxEP)             
	--txt_icon_silverCoin_test_num
	g_BaseUISceneObject:getChildByName("home_menu_title"):getChildByName("txt_icon_silverCoin_test_num"):getChildByName("font"):setString( userData.coins)       

	g_BaseUISceneObject.epProgress:setPercentage((ep/maxEP) * 100)
	
	--txt_icon_cionEvent_num
	g_BaseUISceneObject:getChildByName("home_menu_title"):getChildByName("txt_icon_cionEvent_num"):getChildByName("font"):setString( CalculationManager.calcComplex_getGemsNow() )      
	
	--vip
	local userVipLv = DataManager.getGameInitData().sharkUser.vipLevel
	g_BaseUISceneObject:getChildByName("home_menu_title"):getChildByName("txt_viplevel"):getChildByName("txt"):setString("V"..userVipLv)

	--if __IOS then
		local energyRecoverTime = (maxEnergy - energy) * st_recover_per_second
		local epRecoverTime = (maxEP - ep) * vi_recover_per_second
		cancelLocalNotification(5)
		cancelLocalNotification(6)
		if energyRecoverTime > 0 then
			registerLocalNotification(6, energyRecoverTime)
		end
		if epRecoverTime > 0 then
			registerLocalNotification(5, epRecoverTime)
		end
	--end
end

local function refreshPlayerStrength( e )
	local showingFightCapacity = DataManager.getShowFightCapacity()

	if g_BaseUISceneObject:getChildByName("home_menu_title").refCocosObj:getChildByTag(10086) then
		g_BaseUISceneObject:getChildByName("home_menu_title").refCocosObj:getChildByTag(10086):removeFromParentAndCleanup(true)
	end
	local pos = g_BaseUISceneObject:getChildByName("home_menu_title"):getChildByName("bg_guild_fight_name"):getPosition()
	local playerStrength = CCLabelAtlas:create(showingFightCapacity, "pic/shouye_power_number.png", 24, 30, 48)
	playerStrength:setScale(1.1)
	playerStrength:setAnchorPoint(ccp(0.5, 0.5))
	local numberLabel_co = CocosObject.new(playerStrength)
	numberLabel_co:setPositionXY(pos.x,pos.y)
	numberLabel_co:setTag(10086)
	g_BaseUISceneObject:getChildByName("home_menu_title"):addChild(numberLabel_co)
end

--menuStateType 最下方菜单的显示方式
function BaseUIScene:onInit(menuStateType, params)
	if not menuStateType then
		menuStateType = SceneMenuTypeEnum.BASE
	end

	self.builder = LayoutBuilder:createWithContentsOfFile("scene/shouye_new.json")
	self.builder.useArtLabelTTF = true
	self.BaseUi = self.builder:build("shouye_home_menu")
  
  Set_ShareData( "EnterAnimationFinished", 0 ) --通知“新手引导模块”正在加载新场景
	
    g_BaseUISceneObject = self.BaseUi
    
    BaseUINotify:addEventListener(DataChangedNotifyEnum.BaseUISceneDataChanged,updateUI)  
    BaseUINotify:addEventListener(ConstManager.FIGHT_CAPACITY_SHOW_UPDATE,refreshPlayerStrength)  

    local myStrength = math.floor(CommonManager:getLocalPlayerStrength(true))
    refreshPlayerStrength()
      
    local userData = DataManager.getCurrUser()
	
	--MainActorPanel
	local layerSize = self.BaseUi:getChildByName("home_menu_title"):getGroupBounds().size
	local layerHeight = layerSize.height
	local layerPosition = self.BaseUi:getChildByName("home_menu_title"):getPosition()
	local layerPositionY = layerPosition.y
	local startY = 0
    local function onMainActorClick( eventType, pos )
		if (self.targetInfoPanel or
			self.touchDisableSetTimes>0) then
			return
		end--[[
    if not g_homeInfo then
      return
    end]]
		if (eventType == "began") then
			startY = pos[2]
		end
    if (eventType == "ended"
			and pos[2]>(layerPositionY-layerHeight+112)
			and startY>(layerPositionY-layerHeight+112)
			) then
			if (not self.targetInfoPanel) then
				if self.passwordClick then
					self.passwordClick()
				end
			
				self.targetInfoPanel = MainActorPanel:create( self )
				PopoutManager:sharedManager():popout(self.targetInfoPanel, kPopoutDir.kScale, true, false ,self)
			end
		end    
  end
    self.mainActorTouchLayer = MultiTouchLayer:create(layerSize.width,layerSize.height)
    self.mainActorTouchLayer:setPosition(ccp(layerPosition.x,layerPosition.y))
    self.mainActorTouchLayer:registerScriptTouchHandler( onMainActorClick,true )
    self.BaseUi:addChild(self.mainActorTouchLayer)

    --vip
	local userVipLv = DataManager.getGameInitData().sharkUser.vipLevel
	self.BaseUi:getChildByName("home_menu_title"):getChildByName("txt_viplevel"):getChildByName("txt"):setString("V"..userVipLv)

    --self.BaseUi:getChildByName("home_menu_title"):getChildByName("txt_home_stamina"):getChildByName("txt_home_stamina"):setString(getTextByKey("home_stamina"))
    --self.BaseUi:getChildByName("home_menu_title"):getChildByName("txt_home_energy"):getChildByName("txt_home_energy"):setString(getTextByKey("home_energy"))
    --Exp
    --[[注释的经验数]]
	local orgText = self.BaseUi:getChildByName("home_menu_title"):getChildByName("txt_icon_playerExp_num"):getChildByName("font")
	orgText:setAroundColor(aroundColor or ccc3(0,0,0))
	--local aNewLabel = ViewControlUtil.buildArtLabel(orgText,"")
	--aNewLabel.name = "font"
	--self.BaseUi:getChildByName("home_menu_title"):getChildByName("txt_icon_playerExp_num"):addChild(aNewLabel)
    self.BaseUi:getChildByName("home_menu_title"):getChildByName("txt_icon_playerExp_num"):getChildByName("font"):setString( userData.exp .. "/" .. MetaManager.user_level[userData.level].exp)
	self.BaseUi:getChildByName("home_menu_title"):getChildByName("txt_icon_playerExp_num"):setZOrder(1001)
	self.BaseUi:getChildByName("home_menu_title"):getChildByName("txt_home_energy_L_num"):setZOrder(1001)
	self.BaseUi:getChildByName("home_menu_title"):getChildByName("txt_home_energy_R_num"):setZOrder(1001)
	--self.BaseUi:getChildByName("home_menu_title"):getChildByName("icon_hone_exp"):setZOrder(1101)
	--self.BaseUi:getChildByName("home_menu_title"):getChildByName("icon_hone_exp1"):setZOrder(1101)
	--self.BaseUi:getChildByName("home_menu_title"):getChildByName("icon_hone_exp2"):setZOrder(1101)
	--Exp Bar
	local sprite = Sprite:create(UI_RES_PATH.."/shouye_new/shouye_icon_playerExp_sb.png")
	local exp_pic = self.BaseUi:getChildByName("home_menu_title"):getChildByName("icon_playerExp")
	sprite:setPosition(ccp(exp_pic:getPosition().x, exp_pic:getPosition().y))
	sprite:setAnchorPoint(exp_pic:getAnchorPoint())
	sprite:setScaleY(2)
	-- sprite:setScaleX(1.105)
	exp_pic:setVisible(false)--隐藏原进度条
	g_BaseUISceneExpBar[0] = ProgressBar:create(sprite) 
	g_BaseUISceneExpBar[0]:setPercentage(userData.exp * 100 / MetaManager.user_level[userData.level].exp)
    sprite:setZOrder(801)
	self.BaseUi:getChildByName("home_menu_title"):addChild(sprite)
    --Level
    self.BaseUi:getChildByName("home_menu_title"):getChildByName("txt_home_lv"):getChildByName("font"):setString( "Lv." .. userData.level )
    --playerName
    self.BaseUi:getChildByName("home_menu_title"):getChildByName("txt_home_playerName"):getChildByName("txt_home_playerName"):setString( userData.nickName)
    --txt_home_energy_L_num
    
	local energy,_,_,_,maxEnergy = CalculationManager.calcComplex_getEnergyNow(userData)
    self.BaseUi:getChildByName("home_menu_title"):getChildByName("txt_home_energy_L_num"):getChildByName("font"):setString( energy .. "/" .. maxEnergy)
    --energyLastUpdate
    local ep,_,_,_,maxEP = CalculationManager.calcComplex_getEPNow(userData)
    self.BaseUi:getChildByName("home_menu_title"):getChildByName("txt_home_energy_R_num"):getChildByName("font"):setString( ep .. "/" .. maxEP)
  
	local aPic = self.BaseUi:getChildByName("home_menu_title"):getChildByName("icon_home_stamina")
	-- aPic:setAnchorPoint(ccp(0,0.5))
	aPic:setZOrder(701)
	-- local anAngel = 180*(energy / maxEnergy)-180
	-- anAngel = (anAngel>0) and 0 or anAngel
	-- aPic:setRotation(anAngel)
	aPic:setVisible(false)
	
	local aPic = self.BaseUi:getChildByName("home_menu_title"):getChildByName("icon_home_energy")
	-- aPic:setAnchorPoint(ccp(0,0.5))
	aPic:setZOrder(801)
	aPic:setVisible(false)
	
	-- self.BaseUi:getChildByName("home_menu_title"):getChildByName("bg_home_menu_top"):setZOrder(901)
	-- self.BaseUi:getChildByName("home_menu_title"):getChildByName("txt_home_hime"):setZOrder(1001)
	
	local function setNotAffectTouchEvent(obj)
		obj.notAffectTouchEvent = true
		if type(obj.list) == "table" then
			for k,v in pairs(obj.list) do
				setNotAffectTouchEvent(v)
			end
		end
	end
	
	local sprite = Sprite:create(UI_RES_PATH.."/shouye_new/shouye_icon_home_energy_sb.png")
	local ep_pic = self.BaseUi:getChildByName("home_menu_title"):getChildByName("icon_home_energy")
	sprite:setPosition(ccp(ep_pic:getPosition().x, ep_pic:getPosition().y))
	sprite:setAnchorPoint(ep_pic:getAnchorPoint())
	ep_pic:setVisible(false)--隐藏原进度条
	self.BaseUi.epProgress = ProgressBar:create(sprite) 
	self.BaseUi.epProgress:setPercentage((ep / maxEP) * 100)
    sprite:setZOrder(801)
	self.BaseUi:getChildByName("home_menu_title"):addChild(sprite)

	local sprite = Sprite:create(UI_RES_PATH.."/shouye_new/shouye_icon_home_stamina_sb.png")
	local stamina_pic = self.BaseUi:getChildByName("home_menu_title"):getChildByName("icon_home_stamina")
	sprite:setPosition(ccp(stamina_pic:getPosition().x, stamina_pic:getPosition().y))
	sprite:setAnchorPoint(stamina_pic:getAnchorPoint())
	stamina_pic:setVisible(false)--隐藏原进度条
	self.BaseUi.staminaProgress = ProgressBar:create(sprite) 
	self.BaseUi.staminaProgress:setPercentage((energy / maxEnergy) * 100)
    sprite:setZOrder(801)
	self.BaseUi:getChildByName("home_menu_title"):addChild(sprite)
	-- local epclipLayer = CCClippingNode:create();
	-- local epclipLayer_co = CocosObject.new(epclipLayer)
	-- epclipLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height / 2))
	-- epclipLayer:setPosition(ccp(0, self.BaseUi:getChildByName("home_menu_title"):getChildByName("icon_home_energy"):getPositionY()))
	-- local epstencil = CCProgressTimer:create(CCSprite:create(UI_RES_PATH.."/shouye_new/shouye_icon_home_energy_sb.png"))
	-- epstencil:setType(kCCProgressTimerTypeBar)
	-- -- epstencil:setReverseProgress(true)
	-- -- epstencil:setRotation(180)
	-- epstencil:setPercentage((ep / maxEP) * 100)
	-- epstencil:setAnchorPoint(ccp(0.5, 0.5))
	-- epstencil:setPosition(ccp(self.BaseUi:getChildByName("home_menu_title"):getChildByName("icon_home_energy"):getPositionX(), 0))
	-- -- epstencil:setScaleX(2)
	-- self.BaseUi.epProgress = epstencil
	-- self.BaseUi:addChild(epstencil)
	-- epclipLayer:setStencil(epstencil)
	-- self.BaseUi.epClipLayer = epclipLayer
	
	-- local showEP = Sprite:create(UI_RES_PATH.."/shouye_new/shouye_icon_home_energy_sb.png")
	-- showEP:setAnchorPoint(ccp(0, 0.5))
	-- showEP:setPosition(ccp(self.BaseUi:getChildByName("home_menu_title"):getChildByName("icon_home_energy"):getPositionX(), 0))
	-- epclipLayer_co:addChild(showEP)
	-- setNotAffectTouchEvent(epclipLayer_co)
	
	-- self.BaseUi:getChildByName("home_menu_title"):addChild(epstencil)
	
	-- local clipLayer = CCClippingNode:create();
	-- local clipLayer_co = CocosObject.new(clipLayer)
	-- clipLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height / 2))
	-- clipLayer:setPosition(ccp(0, self.BaseUi:getChildByName("home_menu_title"):getChildByName("icon_home_stamina"):getPositionY()))
	-- local stencil = ProgressBar:create(self.BaseUi:getChildByName("home_menu_title"):getChildByName("icon_home_stamina"))
	-- -- stencil:setType(kCCProgressTimerTypeBar)
	-- -- stencil:setRotation(180)
	-- stencil:setPercentage((energy / maxEnergy) * 100)
	-- -- stencil:setAnchorPoint(ccp(0.5, 0.5))
	-- -- stencil:setPosition(ccp(self.BaseUi:getChildByName("home_menu_title"):getChildByName("icon_home_stamina"):getPositionX(), 0))
	-- -- stencil:setScaleX(2)
	-- self.BaseUi.staminaProgress = stencil
	-- self.BaseUi:addChild(stencil)
	-- clipLayer:setStencil(stencil)
	-- self.BaseUi.staminaClipLayer = clipLayer
	
	-- local showStamina = Sprite:create(UI_RES_PATH.."/shouye_new/shouye_icon_home_stamina_sb.png")
	-- showStamina:setAnchorPoint(ccp(1, 0.5))
	-- showStamina:setPosition(ccp(self.BaseUi:getChildByName("home_menu_title"):getChildByName("icon_home_stamina"):getPositionX(), 0))
	-- clipLayer_co:addChild(showStamina)
	-- setNotAffectTouchEvent(clipLayer_co)
	
	-- self.BaseUi:getChildByName("home_menu_title"):addChild(clipLayer_co)
	
	--txt_icon_silverCoin_test_num
    self.BaseUi:getChildByName("home_menu_title"):getChildByName("txt_icon_silverCoin_test_num"):getChildByName("font"):setString( userData.coins)             
    --txt_icon_cionEvent_num
    self.BaseUi:getChildByName("home_menu_title"):getChildByName("txt_icon_cionEvent_num"):getChildByName("font"):setString( CalculationManager.calcComplex_getGemsNow(userData) ) 
	
    self.home_menu_title = self.BaseUi:getChildByName("home_menu_title")
    self.home_menu_bottom = self.BaseUi:getChildByName("home_menu_bottom")
    self.bg_home_menu_top = {
		self.BaseUi:getChildByName("home_menu_title"):getChildByName("bg_home_center_L"),
		self.BaseUi:getChildByName("home_menu_title"):getChildByName("bg_home_center_R"),
		--self.BaseUi:getChildByName("home_menu_title"):getChildByName("bg_home_menu_title"),
    self.BaseUi:getChildByName("home_menu_title"):getChildByName("bg_home_menu_title_for_jet"),
		self.BaseUi:getChildByName("home_menu_title"):getChildByName("txt_home_menu_title"),
		self.BaseUi:getChildByName("home_menu_title"):getChildByName("pattern_home_thin_L"),
		self.BaseUi:getChildByName("home_menu_title"):getChildByName("pattern_home_thin_R"),
	}
	--self.BaseUi:getChildByName("home_menu_title"):getChildByName("bg_home_menu_title_for_jet"):setVisible(false)
    self.backDisplay = self.BaseUi:getChildByName("home_menu_title"):getChildByName("bg_home_back")
    self.backBt = Button:create(self.backDisplay)
    self.backBt:addEventListener( Events.kStart, onBackClick, self )

    self.backDisplay2 = self.BaseUi:getChildByName("home_menu_title"):getChildByName("r_click")
    self.backBt2 = Button:create(self.backDisplay2)
    self.backBt2:addEventListener( Events.kStart, onBackClick, self )
       
    self.btn_home_menu_title = self.BaseUi:getChildByName("home_menu_title"):getChildByName("txt_home_menu_title")
    self.btn_home_menu_title:getChildByName("txt_home_menu_title"):setString(self.title)
	
	if self.notShowTitle then
		--self.BaseUi:getChildByName("home_menu_title"):getChildByName("bg_home_menu_title"):setVisible(false)
		self.BaseUi:getChildByName("home_menu_title"):getChildByName("bg_home_menu_title_for_jet"):setVisible(false)
	end
	
	self:addChild(self.BaseUi)
  
  if params and params.baseuiAddedCallback then
    params.baseuiAddedCallback ()
  end

	--切换菜单显示状态
	self:switchMenuState(menuStateType)

	local function onShouYeClick(evt)
		if (self.curSceneEnum == SceneEnum.MainMenuScene) then
			return
		end
		self:callFuncBeforeSceneChange(
			function()
				self:replaceScene(MainMenuScene)
			end
		)
	end
	
	local function onQueueClick(evt)
		if (self.curSceneEnum == SceneEnum.CardQueueScene) then
			return
		end
		self:callFuncBeforeSceneChange(
			function()
				self:replaceScene(CardQueueScene)
			end
		)
	end
  
	local function onChuangGuanClick(evt)
		if (self.curSceneEnum == SceneEnum.CityMainScene) then
			return
		end
		self:callFuncBeforeSceneChange(
			function()
				self:moveToMap()
			end
		)
  end
  
  local function onQiuJiangClick(evt)
    if (self.curSceneEnum == SceneEnum.BeastScene) then
      return
    end
		
		if DataManager.getCurrUser().level < MetaManager.game_meta.gameSettingConfig.beastConfig.beastUnlockLevel then
			SuspensionLabel:showContent(self, Localization:getInstance():getText("module_needLevel", {num = MetaManager.game_meta.gameSettingConfig.beastConfig.beastUnlockLevel}))
			do return end
		end
		
      self:callFuncBeforeSceneChange(
      function()
				local function doPrerationSucceed(fragmentsInfo)
					local argv = {enterScene="MainMenuScene",returnScene="MainMenuScene",params={fragmentsInfo=fragmentsInfo}}
					self:replaceScene(BeastScene, argv)
				end
				
				local function doPrerationFailed()
					self.isChangeingScene = false
				end
				
				BeastScene.doPreparationBeforeReplaceToBeastScene(doPrerationSucceed, doPrerationFailed)
      end
    )
  end
  
  local function onYanWuClick(evt)
    if (self.curSceneEnum == SceneEnum.BackpackScene and self.argv.params.isCardTrain == false) then
      return
    end
    
    self:callFuncBeforeSceneChange(
      function()
      	--没有在培养 才继续判断其他的
      	self.isChangeingScene = false--判断完后要给改回来
        self:replaceScene(BackpackScene, {params = {isCardTrain = false}})
      end
    )
    
  end
  
  --军团
  local function onUnionClick(evt)
    self:callFuncBeforeSceneChange(
      function()
      	--没有在培养 才继续判断其他的
      	self.isChangeingScene = false--判断完后要给改回来
		if UnionManager.ennabled(true) then
			UnionPkData.setUnionWarLightOnWhenIsRightTime(true)
			UnionManager.gotoUnionScene()
		end
      end
    )
  end
	
	local homeBtnDisplay = self.BaseUi:getChildByName("home_menu_bottom"):getChildByName("btn_home_homeBtn")
	local queueBtnDisplay = self.BaseUi:getChildByName("home_menu_bottom"):getChildByName("btn_home_formationBtn")
	local stageBtnDisplay = self.BaseUi:getChildByName("home_menu_bottom"):getChildByName("btn_home_stageBtn")
	local shopBtnDisplay = self.BaseUi:getChildByName("home_menu_bottom"):getChildByName("btn_home_gachaBtn")
	local gachaBtnDisplay = self.BaseUi:getChildByName("home_menu_bottom"):getChildByName("btn_home_shopBtn")
	local unionBtnDisplay = self.BaseUi:getChildByName("home_menu_bottom"):getChildByName("btn_home_guildBtn")
	local homeBtn = Button:create(homeBtnDisplay)
	homeBtn:addEventListener( Events.kStart, onShouYeClick, self )
	
	local queueBtn = Button:create(queueBtnDisplay)
	queueBtn:addEventListener( Events.kStart, onQueueClick, self )

	local stageBtn = Button:create(stageBtnDisplay)
	stageBtn:addEventListener( Events.kStart, onChuangGuanClick, self )

	local shopBtn = Button:create(shopBtnDisplay)
	shopBtn:addEventListener( Events.kStart, onYanWuClick, self )
	
	local gachaBtn = Button:create(gachaBtnDisplay)
	gachaBtn:addEventListener( Events.kStart, onQiuJiangClick, self )

	self.unionBtn = Button:create(unionBtnDisplay)
	self.unionBtn:addEventListener( Events.kStart, onUnionClick, self )
  
    self.backDisplay = self.BaseUi:getChildByName("home_menu_title"):getChildByName("bg_home_back")
    local backBt = Button:create(self.backDisplay)
    backBt:addEventListener( Events.kStart, onBackClick, self )
	
	--控制按钮显示状态，当前场景按钮点亮，其他置灰
	homeBtnDisplay:getChildByName("btn"):setVisible(false)
	queueBtnDisplay:getChildByName("btn"):setVisible(false)
	stageBtnDisplay:getChildByName("btn"):setVisible(false)
	shopBtnDisplay:getChildByName("btn"):setVisible(false)
	gachaBtnDisplay:getChildByName("btn"):setVisible(false)
	unionBtnDisplay:getChildByName("btn"):setVisible(false)
	
	homeBtnDisplay:getChildByName("icon_mainpage2"):setVisible(true)
	queueBtnDisplay:getChildByName("icon_team2"):setVisible(true)
	stageBtnDisplay:getChildByName("icon_stage2"):setVisible(true)
	shopBtnDisplay:getChildByName("icon_ebattle2"):setVisible(true)
	gachaBtnDisplay:getChildByName("icon_gacha2"):setVisible(true)
	unionBtnDisplay:getChildByName("icon_shop2"):setVisible(true)
	
	if self.curSceneEnum == SceneEnum.MainMenuScene then
		homeBtnDisplay:getChildByName("btn"):setVisible(true)
		homeBtnDisplay:getChildByName("icon_mainpage2"):setVisible(false)
	elseif self.curSceneEnum == SceneEnum.CardQueueScene then
		queueBtnDisplay:getChildByName("btn"):setVisible(true)
		queueBtnDisplay:getChildByName("icon_team2"):setVisible(false)
	elseif self.curSceneEnum == SceneEnum.CityMainScene then
		stageBtnDisplay:getChildByName("btn"):setVisible(true)
		stageBtnDisplay:getChildByName("icon_stage2"):setVisible(false)
	elseif self.curSceneEnum == SceneEnum.BackpackScene then
		shopBtnDisplay:getChildByName("btn"):setVisible(true)
		shopBtnDisplay:getChildByName("icon_ebattle2"):setVisible(false)
	elseif self.curSceneEnum == SceneEnum.BeastScene then
		gachaBtnDisplay:getChildByName("btn"):setVisible(true)
		gachaBtnDisplay:getChildByName("icon_gacha2"):setVisible(false)
	elseif self.curSceneEnum == SceneEnum.UnionScene or self.curSceneEnum == SceneEnum.UnionListScene then
		unionBtnDisplay:getChildByName("btn"):setVisible(true)
		unionBtnDisplay:getChildByName("icon_shop2"):setVisible(false)
	else
	end

	--管理军团按钮闪烁
	if UnionManager.isInBossAttackState() or UnionPkUtils.isShineUnionBtnWhenInUnionPKTime() then
		--当前有boss
		self.unionBtn:setShined(true)
	else
		--无boss
		self.unionBtn:setShined(false)
	end

    self.nodeActionCount = 0
    self.animationType = nil
    self:doEnterAnimation()
	--界面刷新计时器
	self.onUpdateFunc = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(updateUI,60,false);
  
  local aBroadcastTitle = self.BaseUi:getChildByName("cast_broadcast")
  local baseUIReportLabel = aBroadcastTitle:getChildByName("txt_home_broadcast")
  baseUIReportLabel:setVisible(false)
  local aTempPos = baseUIReportLabel:getPosition()
  baseUIReportLabel = baseUIReportLabel:getChildByName("txt_home_broadcast")
  local aReportLabelFontSize = baseUIReportLabel:getFontSize()
  local aReportLabelFontName = baseUIReportLabel:getFontName()
  self.newReportLabel = TextField:create("", aReportLabelFontName, aReportLabelFontSize, nil, kCCTextAlignmentLeft, kCCVerticalTextAlignmentTop)
  self.newReportLabel:setAnchorPoint(ccp(0, 1.0))
  self.newReportLabel:setPositionY(aTempPos.y)
  self.BaseUi:addChild(self.newReportLabel)--mark 等待改成只显示这个广播的情况 zheng.che
  if not broadcast_current_position then
    broadcast_original_position = visibleSize.width
    broadcast_current_position = broadcast_original_position
    broadcast_duration = 0
    broadcast_content = EventManager:sharedManager():getOneSystemBoardcast()
	if not broadcast_content then
		broadcast_content = " "
	end
	broadcast_content = tostring(broadcast_content)
  end
  self.newReportLabel:setString(broadcast_content)
  self.newReportLabel:setPositionX(broadcast_current_position)
  if not broadcast_total_duration then
    broadcast_total_duration = (visibleSize.width + self.newReportLabel:getTexture():getContentSize().width) / broadcast_speed
  end
  local function updateReport(dt) --时间表函数 广播用的
    if broadcast_duration < 0 then
      broadcast_content = EventManager:sharedManager():getOneSystemBoardcast()
	  if not broadcast_content then
		broadcast_content = " "
	end
	broadcast_content = tostring(broadcast_content)
      self.newReportLabel:setString(broadcast_content)
      broadcast_duration = 0
      broadcast_total_duration = (visibleSize.width + self.newReportLabel:getTexture():getContentSize().width) / broadcast_speed
    end
    
    broadcast_duration = broadcast_duration + dt
    if broadcast_duration <= broadcast_total_duration then
      broadcast_current_position = broadcast_current_position - broadcast_speed * dt
    else
      broadcast_current_position = broadcast_original_position
      broadcast_duration = -1
    end
    self.newReportLabel:setPositionX(broadcast_current_position)
  end
  
  self.reportUpdateFunc = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(updateReport,0,false)
    

    if not self.useCoroutine then
        if isUCAndroid() then
            if getIsUCSdkInit() then
                showUCFloatButton(50,50,true)
            end
        elseif is91Android() then
            if getIs91SdkInit() then
                show91FloatButton(true)
            end
        elseif isDKAndroid() then
        	-- print("~~~~~~~~~~~~~~~~~~~~~~~~~~百度多酷悬浮框")
        	showDKFloatButton(true)
        elseif isOppoAndroid() then
            showOppoFloatSprite(true)
        elseif isYyhAndroid() then
            showYyhToolBar(true)
		elseif isAnzhiAndroid() then
            showAnzhiFloatBar(true)
        end
    end 
    
  if self.rewardParticle and self.rewardParticle.refCocosObj then
    self.rewardParticle:setVisible(false)
    self.rewardParticle.refCocosObj:stopSystem()
  end

	local function onUnionColosseumBossDataUpdate(evt)
		--管理军团按钮闪烁
		if UnionManager.isInBossAttackState() or UnionPkUtils.isShineUnionBtnWhenInUnionPKTime() then
			--当前有boss
			self.unionBtn:setShined(true)
		else
			--无boss
			self.unionBtn:setShined(false)
		end
	end
	self.onUnionColosseumBossDataUpdate = onUnionColosseumBossDataUpdate
	UnionManager.eventDispatcher:addEventListener(UnionManager.COLOSSEUM_BOSS_STATE_UPDATE, self.onUnionColosseumBossDataUpdate, self)
  
end

function BaseUIScene:setTitleVisible( flag )
	for key, value in pairs(self.bg_home_menu_top) do
		value:setVisible(flag)
	end
	self.backBt:setEnable(false)
end

function BaseUIScene:initBackGround()
	local background = nil
	local currentPixelFormat = CCTexture2D:defaultAlphaPixelFormat()
	if IsDiaosiDevice() then
		CCTexture2D:setDefaultAlphaPixelFormat(kCCTexture2DPixelFormat_RGBA4444);
		background = Sprite:create("pic/base_ui_bg_ex.png")
	else
		CCTexture2D:setDefaultAlphaPixelFormat(kCCTexture2DPixelFormat_RGBA8888);
		background = Sprite:create("pic/base_ui_bg.png")
	end
	
	background:setScale(2)
	background:setPosition(ccp(visibleSize.width/2,visibleSize.height/2))
	self:addChild(background)
	CCTexture2D:setDefaultAlphaPixelFormat(currentPixelFormat);
end

function BaseUIScene:dispose()
  UnionManager.eventDispatcher:removeEventListener(UnionManager.COLOSSEUM_BOSS_STATE_UPDATE, self.onUnionColosseumBossDataUpdate)

  if self.onUpdateRewardUIFunc then
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.onUpdateRewardUIFunc)
  end
	unregisterBackKey("baseUIBackBt")
  if (self.onUpdateFunc) then
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.onUpdateFunc)
  end
  if (self.reportUpdateFunc) then
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.reportUpdateFunc)
  end
  if self.onUserOnlineFunc then
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.onUserOnlineFunc)
  end
  if self.onCrossDayUpdateFunc then
  	CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.onCrossDayUpdateFunc)
  end

  Scene.dispose(self)

  --标记为已经清除 凡有此标记的scene可以直接等死 不用做更新操作了
  self.disposed = true
end

function BaseUIScene:nodeAnimationFinished()
  self.nodeActionCount = self.nodeActionCount + 1
  if self.nodeActionCount >= 2 then
    self.nodeActionCount = 0
    if self.animationType == "exitAction" then
      self:sufExitAnimation()
	  
	  local function waitNextStep()
		CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.waitNextStepHandler)
		self.waitNextStepHandler = nil;
		local scene = self.targetScene:create(self.argumentList, true)
		
		
		if type(self.targetScene.onInitCoroutine) == "function" then
			local loadingFlash = FlashSprite:create("EVO2/Loading_lvbu")
			loadingFlash:changeAnimation(0)
			self:addChild(CocosObject.new(loadingFlash))
			--[[local co = coroutine.create(self.targetScene.onInitCoroutine)
			local onInitCoroutineHandler
			local function continueOnInitCoroutine()
				if coroutine.status(co) ~= "dead" then
					coroutine.resume(co)
				else
					if onInitCoroutineHandler ~= nil then
						CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(onInitCoroutineHandler)
						onInitCoroutineHandler = nil;
					end
					Director:sharedDirector():replaceScene(scene)
				end
			end
			onInitCoroutineHandler = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(continueOnInitCoroutine,0.01,false);
			
			coroutine.resume(co)--]]
			local onInitCoroutineHandler
			local function continueOnInitCoroutine()
				local function onInitEndFunc()
					Director:sharedDirector():replaceScene(scene)
				end
				if onInitCoroutineHandler ~= nil then
					CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(onInitCoroutineHandler)
					onInitCoroutineHandler = nil;
				end
				self.targetScene:onInitCoroutine(onInitEndFunc)
			end
			onInitCoroutineHandler = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(continueOnInitCoroutine,0.01,false);
			self.touchEnabled = false
		else
			 Director:sharedDirector():replaceScene(scene)
		end
		
	  end
	  if not self.waitNextStepHandler then
		self.waitNextStepHandler = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(waitNextStep, self.exit_animation_duration,false);
	  end
      
    elseif self.animationType == "enterAction" then
      self:sufEnterAnimation()
    end
  end
end

function BaseUIScene:preEnterAnimation()
  CCDirector:sharedDirector():getTouchDispatcher():setDispatchEvents(false)
--  self.preTargetInfoPanel = self.targetInfoPanel
--  self.targetInfoPanel = true --说明：这里不能设为true，不然如果加载Scene时有网络请求且信号不好，则会卡死
  self:setTableViewsEnabled(false)
  self.animationType = "enterAction"
end

function BaseUIScene:onEnter(params)
	Scene.onEnter(self, params)
end

function BaseUIScene:startEnterAnimation()
  local function enterActionFinished()
	registerBackKey("baseUIBackBt", self.backBt)
    self:nodeAnimationFinished()
--	self.targetInfoPanel = self.preTargetInfoPanel
	self:setTableViewsEnabled(true)

	--print("enterActionFinished !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
	NotificationManager:dispatchEvent(Event.new("enterActionFinished"))
  end
  if not self.ignoreAction then
    local aMenuTitle = self.BaseUi:getChildByName("home_menu_title")
    local aHeight = aMenuTitle:getGroupBounds().size.height
    self.backDisplay:setPositionY(self.backDisplay:getPositionY() + aHeight)
    self.backDisplay:runAction(CCMoveBy:create(enter_animation_duration, ccp(0, -aHeight)))
    
    for _, aChild in pairs(self.bg_home_menu_top) do
      aChild:setPositionY(aChild:getPositionY() + aHeight)
      aChild:runAction(CCMoveBy:create(enter_animation_duration, ccp(0, -aHeight)))
    end
    
    local arr = CCArray:create()
    arr:addObject(CCDelayTime:create(enter_animation_duration))
    --arr:addObject(CCMoveBy:create(0.5, ccp(-visibleSize.width, 0)))
    arr:addObject(CCCallFunc:create(enterActionFinished))
    self.btn_home_menu_title:runAction(CCSequence:create(arr))
  else
    self:runAction(CCCallFunc:create(enterActionFinished))
  end
end

function BaseUIScene:sufEnterAnimation()
  local function Get_Whether_NewUserGuide_Running() --判断是否在运行新手引导
    if Get_ShareData( "New_User_Guide_Running" ) == 1 then --如果新手引导正在运行
      return true
    end
    if _G.Guide_JudgeInEachFrameSchedule ~= nil then --如果正在等待启动下一段新手引导
      return true
    end
    if Get_ShareData( "NewUserGuide_Not_Finished" ) == 1 then --如果第一次启动游戏，正等待启动新手引动导
      return true
    end
    return false
  end
  CCDirector:sharedDirector():getTouchDispatcher():setDispatchEvents(true)
  if ( not Get_Whether_NewUserGuide_Running() ) then       
    --进行防沉迷判断
    local function popAddictionPanel(addictionState)
        he_log_info("+++++++++++++++++++++++++++360 Log:addiction state: " .. addictionState .. "++++++++++++++++++++++++++++++++")
        if addictionState ~= AddictionStateTable.normal then
            he_log_info("+++++++++++++++++++++++++++addiction Log:pop addiction panel++++++++++++++++++++++++++++++++")
            self.targetInfoPanel = AntiAddictionReminderPanel:create( self , addictionState)
            PopoutManager:sharedManager():popout(self.targetInfoPanel , kPopoutDir.kScale, true, false ,self)
        end
    end
    AntiAddictionManager.judgeIsAddiction(popAddictionPanel)
  end
	self.isChangeingScene = false
	local function recalculateUserLevel()
		local userData = DataManager.getCurrUser()
		local aUserLevelConfig = MetaManager.user_level[userData.level]
		local aMaxLevel = RewardManager.getMaxLimitOfUserLevel()
		while tonumber(userData.exp, 10) >= tonumber(aUserLevelConfig.exp, 10) do
			if userData.level >= aMaxLevel then
				break
			end
			userData.exp = tostring(tonumber(userData.exp)-tonumber(aUserLevelConfig.exp))
			userData.level = userData.level + 1
			aUserLevelConfig = MetaManager.user_level[userData.level]
		end
		DataManager.setCurrUser(userData)
	end
	recalculateUserLevel()
	local function resetLevelAndExpUI()
		local userData = DataManager.getCurrUser()
		g_BaseUISceneObject:getChildByName("home_menu_title"):getChildByName("txt_home_lv"):getChildByName("font"):setString( "Lv." .. userData.level)
		g_BaseUISceneObject:getChildByName("home_menu_title"):getChildByName("txt_icon_playerExp_num"):getChildByName("font"):setString(userData.exp .. "/" .. MetaManager.user_level[userData.level].exp)
		g_BaseUISceneExpBar[0]:setPercentage(userData.exp * 100 / MetaManager.user_level[userData.level].exp)
	end
	resetLevelAndExpUI()
	UserLevelManager.checkUserLevelUp(nil)
  Set_ShareData( "EnterAnimationFinished", 1 ) --通知“新手引导模块”动画播放完了
  
  if self.rewardParticle and self.rewardParticle.refCocosObj then
    self.rewardParticle:setVisible(true)
    self.rewardParticle.refCocosObj:resetSystem()
  end
  
end

function BaseUIScene:preExitAnimation()
  CCDirector:sharedDirector():getTouchDispatcher():setDispatchEvents(false)
  self.animationType = "exitAction"
  
  if self.rewardParticle and self.rewardParticle.refCocosObj then
    self.rewardParticle:setVisible(false)
  end
  
  if self.mainActorPanel then
    self.mainActorPanel:removeFromParentAndCleanup()
  end
  
end

function BaseUIScene:startExitAnimation()
  local function enterActionFinished()
    self:nodeAnimationFinished()
  end
  if not self.ignoreAction then
	local aMenuTitle = self.BaseUi:getChildByName("home_menu_title")
	local aHeight = aMenuTitle:getGroupBounds().size.height
	for key, aChild in pairs(self.bg_home_menu_top) do
		aChild:runAction(CCMoveBy:create(enter_animation_duration, ccp(0, aHeight)))
	end

	if self.backDisplay ~= nil then
		self.backDisplay:runAction(CCMoveBy:create(enter_animation_duration, ccp(0, aHeight)))
	end
    local arr = CCArray:create()
    --arr:addObject(CCMoveBy:create(0.5, ccp(visibleSize.width, 0)))
    arr:addObject(CCCallFunc:create(enterActionFinished))
    self.btn_home_menu_title:runAction(CCSequence:create(arr))
  else
    self:runAction(CCCallFunc:create(enterActionFinished))
  end
end

function BaseUIScene:sufExitAnimation()
  CCDirector:sharedDirector():getTouchDispatcher():setDispatchEvents(true)
end

function BaseUIScene:replaceToArena()
    local userData = DataManager.getCurrUser()
    local function getArenaMatchedPlayersSucceed(event)
      ArenaManager:sharedManager():resetArenaData(event.data)
      
      if ArenaManager:sharedManager():whetherRequestForArenaScore() then
        local function gainArenaScoreByRankSucceed(event)
          ArenaManager:sharedManager():cacheGainArenaRankScoreTime()
          RewardManager:getReward({event.data.reward})
          ArenaManager:sharedManager():gainArenaScoreByRank(event.data.reward.amount)
          self:replaceScene(ArenaRankScene)
        end 
        local function gainArenaScoreByRankFailed(event)
          ArenaManager:sharedManager():cacheGainArenaRankScoreTime()
          if event.data.retCode == 712407 then
            
          end
          self:replaceScene(ArenaRankScene)
        end
      
        local params = {}
        local request = GainArenaScoreByRankRequest.new(params, rpc.SendingPriority.kHigh)
        request:addEventListener(RequestNotifyEnum.GainArenaScoreByRankSucceed, gainArenaScoreByRankSucceed)
        request:addEventListener(RequestNotifyEnum.GainArenaScoreByRankFailed, gainArenaScoreByRankFailed)
        request:start()
      else
        self:replaceScene(ArenaRankScene)
      end
    end 
    
    local function getArenaMatchedPlayersFailed(event)
      if event.data.retCode == 712400 then
        local aContent = Localization:getInstance():getText("arena_levelInsufficient", {num = MetaManager.game_meta.gameSettingConfig.arenaUnlockLevel})
        SuspensionLabel:showContent(self, aContent)
      end
    end
    
    if (userData.level >= MetaManager.game_meta.gameSettingConfig.arenaUnlockLevel) then
      local params = {}
      local request = GetArenaMatchedPlayersRequest.new(params, rpc.SendingPriority.kHigh)
      request:addEventListener(RequestNotifyEnum.GetArenaMatchedPlayersSucceed, getArenaMatchedPlayersSucceed)
      request:addEventListener(RequestNotifyEnum.GetArenaMatchedPlayersFailed, getArenaMatchedPlayersFailed)
      request:start()
    else
      local aContent = Localization:getInstance():getText("arena_levelInsufficient", {num = MetaManager.game_meta.gameSettingConfig.arenaUnlockLevel})
      SuspensionLabel:showContent(self, aContent)
    end
end

function BaseUIScene:moveToMap()
  local argv = {enterScene="MainMenuScene",returnScene="MainMenuScene",params={notReset=false}}
    self:replaceScene(CityMainScene, argv)
end

function BaseUIScene:setupCountdownRewardUI(rewardUI, particlePosX,showOnMainMenu)
  local txtRewardCoolDown
  local txtGetReward
  local btnGetReward
  local gameInitData = DataManager.getGameInitData()

      --生成礼包粒子效果
    local function geneRewardParticle()
      self.rewardParticle = ParticleManager.geneParticle(ParticlePathConstants.FxStarline, ccp(particlePosX or 211, 40), 1, 1000, rewardUI)
      local particleMoveArray = CCArray:create()
      local particleMoveTime = 0.4
      particleMoveArray:addObject(CCMoveBy:create(particleMoveTime, ccp(90, 0)))
      particleMoveArray:addObject(CCMoveBy:create(particleMoveTime, ccp(0, -90)))
      particleMoveArray:addObject(CCMoveBy:create(particleMoveTime, ccp(-90, 0)))
      particleMoveArray:addObject(CCMoveBy:create(particleMoveTime, ccp(0, 90)))
      self.rewardParticle:runAction(CCRepeatForever:create(CCSequence:create(particleMoveArray)))
    end
  
  local countdownRewardInfo = DataManager.getCountdownRewardInfo()
  if countdownRewardInfo and (not countdownRewardInfo.finished) and IsGuideExecuted(GuideConfig.kRisk3) then 
    
    -- 计算冷却时间
    local function calcTimeCoolDown(latestRewardTimestamp, rewardId)
      if not MetaManager.countdown_reward[rewardId] then
        return 0
      end
      return MetaManager.countdown_reward[rewardId].countdownTime - (TimeUtil.getServerTimeSeconds() - latestRewardTimestamp)
    end
    local timeCoolDown = calcTimeCoolDown(countdownRewardInfo.latestRewardTimestamp, countdownRewardInfo.inProcessRewardId)
    if timeCoolDown < 0 then
      timeCoolDown = 0
    end
    

    
    --更新礼包UI
    local function onUpdateRewardUI(ee)
      if timeCoolDown <= 0 then
        return
      else
        timeCoolDown = timeCoolDown - 1
      end
      if timeCoolDown <= 0 then
        txtRewardCoolDown:setVisible(false)
        txtGetReward:setVisible(true)
        geneRewardParticle()
      else
        txtRewardCoolDown:setString(TimeUtil.formatTime(timeCoolDown))
      end
    end
    
    --点击礼包事件
    local function onClickGetReward(evt)
      local function popRewardPanelFinish()
      	if self.rewardParticle then --删除粒子效果
            self.rewardParticle:removeFromParentAndCleanup(true)
          end

          countdownRewardInfo = DataManager.getCountdownRewardInfo()
          
          if not countdownRewardInfo.finished then
            --计算当前的冷却时间
            timeCoolDown = calcTimeCoolDown(countdownRewardInfo.latestRewardTimestamp, countdownRewardInfo.inProcessRewardId)
            txtRewardCoolDown:setVisible(true)
            txtGetReward:setVisible(false)       
            if not self.onUpdateRewardUIFunc then --计时器不存在时创建
              self.onUpdateRewardUIFunc = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(onUpdateRewardUI, 1, false)
            end
          else
            timeCoolDown = 0
            --新手礼包全部领取后隐藏UI
            self:setupCountdownRewardUI(rewardUI , particlePosX,showOnMainMenu)
            -- rewardUI:setVisible(false)
          end
      end
    
      --btnGetReward:setEnable(false)
      -- if timeCoolDown > 0 then
        
        -- self.targetInfoPanel = CountdownRewardPanel:create(self, timeCoolDown, countdownRewardInfo.inProcessRewardId,
        --   countdownRewardInfo.finished, CountdownType.ViewReward, popRewardPanelFinish)
        self.targetInfoPanel = CountDownRewardNewPanel:create(self, timeCoolDown, countdownRewardInfo.inProcessRewardId,
          countdownRewardInfo.finished, CountdownType.ViewReward, popRewardPanelFinish)
        PopoutManager:sharedManager():popout(self.targetInfoPanel, kPopoutDir.kScale, true, false, self)
      -- else
        -- local function getCountdownRewardFinish(responseData)
        --   btnGetReward:setEnable(true)
        --   local gainRewardId = countdownRewardInfo.inProcessRewardId
          
        --   countdownRewardInfo = {
        --     latestRewardTimestamp = responseData.data.latestRewardTimestamp,
        --     inProcessRewardId = responseData.data.inProcessRewardId,
        --     finished = responseData.data.finished,
        --   }
        --   --更新新手礼包信息并领奖
        --   DataManager.setCountdownRewardInfo(countdownRewardInfo)
        --   RewardManager:getReward(responseData.data.rewards)
     
          -- if self.rewardParticle then --删除粒子效果
          --   self.rewardParticle:removeFromParentAndCleanup(true)
          -- end
          
          -- if not countdownRewardInfo.finished then
          --   --计算当前的冷却时间
          --   timeCoolDown = calcTimeCoolDown(countdownRewardInfo.latestRewardTimestamp, countdownRewardInfo.inProcessRewardId)
          --   txtRewardCoolDown:setVisible(true)
          --   txtGetReward:setVisible(false)       
          --   if not self.onUpdateRewardUIFunc then --计时器不存在时创建
          --     self.onUpdateRewardUIFunc = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(onUpdateRewardUI, 1, false)
          --   end
          -- else
          --   timeCoolDown = 0
          --   --新手礼包全部领取后隐藏UI
          --   rewardUI:setVisible(false)
          -- end
          
      --     --弹出面板
      --     self.targetInfoPanel = CountdownRewardPanel:create(self, timeCoolDown, gainRewardId, 
      --       countdownRewardInfo.finished, CountdownType.GetReward, popRewardPanelFinish)
      --     PopoutManager:sharedManager():popout(self.targetInfoPanel, kPopoutDir.kScale, true, false, self)
      --   end
        
        -- local function getCountdownRewardFailed(evt)
        --   local errorCode = tonumber(evt.data)
        --   if(CommErrorCodes.COUNTDOWN_REWARD_META_NOT_CONFIGED.code == errorCode) then
        --     CanonMessageBox:showCommErrorBox(CommErrorCodes.COUNTDOWN_REWARD_META_NOT_CONFIGED, nil, nil, nil)
        --   elseif(CommErrorCodes.COUNTDOWN_REWARD_NOT_REACH_TIME.code == errorCode) then
        --     CanonMessageBox:showCommErrorBox(CommErrorCodes.COUNTDOWN_REWARD_NOT_REACH_TIME, nil, nil, nil)
        --   end
        -- end
        
      --   local params = {}
      --   local request = GetCountdownRewardRequest.new(params, rpc.SendingPriority.kHigh)
      --   request:addEventListener(RequestNotifyEnum.GetCountdownRewardSucceed, getCountdownRewardFinish)
      --   request:addEventListener(RequestNotifyEnum.GetCountdownRewardFailed, getCountdownRewardFailed)
      --   request:start()
      -- end
    end
    
    txtRewardCoolDown = rewardUI:getChildByName("txt_countdown"):getChildByName("txt")
    txtRewardCoolDown:setString("")
    txtGetReward = rewardUI:getChildByName("icon_txt_getreward")
    btnGetReward = Button:create(rewardUI:getChildByName("icon_countdown_reward"))
    btnGetReward:addEventListener(Events.kStart, onClickGetReward, self)
    rewardUI:getChildByName("lbl_zhouyidalibao"):setVisible(false)
    if timeCoolDown <= 0 then
      geneRewardParticle()
      txtRewardCoolDown:setVisible(false)
    else
      txtGetReward:setVisible(false)
      txtRewardCoolDown:setString(TimeUtil.formatTime(timeCoolDown))
      --礼包更新计时器
      self.onUpdateRewardUIFunc = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(onUpdateRewardUI, 1, false)
    end
  elseif showOnMainMenu and MaintenanceManager.isActivityOpen("activityOneDay") and (not gameInitData.gainMondayRewardStatus) then
  	rewardUI:setVisible(true)
  	rewardUI:getChildByName("lbl_zhouyidalibao"):setVisible(true)
  	rewardUI:getChildByName("txt_countdown"):setVisible(false)
  	rewardUI:getChildByName("icon_txt_getreward"):setVisible(false)
  	--点击礼包事件
    local function onClickGetReward(evt)
    	if BagCalcManager.isFull() then
	        local aContent = Localization:getInstance():getText("rewardPopup_inventoryFullTxt")
	        NewPackageFullPanel:show()
	        return
	    end
    	local function activeRewardSucceedResponse( e )
    		if self.rewardParticle then --删除粒子效果
	            self.rewardParticle:removeFromParentAndCleanup(true)
	        end
    		local function onGet()
	          -- body
	        	RewardManager:getReward(e.data.rewards)
	        	rewardUI:setVisible(false)
	        	gameInitData = DataManager.getGameInitData()
	        	gameInitData.gainMondayRewardStatus = true
	        	DataManager.setGameInitData(gameInitData)
	        end
	        
	        local aRewardPanel = RewardReviewPanel:create( self, {rewardList = e.data.rewards, rewardTitle = Localization:getInstance():getText("activity_newyear_rewardTitle"), callback = onGet} )
	        self:addChild(aRewardPanel)
	        aRewardPanel:scaleIn()
    	end

    	local function activeRewardFailedResponse( e )
    		if ( e.data == 710516) then
	          	NewPackageFullPanel:show()
	        elseif  e.data == 714681 then  --activity closed
	          local function closeCanonMessageBox()
	          	self:setupCountdownRewardUI(rewardUI , particlePosX,false)
	          end
	          local text = Localization:getInstance():getText("activity_mondayreward_errortxt1")
	          self.targetInfoPanel = CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
	        end
    	end
    	GainMondayRewardRequest.sendRequest(nil ,activeRewardSucceedResponse , activeRewardFailedResponse)
  	end
  	rewardUI:getChildByName("icon_countdown_reward"):removeAllEventListeners()
  	btnGetReward = Button:create(rewardUI:getChildByName("icon_countdown_reward"))
    btnGetReward:addEventListener(Events.kStart, onClickGetReward, self)
    geneRewardParticle()

  else
    rewardUI:setVisible(false)
  end
  	--定期更新时间
	local function timeTick(ee)
	    --print("定期更新时间: " .. self.currentTime)
	     -- print("定期更新时间2: " .. TimeUtil.getServerTimeSeconds())
	    -- print("标准时间:"..TimeUtil.formatTime(TimeUtil.getServerTimeSeconds()))
	    local b = TimeUtil.whetherSwitchDay(self.currentTime)
	    -- self.isAcrossDay = true
	    --print(b)
	    --print(type(b))
	    if b then
	      --跨天了
        	gameInitData.gainMondayRewardStatus = false
        	DataManager.setGameInitData(gameInitData)
        	gameInitData = DataManager.getGameInitData()
	      	self:setupCountdownRewardUI(rewardUI , particlePosX,showOnMainMenu)
	      --重新记录当前时间
	      	self.currentTime = TimeUtil.getServerTimeSeconds()
	    end
	end

	if self.onCrossDayUpdateFunc then
	  	CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.onCrossDayUpdateFunc)
	end

	self.currentTime = TimeUtil.getServerTimeSeconds()
  	self.onCrossDayUpdateFunc = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(timeTick,15,false);
end

--add by zheng.che
--切换显示模式
function BaseUIScene:switchMenuState(aType)
	--先强制不显示主菜单和标题菜单
	self.BaseUi:getChildByName("home_menu_title"):setVisible(false)
	self.BaseUi:getChildByName("home_menu_bottom"):setVisible(false)

	if self.currentMenu then
		self.currentMenu:removeFromParentAndCleanup(true)
		self.currentMenu = nil
	end

	if aType == SceneMenuTypeEnum.BASE then
		--普通
		self.BaseUi:getChildByName("home_menu_title"):setVisible(true)
		self.BaseUi:getChildByName("home_menu_bottom"):setVisible(true)
	elseif aType == SceneMenuTypeEnum.UNION then
		--军团
		self.currentMenu = UnionBottomMenuPanel.create(self)
		self.BaseUi:removeChild(self.mainActorTouchLayer)
	end

	if self.currentMenu then
		self:addChild(self.currentMenu)
	end
end

PlistResMgr:getInstance():registerSystemBackHandler(onSystemBackKeyClick)