--------------------------------------------------------------------------------
-- AnnouncementPanel.lua -- 公告界面
-- author: Jiang Yize
-- date: 2013-10-17
--------------------------------------------------------------------------------

AnnouncementPanel = class(Layer)

local TITLE_POS_X = 55
local TITLE_POS_Y = 60
local LAYER_SPACING = 20
local CONTENT_OFFSET = 10
local TITLE_FONT_SIZE = 35
local CONTENT_FONT_SIZE = 30
local CONTENT_SPACING = 5
local SCROLL_VIEW_HEIGHT_OFFSET = 300

ShowPanelType = {
  ShowAnnounce = 1,
  ShowHelp = 2,
}

function AnnouncementPanel:ctor()
  self.container = nil
  self.announcementData = nil
end

function AnnouncementPanel:create(container, announcementData, panelType, closeCallBackFunc)
  self.container = container
  self.announcementData = announcementData
  self.panelType = panelType
  self.colseCallBackFunc = closeCallBackFunc

  local panel = AnnouncementPanel.new()
  panel:initLayer()
  
  return panel
end

function AnnouncementPanel:initLayer()
  AnnouncementPanel.super.initLayer(self)
  
  -- 设置Layer
  local winSize = CCDirector:sharedDirector():getWinSize()
  self:setContentSize(CCSizeMake(winSize.width, winSize.height))
  
  -- 获取公告UI
  local builder = LayoutBuilder:createWithContentsOfFile("scene/common_new.json")
  local ui = builder:build("common_popup_announcement")
  self:addChild(ui)
  
  local titleLabel = ui:getChildByName("common_txt_announcement_title"):getChildByName("txt")
  if self.panelType == ShowPanelType.ShowAnnounce then
    titleLabel:setString(getTextByKey("option_notice"))
  else
    titleLabel:setString(getTextByKey("option_help"))
  end
  
  -- 关闭Panel事件
  local function onClosePanel(evt)
    PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale)
    self.container.targetInfoPanel = nil
    if self.colseCallBackFunc and type(self.colseCallBackFunc) == "function" then
      self.colseCallBackFunc()
    end
  end
  
  -- 关闭公告按钮
  local closeButtonDisplay = ui:getChildByName("common_btn_close_sb")
  local closeButton = Button:create(closeButtonDisplay)
  closeButton:addEventListener(Events.kStart, onClosePanel, self)
  
  local exTxtTitle = ui:getChildByName("common_txt_announcement_maintitle"):getChildByName("txt")
  local exTxtContent = ui:getChildByName("common_txt_announcement"):getChildByName("txt")
  local exBgUp = ui:getChildByName("common_announcement_bg_up")
  local exBgCenter = ui:getChildByName("common_announcement_bg_center")
  local exBgDown = ui:getChildByName("common_announcement_bg_down")
  
  -- 隐藏UI
  exTxtTitle:setVisible(false)
  exTxtContent:setVisible(false)
  exBgUp:setVisible(false)
  exBgCenter:setVisible(false)
  exBgDown:setVisible(false)
  
  --local yellowPanel = ui:getChildByName("yellow9_panel")
  --yellowPanel:setVisible(false)
  local svHeight = winSize.height - SCROLL_VIEW_HEIGHT_OFFSET
  local svPosY = ui:getChildByName("common_bg_cardInfo_Title_sb3"):getPosition().y
  
  self.colorLayer = LayerColor:create()
  self.colorLayer:setPosition(ccp(0, 160))
  self.colorLayer:setOpacity(0)
  self.colorLayer:setContentSize(CCSizeMake(winSize.width, svHeight))
  self:addChild(self.colorLayer)
  
  self.scrollView = ScrollView:create(winSize.width, svHeight)
  self.scrollView:setPosition(ccp(0, 0))
  self.scrollView:setDirection(kCCScrollViewDirectionVertical)
  
  -- 生成公告信息
  local function buildAnnouncement(data)
    local exTexture = CCTextureCache:sharedTextureCache():addImage("common/announcement_bg_center.png")
    local exTextureWidth = exTexture:getContentSize().width
    local exTextureHeight = exTexture:getContentSize().height
   
    -- 生成公告标题
    local function buildBgUp()
      local bgUp = Sprite:create(UI_RES_PATH.."/common_new/common_announcement_bg_up.png")
      bgUp:setAnchorPoint(ccp(0, 0))
      
      local titleText = ""
      if self.panelType == ShowPanelType.ShowAnnounce then
        titleText = data["titleText"]
      else
        titleText = getTextByKey(data["titleKey"])
      end
      
      local titleField = TextField:create(titleText)
      titleField:setAnchorPoint(ccp(0, 1))
      titleField:setPosition(ccp(TITLE_POS_X, TITLE_POS_Y))
      titleField:setFontSize(TITLE_FONT_SIZE)
      titleField:setColor(exTxtTitle:getColor())
      titleField:setDimensions(CCSizeMake(exTxtTitle:getDimensions().width, 0))
      titleField:setHorizontalAlignment(kCCTextAlignmentCenter)
      bgUp:addChild(titleField)
      return bgUp, bgUp:getContentSize().height
    end
    
    -- 生成公告正文
    local function buildBgCenter()
      local contentTotalHeight = 0
      local contentCells = {}
      local contentFields = {}
      
      local function splitString(str, ch)
        local ret = {}
        while true do
          local pos = string.find(str, ch)
          if not pos then
            ret[#ret + 1] = str
            break
          end
          ret[#ret + 1] = string.sub(str, 1, pos - 1)
          str = string.sub(str, pos + 1, #str)
        end
        return ret
      end
      
      local contentText = {}
      if self.panelType == ShowPanelType.ShowAnnounce then
        contentText = splitString(data["contentText"], '\n')
        if(not contentText) or (contentText == {}) then
          return contentCells, contentFields, contentTotalHeight
        end
      else
        contentText = data["contentKeys"]
      end
      
      for idx, content in pairs(contentText) do
        local contentField = TextField:create(getTextByKey(content))
        contentField:setAnchorPoint(ccp(0, 0))
        contentField:setFontSize(CONTENT_FONT_SIZE)
        contentField:setColor(exTxtContent:getColor())
        contentField:setDimensions(CCSizeMake(exTxtContent:getDimensions().width, 0))
        table.insert(contentFields, contentField)
        local contentHeight = contentField:getContentSize().height + CONTENT_SPACING
        contentTotalHeight = contentTotalHeight + contentHeight 
      end
      
      local tempHeight = contentTotalHeight
      contentTotalHeight = 0
      while tempHeight > 0 do
        if(tempHeight >= exTextureHeight) then
          local bgCenterCC = CCSprite:create("common/announcement_bg_center.png")
          local bgCenter = CocosObject.new(bgCenterCC) 
          bgCenter:setAnchorPoint(ccp(0, 0))
          table.insert(contentCells, bgCenter)
          tempHeight = tempHeight - exTextureHeight
          contentTotalHeight = contentTotalHeight + exTextureHeight
        else
          local bgCenterCC = CCSprite:create("common/announcement_bg_center.png", CCRectMake(0, 0, exTextureWidth, tempHeight))
          local bgCenter = CocosObject.new(bgCenterCC) 
          bgCenter:setAnchorPoint(ccp(0, 0))
          table.insert(contentCells, bgCenter)
          contentTotalHeight = contentTotalHeight + tempHeight
          tempHeight = 0
        end
      end
      return contentCells, contentFields, contentTotalHeight
    end
    
    -- 生成公告底部
    local function buildBgDown()
      local bgDown = Sprite:create(UI_RES_PATH.."/common_new/common_announcement_bg_down.png")
      bgDown:setAnchorPoint(ccp(0, 0))
      return bgDown, bgDown:getContentSize().height
    end
    
    local height = 0
    local layer = Layer:create()
    local bgPosX = (winSize.width - exBgUp:getContentSize().width) / 2
    local txtPosX = (winSize.width - exTxtContent:getDimensions().width) / 2 + CONTENT_OFFSET
    
    -- 公告底部
    local bgDown, bgDownHeight = buildBgDown()
    local exBgDownWidth = exBgDown:getContentSize().width
    bgDown:setPosition(ccp(bgPosX, height + CONTENT_SPACING))
    layer:addChild(bgDown)
    height = height + bgDownHeight
    
    -- 公告内容
    contentCells, contentFields, contentTotalHeight = buildBgCenter()
    local contentPosY = height + contentTotalHeight
    for idx, bgCenter in pairs(contentCells) do
      contentPosY = contentPosY - bgCenter:getContentSize().height 
      bgCenter:setPosition(ccp(bgPosX, contentPosY + 2))
      layer:addChild(bgCenter)
    end
    contentPosY = height + contentTotalHeight
    for idx, contentField in pairs(contentFields) do
      contentPosY = contentPosY - contentField:getContentSize().height - CONTENT_SPACING
      contentField:setPosition(ccp(txtPosX, contentPosY - 5))
      layer:addChildAt(contentField, 2000)
    end
    height = height + contentTotalHeight
    
    -- 公告标题
    local bgUp, bgUpHeight = buildBgUp()
    bgUp:setPosition(ccp(bgPosX, height - CONTENT_SPACING))
    layer:addChild(bgUp)
    height = height + bgUpHeight
   
    -- 设置Layer大小
    layer:setContentSize(CCSizeMake(winSize.width, height))
    return layer, height
  end
  
  local totalHeight = 0
  local layerIndex = 0
  local layerSet = {}
  local layerHeights = {}
  
  for idx, data in pairs(self.announcementData) do
    local layer, height = buildAnnouncement(data)
    table.insert(layerSet, layerIndex, layer)
    table.insert(layerHeights, layerIndex, height)
    totalHeight = totalHeight + height + LAYER_SPACING
    layerIndex = layerIndex + 1
  end
  
  local layerPosY = totalHeight
  for idx, layer in pairs(layerSet) do
    layerPosY = layerPosY - layerHeights[idx] - LAYER_SPACING
    layer:setPositionY(layerPosY)
    self.scrollView:addChild(layer)
  end
  
  self.scrollView:setContentSize(CCSizeMake(winSize.width, totalHeight))
  self.scrollView:setContentOffset(ccp(0, svHeight - totalHeight), false)
  self.colorLayer:addChild(self.scrollView)

end
