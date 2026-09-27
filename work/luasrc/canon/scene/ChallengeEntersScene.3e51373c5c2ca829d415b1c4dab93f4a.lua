--------------------------------------------------------------------------------
-- ChallengeEntersScene.lua - 演武统一入口显示界面
-- author: xiaojie.bai
-- date: 2013-10-05 10:15
--------------------------------------------------------------------------------

local function getNewBabelUnlockLevel()
	return MetaManager.getNewBabelSettings().unlockLevel
end

function getDestinyFightUnlockLevel()
	return MetaManager.getSpiritSettings().unlockLevel
end

require "canon.scene.BaseUIScene"
require "canon.panel.EliteEnterPanel"
require "canon.panel.SkyEnterPanel"
require "canon.models.ChallengeEntersManager"
require "canon.panel.NewBabelEnterPanel"
require "canon.panel.DestinyFightEnterPanel"

ChallengeEntersScene = class(BaseUIScene)
local visibleSize = CCDirector:sharedDirector():getVisibleSize();

local DICT_PANEL = {
    {
      name = "elite",
      head = {textKey = "elite_title", icon = "pic/activityIcons/icon_jingyinguangqia.png", icon_selected = "pic/activityIcons/icon_Activity_waikuang.png"},
      panel = EliteEnterPanel
    },
    {
      name = "skytower",
      head = {textKey = "babel_title", icon = "pic/activityIcons/icon_tongtianta.png", icon_selected = "pic/activityIcons/icon_Activity_waikuang.png"},
      panel = NewBabelEnterPanel
    },
	{--宿命对决
      name = "destiny",
      head = {textKey = "destinyBattle_title", icon = "pic/activityIcons/icon_destiny_fight.png", icon_selected = "pic/activityIcons/icon_Activity_waikuang.png"},
      panel = DestinyFightEnterPanel
    },
  }
  
function ChallengeEntersScene:ctor()
  self.curSceneEnum = SceneEnum.ChallengeEntersScene
	self.title = getTextByKey("home_challengeBtn")
  
  self.mainUI = nil
  self.headUI = nil
  self.selectedPanel = nil
end

function ChallengeEntersScene:create(argv)
  local scene = ChallengeEntersScene.new()
  
  scene.enabledPanels = {}
  scene.panelPool = {}
  
  scene.selectedPanelIdx = 1
  scene.selectedPanelName = nil
  scene.selectedPanel = nil
	
	scene.argv = argv
	
	if not scene.argv then
		scene.argv = {}
	end
	
	if not scene.argv.params then
		scene.argv.params = {}
	end
	
  scene:initScene()
  return scene
end

function ChallengeEntersScene:back()
  if self.argv.returnScene == "DailyTargetScene" then
    DailyTargetScene.gotoDailyTargetScene()
  else
    self:replaceScene(MainMenuScene)
  end
end

function ChallengeEntersScene:initEnabledPanels()
  for _, value in ipairs(DICT_PANEL) do
    local enable = value.panel.enable()
    if(enable) then
      value.head.text = getTextByKey(value.head.textKey)
      
      table.insert(self.enabledPanels, value)
    end
  end
end

function ChallengeEntersScene:createHeadTableView()
  local enabledPanels = self.enabledPanels
  local scene = self;
  local selectedPanelIdx = self.selectedPanelIdx
  
  local HeadTableViewRenderer = class(TableViewRenderer)
  function HeadTableViewRenderer:ctor(width, height)
    self.list = enabledPanels
  end
  
  function HeadTableViewRenderer:buildCell(container)
    local layer = Layer:create()
    container:addChild(layer)
    layer:setTag(1024)
  end
  
  function HeadTableViewRenderer:setData(rawCocosObj, index)
    local cellLayer = self:getChildByTag(rawCocosObj, 1024)
    cellLayer:removeAllChildrenWithCleanup(true)
    
    local enablePanel = enabledPanels[index + 1]
    local icon = enablePanel.head.icon
    local selectedIcon = enablePanel.head.icon_selected
    
    local pic = CCSprite:create(icon)
    pic:setAnchorPoint(ccp(0, 0))
    cellLayer:addChild(pic)
    
    local selectPic = CCSprite:create(selectedIcon)
    selectPic:setAnchorPoint(ccp(0, 0))
    cellLayer:addChild(selectPic)
    
    if(scene.selectedPanelIdx == index + 1) then
      selectPic:setVisible(true)
    else
      selectPic:setVisible(false)
    end
    
    local activityNameBg = CCSprite:create("pic/activityIcons/activityNameBG.png")
    activityNameBg:setPosition(pic:getContentSize().width/2,pic:getContentSize().height*0.15)
    pic:addChild(activityNameBg)
    
    local text = ArtLabelTTF:create(enablePanel.head.text,nil,30)
    text:setPosition(pic:getContentSize().width/2,pic:getContentSize().height*0.15)
    pic:addChild(text)
  end
  
  local function onListItemTouch(evt)
    local index = evt.data + 1
    if(self.selectedPanelIdx == index) then
      return nil
    end
    if self.enabledPanels[index].name == "skytower" and getNewBabelUnlockLevel() > DataManager.getCurrUser().level then
			SuspensionLabel:showContent(self, Localization:getInstance():getText("babel_levelInsufficient", {num = getNewBabelUnlockLevel()}))
			do return end
	elseif self.enabledPanels[index].name == "destiny" and getDestinyFightUnlockLevel() > DataManager.getCurrUser().level then
			SuspensionLabel:showContent(self, Localization:getInstance():getText("destinyBattle_levelInsufficient", {num = getDestinyFightUnlockLevel()}))
			do return end
	end	
    self:replacePanel(index)
  end
  
  local renderer = HeadTableViewRenderer.new(ChallengeEntersManager.DICT.ITEM_HEAD_WIDTH, ChallengeEntersManager.DICT.ITEM_HEAD_HEIGHT)
  local aTableView = TableView:create(renderer, ChallengeEntersManager.DICT.TB_HEAD_WIDTH, ChallengeEntersManager.DICT.TB_HEAD_HEIGHT)
  aTableView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch)
  aTableView:setPosition(ccp(ChallengeEntersManager.DICT.TB_HEAD_POSX, ChallengeEntersManager.DICT.TB_HEAD_POSY))
  aTableView:setDirection(kCCScrollViewDirectionHorizontal)
  aTableView:setPageEnabled(true)
  aTableView:reloadData()
  
  return aTableView
end

function ChallengeEntersScene:replacePanel(idx)
  if self.isChangeingScene then
    return
  end
  
  self.selectedPanelIdx = idx
  self.selectedPanelName = self.enabledPanels[self.selectedPanelIdx].name
  
  local panel = self.panelPool[self.selectedPanelName]
  if(not panel) then
    panel = self.enabledPanels[self.selectedPanelIdx].panel:create(self)
    self.panelPool[self.selectedPanelName] = panel
  end
  
  self:removeChild(self.selectedPanel, false)
  self.selectedPanel = panel
  self:addChild(self.selectedPanel)
  
  ViewControlUtil.refreshTableView(self.headUI, true)
end

function ChallengeEntersScene:onInit()
	BaseUIScene.initBackGround(self)
  --新UI加黑底
  local colorLayer = LayerColor:create()
  colorLayer:setOpacity(kDarkOpacity)
  colorLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
  self:addChild(colorLayer)
  
  local builder = LayoutBuilder:createWithContentsOfFile(EliteManager.DICT.RESOURCE_FILE)
  self.mainUI = builder:build("elite_page_challenge_enters")
  self:addChild(self.mainUI)
  
  self:initEnabledPanels()
	
	if self.argv.params.showPanelName then
		for k, data in pairs(self.enabledPanels) do
			if data.name == self.argv.params.showPanelName then
				self.selectedPanelIdx = k
				break;
			end
		end
	end
	
  self.selectedPanelName = self.enabledPanels[self.selectedPanelIdx].name
  
  self.headUI = self:createHeadTableView()
  self:addChild(self.headUI)
  
  self.selectedPanel = self.enabledPanels[self.selectedPanelIdx].panel:create(self)
  self.panelPool[self.selectedPanelName] = self.selectedPanel
  self:addChild(self.selectedPanel)
  
	BaseUIScene.onInit(self)
end

function ChallengeEntersScene:dispose()
  ChallengeEntersScene.super.dispose(self)
end

function ChallengeEntersScene:doEnterAnimation()
  self:preEnterAnimation()
  self:startEnterAnimation()
end

function ChallengeEntersScene:preEnterAnimation()
  BaseUIScene.preEnterAnimation(self)
end

function ChallengeEntersScene:startEnterAnimation()
  BaseUIScene.startEnterAnimation(self)
  
  local function enterActionFinished()
    self:nodeAnimationFinished()
  end
  
  local function getCCSequence()
    local arr = CCArray:create()
    arr:addObject(CCMoveBy:create(0.3, ccp(visibleSize.width, 0)))
    arr:addObject(CCCallFunc:create(enterActionFinished))
    
    return CCSequence:create(arr)
  end
  
  local function getCCSequenceNoEnter()
    local arr = CCArray:create()
    arr:addObject(CCMoveBy:create(0.3, ccp(visibleSize.width, 0)))
    
    return CCSequence:create(arr)
  end
  self.mainUI:setPositionX(self.mainUI:getPositionX() - visibleSize.width)
  self.headUI:setPositionX(self.headUI:getPositionX() - visibleSize.width)
  self.selectedPanel:setPositionX(self.selectedPanel:getPositionX() - visibleSize.width)
  
  self.mainUI:runAction(getCCSequence())  self.headUI:runAction(getCCSequenceNoEnter())
  self.selectedPanel:runAction(getCCSequenceNoEnter())
end

function ChallengeEntersScene:sufEnterAnimation()
  BaseUIScene.sufEnterAnimation(self)
end

function ChallengeEntersScene:doExitAnimation()
  self:preExitAnimation()
  self:startExitAnimation()
end

function ChallengeEntersScene:preExitAnimation()
  BaseUIScene.preExitAnimation(self)
end

function ChallengeEntersScene:startExitAnimation()
  BaseUIScene.startExitAnimation(self)
  
  local function exitActionFinished()
    self:nodeAnimationFinished()
  end
  
  local function getCCSequence()
    local arr = CCArray:create()
    arr:addObject(CCMoveBy:create(0.3, ccp(-visibleSize.width, 0)))
    arr:addObject(CCCallFunc:create(exitActionFinished))
    
    return CCSequence:create(arr)
  end
  
  local function getCCSequenceNoExit()
    local arr = CCArray:create()
    arr:addObject(CCMoveBy:create(0.3, ccp(-visibleSize.width, 0)))
    arr:addObject(CCCallFunc:create(exitActionFinished))
    
    return CCSequence:create(arr)
  end
  self.mainUI:runAction(getCCSequence())
  self.headUI:runAction(getCCSequenceNoExit())
  self.selectedPanel:runAction(getCCSequenceNoExit())
end

function ChallengeEntersScene:sufExitAnimation()
  BaseUIScene.sufExitAnimation(self)
end

function ChallengeEntersScene.readyToNewBabelEnterPanel()
  local curScene = Director:mgr():run()
  if getNewBabelUnlockLevel() > DataManager.getCurrUser().level then
    SuspensionLabel:showContent(curScene, Localization:getInstance():getText("babel_levelInsufficient", {num = getNewBabelUnlockLevel()}))
    return
  end
  
  Director:sharedDirector():replaceScene(ChallengeEntersScene:create({params = {showPanelName = "skytower"}}))
end