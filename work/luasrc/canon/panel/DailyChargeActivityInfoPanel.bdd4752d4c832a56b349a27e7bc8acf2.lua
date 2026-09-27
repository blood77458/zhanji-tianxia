require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

local scroll_width = 525
local scroll_height = 700--420
local scroll_posX = 95
local scroll_posY = 290--430
local scroll_startPosY = 690--410

local card_scale = 0.7
local first_position_x = 140
local card_height = 480

--
-- DailyChargeActivityInfoPanel
--

DailyChargeActivityInfoPanel = class(Layer)

function DailyChargeActivityInfoPanel:ctor()
    self.container = nil
    self.contentList = nil
end

function DailyChargeActivityInfoPanel:create( container, contentList )
    local s = DailyChargeActivityInfoPanel.new()
    s:initLayer(container, contentList)
    return s
end

function DailyChargeActivityInfoPanel:initLayer(container, contentList)
    DailyChargeActivityInfoPanel.super.initLayer(self)
    
    self.container = container
    self.contentList = contentList
    
    self.container.targetInfoPanel = self
    
    self.colorLayer = LayerColor:create()
    self.colorLayer:setOpacity(kDarkOpacity)
    self.colorLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
    self:addChild(self.colorLayer)
    
    self.tempLayer = Layer:create()
    self.tempLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
    self:addChild(self.tempLayer)
    self.tempLayer:setAnchorPoint(ccp(0.5, 0.5))
    
    local builder = LayoutBuilder:createWithContentsOfFile("scene/common_new.json")
    builder.useArtLabelTTF = true
    self.panelUI = builder:build("popup_daily_first_blunt_02") 
    self.tempLayer:addChild(self.panelUI)
    
    self.panelUI:getChildByName("common_txt_playerInfo_title"):getChildByName("txt_playerInfo_title"):setString(Localization:getInstance():getText("activity_dailyCharge_title"))
    self.panelUI:getChildByName("txt_1"):getChildByName("txt"):setString(Localization:getInstance():getText("activity_dailyCharge_rules1"))
	self.panelUI:getChildByName("txt_2"):getChildByName("txt"):setString(Localization:getInstance():getText("activity_dailyCharge_dailyReward1"))
	self.panelUI:getChildByName("txt_3"):getChildByName("txt"):setString(Localization:getInstance():getText("activity_dailyCharge_totalReward1"))
	
	local txt_width = 525
	local aStartPosY =1080 --1030--410
	local sStartPosX = self.panelUI:getChildByName("txt_sellItem_equip"):getPositionX()

	local infoText = getTextByKey("activity_dailyCharge_rules2")
					..getTextByKey("activity_dailyCharge_rules3")
					..getTextByKey("activity_dailyCharge_rules4")
					..getTextByKey("activity_dailyCharge_rules5")
					..getTextByKey("activity_dailyCharge_rules6")
					..getTextByKey("activity_dailyCharge_rules7")
					..getTextByKey("activity_dailyCharge_rules8")
	local infoTextList = infoText:split("\\n")
	
	if __IOS and toluahelper.isIOS64bit() then
		local finalString = ""
		for i, aString in ipairs(infoTextList) do
		  if i > 1 then
			  finalString = finalString.."\n"
		  end
		  finalString = finalString..aString
		end
		local aLabel = TextField:create(finalString, "Helvetica", 26, CCSizeMake(txt_width, 0), kCCTextAlignmentLeft, kCCVerticalTextAlignmentTop)
		aLabel:setColor(ccc3(255,255,255))
		aLabel:setAnchorPoint(ccp(0, 0))
		aLabel:setPosition(ccp(sStartPosX, aStartPosY - (aLabel:getTexture():getContentSize().height)))
		self.panelUI:addChild(aLabel)
	else
		for _, aString in ipairs(infoTextList) do
		  local aLabel = TextField:create(aString, "Helvetica", 26, CCSizeMake(txt_width, 0), kCCTextAlignmentLeft, kCCVerticalTextAlignmentTop)
		  aLabel:setColor(ccc3(255,255,255))
		  aLabel:setAnchorPoint(ccp(0, 0))
		  aLabel:setPosition(ccp(sStartPosX, aStartPosY - (aLabel:getTexture():getContentSize().height)))
		  self.panelUI:addChild(aLabel)
		  aStartPosY = aStartPosY - aLabel:getTexture():getContentSize().height
		end
	end    
	
    local function closeAction(evt)
      self:dismiss()
    end
    
    local closeButton = Button:create(self.panelUI:getChildByName("common_btn_close"))
    closeButton:addEventListener(Events.kStart, closeAction, self)
    
	local rewardMeta = DataManager.GameMetaData.accumulateRechargeConfig
    local finialReward = rewardMeta.totalReward
	local dailyReward = rewardMeta.dailyRewards
-- daily reward	
	local params = {sourceSizes = {118,118}}
    local itemBeginX = 180
	local itemBeginY = 670
	local itemWidth = 180
	local itemHeight = 190
	
	for row = 1, 2 do
	 for line = 1, 3 do
		--icon
		local item = dailyReward[line + (row - 1)*3]
		local itemType = item.contentType
		local itemId = item.contentID
		local itemNum = item.contentNum
		local index = item.id
		local icon = CanonGoodIcon.createGoodIcon(itemType, itemId, itemNum, params)
		self.panelUI:addChild(icon)
		icon:setPositionXY(itemBeginX + itemWidth * ((index - 1) % 3), itemBeginY - (row - 1) * itemHeight)
		--title
		local titleLabel = TextField:create(getTextByKey("activity_dailyCharge_dailyReward"..index+1), nil, 25)
		icon:addChild(titleLabel)
		titleLabel:setPositionXY(icon:getContentSize().width/2,90)
		titleLabel:setColor(ccc3(255,255,255))
		--num
		local numLabel = TextField:create(itemNum, nil, 25)
		numLabel:setAnchorPoint(ccp(1,0.5))
		icon:addChild(numLabel)
		numLabel:setPositionXY(60,-50)
	 end
	end
	
-- finial reward
	local finialRewardPosX = self.panelUI:getChildByName("item_employees1"):getPositionX()
	local finialRewardPosY = self.panelUI:getChildByName("item_employees1"):getPositionY()
	local itemType = ResourceEnum.CARD
	local itemId = finialReward.cardID
	local icon = CanonGoodIcon.createGoodIcon(itemType, itemId, 1, params)
  icon:setScale(1.05)
	self.panelUI:addChild(icon)
	icon:setPositionXY(finialRewardPosX,finialRewardPosY)
	self.panelUI:getChildByName("txt_4"):getChildByName("txt"):setString(Localization:getInstance():getText("activity_dailyCharge_totalReward2"))
--提示面板改为不滑动
--[[
    local aStartPosY = scroll_startPosY
    local aStringList = self.contentList.content1:split("\\n")
    local aScrollContentList = {}
    local aScrollView = ScrollView:create(scroll_width, scroll_height)
    aScrollView:setPosition(ccp(scroll_posX, scroll_posY))
    aScrollView:setDirection(kCCScrollViewDirectionVertical)
    self.panelUI:addChildAt(aScrollView, 6)
    for _, aString in ipairs(aStringList) do
      local aLabel = TextField:create(aString, "Helvetica", 26, CCSizeMake(scroll_width, 0), kCCTextAlignmentLeft, kCCVerticalTextAlignmentTop)
      aLabel:setColor(ccc3(0,0,0))
      aLabel:setAnchorPoint(ccp(0, 0))
      aLabel:setPosition(ccp(0, aStartPosY - aLabel:getTexture():getContentSize().height))
      aScrollView:addChild(aLabel)
      table.insert(aScrollContentList, aLabel)
      aStartPosY = aStartPosY - aLabel:getTexture():getContentSize().height
    end
    
    local rowNum = math.modf((#self.contentList.cardIdList + 1) / 2)
    for i = 1, rowNum do
      local offset_x
      for j = 1, 2 do
        local aIndex = (i - 1) * 2 + j
        if aIndex <= #self.contentList.cardIdList then
          local position_x
          local position_y
          if j == 1 then
            position_x = first_position_x
            position_y = aStartPosY - card_height * card_scale / 2
          else
            position_x = scroll_width - first_position_x
            position_y = aStartPosY - card_height * card_scale / 2
            aStartPosY = aStartPosY - card_height * card_scale
          end
          local aMetaId = self.contentList.cardIdList[aIndex]
          local aCardSprite = getBigCanonCardWithInfoByMetaId(aMetaId)
          local aCardLevelConfig = MetaManager.card_level[1]
          local aCardMetaConfig = MetaManager.card_meta[aMetaId]
          local aCardRareConfig = MetaManager.card_rare[aCardMetaConfig.rare]
          local aCardEvolveConfig = MetaManager.card_evolve[1]
          local aAttack = aCardLevelConfig.levelCoefficient * aCardMetaConfig.reviseATT * aCardRareConfig.basicAttack * aCardEvolveConfig.reviseAttack + aCardMetaConfig.initAtt
          local aDefence = aCardLevelConfig.levelCoefficient * aCardMetaConfig.reviseDEF * aCardRareConfig.basicDefence * aCardEvolveConfig.reviseDefence + aCardMetaConfig.initDef
          local aHp = aCardLevelConfig.levelCoefficient * aCardMetaConfig.reviseHP * aCardRareConfig.basicHP * aCardEvolveConfig.reviseHp + aCardMetaConfig.initHp
          aCardSprite:setAtk(math.modf(aAttack))
          aCardSprite:setDef(math.modf(aDefence))
          aCardSprite:setHp(math.modf(aHp))
          aCardSprite:setLevel(1)
          aCardSprite:setScale(card_scale)
          aCardSprite:setPosition(ccp(position_x, position_y))
          aScrollView:addChild(aCardSprite)
          table.insert(aScrollContentList, aCardSprite)
        end
      end
    end
    
    --对于字体盖牌的临时处理
    local picRowNum = math.floor((#self.contentList.cardIdList+1) / 2)--图片共有几排
    aStartPosY = aStartPosY - (card_height * card_scale)*(picRowNum - 1)
    
    aStringList = self.contentList.content2:split("\\n")
    for _, aString in ipairs(aStringList) do
      local aLabel = TextField:create(aString, "Helvetica", 26, CCSizeMake(scroll_width, 0), kCCTextAlignmentLeft, kCCVerticalTextAlignmentTop)
      aLabel:setColor(ccc3(0,0,0))
      aLabel:setAnchorPoint(ccp(0, 0))
      aLabel:setPosition(ccp(0, aStartPosY - aLabel:getTexture():getContentSize().height))
      aScrollView:addChild(aLabel)
      table.insert(aScrollContentList, aLabel)
      aStartPosY = aStartPosY - aLabel:getTexture():getContentSize().height
    end
    
    aScrollView:setContentSize(CCSizeMake(scroll_width, (aStartPosY < 0) and (scroll_height - aStartPosY) or scroll_height))
  if aStartPosY < 0 then
    for _, aGroup in ipairs(aScrollContentList) do
      aGroup:setPositionY(aGroup:getPositionY() - aStartPosY)
    end
    aScrollView:setContentOffset(ccp(0, aStartPosY), false)
  end
    

    self.tempLayer:setScale(0.1)
	--]]
end

function DailyChargeActivityInfoPanel:scaleIn()
  self.tempLayer.touchEnabled = false
  self.tempLayer.touchChildren = false
  local function scaleInFinished()
    self.tempLayer.touchEnabled = true
    self.tempLayer.touchChildren = true
  end
  local arr = CCArray:create()
  arr:addObject(CCEaseSineOut:create(CCScaleTo:create(0.3, 1.0)))
  arr:addObject(CCCallFunc:create(scaleInFinished))
  self.tempLayer:runAction(CCSequence:create(arr))
end

function DailyChargeActivityInfoPanel:dismiss()
  self.container.targetInfoPanel = nil
  self:removeFromParentAndCleanup(true)
  self.container:setTableViewsEnabled(true)
end

