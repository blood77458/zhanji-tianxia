require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

local scroll_width = 525
local scroll_height = 570--700--420
local scroll_posX = 95
local scroll_posY = 350
local scroll_startPosY = 560--690--410

local card_scale = 0.75
local first_position_x = 80
local card_height = 108

--
-- CrossBossInfoPanel
--

CrossBossInfoPanel = class(Layer)

function CrossBossInfoPanel:ctor()
    self.container = nil
    self.contentList = nil
end

function CrossBossInfoPanel:create( container, contentList , version)
    local s = CrossBossInfoPanel.new()
    s.version = version
    s:initLayer(container, contentList)
    return s
end

function CrossBossInfoPanel:initLayer(container, contentList)
    CrossBossInfoPanel.super.initLayer(self)
    
    self.container = container
    self.contentList = contentList
    self.container:setTableViewsEnabledInner(false)
    
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
    for _, aString in ipairs(aStringList) do
      local aLabel = TextField:create(aString, "Helvetica", 26, CCSizeMake(scroll_width, 0), kCCTextAlignmentLeft, kCCVerticalTextAlignmentTop)
      aLabel:setColor(ccc3(0,0,0))
      aLabel:setAnchorPoint(ccp(0, 0))
      aLabel:setPosition(ccp(0, aStartPosY - aLabel:getTexture():getContentSize().height))
      aScrollView:addChild(aLabel)
      table.insert(aScrollContentList, aLabel)
      aStartPosY = aStartPosY - aLabel:getTexture():getContentSize().height
    end

    aStartPosY = aStartPosY - 12

    local function addParticle(cardCell)
      if self.cardParticle ~= nil then
        self.cardParticle:removeFromParentAndCleanup(true)
      end
      self.cardParticle = CCParticleSystemQuad:create(ParticlePathConstants.FxStarline)
      self.cardParticle:setPositionType(kCCPositionTypeRelative)
      self.cardParticle:setPosition(ccp(-67,67))
      cardCell:addChild(CocosObject.new(self.cardParticle), 1000)
      local particleMoveArray = CCArray:create()
      local particleMoveTime = 0.4
      particleMoveArray:addObject(CCMoveBy:create(particleMoveTime, ccp(134, 0)))
      particleMoveArray:addObject(CCMoveBy:create(particleMoveTime, ccp(0, -134)))
      particleMoveArray:addObject(CCMoveBy:create(particleMoveTime, ccp(-134, 0)))
      particleMoveArray:addObject(CCMoveBy:create(particleMoveTime, ccp(0, 134)))
      self.cardParticle:runAction(CCRepeatForever:create(CCSequence:create(particleMoveArray)))
    end
    
    local rowNum = math.modf((#self.contentList.cardIdList + 1) / 2)
    local cardPos = {80 , 200 , 325 , 445}
    for i = 1, 1 do
      local offset_x
      for j = 1, 4 do
        local aIndex = (i - 1) * 2 + j
        if aIndex <= #self.contentList.cardIdList then
          local position_x
          local position_y
          position_x = cardPos[j]
          position_y = aStartPosY - card_height * card_scale / 2
          -- aStartPosY = aStartPosY - card_height * card_scale
          -- if j == 1 then
          --   position_x = first_position_x
          --   position_y = aStartPosY - card_height * card_scale / 2
          -- else
          --   position_x = scroll_width - first_position_x
          --   position_y = aStartPosY - card_height * card_scale / 2
          --   aStartPosY = aStartPosY - card_height * card_scale
          -- end
          local aMetaId = self.contentList.cardIdList[aIndex]
          local aCardSprite = getHeadIconCanonCardByMetaId(aMetaId)
          local cardName = CanonGoodIcon.getGoodName(ResourceEnum.CARD, aMetaId, 0, {withoutAmount  = true})
          local cardNameLabel = TextField:create(cardName, "Helvetica", 26, CCSizeMake(0,0), kCCTextAlignmentCenter)
          cardNameLabel:setColor(ccc3(0,0,0))
          cardNameLabel:setPosition(ccp(0,-83))
          aCardSprite:addChild(cardNameLabel)
          local specialHero = CrossWorldBossManager.getSpecialHero( self.version )
          if specialHero.metaId == aMetaId then
            addParticle(aCardSprite)
          end
          -- local aCardLevelConfig = MetaManager.card_level[1]
          -- local aCardMetaConfig = MetaManager.card_meta[aMetaId]
          -- local aCardRareConfig = MetaManager.card_rare[aCardMetaConfig.rare]
          -- local aCardEvolveConfig = MetaManager.card_evolve[1]
          -- local aAttack = aCardLevelConfig.levelCoefficient * aCardMetaConfig.reviseATT * aCardRareConfig.basicAttack * aCardEvolveConfig.reviseAttack + aCardMetaConfig.initAtt
          -- local aDefence = aCardLevelConfig.levelCoefficient * aCardMetaConfig.reviseDEF * aCardRareConfig.basicDefence * aCardEvolveConfig.reviseDefence + aCardMetaConfig.initDef
          -- local aHp = aCardLevelConfig.levelCoefficient * aCardMetaConfig.reviseHP * aCardRareConfig.basicHP * aCardEvolveConfig.reviseHp + aCardMetaConfig.initHp
          -- aCardSprite:setAtk(math.modf(aAttack))
          -- aCardSprite:setDef(math.modf(aDefence))
          -- aCardSprite:setHp(math.modf(aHp))
          -- aCardSprite:setLevel(1)
          aCardSprite:setScale(card_scale)
          aCardSprite:setPosition(ccp(position_x, position_y))
          aScrollView:addChild(aCardSprite)
          table.insert(aScrollContentList, aCardSprite)
        end
      end
    end

    aStartPosY = aStartPosY - 38
    
    --对于字体盖牌的临时处理
    local picRowNum = math.floor((#self.contentList.cardIdList+1) / 2)--图片共有几排
    aStartPosY = aStartPosY - (card_height * card_scale)*(picRowNum - 1) - 10
    
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

    aStartPosY = aStartPosY - 20

    aStringList = self.contentList.content3:split("\\n")
    for _, aString in ipairs(aStringList) do
      local aLabel = TextField:create(aString, "Helvetica", 26, CCSizeMake(scroll_width, 0), kCCTextAlignmentLeft, kCCVerticalTextAlignmentTop)
      aLabel:setColor(ccc3(0,0,0))
      aLabel:setAnchorPoint(ccp(0, 0))
      aLabel:setPosition(ccp(0, aStartPosY - aLabel:getTexture():getContentSize().height))
      aScrollView:addChild(aLabel)
      table.insert(aScrollContentList, aLabel)
      aStartPosY = aStartPosY - aLabel:getTexture():getContentSize().height
    end

    local rowNum = math.modf((#self.contentList.cardIdList2 + 1) / 2)
    for i = 1, rowNum do
      local offset_x
      for j = 1, 2 do
        local aIndex = (i - 1) * 2 + j
        if aIndex <= #self.contentList.cardIdList2 then
          local position_x
          local position_y
          if j == 1 then
            position_x = 140
            position_y = aStartPosY - 480 * card_scale / 2
          else
            position_x = scroll_width - 140
            position_y = aStartPosY - 480 * card_scale / 2
            aStartPosY = aStartPosY - 480 * card_scale
          end
          local aMetaId = self.contentList.cardIdList2[aIndex]
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
    local picRowNum = math.floor((#self.contentList.cardIdList2+1) / 2)--图片共有几排
    aStartPosY = aStartPosY - (480 * card_scale) - 10

    aStringList = self.contentList.content4:split("\\n")
    for _, aString in ipairs(aStringList) do
      local aLabel = TextField:create(aString, "Helvetica", 26, CCSizeMake(scroll_width, 0), kCCTextAlignmentLeft, kCCVerticalTextAlignmentTop)
      aLabel:setColor(ccc3(0,0,0))
      aLabel:setAnchorPoint(ccp(0, 0))
      aLabel:setPosition(ccp(0, aStartPosY - aLabel:getTexture():getContentSize().height))
      aScrollView:addChild(aLabel)
      table.insert(aScrollContentList, aLabel)
      aStartPosY = aStartPosY - aLabel:getTexture():getContentSize().height
    end

    --对于字体盖牌的临时处理
    local picRowNum = math.floor((#self.contentList.cardIdList2+1) / 2)--图片共有几排
    aStartPosY = aStartPosY - (480 * card_scale)*(picRowNum - 1) - 10
    
    aScrollView:setContentSize(CCSizeMake(scroll_width, (aStartPosY < 0) and (scroll_height - aStartPosY) or scroll_height))
  if aStartPosY < 0 then
    for _, aGroup in ipairs(aScrollContentList) do
      aGroup:setPositionY(aGroup:getPositionY() - aStartPosY)
    end
    aScrollView:setContentOffset(ccp(0, aStartPosY), false)
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

function CrossBossInfoPanel:scaleIn()
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

function CrossBossInfoPanel:dismiss()
  self.container.targetInfoPanel = nil
  self:removeFromParentAndCleanup(true)
  self.container:setTableViewsEnabledInner(true)
end

