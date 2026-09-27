require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()
TabEnum = {
  chatToAll = 1,
  chatToSpecial = 2,
  chatToUnion = 3
}

local scroll_width = 650
local scroll_height = 630
local scroll_posX = 35
local scroll_posY = 380
local scroll_startPosY = 620
local horizontal_distance = 6
local vertical_distance = 15

local SELF_INSTANCE

--
-- UnionChatContainerPanel
--

local function getSpeakerNum()
  local result = 0
  for _, v in pairs(DataManager.getPropsData()) do
    if v.metaId == 400127 then
      result = tonumber(v.amount, 10)
      break
    end
  end
  return result
end

local function allTabButtonSelected(evt)
  evt.context:changeToPanel(TabEnum.chatToAll)
end

local function specialTabButtonSelected(evt)
  evt.context:changeToPanel(TabEnum.chatToSpecial)
end

local function unionTabButtonSelected(evt)
  evt.context:changeToPanel(TabEnum.chatToUnion)
end

local function sendButtonSelected(evt)
  local serverTime = TimeUtil.getServerTimeSeconds()
  local noChatEndSeconds = DataManager.getCurrUser().noChatEndSeconds
  if noChatEndSeconds > serverTime then
    local limitEndTime = TimeUtil.formatDate(noChatEndSeconds)
    local messageLengthLimit = getTextByKey("silenced_text2")..limitEndTime
    local scene = Director:mgr():run()
    local aPanel = MessageBoxPanel:create(evt.context, MessageBoxType.kSpeakLimitWarning ,{warningMessage = messageLengthLimit , chatTouchEnable = true})
    evt.context:addChild(aPanel)
    aPanel:scaleIn()
    return
  end
  evt.context:sendChatContent()
end

local function nameButtonSelected(evt)
  SELF_INSTANCE:showUserDetailPanel(evt.target.uid)
end

UnionChatContainerPanel = class(Layer)

function UnionChatContainerPanel:ctor()
	self.container = nil
  self.extraParams = {}
end

function UnionChatContainerPanel:create( container, extraParams )
	local s = UnionChatContainerPanel.new()
  SELF_INSTANCE = s
	s:initLayer(container, extraParams)
	return s
end

function UnionChatContainerPanel:initLayer(container, extraParams)
	UnionChatContainerPanel.super.initLayer(self)
	self.container = container
  self.extraParams = extraParams or {}
  --[[
  self.pre_container_targetInfoPanel = self.container.targetInfoPanel
	self.container.targetInfoPanel = self
  if (self.container.setTableViewsEnabled) then
    self.container:setTableViewsEnabled(false)
  end
  ]]
  self.colorLayer = LayerColor:create()
  self.colorLayer:setOpacity(kDarkOpacity)
  self.colorLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
  self:addChild(self.colorLayer)
  
  self.tempLayer = Layer:create()
  self.tempLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
  self:addChild(self.tempLayer)
  self.tempLayer:setAnchorPoint(ccp(0.5, 0.5))
  
  local builder = LayoutBuilder:createWithContentsOfFile("scene/guild.json")
  builder.useArtLabelTTF = true
  self.panelUI = builder:build("guild_chat_all") 
  self.tempLayer:addChild(self.panelUI)
  
  local function closeButtonClicked(evt)
    self:dismissSelf()
  end
  local closeButtonDisplay = self.panelUI:getChildByName("btn_close")
  local closeButton = Button:create(closeButtonDisplay)
  closeButton:addEventListener( Events.kStart, closeButtonClicked, self )
  
  self.allTabButtonDisplay = self.panelUI:getChildByName("btn_world_chat")
	self.allTabButtonDisplay:getChildByName("txt"):setString(Localization:getInstance():getText("union_chat_world_text"))
  self.allTabButtonDisplay:getChildByName("btn_light_act"):setOpacity(0)
	self.allTabButton = Button:create(self.allTabButtonDisplay)
	self.allTabButton:addEventListener(Events.kStart, allTabButtonSelected, self)
  
  self.specialTabButtonDisplay = self.panelUI:getChildByName("btn_sec_chat")
	self.specialTabButtonDisplay:getChildByName("txt"):setString(Localization:getInstance():getText("union_chat_private_text"))
  self.specialTabButtonDisplay:getChildByName("btn_light_act"):setOpacity(0)
	self.specialTabButton = Button:create(self.specialTabButtonDisplay)
	self.specialTabButton:addEventListener(Events.kStart, specialTabButtonSelected, self)
  
  self.unionTabButtonDisplay = self.panelUI:getChildByName("btn_guild_chat")
	self.unionTabButtonDisplay:getChildByName("txt"):setString(Localization:getInstance():getText("union_chat_union_text"))
  self.unionTabButtonDisplay:getChildByName("btn_light_act"):setOpacity(0)
	self.unionTabButton = Button:create(self.unionTabButtonDisplay)
	self.unionTabButton:addEventListener(Events.kStart, unionTabButtonSelected, self)
  
  self.tabButtonList = {}
  table.insert(self.tabButtonList, self.allTabButton)
  table.insert(self.tabButtonList, self.specialTabButton)
  table.insert(self.tabButtonList, self.unionTabButton)
  
  self.speakerSprite = self.panelUI:getChildByName("icon_nicering")
  self.speakerNumLabel = self.panelUI:getChildByName("txt_rings")
  self.specialLabel1 = self.panelUI:getChildByName("txt_chat_sub1")
  self.specialLabel1:getChildByName("txt"):setString(Localization:getInstance():getText("union_chat_input_target_text"))
  local specialNameBg1 = self.panelUI:getChildByName("alpha_white9_panelin33")
  local specialNameBg2 = self.panelUI:getChildByName("alpha_white9_panelin23")
  local specialNameBg3 = self.panelUI:getChildByName("alpha_white9_panelin13")
  local specialNameBg4 = self.panelUI:getChildByName("alpha_white9_panel53")
  local specialNameBg5 = self.panelUI:getChildByName("alpha_white9_panel43")
  local specialNameBg6 = self.panelUI:getChildByName("alpha_white9_panel33")
  local specialNameBg7 = self.panelUI:getChildByName("alpha_white9_panel23")
  local specialNameBg8 = self.panelUI:getChildByName("alpha_white9_panel13")
  self.specialNameBgList = {}
  table.insert(self.specialNameBgList, specialNameBg1)
  table.insert(self.specialNameBgList, specialNameBg2)
  table.insert(self.specialNameBgList, specialNameBg3)
  table.insert(self.specialNameBgList, specialNameBg4)
  table.insert(self.specialNameBgList, specialNameBg5)
  table.insert(self.specialNameBgList, specialNameBg6)
  table.insert(self.specialNameBgList, specialNameBg7)
  table.insert(self.specialNameBgList, specialNameBg8)
  self.specialLabel2 = self.panelUI:getChildByName("txt_chat_sub2")
  self.specialLabel2:getChildByName("txt"):setString(Localization:getInstance():getText("union_chat_input_say_text"))
  self.vipTipLabel = self.panelUI:getChildByName("txt_vip_chat")
  self.vipTipLabel:getChildByName("txt"):setString(Localization:getInstance():getText("union_chat_world_VIP_horn"))
  
  self.nickNameLabel = self.panelUI:getChildByName("txt_guild_chat1"):getChildByName("txt")
  self.nickNameLabel:setVisible(false)
  self.chatContentLabel = self.panelUI:getChildByName("txt_guild_chat2"):getChildByName("txt")
  self.chatContentLabel:setVisible(false)
  
  local function onTextInputEvent( evt )
		local selectedText = self.editInputLabel:getText()
    if evt.target == self.editInputLabel then
      
    elseif evt.target == self.editInputLabel then
      
    end
    
	end
  
  local function createInputText(inputBackground)
    local inputSize = inputBackground:getPreferredSize()
    local inputPos = inputBackground:getPosition()
    local numberClipLayer = CCClippingNode:create()
    local numberClipLayer_co = CocosObject.new(numberClipLayer)
    numberClipLayer:setContentSize(CCSizeMake(inputSize.width, inputSize.height))
    numberClipLayer:setAnchorPoint(ccp(0, 1))
    numberClipLayer:setPosition(ccp(inputPos.x + inputSize.width / 2, inputPos.y - inputSize.height / 2))
    self.panelUI:addChildAt(numberClipLayer_co, 20)
    local stencil = CCSprite:create("pic/5.png")
    stencil:setScaleX(inputSize.width / stencil:getContentSize().width)
    stencil:setScaleY(inputSize.height / stencil:getContentSize().height)
    stencil:setAnchorPoint(ccp(0.5, 0))
    stencil:setPosition(ccp(0, stencil:getContentSize().height / 2))
    numberClipLayer:setStencil(stencil)
    local inputSprite = Scale9Sprite:create("common/button.png")
    inputSprite:setAnchorPoint(ccp(0, 1))
    inputSprite:setOpacity(0)
    local editInputLabel = TextInput:create(CCSizeMake(inputSize.width, inputSize.height * 0.8), inputSprite)
    editInputLabel:setPosition(ccp(0, inputSize.height))
    editInputLabel:setReturnType(kKeyboardReturnTypeDone)
    editInputLabel:addEventListener(kTextInputEvents.kChanged, onTextInputEvent)
    numberClipLayer_co:addChild(editInputLabel)
    return editInputLabel
  end
  self.editInputLabel = createInputText(self.panelUI:getChildByName("alpha_white9_panelin32"))
  self.editInputLabel:setPlaceHolder(Localization:getInstance():getText("union_chat_input_content"))
  self.nameInputLabel = createInputText(self.panelUI:getChildByName("alpha_white9_panelin33"))
  self.nameInputLabel:setPlaceHolder(Localization:getInstance():getText("union_chat_input_name"))
  
  self.sendButtonDisplay = self.panelUI:getChildByName("btn_chat")
  self.sendButtonDisplay:getChildByName("txt"):setString(Localization:getInstance():getText("union_chat_send_button_text"))
  self.sendButton = Button:create(self.sendButtonDisplay)
	self.sendButton:addEventListener(Events.kStart, sendButtonSelected, self)
  
  self.selectedPanelIndex = nil
  
  local touchLayer1 = Layer:create()
  touchLayer1:setContentSize(CCSizeMake(scroll_width, visibleSize.height - scroll_height - scroll_posY))
  touchLayer1:setPosition(ccp(scroll_posX, scroll_posY + scroll_height))
  self.panelUI:addChildAt(touchLayer1, 20)
  
  local touchLayer2 = Layer:create()
  touchLayer2:setContentSize(CCSizeMake(scroll_width, scroll_posY))
  touchLayer2:setPosition(ccp(scroll_posX, 0))
  self.panelUI:addChildAt(touchLayer2, 20)
  --[[
  self.scrollView = ScrollView:create(scroll_width, scroll_height)
  self.scrollView:setPosition(ccp(scroll_posX, scroll_posY))
  self.scrollView:setDirection(kCCScrollViewDirectionVertical)
  --self.scrollView:setBounceable(false)
  self.panelUI:addChildAt(self.scrollView, 20)
  self.cellViewList = {}
  self.startPosY = scroll_startPosY
  self.totalContentHeight = 0
  ]]
  self.chatShowMax = 0
  
  self.specialFlashing = false
  self.unionFlashing = false
  
  self.getChatNewIndex = function()
    local result = 0
    if self.selectedPanelIndex == TabEnum.chatToSpecial then
      result = ChatManager.getSpecialChatNewIndex()
    elseif self.selectedPanelIndex == TabEnum.chatToAll then
      result = ChatManager.getWorldChatNewIndex()
    else
      result = ChatManager.getUnionChatNewIndex()
    end
    return result
  end
  self.addChatNewIndex = function(aNewIndex)
    if self.selectedPanelIndex == TabEnum.chatToSpecial then
      ChatManager.setSpecialChatNewIndex(aNewIndex)
    elseif self.selectedPanelIndex == TabEnum.chatToAll then
      ChatManager.setWorldChatNewIndex(aNewIndex)
    else
      ChatManager.setUnionChatNewIndex(aNewIndex)
    end
    NotificationManager:dispatchEvent(Event.new(ChatManager.CHAT_MESSAGE_SHOWED))
  end
  local aTabType = TabEnum.chatToAll
  if __IOS and isInAppleReview() then
    self.allTabButtonDisplay:setVisible(false)
    aTabType = TabEnum.chatToSpecial
  end
  
  local aSpecianName
  if self.extraParams and self.extraParams.tabType then
    aTabType = self.extraParams.tabType
  end
  if aTabType == TabEnum.chatToSpecial then
    aSpecianName = self.extraParams.specialName or ""
  end
  self:changeToPanel(aTabType, aSpecianName)
  
  --self.tempLayer:setScale(0.1)
  
  if (aTabType ~= TabEnum.chatToSpecial) and ChatManager.hasUnreadSpecialChat() then
    self:showFlashing(TabEnum.chatToSpecial)
  end
  if (aTabType ~= TabEnum.chatToUnion) and ChatManager.hasUnreadUnionChat() then
    self:showFlashing(TabEnum.chatToUnion)
  end
  
  self.newContentCallback = function(ee)
    if ee.data.chatContent.retCode ~= 0 then
      self:showFailMessageForRetcode(ee.data.chatContent.retCode)
    elseif ee.data.chatType == self.selectedPanelIndex then
      if not self.isAddingScrollContent then
        --[[
        if self.selectedPanelIndex == TabEnum.chatToSpecial then
          ChatManager.resetSpecialChatNewIndex()
        elseif self.selectedPanelIndex == TabEnum.chatToAll then
          ChatManager.resetWorldChatNewIndex()
        else
          ChatManager.resetUnionChatNewIndex()
        end
        ]]
        self:showNewContent(ee.data.chatContent)
      end
    else
      self:showFlashing(ee.data.chatType)
    end
  end
  NotificationManager:addEventListener(ChatManager.NEW_CHAT_CONTENT,self.newContentCallback)
  
  self.consumeSpeakerCallback = function(ee)
    self.speakerNumLabel:getChildByName("txt"):setString(string.format("x%d", getSpeakerNum()))
  end
  NotificationManager:addEventListener(ChatManager.CONSUME_SPEAKER, self.consumeSpeakerCallback)
  
  self.sendFailedCallback = function(ee)
    SuspensionLabel:showContent(self.container, Localization:getInstance():getText("union_chat_send_not_satisfied8"))
  end
  NotificationManager:addEventListener(ChatManager.SEND_FAILED, self.sendFailedCallback)
  --[[
  local scrollBar = Scale9Sprite:create("pic/scroll.png")
  scrollBar:setAnchorPoint(ccp(0.5, 1))
  scrollBar:setPositionX(scroll_posX + scroll_width)
  scrollBar:setPositionY(scroll_posY + scroll_height)
  self.panelUI:addChildAt(scrollBar, 21)
  local scroll_bar_original_height = scrollBar:getOriginalSize().height
  local scroll_bar_original_width = scrollBar:getOriginalSize().width
  scrollBar:setPreferredSize(CCSizeMake(scroll_bar_original_width, scroll_height))
  ]]
  local scrollBar = Scale9Sprite:create("pic/scroll.png")
  local scroll_bar_original_height = scrollBar:getOriginalSize().height
  local scroll_bar_original_width = scrollBar:getOriginalSize().width
  local numberClipLayer = CCClippingNode:create()
  local numberClipLayer_co = CocosObject.new(numberClipLayer)
  numberClipLayer:setContentSize(CCSizeMake(scroll_bar_original_width, scroll_height))
  numberClipLayer:setAnchorPoint(ccp(0, 1))
  numberClipLayer:setPosition(ccp(scroll_posX + scroll_width, scroll_posY + scroll_height + scroll_height))
  self.panelUI:addChildAt(numberClipLayer_co, 21)
  local stencil = CCSprite:create("pic/5.png")
  stencil:setScaleX(scroll_bar_original_width / stencil:getContentSize().width)
  stencil:setScaleY(scroll_height / stencil:getContentSize().height)
  stencil:setAnchorPoint(ccp(0, 1))
  stencil:setPosition(ccp(0, 0))
  numberClipLayer:setStencil(stencil)
  scrollBar:setAnchorPoint(ccp(0, 1))
  scrollBar:setPositionX(0)
  scrollBar:setPositionY(0)
  numberClipLayer_co:addChild(scrollBar)
  scrollBar:setPreferredSize(CCSizeMake(scroll_bar_original_width, scroll_height))
  
  local function checkSrcollCallback()
    local scroll_view_content_height = self.scrollView:getContentSize().height
    if scroll_view_content_height <= scroll_height then
      scrollBar:setVisible(false)
    else
      scrollBar:setVisible(true)
      local aScale = scroll_height / scroll_view_content_height
      local aPreferredHeight = aScale * scroll_height
      if aPreferredHeight < scroll_bar_original_height  then
        aPreferredHeight = scroll_bar_original_height
      end
      scrollBar:setPreferredSize(CCSizeMake(scrollBar:getOriginalSize().width, aPreferredHeight))
      local offsetY = -self.scrollView:getContentOffset().y
      local scroll_bar_offsetY = offsetY / (scroll_view_content_height - scroll_height) * (scroll_height - aPreferredHeight)
      scrollBar:setPositionY(scroll_posY + aPreferredHeight + scroll_bar_offsetY - scroll_posY - scroll_height)
    end
  end
  self.checkSrcollFunc = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(checkSrcollCallback, 0, false);
end

function UnionChatContainerPanel:dispose()
  self.scrollView.startPosY = self.startPosY
  self.scrollView.totalContentHeight = self.totalContentHeight
  
  NotificationManager:removeEventListener(ChatManager.NEW_CHAT_CONTENT, self.newContentCallback)
  NotificationManager:removeEventListener(ChatManager.CONSUME_SPEAKER, self.consumeSpeakerCallback)
  NotificationManager:removeEventListener(ChatManager.SEND_FAILED, self.sendFailedCallback)
  if self.checkSrcollFunc then
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.checkSrcollFunc)
  end
  if self.addScrollContentFunc then
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.addScrollContentFunc)
  end
  UnionChatContainerPanel.super.dispose(self)
end

function UnionChatContainerPanel:scaleIn()
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

function UnionChatContainerPanel:dismissSelf()
  --[[
  self.container.targetInfoPanel = self.pre_container_targetInfoPanel
  if (self.container.setTableViewsEnabled) then
    self.container:setTableViewsEnabled(true)
  end
  self:removeFromParentAndCleanup(true)]]
  PopoutManager:pullin(self, kPopoutDir.kScale)
end

local scrollViewArray = {}
local function getScrollView(aIndex)
  if not scrollViewArray[aIndex] then
    local aScrollView = ScrollView:create(scroll_width, scroll_height)
    aScrollView:setPosition(ccp(scroll_posX, scroll_posY))
    aScrollView:setDirection(kCCScrollViewDirectionVertical)
    aScrollView:retain()
    aScrollView.cellViewList = {}
    aScrollView.startPosY = scroll_startPosY
    aScrollView.totalContentHeight = 0
    scrollViewArray[aIndex] = aScrollView
    aScrollView:setContentSize(CCSizeMake(scroll_width, (aScrollView.startPosY < 0) and (scroll_height - aScrollView.startPosY) or scroll_height))
    aScrollView:adjustHitArea()
    aScrollView:setContentOffset(ccp(0, 0), false)
  end
  return scrollViewArray[aIndex]
end

function UnionChatContainerPanel.resetChatContentView()
  for i = 3, 1, -1 do
    if scrollViewArray[i] then
      scrollViewArray[i].toRetain = false;
      scrollViewArray[i]:dispose()
      scrollViewArray[i] = nil
    end
  end
end

function UnionChatContainerPanel:changeToPanel(aIndex, aSpecialName)
  if self.selectedPanelIndex == aIndex then
    return
  end
  self.selectedPanelIndex = aIndex
  
  if self.scrollView then
    --self.scrollView.cellViewList = self.cellViewList
    self.scrollView.startPosY = self.startPosY
    self.scrollView.totalContentHeight = self.totalContentHeight
    self.scrollView:removeFromParentAndCleanup(true)
  end
  self.scrollView = getScrollView(self.selectedPanelIndex)
  self.panelUI:addChildAt(self.scrollView, 20)
  self.cellViewList = self.scrollView.cellViewList
  self.startPosY = self.scrollView.startPosY
  self.totalContentHeight = self.scrollView.totalContentHeight
  
  NotificationManager:dispatchEvent(Event.new(ChatManager.CHAT_TAG_VIEWED))
  self:resetUI(aSpecialName)
  self:resetScrollView()
end

function UnionChatContainerPanel:resetUI(aSpecialName)
  for aButtonIndex, aTabButton in ipairs(self.tabButtonList) do
    if aButtonIndex == self.selectedPanelIndex then
      aTabButton:setEnable(false)
      aTabButton.display:getChildByName("arrow"):setVisible(true)
      aTabButton.display:getChildByName("normal"):setVisible(false)
      aTabButton.display:getChildByName("btn"):setVisible(true)
    else
      aTabButton:setEnable(true)
      aTabButton.display:getChildByName("arrow"):setVisible(false)
      aTabButton.display:getChildByName("normal"):setVisible(true)
      aTabButton.display:getChildByName("btn"):setVisible(false)
    end
  end
  
  if not UnionManager.isInUnion() then
    self.unionTabButtonDisplay:getChildByName("normal"):setVisible(false)
    self.unionTabButtonDisplay:getChildByName("btn"):setVisible(false)
    self.unionTabButtonDisplay:getChildByName("btn_light_act"):setVisible(false)
    self.unionTabButtonDisplay:getChildByName("btn_tab_inactive"):setVisible(true)
    self.unionTabButton:setEnable(false)
  end
  
  if self.selectedPanelIndex == TabEnum.chatToSpecial then
    self.chatShowMax = DataManager.GameMetaData.chatSettingConfig.privateChatShowMax
    
    self.speakerSprite:setVisible(false)
    self.speakerNumLabel:setVisible(false)
    self.vipTipLabel:setVisible(false)
    self.specialLabel1:setVisible(true)
    self.specialLabel2:setVisible(true)
    for _, aSpecialNameBg in ipairs(self.specialNameBgList) do
      aSpecialNameBg:setVisible(true)
    end
    self.nameInputLabel:setVisible(true)
    self.nameInputLabel:setText(aSpecialName or "")
  elseif self.selectedPanelIndex == TabEnum.chatToAll then
    self.chatShowMax = DataManager.GameMetaData.chatSettingConfig.worldChatShowMax
    
    self.speakerSprite:setVisible(true)
    self.speakerNumLabel:setVisible(true)
    self.speakerNum = getSpeakerNum()
    self.speakerNumLabel:getChildByName("txt"):setString(string.format("x%d", self.speakerNum))
    if DataManager.getCurrUser().vipLevel > 0 then
      self.vipTipLabel:setVisible(false)
    else
      self.vipTipLabel:setVisible(true)
    end
    self.specialLabel1:setVisible(false)
    self.specialLabel2:setVisible(false)
    for _, aSpecialNameBg in ipairs(self.specialNameBgList) do
      aSpecialNameBg:setVisible(false)
    end
    self.nameInputLabel:setVisible(false)
    self.nameInputLabel:setText("")
  else
    self.chatShowMax = DataManager.GameMetaData.chatSettingConfig.unionChatShowMax
    
    self.speakerSprite:setVisible(false)
    self.speakerNumLabel:setVisible(false)
    self.vipTipLabel:setVisible(false)
    self.specialLabel1:setVisible(false)
    self.specialLabel2:setVisible(false)
    for _, aSpecialNameBg in ipairs(self.specialNameBgList) do
      aSpecialNameBg:setVisible(false)
    end
    self.nameInputLabel:setVisible(false)
    self.nameInputLabel:setText("")
  end
  self.editInputLabel:setText("")
  self:hideFlashing()
end

function UnionChatContainerPanel:resetScrollView()
  --[[
  for k, aGroup in pairs(self.cellViewList) do
    for _, aChild in ipairs(aGroup.cellViewChildren) do
      self.scrollView:getContainer():removeChild(aChild.refCocosObj, true)
      self.scrollView:removeChild(aChild, true)
    end
		self.cellViewList[k] = nil
	end
  ]]
  local chatList
  if self.selectedPanelIndex == TabEnum.chatToSpecial then
    chatList = ChatManager.getSpecialChatList()
  elseif self.selectedPanelIndex == TabEnum.chatToAll then
    chatList = ChatManager.getWorldChatList()
  else
    chatList = ChatManager.getUnionChatList()
  end
  if #chatList > self.chatShowMax then
    for i = 1, #chatList - self.chatShowMax do
      table.remove(chatList, i)
    end
  end
  --[[
  self.startPosY = scroll_startPosY
  self.totalContentHeight = 0
  ]]
  -------------------------------------------------
  self.isAddingScrollContent = true
  if self.addScrollContentFunc then
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.addScrollContentFunc)
    self.addScrollContentFunc = nil
  end
  local function addScrollContent()
    local local_index = self.getChatNewIndex()
    --print("local_index:" .. local_index)
    if #chatList <= local_index then
      self.isAddingScrollContent = false
      if self.addScrollContentFunc then
        CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.addScrollContentFunc)
        self.addScrollContentFunc = nil
      end
      return
    end
    self:showNewContent(chatList[local_index + 1])
  end
  self.addScrollContentFunc = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(addScrollContent, 0, false)
  --[[
  for _, aChat in ipairs(chatList) do
    self:addNewContent(aChat)
  end
  self.scrollView:setContentSize(CCSizeMake(scroll_width, (self.startPosY < 0) and (scroll_height - self.startPosY) or scroll_height))
  self.scrollView:adjustHitArea()
  if self.startPosY < 0 then
    for _, aGroup in ipairs(self.cellViewList) do
      for _, aChild in ipairs(aGroup.cellViewChildren) do
        aChild:setPositionY(aChild:getPositionY() - self.startPosY)
        if aChild.origninalPosY then
          aChild.origninalPosY = aChild:getPositionY()
        end
      end
    end
    self.startPosY = 0
  end
  self.scrollView:setContentOffset(ccp(0, 0), false)
  ]]
end

function UnionChatContainerPanel:showFailMessageForRetcode(aRetCode)
  print("chat response retCode:" .. aRetCode)
  if aRetCode == 716520 then
    SuspensionLabel:showContent(self.container, Localization:getInstance():getText("union_chat_send_not_satisfied4"))
  elseif aRetCode == 716521 then
    SuspensionLabel:showContent(self.container, Localization:getInstance():getText("union_chat_send_not_satisfied7"))
  elseif aRetCode == 716522 then
    local messageLengthLimit = DataManager.GameMetaData.chatSettingConfig.messageLengthMax
    SuspensionLabel:showContent(self.container, Localization:getInstance():getText("union_chat_send_not_satisfied2", {num1 = messageLengthLimit / 2, num2 = messageLengthLimit}))
  elseif aRetCode == 716531 then
    local messageLengthLimit = getTextByKey("silenced_text3")
    local scene = Director:mgr():run()
    local aPanel = MessageBoxPanel:create(self, MessageBoxType.kSpeakLimitWarning ,{warningMessage = messageLengthLimit , chatTouchEnable = true})
    self:addChild(aPanel)
    aPanel:scaleIn()
  else
    
  end
end

----------------------------------------------

local function getOriginalGroupBounds(aObject)
  local aBounds = {origin = {x = 0, y = 0}, size = {width = 0, height = 0}}
  local objectBounds = aObject:getGroupBounds()
  aBounds.origin.x = objectBounds.origin.x
  aBounds.origin.y = objectBounds.origin.y
  aBounds.size.width = objectBounds.size.width / SELF_INSTANCE.parent:getScale()
  aBounds.size.height = objectBounds.size.height / SELF_INSTANCE.parent:getScale()
  return aBounds
end

local function getSystemText(pos_x, pos_y)
  local amountText = ArtTextField:create(Localization:getInstance():getText("union_chat_system_text"), nil, 32)
  amountText:setAnchorPoint(ccp(0, 1))
  amountText:setPosition(ccp(pos_x, pos_y))
  amountText:setColor(ccc3(252, 51, 2))
  amountText:setAroundColor(ccc3(50, 35, 35))
  return amountText
end

local function getVipText(pos_x, pos_y)
  local vipText = ArtTextField:create(Localization:getInstance():getText("union_chat_vip_text1"), nil, 32)
  vipText:setAnchorPoint(ccp(0, 1))
  vipText:setPosition(ccp(pos_x, pos_y))
  vipText:setColor(ccc3(252, 240, 100))
  vipText:setAroundColor(ccc3(50, 35, 35))
  return vipText
end

local function getNameText(text, pos_x, pos_y)
  local nameText = ArtTextField:create(text, nil, 32)
  nameText:setAnchorPoint(ccp(0, 1))
  nameText:setPosition(ccp(pos_x, pos_y))
  nameText:setColor(ccc3(2, 255, 51))
  nameText:setAroundColor(ccc3(50, 35, 35))
  nameText.origninalPosX = pos_x
  nameText.origninalPosY = pos_y
  return nameText
end

local function setTextButton(context, viewList, nameText, uid)
  local nameTextBounds = getOriginalGroupBounds(nameText)
  local function onTextTouchBegin(evt)
    nameText:setPositionX(nameText.origninalPosX + 1)
    nameText:setPositionY(nameText.origninalPosY - 1)
  end
  local function onTextTouchEnd(evt)
    nameText:setPositionX(nameText.origninalPosX)
    nameText:setPositionY(nameText.origninalPosY)
  end
  local aText = TextField:create(nameText:getString(), nil, 32, CCSizeMake(nameTextBounds.size.width,nameTextBounds.size.height))
  aText:setOpacity(0)
  aText:setAnchorPoint(ccp(0, 1))
  aText:setPosition(ccp(nameText:getPositionX(), nameText:getPositionY() - nameTextBounds.size.height))
  nameText:getParent():addChild(aText)
  table.insert(viewList, aText)
  local nameButton = Button:create(aText)
  aText.testChat = true
  aText:addEventListener(DisplayEvents.kTouchBegin, onTextTouchBegin)
  aText:addEventListener(DisplayEvents.kTouchEnd, onTextTouchEnd)
  nameButton.uid = uid
  nameButton:addEventListener(Events.kStart, nameButtonSelected, context)
end

local function getSayText(text, pos_x, pos_y)
  local sayText = ArtTextField:create(text, nil, 32)
  sayText:setAnchorPoint(ccp(0, 1))
  sayText:setPosition(ccp(pos_x, pos_y))
  sayText:setColor(ccc3(255, 255, 255))
  sayText:setAroundColor(ccc3(50, 35, 35))
  return sayText
end

local function getWordText(text, pos_x, pos_y)
  local wordText = ArtTextField:create(text, nil, 32, CCSizeMake(scroll_width, 0))
  wordText:setAnchorPoint(ccp(0, 1))
  wordText:setPosition(ccp(pos_x, pos_y))
  wordText:setColor(ccc3(255, 255, 255))
  wordText:setAroundColor(ccc3(50, 35, 35))
  return wordText
end

--------------------------------------------

function UnionChatContainerPanel:addNewContent(aChat)
  local aChatCellView = {}
  local aDistance = 0
  if tonumber(aChat.uid) == 1 then
    local amountText = getSystemText(0, self.startPosY)
    self.scrollView:addChild(amountText)
    table.insert(aChatCellView, amountText)
    self.startPosY = self.startPosY - getOriginalGroupBounds(amountText).size.height
    aDistance = aDistance + getOriginalGroupBounds(amountText).size.height
  elseif self.selectedPanelIndex == TabEnum.chatToSpecial then
    local aStartPosX = 0
    if aChat.senderVipLevel > 0 then
      local vipText = getVipText(aStartPosX, self.startPosY)
      self.scrollView:addChild(vipText)
      table.insert(aChatCellView, vipText)
      aStartPosX = aStartPosX + getOriginalGroupBounds(vipText).size.width + horizontal_distance
    end
    local nameText = getNameText(aChat.senderNickName, aStartPosX, self.startPosY)
    self.scrollView:addChild(nameText)
    table.insert(aChatCellView, nameText)
    aStartPosX = aStartPosX + getOriginalGroupBounds(nameText).size.width + horizontal_distance
    if (tonumber(aChat.senderUid) ~= tonumber(DataManager.getCurrUser().uid)) then
      setTextButton(self, aChatCellView, nameText, tonumber(aChat.senderUid))
    end
    
    local sayText = getSayText(Localization:getInstance():getText("union_chat_input_target_text"), aStartPosX, self.startPosY)
    self.scrollView:addChild(sayText)
    table.insert(aChatCellView, sayText)
    aStartPosX = aStartPosX + getOriginalGroupBounds(sayText).size.width + horizontal_distance
    
    if aChat.receiverVipLevel > 0 then
      local vipText = getVipText(aStartPosX, self.startPosY)
      self.scrollView:addChild(vipText)
      table.insert(aChatCellView, vipText)
      aStartPosX = aStartPosX + getOriginalGroupBounds(vipText).size.width + horizontal_distance
    end
    nameText = getNameText(aChat.receiverNickName, aStartPosX, self.startPosY)
    self.scrollView:addChild(nameText)
    table.insert(aChatCellView, nameText)
    aStartPosX = aStartPosX + getOriginalGroupBounds(nameText).size.width + horizontal_distance
    if (tonumber(aChat.receiverUid) ~= tonumber(DataManager.getCurrUser().uid)) then
      setTextButton(self, aChatCellView, nameText, tonumber(aChat.receiverUid))
    end
    
    sayText = getSayText(Localization:getInstance():getText("union_chat_say_text"), aStartPosX, self.startPosY)
    self.scrollView:addChild(sayText)
    table.insert(aChatCellView, sayText)
    
    self.startPosY = self.startPosY - getOriginalGroupBounds(sayText).size.height
    aDistance = aDistance + getOriginalGroupBounds(sayText).size.height
  else
    local aStartPosX = 0
    if aChat.vipLevel > 0 then
      local vipText = getVipText(aStartPosX, self.startPosY)
      self.scrollView:addChild(vipText)
      table.insert(aChatCellView, vipText)
      aStartPosX = aStartPosX + getOriginalGroupBounds(vipText).size.width + horizontal_distance
    end
    
    local nameText = getNameText(aChat.nickName, aStartPosX, self.startPosY)
    self.scrollView:addChild(nameText)
    table.insert(aChatCellView, nameText)
    aStartPosX = aStartPosX + getOriginalGroupBounds(nameText).size.width + horizontal_distance
    
    if (tonumber(aChat.uid) ~= tonumber(DataManager.getCurrUser().uid)) then
      setTextButton(self, aChatCellView, nameText, tonumber(aChat.uid))
    end
    
    local sayText = getSayText(Localization:getInstance():getText("union_chat_say_text"), aStartPosX, self.startPosY)
    self.scrollView:addChild(sayText)
    table.insert(aChatCellView, sayText)
    
    self.startPosY = self.startPosY - getOriginalGroupBounds(sayText).size.height
    aDistance = aDistance + getOriginalGroupBounds(sayText).size.height
  end
  local wordText = getWordText(aChat.message, 0, self.startPosY)
  self.scrollView:addChild(wordText)
  table.insert(aChatCellView, wordText)
  
  self.startPosY = self.startPosY - getOriginalGroupBounds(wordText).size.height - vertical_distance
  aDistance = aDistance + getOriginalGroupBounds(wordText).size.height + vertical_distance
  local temp = {}
  temp.cellViewChildren = aChatCellView
  temp.distance = aDistance
  table.insert(self.cellViewList, temp)
  self.totalContentHeight = self.totalContentHeight + aDistance
end

function UnionChatContainerPanel:showNewContent(aContent)
  self.addChatNewIndex(self.getChatNewIndex() + 1)
  
  local aDistance = 0
  if #self.cellViewList >= self.chatShowMax then
    for _, aChild in ipairs(self.cellViewList[1].cellViewChildren) do
      self.scrollView:getContainer():removeChild(aChild.refCocosObj, true)
      self.scrollView:removeChild(aChild, true)
    end
    aDistance = self.cellViewList[1].distance
    table.remove(self.cellViewList, 1)
    self.totalContentHeight = self.totalContentHeight - aDistance
  end
  self:addNewContent(aContent)
  local aNewDistance = self.cellViewList[#self.cellViewList].distance
  local oldContentSizeY = self.scrollView:getContentSize().height
  local oldContentOffsetY = self.scrollView:getContentOffset().y
  if self.totalContentHeight > scroll_height then
    self.scrollView:setContentSize(CCSizeMake(scroll_width, self.totalContentHeight))
    self.scrollView:adjustHitArea()
    self.startPosY = 0
  else
    self.scrollView:setContentSize(CCSizeMake(scroll_width, scroll_height))
    self.scrollView:adjustHitArea()
    --
  end
  local newContentSizeY = self.scrollView:getContentSize().height
  for _, aGroup in ipairs(self.cellViewList) do
    for _, aChild in ipairs(aGroup.cellViewChildren) do
      aChild:setPositionY(aChild:getPositionY() + aDistance + (newContentSizeY - oldContentSizeY))
      if aChild.origninalPosY then
        aChild.origninalPosY = aChild:getPositionY()
      end
    end
  end
  if oldContentOffsetY < (scroll_height - newContentSizeY) then
    oldContentOffsetY = (scroll_height - newContentSizeY)
  end
  self.scrollView:setContentOffset(ccp(0, oldContentOffsetY), false)
end
  
function UnionChatContainerPanel:showFlashing(chatType)
  local flashObject
  if chatType == TabEnum.chatToSpecial then
    if not self.specialFlashing then
      flashObject = self.specialTabButtonDisplay:getChildByName("btn_light_act")
      self.specialFlashing = true
    end
  elseif chatType == TabEnum.chatToUnion then
    if not self.unionFlashing then
      flashObject = self.unionTabButtonDisplay:getChildByName("btn_light_act")
      self.unionFlashing = true
    end
  end
  if flashObject then
    local arr = CCArray:create()
    arr:addObject(CCFadeIn:create(1.0))
    arr:addObject(CCFadeOut:create(1.0))
    flashObject:runAction(CCRepeatForever:create(CCSequence:create(arr)))
  end
end

function UnionChatContainerPanel:hideFlashing()
  local flashObject
  if self.selectedPanelIndex == TabEnum.chatToSpecial then
    if self.specialFlashing then
      flashObject = self.specialTabButtonDisplay:getChildByName("btn_light_act")
      self.specialFlashing = false
    end
  elseif self.selectedPanelIndex == TabEnum.chatToUnion then
    if self.unionFlashing then
      flashObject = self.unionTabButtonDisplay:getChildByName("btn_light_act")
      self.unionFlashing = false
    end
  end
  if flashObject then
    flashObject:stopAllActions()
    flashObject:setOpacity(0)
  end
end

function UnionChatContainerPanel:showUserDetailPanel(aUid)
  local function panelClosed(evt)
    self:setTableViewTouched(true)
  end
  
  local function privateCallback(nickName, uid)
    self.nameInputLabel:setText(nickName)
    if self.selectedPanelIndex ~= TabEnum.chatToSpecial then
      self:changeToPanel(TabEnum.chatToSpecial, nickName)
    end
  end
  self:setTableViewTouched(false)
  local userDetailPanel = UserDetailPanel:create( self.container, {friendUid = aUid, messageType = UserDetailPanel.MESSAGE_TYPE_PRIVATE_MESSAGE, onPrivateMessageCallback = privateCallback} )
  userDetailPanel.Close_CallBack = panelClosed
  PopoutManager:sharedManager():popout(userDetailPanel, kPopoutDir.kScale, true, false, self.container)
end

function UnionChatContainerPanel:sendChatContent()
  local aContent = self.editInputLabel:getText()
  if (not aContent) or (aContent == "") then
    SuspensionLabel:showContent(self.container, Localization:getInstance():getText("union_chat_send_not_satisfied5"))
    return
  end
  --去除首尾空格再判断
  local content_no_blank = string.gsub(aContent, "^%s*(.-)%s*$", "%1")
  if (not content_no_blank) or (content_no_blank == "") then
    SuspensionLabel:showContent(self.container, Localization:getInstance():getText("union_chat_send_not_satisfied5"))
    return
  end
  if self.selectedPanelIndex == TabEnum.chatToAll then
    if (DataManager.getCurrUser().vipLevel < 1) and (getSpeakerNum() < 1) then
      self:showVipPanel()
      return
    end
    local currentWorldChatNum = DailyDataManager.getWorldMessageNum()
    if DataManager.GameMetaData.chatSettingConfig.worldChatQuota <= currentWorldChatNum then
      SuspensionLabel:showContent(self.container, Localization:getInstance():getText("union_chat_send_not_satisfied1"))
      return
    end
    self:judgeContentLengthForSend(aContent)
  elseif self.selectedPanelIndex == TabEnum.chatToSpecial then
    local aName = self.nameInputLabel:getText()
    if (not aName) or (aName == "") then
      SuspensionLabel:showContent(self.container, Localization:getInstance():getText("union_chat_send_not_satisfied3"))
      return
    end
    if aName == DataManager.getCurrUser().nickName then
      SuspensionLabel:showContent(self.container, Localization:getInstance():getText("union_chat_send_not_satisfied6"))
      return
    end
    self:judgeContentLengthForSend(aContent)
  else
    self:judgeContentLengthForSend(aContent)
  end
end

function UnionChatContainerPanel:judgeContentLengthForSend(aContent)
  local chinum,engnum = StringUtil.calcChineseEnglishNum(aContent)
  local messageLengthLimit = DataManager.GameMetaData.chatSettingConfig.messageLengthMax
  if (chinum*2+engnum)>messageLengthLimit then
    SuspensionLabel:showContent(self.container, Localization:getInstance():getText("union_chat_send_not_satisfied2", {num1 = messageLengthLimit / 2, num2 = messageLengthLimit}))
    return
  end
  ----------send
  local chatMethod
  local userName
  if self.selectedPanelIndex == TabEnum.chatToAll then
    chatMethod = MethodDict.METHOD_WORLDCHAT
  elseif self.selectedPanelIndex == TabEnum.chatToSpecial then
    chatMethod = MethodDict.METHOD_PRIVATECHAT
    userName = self.nameInputLabel:getText()
  else
    chatMethod = MethodDict.METHOD_UNIONCHAT
  end
  ChatManager.sendChat({method = chatMethod, message = self.editInputLabel:getText(), userName = userName})
  self.editInputLabel:setText("")
end

function UnionChatContainerPanel:showVipPanel()
  local function panelClosed(evt)
    self:setTableViewTouched(true)
    self.container:setTableViewsEnabled(true)
    if self.extraParams.vipSpecial then
      self.container:setTableViewsEnabled(false)
    end
  end
  local function becomeVIPCallback()
    self.container:setTableViewsEnabled(true)
    self:dismissSelf()
  end
  self:setTableViewTouched(false)
  local aPanel = VipWarningPanel:create( self.container, 1, {title = Localization:getInstance():getText("union_chat_world_VIP_horn")})
  aPanel.Close_CallBack = panelClosed
  aPanel.BecomeVIP_CallBack = becomeVIPCallback
  PopoutManager:sharedManager():popout(aPanel, kPopoutDir.kScale, true, false , self.container)
end

function UnionChatContainerPanel:setTableViewTouched(enabled)
  self.scrollView:setTouchEnabled(enabled)
  self.editInputLabel:setEnabled(enabled)
  self.nameInputLabel:setEnabled(enabled)
end