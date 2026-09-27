require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"

require "hecore.display.Layer"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

local scroll_width = 525
local scroll_height = 420
local scroll_posX = 108
local scroll_posY = 435
local scroll_startPosY = 410

--
-- ActivityInfoPanel
--

ActivityInfoPanel = class(Layer)

function ActivityInfoPanel:ctor()
    self.container = nil
    self.content = nil
   
end

function ActivityInfoPanel:create( container, content ,titleTxt) --8.15 meilan.xie 使用通用的说明面板需要显示不同标题 如果不用不用传参数
    local s = ActivityInfoPanel.new()
    s:initLayer(container, content,titleTxt)
    return s
end

function ActivityInfoPanel:initLayer(container, content,titleTxt)
    MissionUnlockContentPanel.super.initLayer(self)
    
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
    
    local builder = LayoutBuilder:createWithContentsOfFile("scene/launch_activity.json")
    builder.useArtLabelTTF = true
    self.panelUI = builder:build("activity_info") 
    self.tempLayer:addChild(self.panelUI)
    
   
    if titleTxt == nil then
       titleTxt = "activity_helpBtn"
    end
    self.panelUI:getChildByName("txt_activity_info1"):getChildByName("txt"):setString(Localization:getInstance():getText(titleTxt))
    
    local function closeAction(evt)
      self:dismiss()
    end
    
    local closeButton = Button:create(self.panelUI:getChildByName("common_btn_close"))
    closeButton:addEventListener(Events.kStart, closeAction, self)
    
    self.panelUI:getChildByName("activity_info_btn_close"):getChildByName("txt"):setString(Localization:getInstance():getText("close"))
    closeButton = Button:create(self.panelUI:getChildByName("activity_info_btn_close"))
    closeButton:addEventListener(Events.kStart, closeAction, self)
    
    self.panelUI:getChildByName("txt_activity_info"):setVisible(false)
    
    local aStartPosY = scroll_startPosY
    local aStringList = self.content:split("\\n")

    local aScrollContentList = {}
    local aScrollView = ScrollView:create(scroll_width, scroll_height)
    aScrollView:setPosition(ccp(scroll_posX, scroll_posY))
    aScrollView:setDirection(kCCScrollViewDirectionVertical)
    self.panelUI:addChildAt(aScrollView, 10)
	
	if __IOS and toluahelper.isIOS64bit() then
		local finalString = ""
		for i, aString in ipairs(aStringList) do
		  if i > 1 then
			  finalString = finalString.."\n"
		  end
		  finalString = finalString..aString
		end
		finalString = finalString .. "\n"
		
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

function ActivityInfoPanel:scaleIn()
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

  --添加到二级堆栈
  UiStackManager.push(self)
end

function ActivityInfoPanel:dismiss()
  UiStackManager.remove(self)
  
  self.container.targetInfoPanel = nil
  self:removeFromParentAndCleanup(true)
  if self.container.setTableViewsEnabled then
    self.container:setTableViewsEnabled(true)
  end
end