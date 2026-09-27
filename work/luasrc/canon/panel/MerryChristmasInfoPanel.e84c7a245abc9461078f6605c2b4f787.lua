require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

--
-- MerryChristmasInfoPanel
--

MerryChristmasInfoPanel = class(Layer)

function MerryChristmasInfoPanel:ctor()
    self.container = nil
    self.content = nil
end

function MerryChristmasInfoPanel:create( container, content )
    local s = MerryChristmasInfoPanel.new()
    s:initLayer(container, content)
    return s
end

function MerryChristmasInfoPanel:initLayer(container, content)
    MerryChristmasInfoPanel.super.initLayer(self)
    
    self.container = container
    self.content = content

    self.container.targetInfoPanel = self
    
    self.colorLayer = LayerColor:create()
    self.colorLayer:setOpacity(kDarkOpacity)
    self.colorLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
    self:addChild(self.colorLayer)
    
    self.tempLayer = Layer:create()
    self.tempLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
    self:addChild(self.tempLayer)
    self.tempLayer:setAnchorPoint(ccp(0.5, 0.5))
    
    local builder = LayoutBuilder:createWithContentsOfFile("scene/Christmas.json")
    builder.useArtLabelTTF = true
    self.panelUI = builder:build("popup_Christmas_01") 
    self.tempLayer:addChild(self.panelUI)
    
    self.panelUI:getChildByName("common_txt_playerInfo_title"):getChildByName("txt_playerInfo_title"):setString(Localization:getInstance():getText("activity_helpBtn"))
    
    local function closeAction(evt)
      self:dismiss()
    end
    
    local closeButton = Button:create(self.panelUI:getChildByName("common_btn_close"))
    closeButton:addEventListener(Events.kStart, closeAction, self)
  
    local cardFigure = getBigCanonCardWithInfoByMetaId(MetaManager.getMerryChristmasConfig().specialReward)
    local cardDetail = self.panelUI:getChildByName("normal_card_small")
    cardFigure:setPosition(ccp(70,45))
    cardFigure:setScale(0.5)
    cardFigure.touchEnabled = false
    cardFigure.touchChildren = false

    cardFigure.atkBgSpt:setVisible(false)
    cardFigure.atkIconSpt:setVisible(false)
    cardFigure.textAtk:setVisible(false)
    cardFigure.defBgSpt:setVisible(false)
    cardFigure.defIconSpt:setVisible(false)
    cardFigure.textDef:setVisible(false)
    cardFigure.hpBgSpt:setVisible(false)
    cardFigure.hpIconSpt:setVisible(false)
    cardFigure.textHp:setVisible(false)

    cardDetail:addChild(cardFigure)

    local txt_width = 564
    local sStartPosX = self.panelUI:getChildByName("txt_1"):getPositionX()
    local aStartPosY = self.panelUI:getChildByName("txt_1"):getPositionY()

    local infoTextList = content:split("\\n")
	local aOffset = 0
	if __IOS and toluahelper.isIOS64bit() then
		local finalString = ""
		for i, aString in ipairs(infoTextList) do
		  if i > 1 then
			  finalString = finalString.."\n"
		  end
		  finalString = finalString..aString
		end
		local aLabel = TextField:create(finalString, "Helvetica", 26, CCSizeMake(txt_width, 0), kCCTextAlignmentLeft, kCCVerticalTextAlignmentTop)
		aLabel:setColor(ccc3(0,0,0))
		aLabel:setAnchorPoint(ccp(0, 1))
		aLabel:setPosition(ccp(sStartPosX, aStartPosY + aOffset))
		self.panelUI:addChild(aLabel)
	else
		for aIndex, aString in ipairs(infoTextList) do
			local aLabel = TextField:create(aString, "Helvetica", 26, CCSizeMake(txt_width, 0), kCCTextAlignmentLeft, kCCVerticalTextAlignmentTop)
			aLabel:setColor(ccc3(0,0,0))
			aLabel:setAnchorPoint(ccp(0, 1))
			
			if __ANDROID then
				if aIndex == 2 then
					aOffset = -4
				elseif aIndex == 3 then
					aOffset = -2
				end
			end
			aLabel:setPosition(ccp(sStartPosX, aStartPosY + aOffset))
			self.panelUI:addChild(aLabel)
			aStartPosY = aStartPosY - aLabel:getTexture():getContentSize().height
		end
	end

    self.panelUI:getChildByName("txt_2"):getChildByName("txt"):setString(getTextByKey("eventChristmas_help2"))

    self.tempLayer:setScale(0.1)
end

function MerryChristmasInfoPanel:scaleIn()
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

function MerryChristmasInfoPanel:dismiss()
  self.container.targetInfoPanel = nil
  self:removeFromParentAndCleanup(true)
  self.container:setTableViewsEnabled(true)
end