require "hecore.display.CocosObject"
require "hecore.display.Director"
require "hecore.ui.Button"
require "hecore.display.Sprite"
require "hecore.ui.LayoutBuilder"
require "canon.panel.UnionBankPreviewPanel"
require "canon.request.ReceiveUnionWageRequest"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()
local enter_animation_duration = 0.3

--
-- UnionBankScene
--

UnionBankScene = class(BaseUIScene)

function UnionBankScene:ctor()
	
end

function UnionBankScene:create(argv)
  local s = UnionBankScene.new()
  if argv then 
      self.argv = argv 
  else
      self.argv = {enterScene=nil,returnScene=nil,params={}}
  end
  s.curSceneEnum = SceneEnum.UnionBankScene
  s:initScene()
  return s
end

function UnionBankScene:onInit()
	BaseUIScene.initBackGround(self)
  
  self.title = Localization:getInstance():getText("arena_title")
  
  local builder = LayoutBuilder:createWithContentsOfFile("scene/guild.json")
  local ui2 = builder:build("guild_bank")
  self:addChild(ui2)
  self.ui2 = ui2
  local ui = builder:build("guild_bank_title")
  self:addChild(ui)
  self.ui = ui
  
  local function backButtonSelected(evt)
    self:back()
  end
	local backButton = Button:create(ui:getChildByName("r_click"))
	backButton:addEventListener(Events.kStart, backButtonSelected, self)
  
  ui:getChildByName("txt_guild_19"):getChildByName("txt"):setString(Localization:getInstance():getText("union_building_name3"))
  ui:getChildByName("txt_guild_20"):getChildByName("txt"):setString(tostring(UnionManager.getBankLevel()))
  
  local guide_other = ui2:getChildByName("full")
  guide_other:setVisible(false)
  local card3_spf = Sprite:createWithSpriteFrame(getFullCardSpriteFrame(104171))
  card3_spf:setScale(1.2)
  card3_spf:setPosition(ccp(guide_other:getPositionX() + guide_other:getContentSize().width / 2.0 + 70, guide_other:getPositionY() - guide_other:getContentSize().height / 2.0 - 60))
  ui2:addChildAt(card3_spf, 10)
  
  ui2:getChildByName("txt_guild_21_u"):getChildByName("txt"):setString(tostring(UnionManager.getUnionWealth()))
  local timeTable = MaintenanceManager:getStartAndEndHourMinOfOneDay(UnionManager.getUnionConfig().unionBankRewardFeatureName)
  self.timeLimitTable = timeTable
  ui2:getChildByName("txt_guild_33"):getChildByName("txt"):setString(Localization:getInstance():getText("union_bank_salary_remind1", {num1=timeTable.beginHour, num2=timeTable.endHour}))
  ui2:getChildByName("txt_guild_33_1"):getChildByName("txt"):setString(Localization:getInstance():getText("union_bank_salary_remind2"))
  ui2:getChildByName("txt_guild_bank_info"):getChildByName("txt"):setString(Localization:getInstance():getText("union_bank_salary_cost"))
  
  local salaryCell = ui2:getChildByName("list_guild_bank_pay")
  salaryCell:getChildByName("txt_bank_list_title"):getChildByName("txt"):setString(Localization:getInstance():getText("union_bank_salary_title"))
  local aRewardPackageConfig = MetaManager.reward_package[MetaManager.union_building_bank[UnionManager.getBankLevel()].rewardId]
  for i = 1, 4 do
    local aCell = salaryCell:getChildByName(string.format("guild_bank_item%d", i))
    local aItemType = aRewardPackageConfig[string.format("content%dType", i)]
    local aItemId = aRewardPackageConfig[string.format("content%dId", i)]
    local aItemAmount = aRewardPackageConfig[string.format("content%dAmount", i)]
    if (aItemType == 0) then
      aCell:setVisible(false)
    else
      aCell:setVisible(true)
      local aName = ""
      if aItemType == ResourceEnum.COIN then
        aName = Localization:getInstance():getText("resource_silverCoin")
      elseif aItemType == ResourceEnum.GEMS then
        aName = Localization:getInstance():getText("resource_goldCoin")
      elseif aItemType == ResourceEnum.CARD then
        local aCardMetaConfig = MetaManager.card_meta[aItemId]
        aName = Localization:getInstance():getText(aCardMetaConfig.name)
      elseif aItemType == ResourceEnum.EQUIP then
        local aEquipMetaConfig = MetaManager.equip_meta[aItemId]
        aName = Localization:getInstance():getText(aEquipMetaConfig.name)
      elseif aItemType == ResourceEnum.PROP then
        local aPropMetaConfig = MetaManager.prop_meta[aItemId]
        aName = Localization:getInstance():getText(aPropMetaConfig.name)
      elseif aItemType == ResourceEnum.CARD_FRAGMENT then
        local cardMetaId = MetaManager.card_fragment_meta[aItemId].cardId
        aName = Localization:getInstance():getText(MetaManager.card_meta[cardMetaId].name)
      elseif aItemType == ResourceEnum.EQUIP_FRAGMENT then
        local equipMetaId = MetaManager.equip_fragment_meta[aItemId].equipId
        aName = Localization:getInstance():getText(MetaManager.equip_meta[equipMetaId].name)
      elseif aItemType == ResourceEnum.RP_VALUE then
        aName = Localization:getInstance():getText("gacha_rpNum")
      end
      aName = aName .. "x" .. aItemAmount
      aCell:getChildByName("txt_bank_item_name"):getChildByName("txt"):setString(aName)
      local params = {}
      params.sourceDisplay = aCell:getChildByName("normal_card_small")
      params.container = aCell
      params.showInCenter = true
      params.zindex = 5
      CanonGoodIcon.createGoodIcon(aItemType, aItemId, 0, params)
    end
  end
  
  local function previewButtonSelected(evt)
    --print("previewButtonSelected")
    local previewPanel = UnionBankPreviewPanel:create(self)
    self:addChild(previewPanel)
    previewPanel:scaleIn()
  end
	self.previewButton = Button:create(ui2:getChildByName("icon_wage_preview"))
	self.previewButton:addEventListener(Events.kStart, previewButtonSelected, self)
  
  local function gainButtonSelected(evt)
    local temp = os.date("*t", TimeUtil.getServerTimeSeconds())
    local timestampInDay = temp.hour * 3600 + temp.min * 60 + temp.sec
    local beginTimestamp = self.timeLimitTable.beginHour * 3600 + self.timeLimitTable.beginMin * 60
    local endTimestamp = self.timeLimitTable.endHour * 3600 + self.timeLimitTable.endMin * 60
    if (timestampInDay < beginTimestamp) or (timestampInDay > endTimestamp) then
      local aContent = Localization:getInstance():getText("union_bank_salary_remind1", {num1 = self.timeLimitTable.beginHour, num2 = self.timeLimitTable.endHour})
      SuspensionLabel:showContent(self, aContent)
      return
    end
    
    if UnionManager.getMyContribute() < UnionManager.getUnionConfig().unionBankRewardContributeNeed then
      local aContent = Localization:getInstance():getText("union_shop_item_buy_not_satisfied1")
      SuspensionLabel:showContent(self, aContent)
      return
    end
    
    if BagCalcManager.isFull() then
      NewPackageFullPanel:show()
      -- local aContent = Localization:getInstance():getText("arena_inventoryFull")
      -- SuspensionLabel:showContent(self, aContent)
      return
    end
    
    local function onSucceed(requestEvent)
		ReceiveUnionWageRequest.onSucceedDefault(requestEvent)
    DailyDataManager.setDailyDataReceivedWage(true)
    UnionManager.setMyContribute(UnionManager.getMyContribute() - UnionManager.getUnionConfig().unionBankRewardContributeNeed)
    
    self:refreshBankInfo()
    local RewardPanel1 = GetRewardInfoPanel:create( self, requestEvent.data.rewards )
    PopoutManager:sharedManager():popout( RewardPanel1, kPopoutDir.kScale, true, false ,self )
	end
  local params = {unionWageId = UnionManager.getBankLevel()}
  ReceiveUnionWageRequest.sendRequest(onSucceed, ReceiveUnionWageRequest.onFailedDefault, params)
  end
	self.gainButton = Button:create(ui2:getChildByName("btn_get_pay"))
	self.gainButton:addEventListener(Events.kStart, gainButtonSelected, self)

  --等级是否已满状态
  if UnionManager.isBuildingMaxLevel(UnionManager.UNION_BUILDING_BANK) then
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
  
  self:refreshBankInfo()
  
  BaseUIScene.onInit(self, SceneMenuTypeEnum.UNION)
end

function UnionBankScene:refreshBankInfo()
  local aUpgradePrice = UnionManager.getBankUpgradePrice()
  
  self.ui:getChildByName("txt_guild_21"):getChildByName("txt"):setString(tostring(UnionManager.getMyHistoryContribute()))
  self.ui:getChildByName("txt_guild_21_2"):getChildByName("txt"):setString(tostring(CalculationManager.calcComplex_getGemsNow()))
  self.ui:getChildByName("txt_guild_22"):getChildByName("txt"):setString(tostring(DataManager.getCurrUser().coins))
  self.ui2:getChildByName("txt_guild_21_m"):getChildByName("txt"):setString(aUpgradePrice and tostring(aUpgradePrice) or Localization:getInstance():getText("union_building_upgrade_max_remind"))
  self.ui2:getChildByName("txt_guild_21_d"):getChildByName("txt"):setString(tostring(UnionManager.getMyContribute()))
  
  self.ui2:getChildByName("txt_guild_34"):getChildByName("txt"):setString(tostring(UnionManager.getUnionConfig().unionBankRewardContributeNeed))
  
  local gainButtonDisplay = self.ui2:getChildByName("btn_get_pay")
  if DailyDataManager.getDailyDataReceivedWage() then
    gainButtonDisplay:getChildByName("btn"):setVisible(false)
    gainButtonDisplay:getChildByName("btn_inactive"):setVisible(true)
    gainButtonDisplay:getChildByName("txt"):setString(Localization:getInstance():getText("union_bank_salary_get_button_finish"))
    self.gainButton:setEnable(false)
  else
    gainButtonDisplay:getChildByName("btn"):setVisible(true)
    gainButtonDisplay:getChildByName("btn_inactive"):setVisible(false)
    gainButtonDisplay:getChildByName("txt"):setString(Localization:getInstance():getText("union_bank_salary_get_button"))
    self.gainButton:setEnable(true)
  end
end

function UnionBankScene:dispose()
  if self.countDownEntry then
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.countDownEntry)
    self.countDownEntry = nil
  end
  UnionBankScene.super.dispose(self)
end

function UnionBankScene:doEnterAnimation()
  self:preEnterAnimation()
  self:startEnterAnimation()
end

function UnionBankScene:preEnterAnimation()
  BaseUIScene.preEnterAnimation(self)
  --
  CanonPlayBackgroundMusic("music/background.mp3", true)
end

function UnionBankScene:startEnterAnimation()
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

function UnionBankScene:sufEnterAnimation()
  BaseUIScene.sufEnterAnimation(self)
  --
end

function UnionBankScene:doExitAnimation()
  self:preExitAnimation()
  self:startExitAnimation()
end

function UnionBankScene:preExitAnimation()
  BaseUIScene.preExitAnimation(self)
  
end

function UnionBankScene:startExitAnimation()
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
  
end

function UnionBankScene:sufExitAnimation()
  BaseUIScene.sufExitAnimation(self)
end

function UnionBankScene:back()
  if self.argv.enterScene == "UnionScene" then
    UnionManager.gotoUnionScene()
  end
end

function UnionBankScene.getBuildingTipNum()
  local result = 0
  if DailyDataManager.getDailyDataReceivedWage() then
    result = 0
  else
    result = 1
  end
  return result
end