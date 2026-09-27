require "hecore.display.CocosObject"
require "hecore.display.Director"
require "hecore.ui.Button"
require "hecore.display.Sprite"
require "hecore.ui.LayoutBuilder"
require "canon.panel.UnionShopSpecialPanel"
require "canon.panel.UnionShopNormalPanel"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()
local enter_animation_duration = 0.3
local TabEnum = {
  specialProp = 1,
  normalProp = 2,
}

--
-- UnionShopScene
--

local function specialTabButtonSelected(evt)
  local container = evt.context
  local function onSucceed(requestEvent)
		GetUnionBuildingShopInfoRequest.onSucceedDefault(requestEvent)
    container:changeToPanel(TabEnum.specialProp)
    
	end

	GetUnionBuildingShopInfoRequest.sendRequest(onSucceed, GetUnionBuildingShopInfoRequest.onFailedDefault)
end

local function normalTabButtonSelected(evt)
  local container = evt.context
  container:changeToPanel(TabEnum.normalProp)
end

UnionShopScene = class(BaseUIScene)

function UnionShopScene:ctor()
	
end

function UnionShopScene:create(argv)
  local s = UnionShopScene.new()
  if argv then 
      self.argv = argv 
  else
      self.argv = {enterScene=nil,returnScene=nil,params={}}
  end
  s.curSceneEnum = SceneEnum.UnionShopScene
  s:initScene()
  return s
end

function UnionShopScene:onInit()
  UnionManager.setFirstEnterUnionShop(false)
  
	BaseUIScene.initBackGround(self)
  
  self.title = Localization:getInstance():getText("arena_title")
  
  local builder = LayoutBuilder:createWithContentsOfFile("scene/guild.json")
  local ui2 = builder:build("guild_shop")
  self:addChild(ui2)
  self.ui2 = ui2
  local ui = builder:build("guild_shop_title")
  self:addChild(ui)
  self.ui = ui
  
  local function backButtonSelected(evt)
    self:back()
  end
  local backButton = Button:create(ui:getChildByName("r_click"))
  backButton:addEventListener(Events.kStart, backButtonSelected, self)
  
  ui:getChildByName("txt_guild_19"):getChildByName("txt"):setString(Localization:getInstance():getText("union_building_name2"))
  
  self:refreshShopInfo()
  
  ui2:getChildByName("txt_guild_23"):getChildByName("txt"):setString(Localization:getInstance():getText("union_shop_special_cut_down"))
  ui2:getChildByName("txt_guild_24"):getChildByName("txt"):setString("")
  ui2:getChildByName("txt_guild_25"):getChildByName("txt"):setString(Localization:getInstance():getText("union_shop_special_remind"))
  
  local function onCreatePanel(aIndex)
		if aIndex == TabEnum.specialProp then
			return UnionShopSpecialPanel:create(self, aIndex)
		elseif aIndex == TabEnum.normalProp then
			return UnionShopNormalPanel:create(self, aIndex)
		end
	end

	self.tabChangeComponent = TabPanelChangeComponent.new(self, onCreatePanel, nil, nil, nil)
  
	self.uiGroup1 = ui:getChildByName("btn_guild_list")
	self.uiGroup1:getChildByName("txt"):setString(Localization:getInstance():getText("union_shop_type_special_name"))
	self.tabButton1 = Button:create(self.uiGroup1)
	self.tabButton1:addEventListener(Events.kStart, specialTabButtonSelected, self)
	self.tabChangeComponent:addTab(self.tabButton1)

	self.uiGroup2 = ui:getChildByName("btn_guild_list2")
	self.uiGroup2:getChildByName("txt"):setString(Localization:getInstance():getText("union_shop_type_normal_name"))
	self.tabButton2 = CanonButton:create(self.uiGroup2)
	self.tabButton2:addEventListener(Events.kStart, normalTabButtonSelected, self)
	self.tabChangeComponent:addTab(self.tabButton2)

  --等级是否已满状态
  if UnionManager.isBuildingMaxLevel(UnionManager.UNION_BUILDING_SHOP) then
    --已满级
    self.ui2:getChildByName("txt_guild_21_m"):setVisible(false)
    self.ui2:getChildByName("lbl_guild2"):setVisible(false)
    
    self.ui2:getChildByName("lbl_guild_build_max"):setVisible(true)
  else
    --不是满级
    self.ui2:getChildByName("txt_guild_21_m"):setVisible(true)
    self.ui2:getChildByName("lbl_guild2"):setVisible(true)
    
    self.ui2:getChildByName("lbl_guild_build_max"):setVisible(false)
  end
  
  self:changeToPanel(TabEnum.specialProp)
  
  BaseUIScene.onInit(self, SceneMenuTypeEnum.UNION)
end

function UnionShopScene:setTableViewsEnabled(enabled)
	if self.tabChangeComponent.currentSelectedPanel then
		self.tabChangeComponent.currentSelectedPanel:setTableViewTouched(enabled)
	end
end

function UnionShopScene:changeToPanel(aIndex)
  self.tabChangeComponent:changeToPanelByIndex(aIndex)
  local cutDownLabel = self.ui2:getChildByName("txt_guild_23")
  local cutDownTimeLabel = self.ui2:getChildByName("txt_guild_24")
  local cutDownRemindLabel = self.ui2:getChildByName("txt_guild_25")
  if aIndex == TabEnum.specialProp then
    cutDownLabel:setVisible(true)
    cutDownTimeLabel:setVisible(true)
    cutDownRemindLabel:setVisible(true)
    local oldDateTable = os.date("*t", TimeUtil.getServerTimeSeconds())
    local oldYear = oldDateTable.year
    local oldMonth = oldDateTable.month
    local oldDay = oldDateTable.day
    local oldTotalSeconds = TimeUtil.toServerTimestamp({year=oldYear,month=oldMonth,day=oldDay,hour=12})
    local currentTotalSeconds = TimeUtil.getServerTimeSeconds()
    if oldTotalSeconds <= currentTotalSeconds then
      oldTotalSeconds = oldTotalSeconds + 24 * 3600
    end
    local leftSeconds = oldTotalSeconds - currentTotalSeconds + 2 --加两秒用来避开到期时刷新数据不对 add by zheng.che
    local function setCountDownLabel(aSeconds)
      local hour = math.modf(leftSeconds / 3600)
      local tempSeconds = math.mod(leftSeconds, 3600)
      local min = math.modf(tempSeconds / 60)
      tempSeconds = math.mod(tempSeconds, 60)
      cutDownTimeLabel:getChildByName("txt"):setString(string.format("%02d:%02d:%02d", hour, min, tempSeconds))
    end
    local function countDownFunc()
      leftSeconds = leftSeconds - 1
      setCountDownLabel(leftSeconds)
      if leftSeconds <= 0 then
        leftSeconds = 24 * 3600
        local function onSucceed2(requestEvent2)
          GetUnionBuildingShopInfoRequest.onSucceedDefault(requestEvent2)
          self:refreshShopInfoAndSpecialShopPanel()
        end
        GetUnionBuildingShopInfoRequest.sendRequest(onSucceed2, GetUnionBuildingShopInfoRequest.onFailedDefault)
      end
    end
    if not self.countDownEntry then
      countDownFunc()
      self.countDownEntry = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(countDownFunc,1,false)
    end
    setCountDownLabel(leftSeconds)
  elseif aIndex == TabEnum.normalProp then
    if self.countDownEntry then
      CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.countDownEntry)
      self.countDownEntry = nil
    end
    cutDownLabel:setVisible(false)
    cutDownTimeLabel:setVisible(false)
    cutDownRemindLabel:setVisible(false)
  end
end

function UnionShopScene:refreshShopInfoAndSpecialShopPanel()
  self:refreshShopInfo()
  if type(self.tabChangeComponent.currentSelectedPanel.refreshSpecialTable) == "function" then
    self.tabChangeComponent.currentSelectedPanel:refreshSpecialTable()
  end
end

function UnionShopScene:refreshShopInfoAndNormalShopPanel()
  self:refreshShopInfo()
  if type(self.tabChangeComponent.currentSelectedPanel.refreshNormalTable) == "function" then
    self.tabChangeComponent.currentSelectedPanel:refreshNormalTable()
  end
end

function UnionShopScene:refreshShopInfo()
  self.ui:getChildByName("txt_guild_21"):getChildByName("txt"):setString(tostring(UnionManager.getMyHistoryContribute()))
  self.ui:getChildByName("txt_guild_21_2"):getChildByName("txt"):setString(tostring(CalculationManager.calcComplex_getGemsNow()))
  self.ui:getChildByName("txt_guild_22"):getChildByName("txt"):setString(tostring(DataManager.getCurrUser().coins))
  self.ui:getChildByName("txt_guild_20"):getChildByName("txt"):setString(tostring(UnionManager.getShopLevel()))
  self.ui2:getChildByName("txt_guild_21_u"):getChildByName("txt"):setString(tostring(UnionManager.getUnionWealth()))
  local aUpgradePrice = UnionManager.getShopUpgradePrice()
  self.ui2:getChildByName("txt_guild_21_m"):getChildByName("txt"):setString(aUpgradePrice and tostring(aUpgradePrice) or Localization:getInstance():getText("union_building_upgrade_max_remind"))
  self.ui2:getChildByName("txt_guild_21_d"):getChildByName("txt"):setString(tostring(UnionManager.getMyContribute()))
end

function UnionShopScene:dispose()
  if self.countDownEntry then
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.countDownEntry)
    self.countDownEntry = nil
  end
  UnionShopScene.super.dispose(self)
end

function UnionShopScene:doEnterAnimation()
  self:preEnterAnimation()
  self:startEnterAnimation()
end

function UnionShopScene:preEnterAnimation()
  BaseUIScene.preEnterAnimation(self)
  --
  CanonPlayBackgroundMusic("music/background.mp3", true)
end

function UnionShopScene:startEnterAnimation()
  BaseUIScene.startEnterAnimation(self)
  local function enterActionFinished()
    self:nodeAnimationFinished()
  end
  
  self.ui2:setPositionX(self.ui2:getPositionX() - visibleSize.width)
  self.ui2:runAction(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
  
  local aHeight = self.ui:getGroupBounds().size.height
  self.ui:setPositionY(self.ui:getPositionY() + aHeight)
  local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(enter_animation_duration, ccp(0, -aHeight)))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.ui:runAction(CCSequence:create(arr))
  
end

function UnionShopScene:sufEnterAnimation()
  BaseUIScene.sufEnterAnimation(self)
  --
end

function UnionShopScene:doExitAnimation()
  self:preExitAnimation()
  self:startExitAnimation()
end

function UnionShopScene:preExitAnimation()
  BaseUIScene.preExitAnimation(self)
  
end

function UnionShopScene:startExitAnimation()
  BaseUIScene.startExitAnimation(self)
  local function enterActionFinished()
    self:nodeAnimationFinished()
  end
  
  self.ui2:runAction(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
  
  local aHeight = self.ui:getGroupBounds().size.height
  local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(enter_animation_duration, ccp(0, aHeight)))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.ui:runAction(CCSequence:create(arr))
  
  self.tabChangeComponent:startPanelExit(nil)
end

function UnionShopScene:sufExitAnimation()
  BaseUIScene.sufExitAnimation(self)
end

function UnionShopScene:back()
  if self.argv.enterScene == "UnionScene" then
    UnionManager.gotoUnionScene()
  end
end

function UnionShopScene.getBuildingTipNum()
  if not UnionManager.getFirstEnterUnionShop() then
    return 0
  else
    return 1
  end
  --[[
  local result = 0
  local oldDateTable = os.date("*t", TimeUtil.getServerTimeSeconds())
  local oldYear = oldDateTable.year
  local oldMonth = oldDateTable.month
  local oldDay = oldDateTable.day
  local oldTotalSeconds = TimeUtil.toServerTimestamp({year=oldYear,month=oldMonth,day=oldDay,hour=12})
  local currentTotalSeconds = TimeUtil.getServerTimeSeconds()
  if oldTotalSeconds <= currentTotalSeconds then
    result = 1
  end
  return result]]
end