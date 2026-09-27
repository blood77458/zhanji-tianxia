--------------------------------------------------------------------------------
-- ViewControlUtil.lua - 视图组件相关工具类
-- author: xiaojie.bai
-- date: 2013-10-05 14:00
--------------------------------------------------------------------------------

ViewControlUtil = class()
--------------------
-- 判断坐标点是否在控件区域内
--------------------
function ViewControlUtil.isInArea(position, button) 
  return position.x > button:getPositionX() and
    position.x < (button:getPositionX() + button:getContentSize().width) and 
    position.y > (button:getPositionY() - button:getContentSize().height) and 
    position.y < button:getPositionY()
end
  
--------------------
-- 判断坐标点是否在控件区域内
--------------------
function ViewControlUtil.isInAreaPic(position, button, picButton) 
  return position.x > button:getPositionX() and
    position.x < (button:getPositionX() + picButton:getContentSize().width) and 
    position.y > (button:getPositionY() - picButton:getContentSize().height) and 
    position.y < button:getPositionY()
end

--------------------
-- 将目标元件调整为frame的坐标及大小
--------------------
function ViewControlUtil.adjustItemByFrame(destItem, frameSb)
  local framePosition = frameSb:getPosition()
  local frameGroupBounds = frameSb:getGroupBounds().size
  
  local destItemSize = destItem:getGroupBounds().size
  destItem:setPosition(ccp(framePosition.x, framePosition.y))
  destItem:setScaleX(frameGroupBounds.width / destItemSize.width)
  destItem:setScaleY(frameGroupBounds.height / destItemSize.height)
end

--------------------
-- 根据原文字的大小及位置生成一个新的包边字
-- orginLabel：原标签对象, contentText：新标签的文字内容
-- centerColor：新标签字体颜色，aroundColor：新标签包边颜色
-- textFont：字体
-- Fangzhou.Long
--------------------
function ViewControlUtil.buildArtLabel( orginLabel, contentText, centerColor, aroundColor, textFont )
  local pos = orginLabel and orginLabel:getPosition() or {x=0,y=0}
  local aNewLabel = ArtLabelTTF:create(contentText, true)
  aNewLabel:setCenterColor(centerColor or ccc3(255,255,255))
  aNewLabel:setAroundColor(aroundColor or ccc3(0,0,0))
  
  aNewLabel:setFont(textFont)
  aNewLabel:setSize(orginLabel and orginLabel:getFontSize() or 24)
  aNewLabel:setPosition(ccp(pos.x,pos.y))
 
  if (orginLabel) then
	aNewLabel:setTextAnchorPoint(ccp(0,1))
	aNewLabel:setDimensions(orginLabel:getDimensions())
	aNewLabel:setHorizontalAlignment(orginLabel:getHorizontalAlignment())
	aNewLabel:setVerticalAlignment(orginLabel:getVerticalAlignment())
	orginLabel:setVisible(false)
  end
  
  aNewLabel:construct()
  
  return CocosObject.new(aNewLabel),aNewLabel
end

--------------------
-- tableView刷新数据，保证行首或行尾正常显示
------
-- keepOffset 保持tableView刷新前的位置
--------------------
function ViewControlUtil.refreshTableView(tableView, keepOffset)
  if(keepOffset) then
    local canOffset = false
    local direction = tableView:getDirection()
    local numberOfCells = tableView.tableViewRenderer:numberOfCells()
    local cellSize = tableView.tableViewRenderer:getContentSize()
    local viewSize = tableView:getViewSize()
    if(kCCScrollViewDirectionHorizontal == direction) then
      canOffset = cellSize.width * numberOfCells > viewSize.width
    else
      canOffset = cellSize.height * numberOfCells > viewSize.height
    end
    
    if(canOffset) then
      local tableOffset = tableView:getContentOffset()
      if(kCCScrollViewDirectionHorizontal == direction) then
        local maxOffsetX = cellSize.width * (numberOfCells - 1)
        if(maxOffsetX < tableOffset.x) then
          tableOffset.x = maxOffsetX
        end
      else
        local maxOffsetY = viewSize.height  - cellSize.height * (numberOfCells)
        if(maxOffsetY > tableOffset.y) then
          tableOffset.y = tableOffset.y + ((maxOffsetY - tableOffset.y) / cellSize.height) * cellSize.height
        elseif(tableOffset.y > 0) then
          tableOffset.y = 0
        end
      end
      
      tableView:reloadData()
      tableView:setContentOffset(tableOffset)
    else
      tableView:reloadData()
    end
  else
    tableView:reloadData()
  end
end

--------------------
-- tableView指定行居中显示：若指定行为行首或行尾，则正常显示
------
-- index 居中显示的条目数
--------------------
function ViewControlUtil.refreshAndLocateTableView(tableView, index)
  if(not index or index == 0) then
    tableView:reloadData()
    return nil
  end
  
  local canOffset = false
  local direction = tableView:getDirection()
  local numberOfCells = tableView.tableViewRenderer:numberOfCells()
  local cellSize = tableView.tableViewRenderer:getContentSize()
  local viewSize = tableView:getViewSize()
  if(kCCScrollViewDirectionHorizontal == direction) then
    canOffset = cellSize.width * numberOfCells > viewSize.width
  else
    canOffset = cellSize.height * numberOfCells > viewSize.height
  end
  
  if(canOffset) then
    local tableOffset = tableView:getContentOffset()
    if(kCCScrollViewDirectionHorizontal == direction) then
      local offsetIdx = index
      tableOffset.x = (viewSize.width + cellSize.width) / 2 - cellSize.width * offsetIdx
      local maxOffsetX = viewSize.width - cellSize.width * numberOfCells
      if(tableOffset.x < maxOffsetX) then
        tableOffset.x = maxOffsetX
      elseif(tableOffset.x > 0) then
        tableOffset.x = 0
      end
      tableOffset.y = 0
    else
      local offsetIdx = numberOfCells - index
      tableOffset.y = viewSize.height - cellSize.height * offsetIdx - (viewSize.height + cellSize.height) / 2
      local maxOffsetY = viewSize.height - cellSize.height * (numberOfCells)
      if(tableOffset.y > 0) then
        tableOffset.y = 0
      elseif(maxOffsetY > tableOffset.y) then
        tableOffset.y = maxOffsetY
      end
    end
    tableView:reloadData()
    tableView:setContentOffset(tableOffset)
  else
    tableView:reloadData()
  end
end

--------------------
-- tableView 的setData()中对 文本内容设置
--------------------
function ViewControlUtil.setLableText(txtSb, text)
  local className = toluahelper.getClass(txtSb)
	if className == "CCLabelTTF" then
		tolua.cast(txtSb, "CCLabelTTF")
		txtSb:setString(text)
	elseif PlistResMgr:getInstance():getCCNodeClassName(txtSb) == "ArtLabelTTF" then
		tolua.cast(txtSb, "ArtLabelTTF")
		txtSb:setText(text)
		txtSb:construct()
	end
end

--------------------
-- 遮罩显示元件，仅在一个特定区域（clipBg）中显示图像（ccBg）
--------------------
function ViewControlUtil.generateClip(ccBg, clipBg)
	--local ccBg = CCSprite:create("login/login_bg.png")
	local bgSize = clipBg:getBounds().size
	local bgPosition = clipBg:getPosition()
	local AClipBg = CCClippingRegionNode:create(
		ccBg,
		bgPosition.x,
		bgPosition.y,
		bgSize.width,
		bgSize.height
	)
	return CocosObject.new(AClipBg), AClipBg
end

--TODO
function ViewControlUtil:isCellTotallyInView(tableView, cellIdx)
  animatedCells = {}
  
  local numberOfCells = tableView.tableViewRenderer:numberOfCells()
  local cellSize = tableView.tableViewRenderer:getContentSize() --cell大小
  local viewSize = tableView:getViewSize() --表格视图大小
  local tableOffset = tableView:getContentOffset()

  local isIn = false
  local direction = tableView:getDirection()
  if(kCCScrollViewDirectionHorizontal == direction) then
    local canOffset = cellSize.width * numberOfCells > viewSize.width
    if(canOffset) then
      isIn = cellIdx * cellSize.width > tableOffset.x and (cellIdx + 1) * cellSize.width < (tableOffset.x + viewSize.width)
    else
      isIn = true
    end
  else
    local canOffset = cellSize.height * numberOfCells > viewSize.height
    if(canOffset) then
      local originalOffsetY = viewSize.height - cellSize.height * numberOfCells
      if(originalOffsetY > 0) then
        originalOffsetY = 0
      end
      local offsetY = tableOffset.y - originalOffsetY
      
      isIn = cellIdx * cellSize.height > offsetY and (cellIdx + 1) * cellSize.height < (offsetY + viewSize.height)
    else
      isIn = true
    end
  end
  
  return isIn
end

--------------------
-- 抽离表格中可见的单元
--------------------
function ViewControlUtil.generateAnimatedCells(tableView)
  animatedCells = {}
  
  local numberOfCells = tableView.tableViewRenderer:numberOfCells()
  local cellSize = tableView.tableViewRenderer:getContentSize() --cell大小
  local viewSize = tableView:getViewSize() --表格视图大小
  local tableOffset = tableView:getContentOffset()
  
  local originalOffsetY = viewSize.height - cellSize.height * numberOfCells
  local offsetY = tableOffset.y - originalOffsetY
  for i = 1, numberOfCells do
    local idx = i - 1
    
    if offsetY < i * cellSize.height and (offsetY + viewSize.height) > idx * cellSize.height then
      table.insert(animatedCells, tableView:cellAtIndex(idx))
    end
  end
  
  return animatedCells
end

--------------------
-- 表格播放左侧逐行进入动画
--------------------
function ViewControlUtil.showTableViewAction(tableView, visibleSize,callback)
  ViewControlUtil._showTableViewAction(tableView, 0.3, 0.15, visibleSize, true, callback)
end

--------------------
-- 表格播放左侧逐行退出动画
--------------------
function ViewControlUtil.disappearTableViewAction(tableView, visibleSize, callback) 
  ViewControlUtil._showTableViewAction(tableView, 0.3, 0.15, visibleSize, false, callback)
end

function ViewControlUtil._showTableViewAction(tableView, duration, cellDuration, visibleSize, enter, callback)
  if(not tableView) then
    return nil
  end
  tableView:setVisible(true)
  
  local moveWidth = -visibleSize.width
  if(enter) then
    moveWidth = visibleSize.width
  end
  
  local animatedCells = ViewControlUtil.generateAnimatedCells(tableView)
  local preDuration = duration - cellDuration
  
  if #animatedCells > 1 then
    preDuration = preDuration / (#animatedCells - 1)
  else
    preDuration = preDuration
  end
  
  for aIndex, aCell in ipairs(animatedCells) do
    if(enter) then
      aCell:setPositionX(aCell:getPositionX() - moveWidth)
    end
    local arr = CCArray:create()
    arr:addObject(CCDelayTime:create(preDuration * (aIndex - 1)))
    arr:addObject(CCMoveBy:create(cellDuration, ccp(moveWidth, 0)))
    aCell:runAction(CCSequence:create(arr))
  end
  
  local arr = CCArray:create()
  arr:addObject(CCDelayTime:create(duration))
  if(callback) then
    arr:addObject(CCCallFunc:create(callback))
  end
  local function recoverCellPos()
    for aIndex, aCell in ipairs(animatedCells) do
      aCell:setPositionX(aCell:getPositionX() - moveWidth)
    end
    if(tableView and tableView.refCocosObj) then --tableView在Scene中有可能被dispose
      tableView:setVisible(false)
    end
  end
  if(not enter) then
    arr:addObject(CCCallFunc:create(recoverCellPos))
  end
  
  tableView:runAction(CCSequence:create(arr))
end

--------------------
-- 元件内的所有节点元素播放淡入动画
--------------------
function ViewControlUtil.animateFadeIn(symbol)
  ViewControlUtil._animateFadeIn(symbol, 0.3)
end

function ViewControlUtil._animateFadeIn(symbol, duration)
  if(not symbol.list or #symbol.list == 0) then
    symbol:setOpacity(0)
    symbol:runAction(CCFadeIn:create(duration))
  else
    for _, aChild in pairs(symbol.list) do
      ViewControlUtil._animateFadeIn(aChild, duration)
    end
  end
end

--------------------
-- 元件内的所有节点元素播放淡出动画
--------------------
function ViewControlUtil.animateFadeOut(symbol)
  ViewControlUtil._animateFadeOut(symbol, 0.3)
end

function ViewControlUtil._animateFadeOut(symbol, duration)
  if(not symbol.list or #symbol.list == 0) then
    symbol:runAction(CCFadeOut:create(duration))
  else
    for _, aChild in pairs(symbol.list) do
      ViewControlUtil._animateFadeOut(aChild, duration)
    end
  end
end