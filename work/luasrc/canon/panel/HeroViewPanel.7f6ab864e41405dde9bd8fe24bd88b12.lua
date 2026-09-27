--------------------------------------------------------------------------------
-- HeroViewPanel.lua - 鼓舞信息面板
--------------------------------------------------------------------------------

require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"
require "canon.data.MetaManager"
require "canon.models.CommonManager"
require "canon.request.InspireCrossBossTeamRequest"
require "canon.panel.CardInfoPanelForCrossBoss"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

HeroViewPanel = class(Layer)

function HeroViewPanel:ctor()
    self.container = nil

    self.isPopOutDetailInfo = false
end

function HeroViewPanel:create( container  )
    
    local s = HeroViewPanel.new()
    s.container = container
    s:initLayer()
    return s
end

function HeroViewPanel:initLayer()
	HeroViewPanel.super.initLayer(self)
	local builder = LayoutBuilder:createWithContentsOfFile("scene/Siren.json")
    self.panelUI = builder:build("popup_Siren_02")
	self:addChild(self.panelUI)

	local crossBossSettingConfig = CrossWorldBossManager.getCrossBossSettingConfig()

	self.panelUI:getChildByName("txt_8"):getChildByName("txt"):setString(getTextByKey("crossBoss_heroTitle"))

	self.panelUI:getChildByName("txt_01"):getChildByName("txt"):setString(getTextByKey("crossBoss_heroExplain"))
	self.panelUI:getChildByName("txt_04"):getChildByName("txt"):setString(getTextByKey("crossBoss_heroAtkNum") ,{num1 = crossBossSettingConfig.heroAtkAddtion , num2 = crossBossSettingConfig.heroExtraAtkAddtion})
	self.panelUI:getChildByName("txt_02"):getChildByName("txt"):setString(getTextByKey("crossBoss_heroBuff"))
	self.panelUI:getChildByName("txt_03"):getChildByName("txt"):setString(CrossWorldBossManager.getGodHerosIncreaseValue(self.container.version).."%")
	self.panelUI:getChildByName("txt_07"):getChildByName("txt"):setString(getTextByKey("crossBoss_currHero"))

	local version = self.container.version

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

	local godHeros = CrossWorldBossManager.getGodHerosByVersion(version)
  for i=1,#godHeros do
    local godWill = self.panelUI:getChildByName("normal_card_small_name_godWill"..i)
    local sourceDisplay = godWill:getChildByName("normal_card_small")
    local heroIcon = CanonGoodIcon.createGoodIcon(ResourceEnum.CARD, godHeros[i].metaId, 1, {sourceDisplay = sourceDisplay , showInCenter = true})
    local heroName = CanonGoodIcon.getGoodName(ResourceEnum.CARD, godHeros[i].metaId, 0, {withoutAmount  = true})
    godWill:getChildByName("txt_Siren_34"):getChildByName("txt"):setString(heroName)
    godWill:addChildAt(heroIcon,1)
    if not godHeros[i].isActive then
      local backLayer = LayerColor:create()
      backLayer:setColor(ccc3( 10, 10, 10 ))
      backLayer.blackLayerColor = ccc3( 0, 0, 0 )
      backLayer.originalColor = ccc3( 10, 10, 10 )
      backLayer.refCocosObj:setOpacity( 200 )
      local length = 134
      backLayer:setContentSize(CCSizeMake( length, length ))
      backLayer:setPosition(ccp(-length / 2, -length / 2))
      heroIcon:addChild(backLayer)
    end
    if (version%4) + 1 == i then
      addParticle(heroIcon)
    end
    godWill:getChildByName("normal_card_small"):removeFromParentAndCleanup(true)
    local function onClickHeroIcon( evt )
      if self.isPopOutDetailInfo then
        return 
      end
      self.isPopOutDetailInfo = true
      local function onClose()
        self.isPopOutDetailInfo = false
      end
      local aCard = generateCard(nil, godHeros[evt.context].metaId, 1, tonumber(0))
      local cardPanel = CardInfoPanelForCrossBoss:create(self, aCard,onClose)
      self:addChild(cardPanel)
      cardPanel:scaleIn()

      -- CanonGoodIcon.popoutGoodPanel(ResourceEnum.CARD, godHeros[evt.context].metaId)
    end
    local btn = Button:create(heroIcon)
    btn:addEventListener( Events.kStart, onClickHeroIcon, i )
  end

   
    local function onCancelPanel(evt)
        PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
    end 
	self.panelUI:getChildByName("btn"):getChildByName("txt_guild_66"):getChildByName("txt"):setString(getTextByKey("yes"))
    local bt_panel_close = Button:create(self.panelUI:getChildByName("btn"))
    bt_panel_close:addEventListener(Events.kStart, onCancelPanel)   
   
	
end