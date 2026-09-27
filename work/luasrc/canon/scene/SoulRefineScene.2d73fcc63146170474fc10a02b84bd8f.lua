--
-- SoulRefineScene
-- Author: czh
-- Date: 2014-02-12 18:13:31
--
require "hecore.display.CocosObject"
require "hecore.display.Director"
require "hecore.ui.Button"
require "hecore.display.Sprite"
require "hecore.ui.LayoutBuilder"
require "canon.scene.BaseUIScene"
require "canon.request.ChallengeMultiplayerBossRequest"
require "canon.request.GetMultiplayerBossDamageRequest"
require "canon.request.BuyActionPowerRequest"
require "canon.panel.MBDamageRecordPopPanel"
require "canon.utils.TabPanelChange"
require "canon.panel.FragmentCardListPanel"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

MultiplayerBossTagEnum = {
  BossList = 1,
  ChallengeRecord = 2,
  Leaderboard = 3,
}

local enter_animation_duration = 0.3

-------------------------------------------------------------------------------
-- 
-------------------------------------------------------------------------------


local function cardTabButtonSelected(evt)
  evt.context.tabChangeComponent:changeToPanelByIndex(1)
end

local function cquipTabButtonSelected(evt)
  evt.context.tabChangeComponent:changeToPanelByIndex(2)
end

-------------------------------------------------------------------------------
-- 
-------------------------------------------------------------------------------

SoulRefineScene = class(BaseUIScene)

function SoulRefineScene:ctor()
end

local globalReturnScene

function SoulRefineScene:create(argv)
  local s = SoulRefineScene.new()
  if argv then 
      self.argv = argv 
  else
      self.argv = {enterScene=nil,returnScene=nil,params={}}
  end

  --当前选择的panel
  self.selectedPanel = nil
  -- self.bossInfo = self.argv.params.data
  -- if self.argv.returnScene == "SoulRefineScene" then
  --   globalReturnScene = "SoulRefineScene"
  -- elseif self.argv.returnScene == "ChapterMapScene" then
  --   globalReturnScene = "ChapterMapScene"
  -- end
  s:initScene()
  return s
end

function SoulRefineScene:onInit()
	BaseUIScene.initBackGround(self)
    
    --新UI加黑底
    local colorLayer = LayerColor:create()
    colorLayer:setOpacity(kDarkOpacity)
    colorLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
    self:addChild(colorLayer)
    
	self.title = Localization:getInstance():getText("title_activityNian")

	local builder = LayoutBuilder:createWithContentsOfFile("scene/soulcombine.json")
	local ui = builder:build("soulcombine")
	self:addChild(ui)
	self.ui = ui

	self.tabChangeComponent = TabPanelChange.new(self, nil, nil, nil)

	--local cardFragments = {{metaId = 800121, amount = 20}, {metaId = 800122, amount = 30}, {metaId = 800123, amount = 40}, {metaId = 800124, amount = 20}, {metaId = 800125, amount = 20}}
	--local cardFragments = {{metaId = 800121, amount = 20}}
	local cardFragments = DataManager:getGameInitData().sharkCardFragments.sharkCardFragments

	--显示tab
	self.uiGroup1 = ui:getChildByName("btn_tab_cardsoul")
	self.uiGroup1:getChildByName("txt"):setString(Localization:getInstance():getText("tab1"))
	self.cardTabButton = Button:create(self.uiGroup1)
	self.cardTabButton:addEventListener(Events.kStart, cardTabButtonSelected, self)
	self.tabChangeComponent:addTab(self.cardTabButton, FragmentCardListPanel:create(self, cardFragments))

	self.uiGroup2 = ui:getChildByName("btn_tab_itemsoul")
	self.uiGroup2:getChildByName("txt"):setString(Localization:getInstance():getText("tab2"))
	self.euuipTabButton = Button:create(self.uiGroup2)
	self.euuipTabButton:addEventListener(Events.kStart, cquipTabButtonSelected, self)
	self.tabChangeComponent:addTab(self.euuipTabButton, MBRankListPanel:create(self, {}))

	self.tabChangeComponent:changeToPanelByIndex(1)
  

	-- self.uiGroup2 = ui:getChildByName("btn_select_challenge_record")
	-- self.uiGroup2:getChildByName("txt"):setString(Localization:getInstance():getText("activityNian_rewardListTab"))
	-- self.recordButton = Button:create(self.uiGroup2)
	-- self.recordButton:addEventListener(Events.kStart, recordButtonSelected, self)

	-- local challengeButtonDisplay = ui:getChildByName("btn_challenge")
	-- challengeButtonDisplay:getChildByName("txt"):setString(Localization:getInstance():getText("activityNian_battle_battleBtn"))
	-- local challengeButton = Button:create(challengeButtonDisplay)
	-- challengeButton:addEventListener(Events.kStart, challengeButtonSelected, self)
  
	local function refreshSelf()
	end
	self.refreshSelf = refreshSelf
  
	refreshSelf()

	BaseUIScene.onInit(self)
end

-----------------------------------------------进出场景动画------------------------------------------------------------
function SoulRefineScene:doEnterAnimation()
	self:preEnterAnimation()
	self:startEnterAnimation()
end

function SoulRefineScene:preEnterAnimation()
	BaseUIScene.preEnterAnimation(self)
	--
	CanonPlayBackgroundMusic("music/background.mp3", true)
end

function SoulRefineScene:startEnterAnimation()
	BaseUIScene.startEnterAnimation(self)
	local function enterActionFinished()
		self:nodeAnimationFinished()
	end

	self.ui:setPositionX(self.ui:getPositionX() - visibleSize.width)
	local arr = CCArray:create()
	arr:addObject(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
	arr:addObject(CCCallFunc:create(enterActionFinished))
	self.ui:runAction(CCSequence:create(arr))
end

function SoulRefineScene:sufEnterAnimation()
	BaseUIScene.sufEnterAnimation(self)
	--
end

function SoulRefineScene:doExitAnimation()
	self:preExitAnimation()
	self:startExitAnimation()
end

function SoulRefineScene:preExitAnimation()
	BaseUIScene.preExitAnimation(self)
end

function SoulRefineScene:startExitAnimation()
	BaseUIScene.startExitAnimation(self)
	local function enterActionFinished()
		self:nodeAnimationFinished()
	end

	local arr = CCArray:create()
	arr:addObject(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
	arr:addObject(CCCallFunc:create(enterActionFinished))
	self.ui:runAction(CCSequence:create(arr))

	--同时当前选择页也退出动画 并行进行
	self.tabChangeComponent:startPanelExit(nil)
end

function SoulRefineScene:sufExitAnimation()
	BaseUIScene.sufExitAnimation(self)
end
-----------------------------------------------进出场景动画------------------------------------------------------------

-- 退出到外层
function SoulRefineScene:back()
	self:replaceScene(MainMenuScene)
end

function SoulRefineScene:dispose()
	self.tabChangeComponent:dispose()
	self.tabChangeComponent = nil

	SoulRefineScene.super.dispose(self)
end
