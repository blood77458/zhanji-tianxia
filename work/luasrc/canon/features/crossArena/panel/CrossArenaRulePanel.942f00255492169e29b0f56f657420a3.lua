--------------------------------------------------------------------------------
-- CrossArenaRulePanel.lua -- 跨服PVP规则界面
-- author: l1ghtsaber
-- date: 2015-3-6
--------------------------------------------------------------------------------

CrossArenaRulePanel = class(Layer)

local TITLE_POS_X = 55
local TITLE_POS_Y = 60
local LAYER_SPACING = 24
local CONTENT_OFFSET = 10
local TITLE_FONT_SIZE = 26
local CONTENT_FONT_SIZE = 26
local CONTENT_SPACING = 8
local SCROLL_VIEW_HEIGHT_OFFSET = 5
local SCROLL_VIEW_SPACING = 3

function CrossArenaRulePanel:ctor()
  self.container = nil
  self.arenaData = nil
end

function CrossArenaRulePanel:create(container, closeCallBackFunc)
  self.container = container
  self.colseCallBackFunc = closeCallBackFunc

  local panel = CrossArenaRulePanel.new()
  panel:initLayer()
  
  return panel
end

function CrossArenaRulePanel:initLayer()
  CrossArenaRulePanel.super.initLayer(self)
  local battleTimeBegin = os.date("*t" ,CrossArenaManager.getBattleBeginTime())
  local battleTimeEnd = os.date("*t" ,CrossArenaManager.getBattleEndTime())
  local rewardTimeEnd = os.date("*t" ,CrossArenaManager.getRewardEndTime()-1)--因为多语言配的是24点，所以这里-1
  local params = {num1 = battleTimeBegin.year , num2 = battleTimeBegin.month ,num3 = battleTimeBegin.day ,
                  num4 = battleTimeEnd.year , num5 = battleTimeEnd.month ,num6 = battleTimeEnd.day ,
                  num7 = battleTimeEnd.year , num8 = battleTimeEnd.month ,num9 = battleTimeEnd.day ,
                  num10 = rewardTimeEnd.year , num11 = rewardTimeEnd.month ,num12 = rewardTimeEnd.day ,}
  self.arenaData = {  --文本内容
    -- {titleText = getTextByKey("crossArena_battleRuleText"),contentText = getTextByKey("crossArena_battleRuleExplain")},
    -- {titleText = getTextByKey("crossArena_rewardRuleText"),contentText = getTextByKey("crossArena_rewardRuleExplain")},
    -- {titleText = getTextByKey("crossArena_battleRuleText"),contentText = getTextByKey("crossArena_battleRuleExplain")},
    -- {titleText = getTextByKey("crossArena_rewardRuleText"),contentText = getTextByKey("crossArena_rewardRuleExplain")},
    -- {titleText = getTextByKey("crossArena_battleRuleText"),contentText = getTextByKey("crossArena_battleRuleExplain")},
    -- {titleText = getTextByKey("crossArena_rewardRuleText"),contentText = getTextByKey("crossArena_rewardRuleExplain")},
    {titleText = getTextByKey("crossArena_battleRuleText"),contentText = getTextByKey("crossArena_battleRuleExplain", params)},
    {titleText = getTextByKey("crossArena_rewardRuleText"),contentText = getTextByKey("crossArena_rewardRuleExplain")}
  }
  
  -- 获取公告UI
  local builder = LayoutBuilder:createWithContentsOfFile("scene/cross_Arena.json")
  local ui = builder:build("table_crossArena_gz")
  self:addChild(ui)
  
  local titleLabel = ui:getChildByName("txt_distribution"):getChildByName("txt")
  titleLabel:setString(getTextByKey("crossArena_Title"))
  
  -- 关闭Panel事件
  local function onClosePanel(evt)
    PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale)
    self.container.targetInfoPanel = nil
    if self.colseCallBackFunc and type(self.colseCallBackFunc) == "function" then
      self.colseCallBackFunc()
    end
  end
  
  -- 关闭按钮
  local closeButtonDisplay = ui:getChildByName("login_btn_close")
  local closeButton = Button:create(closeButtonDisplay)
  closeButton:addEventListener(Events.kStart, onClosePanel, self)
  
  local exTxtTitle = ui:getChildByName("txt_jj_7"):getChildByName("txt")
  local exTxtContent = ui:getChildByName("txt_jj_8"):getChildByName("txt")
  local exBgUp = ui:getChildByName("yellow9_panel")
  local exBgCenter = ui:getChildByName("white9_panel")
  


  -- 隐藏UI
  exTxtTitle:setVisible(false)
  exTxtContent:setVisible(false)
  exBgUp:setVisible(false)
  exBgCenter:setVisible(false)
 

  
  local yellowPanel = ui:getChildByName("new_green_bg9_pic")
  local tmpsize = {width = 666,height = 600}--yellowPanel:getGroupBounds().size
  local svHeight = tmpsize.height -- SCROLL_VIEW_HEIGHT_OFFSET
  
  self.scrollView = ScrollView:create(tmpsize.width, tmpsize.height)
  self.scrollView:setPosition(ccp(0, 25))
  self.scrollView:setDirection(kCCScrollViewDirectionVertical)
  
  -- 生成信息
  local function buildArenaRule(data)
    local exBgCenterWidth = exBgCenter:getContentSize().width
    local exBgCenterHeight = exBgCenter:getContentSize().height
    local exBgUpWidth =  exBgUp:getContentSize().width
    local exBgUpHeight =  exBgUp:getContentSize().height

    -- 生成标题
    local function buildBgUp()
      local bgUp = LayerColor:create()
      bgUp:setContentSize(CCSizeMake(exBgUpWidth, exBgUpHeight))
      bgUp:setColor(ccc3(147, 156, 144))
      bgUp:setAnchorPoint(ccp(0, 0))
      
      local titleText = ""
      if data["titleText"] then titleText = data["titleText"] end
      
      local titleField = TextField:create(titleText)
      titleField:setAnchorPoint(ccp(0, 0))
      titleField:setPosition(ccp(9, 3))
      titleField:setFontSize(TITLE_FONT_SIZE) --字体大小
      titleField:setColor(exTxtTitle:getColor())
      titleField:setDimensions(CCSizeMake(exTxtTitle:getDimensions().width, 0)) --自动换行
      titleField:setHorizontalAlignment(kCCTextAlignmentCenter) --文本水平对齐格式
      bgUp:addChild(titleField)
      return bgUp, bgUp:getContentSize().height
    end
    
    -- 生成正文
    local function buildBgCenter()
      local contentTotalHeight = 0
      local contentFields = {}
      
      --获得数据contentText
      local contentText = {}
      contentText = data["contentText"]:split("\\n ")
      if(not contentText) or (contentText == {}) then
        return bgCenter, contentFields, contentTotalHeight
      end
      --end
      if __IOS and toluahelper.isIOS64bit() then
        local finalString = ""
        for i, aString in ipairs(contentText) do
          if i > 1 then
            finalString = finalString.."\n"
          end
          finalString = finalString..aString
        end
        finalString = finalString .. "\n"
        
        local contentField = TextField:create(finalString, "Helvetica", CONTENT_FONT_SIZE, CCSizeMake(exTxtContent:getDimensions().width, 0), kCCTextAlignmentLeft, kCCVerticalTextAlignmentTop)
        contentField:setColor(exTxtContent:getColor())
        contentField:setAnchorPoint(ccp(0, 0))
        table.insert(contentFields, contentField)
        local contentHeight = contentField:getContentSize().height + CONTENT_SPACING
        contentTotalHeight = contentTotalHeight + contentHeight 
      else
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
      end
      

      contentTotalHeight = contentTotalHeight + 13
      local bgCenter = LayerColor:create()
      bgCenter:setContentSize(CCSizeMake(exBgCenterWidth, contentTotalHeight))
      bgCenter:setColor(ccc3(147, 156, 144))
      return bgCenter, contentFields, contentTotalHeight  --背景，文本，高度
    end
    
    local height = 0
    local layer = Layer:create()
    local bgPosX = 10
    local txtPosX = 30

    -- 内容
    local bgCenter, contentFields, contentTotalHeight = buildBgCenter()
    bgCenter:setPosition(ccp(bgPosX, 0))
    layer:addChild(bgCenter)

    --local bgHuawen = Sprite:create(UI_RES_PATH.."/common_new/huawen.png")
    --bgHuawen:setAnchorPoint(ccp(0, 0))
    --bgHuawen:setPosition(ccp(txtPosX + 10, 10))
    --layer:addChildAt(bgHuawen, 66)

    local contentPosY = height + contentTotalHeight
    for idx, contentField in pairs(contentFields) do
      contentPosY = contentPosY - contentField:getContentSize().height - CONTENT_SPACING
      contentField:setPosition(ccp(txtPosX, contentPosY))
      layer:addChildAt(contentField, 666)
    end
    height = height + contentTotalHeight
    
    -- 标题
    local bgUp, bgUpHeight = buildBgUp()
    bgUp:setPosition(ccp(bgPosX, height - CONTENT_SPACING+10))
    layer:addChild(bgUp)
    height = height + bgUpHeight
   
    -- 设置Layer大小
    layer:setContentSize(CCSizeMake(tmpsize.width, height))
    return layer, height
  end
  
  local totalHeight = 0
  local layerIndex = 0
  local layerSet = {}
  local layerHeights = {}
  
  for idx, data in pairs(self.arenaData) do
    local layer, height = buildArenaRule(data)
    table.insert(layerSet, layerIndex, layer)
    table.insert(layerHeights, layerIndex, height)
    totalHeight = totalHeight + height + LAYER_SPACING
    layerIndex = layerIndex + 1
  end
  
  local layerPosY = totalHeight
  for idx, layer in pairs(layerSet) do
    layerPosY = layerPosY - layerHeights[idx] - LAYER_SPACING + SCROLL_VIEW_SPACING
    layer:setPositionY(layerPosY)
    self.scrollView:addChild(layer)
  end
  totalHeight = totalHeight + SCROLL_VIEW_SPACING
  
  self.scrollView:setContentSize(CCSizeMake(tmpsize.width, totalHeight))
  self.scrollView:setContentOffset(ccp(10, svHeight - totalHeight), false)
  yellowPanel:addChild(self.scrollView)

end