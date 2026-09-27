require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

local scroll_width = 525
local scroll_height = 560--420 
local scroll_posX = 95
local scroll_posY = 360--430
local scroll_startPosY = 690--410

local card_scale = 0.7
local first_position_x = 140
local card_height = 480

--
-- ActivityMultiplayerBossInfoPanel
--

ActivityMultiplayerBossInfoPanel = class(Layer)

function ActivityMultiplayerBossInfoPanel:ctor()
    self.container = nil
    self.contentList = nil
end

function ActivityMultiplayerBossInfoPanel:create( container, contentList )
    local s = ActivityMultiplayerBossInfoPanel.new()
    s:initLayer(container, contentList)
    return s
end

function ActivityMultiplayerBossInfoPanel:initLayer(container, contentList)
    ActivityMultiplayerBossInfoPanel.super.initLayer(self)
    
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
    
    local builder = LayoutBuilder:createWithContentsOfFile("scene/monster_nian.json")
    builder.useArtLabelTTF = true
    self.panelUI = builder:build("activity_info") 
    self.tempLayer:addChild(self.panelUI)
    
    self.panelUI:getChildByName("txt_activity_info1"):getChildByName("txt"):setString(Localization:getInstance():getText("activity_helpBtn"))
    
    local function closeAction(evt)
      self:dismiss()
    end
    
    local closeButton = Button:create(self.panelUI:getChildByName("btn_close"))
    closeButton:addEventListener(Events.kStart, closeAction, self)
    
    self.panelUI:getChildByName("activity_info_btn_close"):getChildByName("txt"):setString(Localization:getInstance():getText("close"))
    closeButton = Button:create(self.panelUI:getChildByName("activity_info_btn_close"))
    closeButton:addEventListener(Events.kStart, closeAction, self)
    
    self.panelUI:getChildByName("txt_activity_info"):setVisible(false)
    
    local aStartPosY = scroll_startPosY
    local aStringList = self.contentList.content1:split("\\n")
    local aScrollContentList = {}
    local aScrollView = ScrollView:create(scroll_width, scroll_height)
    aScrollView:setPosition(ccp(scroll_posX, scroll_posY))
    aScrollView:setDirection(kCCScrollViewDirectionVertical)
    self.panelUI:addChildAt(aScrollView, 6)
	if __IOS and toluahelper.isIOS64bit() then
		local finalString = ""
		for i, aString in ipairs(aStringList) do
		  if i > 1 then
			  finalString = finalString.."\n"
		  end
		  finalString = finalString..aString
		end
		local aLabel = TextField:create(finalString, "Helvetica", 26, CCSizeMake(scroll_width, 0), kCCTextAlignmentLeft, kCCVerticalTextAlignmentTop)
		aLabel:setColor(ccc3(255,255,255))
		aLabel:setAnchorPoint(ccp(0, 0))
		aLabel:setPosition(ccp(0, aStartPosY - aLabel:getTexture():getContentSize().height))
		aScrollView:addChild(aLabel)
		table.insert(aScrollContentList, aLabel)
		aStartPosY = aStartPosY - aLabel:getTexture():getContentSize().height
	else
		for _, aString in ipairs(aStringList) do
		  local aLabel = TextField:create(aString, "Helvetica", 26, CCSizeMake(scroll_width, 0), kCCTextAlignmentLeft, kCCVerticalTextAlignmentTop)
		  aLabel:setColor(ccc3(255,255,255))
		  aLabel:setAnchorPoint(ccp(0, 0))
		  aLabel:setPosition(ccp(0, aStartPosY - aLabel:getTexture():getContentSize().height))
		  aScrollView:addChild(aLabel)
		  table.insert(aScrollContentList, aLabel)
		  aStartPosY = aStartPosY - aLabel:getTexture():getContentSize().height
		end
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
    aStartPosY = aStartPosY - (card_height * card_scale)*(picRowNum - 1) - 10
    
    aStringList = self.contentList.content2:split("\\n")
	if __IOS and toluahelper.isIOS64bit() then
		local finalString2 = ""
		for i, aString in ipairs(aStringList) do
		  if i > 1 then
			  finalString2 = finalString2.."\n"
		  end
		  finalString2 = finalString2..aString
		end
    finalString2 = finalString2 .. "\n"
		local aLabel2 = TextField:create(finalString2, "Helvetica", 26, CCSizeMake(scroll_width, 0), kCCTextAlignmentLeft, kCCVerticalTextAlignmentTop)
		aLabel2:setColor(ccc3(255,255,255))
		aLabel2:setAnchorPoint(ccp(0, 0))
		aLabel2:setPosition(ccp(0, aStartPosY - aLabel2:getTexture():getContentSize().height))
		aScrollView:addChild(aLabel2)
		table.insert(aScrollContentList, aLabel2)
		aStartPosY = aStartPosY - aLabel2:getTexture():getContentSize().height
	else
		for _, aString in ipairs(aStringList) do
		  local aLabel = TextField:create(aString, "Helvetica", 26, CCSizeMake(scroll_width, 0), kCCTextAlignmentLeft, kCCVerticalTextAlignmentTop)
		  aLabel:setColor(ccc3(255,255,255))
		  aLabel:setAnchorPoint(ccp(0, 0))
		  aLabel:setPosition(ccp(0, aStartPosY - aLabel:getTexture():getContentSize().height))
		  aScrollView:addChild(aLabel)
		  table.insert(aScrollContentList, aLabel)
		  aStartPosY = aStartPosY - aLabel:getTexture():getContentSize().height
		end
	end    

    aScrollView:setContentSize(CCSizeMake(scroll_width, ((aStartPosY < 0) and (scroll_height - aStartPosY) or scroll_height) + 140))
    if aStartPosY < 0 then
      for _, aGroup in ipairs(aScrollContentList) do
        aGroup:setPositionY(aGroup:getPositionY() - aStartPosY)
      end
      aScrollView:setContentOffset(ccp(0, aStartPosY - 140), false)
    end
    
    --[[
    local aString = ""
    for _, v in ipairs(aStringList) do
      aString = aString .. "\n" .. v
    end
    self.panelUI:getChildByName("txt_activity_info"):getChildByName("txt"):setString(aString)
    ]]
    
    self.tempLayer:setScale(0.1)
end

function ActivityMultiplayerBossInfoPanel:scaleIn()
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

function ActivityMultiplayerBossInfoPanel:dismiss()
  self.container.targetInfoPanel = nil
  self:removeFromParentAndCleanup(true)
  self.container:setTableViewsEnabled(true)
end

