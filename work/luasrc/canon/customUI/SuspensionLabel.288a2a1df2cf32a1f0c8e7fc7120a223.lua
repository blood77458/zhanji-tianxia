require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"

suspension_label_z_order = 10000
local visibleSize = CCDirector:sharedDirector():getVisibleSize()
local suspension_label_pos_x = visibleSize.width / 2.0
local suspension_label_pos_y = visibleSize.height / 2.0
local suspension_label_width = 660
local suspension_label_font_size = 26
local suspension_label_font_color = ccc3(255,255,255)
local suspension_label_font_name = "Helvetica"

--
-- SuspensionLabel 悬浮提示文字
--

SuspensionLabel = class()

function SuspensionLabel:showContent(aContainer, aContent, response, stayDuration)
  if (not aContainer) or (not aContent) then
    return
  end
  local content_list
  if type(aContent) == "string" then
    content_list = {aContent}
  else
    content_list = aContent
  end
  
  local aTotalHeight = 0
  local aTotalWidth = 0
  local cell_list = {}
  local aStartHeight = 0
  
  local up_title = Sprite:create("common/txt_event_bg_upanddown.png")
  up_title:setAnchorPoint(ccp(0.5,0.5))
  up_title:setPosition(ccp(0, aStartHeight - up_title:getContentSize().height / 2.0))
  table.insert(cell_list, up_title)
  aTotalHeight = aTotalHeight + up_title:getContentSize().height
  aTotalWidth = up_title:getContentSize().width
  aStartHeight = aStartHeight - up_title:getContentSize().height
  
  local aTexture = CCTextureCache:sharedTextureCache():addImage("common/txt_event_bg_center.png")
  local aTextureWidth = aTexture:getContentSize().width
  local aTextureHeight = aTexture:getContentSize().height
  --[[
  local one_line_content = true
  if #content_list > 1 then
    one_line_content = false
  end]]
  local aExampleLabel = TextField:create("Example", suspension_label_font_name, suspension_label_font_size, CCSizeMake(suspension_label_width, 0), kCCTextAlignmentLeft, kCCVerticalTextAlignmentTop)
  local aExampleHeight = aExampleLabel:getTexture():getContentSize().height
  
  for _, aString in ipairs(content_list) do
    local aLabel = TextField:create(aString, suspension_label_font_name, suspension_label_font_size, CCSizeMake(suspension_label_width, 0), kCCTextAlignmentLeft, kCCVerticalTextAlignmentTop)
    local aHeight = aLabel:getTexture():getContentSize().height
    local aMultiple = aHeight / aExampleHeight
    if aMultiple > (1.0 - 0.1) and aMultiple < (1.0 + 0.1) then
      --if one_line_content then
        aLabel:setHorizontalAlignment(kCCTextAlignmentCenter)
      --end
    end
    
    local aTempPosY = aStartHeight
    local aTempHeight = aHeight
    while aTempHeight > 0 do
      local bg_cc
      local bg
      if aTempHeight >= aTextureHeight then
        bg_cc = CCSprite:create("common/txt_event_bg_center.png")
        bg = CocosObject.new(bg_cc) 
        bg:setAnchorPoint(ccp(0.5, 1))
        bg:setPosition(ccp(0, aTempPosY))
        table.insert(cell_list, bg)
        aTempPosY = aTempPosY - aTextureHeight
        aTempHeight = aTempHeight - aTextureHeight
      else
        bg_cc = CCSprite:create("common/txt_event_bg_center.png", CCRectMake(0,0,aTextureWidth, aTempHeight))
        bg = CocosObject.new(bg_cc) 
        bg:setAnchorPoint(ccp(0.5, 1))
        bg:setPosition(ccp(0, aTempPosY))
        table.insert(cell_list, bg)
        aTempPosY = aTempPosY - aTempHeight
        aTempHeight = 0
      end
    end
    
    aLabel:setColor(suspension_label_font_color)
    aLabel:setAnchorPoint(ccp(0.5, 1))
    aLabel:setPosition(ccp(0, aStartHeight))
    table.insert(cell_list, aLabel)
    aStartHeight = aStartHeight - aHeight
    aTotalHeight = aTotalHeight + aHeight
  end
  
  local down_title = Sprite:create("common/txt_event_bg_upanddown.png")
  down_title:setAnchorPoint(ccp(0.5,0.5))
  down_title:setScaleY(-1)
  down_title:setPosition(ccp(0, aStartHeight - down_title:getContentSize().height / 2.0))
  table.insert(cell_list, down_title)
  aTotalHeight = aTotalHeight + down_title:getContentSize().height
  aStartHeight = aStartHeight - down_title:getContentSize().height
  
  local result = Layer:create()
  result:setContentSize(CCSizeMake(aTotalWidth, aTotalHeight))
  result:setAnchorPoint(ccp(0.5, 0.5))
  
  for _, aCell in ipairs(cell_list) do
    aCell:setPositionY(aCell:getPositionY() + aTotalHeight)
    result:addChild(aCell)
  end
  
  stayDuration =  stayDuration or 3
  
  result:setScaleY(0.1)
  result.showSelf = function (result)
    local function enterActionFinished()
      
    end
    local function exitActionFinished()
      if (type(result) == "table") and (type(result.parent) == "table") and result.parent.refCocosObj and result.refCocosObj then
        result:removeFromParentAndCleanup(true)
      end
	  if response then
		response()
	  end
    end
    local arr = CCArray:create()
    arr:addObject(CCScaleTo:create(0.2, 1.0))
    arr:addObject(CCCallFunc:create(enterActionFinished))
    arr:addObject(CCDelayTime:create(stayDuration))
    arr:addObject(CCScaleTo:create(0.2, 1.0, 0.1))
    arr:addObject(CCCallFunc:create(exitActionFinished))
    result:runAction(CCSequence:create(arr))
  end
  result:setPosition(ccp(suspension_label_pos_x, suspension_label_pos_y - aTotalHeight/2))
  aContainer:addChildAt(result, suspension_label_z_order)
  result:showSelf()
  aExampleLabel:dispose()
  return result
end
 
