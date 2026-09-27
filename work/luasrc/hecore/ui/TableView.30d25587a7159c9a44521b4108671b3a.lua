-------------------------------------------------------------------------
--  Class include: TableViewRenderer, TableView
-------------------------------------------------------------------------

require "hecore.display.Director"
require "hecore.display.TextField"

kTableViewVerticalFillOrder = {kCCTableViewFillTopDown, kCCTableViewFillBottomUp}

-- g_enableTableViewCache = true
-- if IsDiaosiDevice() then
-- 	g_enableTableViewCache = false;
-- end
PlistResMgr:getInstance():setEnableCacheTableView(true)

--
-- TableViewRenderer ---------------------------------------------------------
--
TableViewRenderer = class()
function TableViewRenderer:ctor(width, height)
	self.list = {}
	self.width = width
	self.height = height
	self.name2tagHash = nil--用于记录扫描过的元件名称->自动生成的tag编号
end
function TableViewRenderer:getContentSize()
	return CCSizeMake(self.width, self.height)
end
function TableViewRenderer:buildCell(container)
	local label = TextField:create("")
	label:setAnchorPoint(ccp(0,0))
	container:addChild(label)
	label:setTag(-1001)
end
function TableViewRenderer:setData( rawCocosObj, index )
	local label = self:getChildByTag(rawCocosObj, -1001)
	if type(label.setString) == "function" then label:setString("Index:"..index) end
end
function TableViewRenderer:getChildByTag(rawCocosObj, tag)
    return rawCocosObj:getChildByTag(tag)
end
function TableViewRenderer:getDataSource()
	return self.list
end
function TableViewRenderer:numberOfCells()
	return #self.list
end

function TableViewRenderer:dispose()
	self.name2tagHash = nil
end

-- 扫描cell的全部child的name并自动生成tag (扫描过程出现同名情况 选取最后一个编号)
-- cellCocosDisplay 通过build生成的cell显示元件
function TableViewRenderer:scanTags(cellCocosDisplay)
	if not self.name2tagHash then
		--没有对应数据 生成一份
		self.name2tagHash = {}
		local currentIndex = 0
		local function scanInside(display)
			local tag = -5000 - currentIndex
			self.name2tagHash[display.name] = tag
			currentIndex = currentIndex + 1
			for k, v in pairs(display.list) do
				scanInside(v)
			end
		end
		scanInside(cellCocosDisplay)
		--print("self.name2tagHash = " .. tostringRich(self.name2tagHash))
	end
end

--给cell自动生成tag
function TableViewRenderer:addTags( cellCocosDisplay )
	local function addTagInside(display)
		for k, v in pairs(display.list) do
			local tag = self.name2tagHash[v.name]
			v:setTag(tag)
			addTagInside(v)
		end
	end
	addTagInside(cellCocosDisplay)
end

-- 获得cell的某个子child
-- cellDisplay 要查找的cell元件根节点
-- layerNames 层名列表 用/间隔 如: "txt_jj_21/txt"
function TableViewRenderer:getChildByNames(cellDisplay, layerNames)
	if not self.name2tagHash then
		--没有对应数据
		return nil
	end

	local child = cellDisplay
	local namelist = layerNames:split("/")
	for i, v in ipairs(namelist) do
		local childTag = self.name2tagHash[v]
		child = child:getChildByTag(childTag)
	end

	return child
end

-- 设置文本框文本
-- cellDisplay cell元件根节点
-- layerNames 层名列表 用/间隔 如: "txt_jj_21/txt" 目标必须对应一个文本框
-- str 显示的内容
function TableViewRenderer:setTxtByNames(cellDisplay, layerNames, str)
	local child = self:getChildByNames(cellDisplay, layerNames)
	setNodeText(child, str)
end

-- 获取Tag名
function TableViewRenderer:getTagByLayerName(layerName)
	return self.name2tagHash[layerName]
end

--
-- TableView ---------------------------------------------------------
--

local function grayDisplay(aObject)
  if type(aObject.setColor) == "function" then
    local className = toluahelper.getClass(aObject)
    if true then --className == "CCLabelTTF" or PlistResMgr:getInstance():getCCNodeClassName(aObject) == "ArtLabelTTF" then
      if not aObject.originalColor then
        aObject.originalColor = aObject:getColor()
      end
      if aObject.originalColor.r then
        aObject:setColor(ccc3(aObject.originalColor.r * 0.8, aObject.originalColor.g * 0.8, aObject.originalColor.b * 0.8))
      end
    else
      aObject:setColor(ccc3(128,128,128))
    end
    return
  end
  
  if type(aObject.getChildren) == "function" then
	  local children = aObject:getChildren()
    if (children) then
      local len = children:count()
      for i = 0, len - 1 do
        local aNode = children:objectAtIndex(i)
        local className = toluahelper.getClass(aNode)
        local child = tolua.cast(aNode, className)
        grayDisplay(child)
      end
    end
  end
end

local function brightDisplay(aObject)
  if type(aObject.setColor) == "function" then
    local className = toluahelper.getClass(aObject)
    if true then --className == "CCLabelTTF" or PlistResMgr:getInstance():getCCNodeClassName(aObject) == "ArtLabelTTF" then
      if aObject.originalColor then
        if aObject.originalColor.r then
          aObject:setColor(aObject.originalColor)
        end
      end
    else
      aObject:setColor(ccc3(255,255,255))
    end
    return
  end
  
  if type(aObject.getChildren) == "function" then
	  local children = aObject:getChildren()
    if (children) then
      local len = children:count()
      for i = 0, len - 1 do
        local aNode = children:objectAtIndex(i)
        local className = toluahelper.getClass(aNode)
        local child = tolua.cast(aNode, className)
        brightDisplay(child)
      end
	  end
  end
end

local function checkCellButtonTouchBegan(cell, worldPosition, touchObjectList)
  if not touchObjectList or #touchObjectList == 0 then
    return
  end
  for _, touchObject in pairs(touchObjectList) do
		if HeDisplayUtil:hitTestPoint(touchObject, worldPosition, true, kHitAreaObjectTag) then
			grayDisplay(touchObject)
      if touchObject.originalTablePosX and touchObject.originalTablePosY then
        touchObject:setPositionX(touchObject.originalTablePosX + 1)
        touchObject:setPositionY(touchObject.originalTablePosY - 1)
      end
      touchObject.touched = true
		end
  end
end

local function checkCellButtonTouchEnded(touchObjectList)
  if not touchObjectList or #touchObjectList == 0 then
    return
  end
  for _, touchObject in pairs(touchObjectList) do
    if touchObject.touched then
      brightDisplay(touchObject)
      if touchObject.originalTablePosX and touchObject.originalTablePosY then
        touchObject:setPositionX(touchObject.originalTablePosX)
        touchObject:setPositionY(touchObject.originalTablePosY)
      end
      touchObject.touched = false
    end
  end
  for k, v in pairs(touchObjectList) do
		touchObjectList[k] = nil;
	end
end

local function generateTouchObjectList(tempObject, touchObjectList, buttonTag)
  if type(buttonTag) == "table" then
    for _, aTag in ipairs(buttonTag) do
      if type(aTag) == "table" then
        generateTouchObjectList(tempObject:getChildByTag(aTag[1]), touchObjectList, aTag[2])
      else
        local aObject = tempObject:getChildByTag(aTag)
        if not aObject.ignoreTouch then
          table.insert(touchObjectList, aObject)
          if (not aObject.originalTablePosX) and (not aObject.originalTablePosY) then
            aObject.originalTablePosX = aObject:getPositionX()
            aObject.originalTablePosY = aObject:getPositionY()
          end
        end
      end
    end 
  else
    local aButtonObject = tempObject:getChildByTag(buttonTag)
    if not aButtonObject.ignoreTouch then
      table.insert(touchObjectList, aButtonObject)
      if (not aButtonObject.originalTablePosX) and (not aButtonObject.originalTablePosY) then
        aButtonObject.originalTablePosX = aButtonObject:getPositionX()
        aButtonObject.originalTablePosY = aButtonObject:getPositionY()
      end
    end
  end
end

TableView = class(CocosObject)

function TableView:dispose()
	self:clearDragable()

	if self.tableViewRenderer then
		self.tableViewRenderer:dispose()
	end
	
	CocosObject.dispose(self)
end
--[[
function TableView:setScrollNode(v) self.refCocosObj:setScrollNode(v) end
function TableView:setScrollBar(v) self.refCocosObj:setScrollBar(v) end
function TableView:setScrollTrack(v) self.refCocosObj:setScrollTrack(v) end
]]
function TableView:create(tableViewRenderer, width, height, cellTag, buttonTag, scrollSprite, scrollBgSprite, data, scrollOffset, otherData)
  local touchObject = {}   --button
	local view = nil
	local alreadySetData = {}
	local function tableViewDelegate( eventType, tableView, a1, a2)
		if eventType == "cellSize" then
			return tableViewRenderer:getContentSize()
		elseif eventType == "cellAtIndex" then
			--Return CCTableViewCell, a1 is cell index, a2 is dequeued cell (maybe nil)
			--Do something to create cell and change the content
			if not a2 then
				alreadySetData[a1] = false
				local container = CocosObject.new(CCTableViewCell:create())
				tableViewRenderer:buildCell(container)
				a2 = container.refCocosObj
				if g_enableTableViewCache then
					a2:setVisible(false)
				end
				container:dispose()
			end
			--if not alreadySetData[a1] then
				alreadySetData[a1] = true
				tableViewRenderer:setData(a2, a1)
			--end
			return a2
		elseif eventType == "numberOfCells" then
			return tableViewRenderer:numberOfCells()
    elseif eventType == "cellTouchBegan" then
      --年兽活动要用到拉列表刷新 需要该事件 add by czh @ 2014-2-10
      --print("cellTouchBegan")
      if view and view:hasEventListenerByName("tableCellTouchBegin") then
		local evt = DisplayEvent.new("tableCellTouchBegin", a1, a2)
		view:dispatchEvent(evt)
	  end
	  view:dispatchEvent( DisplayEvent.new(DisplayEvents.kTouchBegin, a1, a2))

      if not a1 then
        return
      end
      if type(cellTag) ~= "number" then
        return
      end
      if type(buttonTag) ~= "number" and type(buttonTag) ~= "table" then
        return
      end
      if type(buttonTag) == "table" and #buttonTag == 0 then
        return
      end
      
      local aTempObject = a1:getChildByTag(cellTag)
      if not aTempObject then
        return
      end
      local touch = a2
      local point = CCDirector:sharedDirector():convertToGL(touch:getLocationInView())
      --local posInCell = a1:convertToNodeSpace(point)
      --touchObject = {}
      generateTouchObjectList(aTempObject, touchObject, buttonTag)
      checkCellButtonTouchBegan(a1, point, touchObject)
    elseif eventType == "cellTouchEnded" then
      checkCellButtonTouchEnded(touchObject)
	  view:dispatchEvent( DisplayEvent.new(DisplayEvents.kTouchEnd, a1, a2))
		elseif eventType == "cellTouched" then
      checkCellButtonTouchEnded(touchObject)
			--A cell was touched, a1 is cell that be touched. This is not necessary. 
			local touch = a2
			local point = CCDirector:sharedDirector():convertToGL(touch:getLocationInView())
			local cellIndex = a1:getIdx() 
			if view and view:hasEventListenerByName(DisplayEvents.kTouchItem) then
				local evt = DisplayEvent.new(DisplayEvents.kTouchItem, view, point)
				evt.data = cellIndex
				view:dispatchEvent(evt)
				if FireClickEvent then
					FireClickEvent() -- 新手引导
				end
			end
    elseif eventType == "cellSelected" then
      if view and view:hasEventListenerByName(DisplayEvents.kSelectItem) then
				local evt = DisplayEvent.new(DisplayEvents.kSelectItem, a1, a2)
				view:dispatchEvent(evt)
			end
		end
		return nil
	end
	local size = CCSizeMake(width, height)
    local luaTableView = LuaTableView:createWithHandler(LuaEventHandler:create(tableViewDelegate), size)
    --
	
	if scrollOffset then
		luaTableView:setScrollOffset(scrollOffset)
	end
	
	if not otherData or not otherData.noScrollBar then	
		if not scrollSprite then
			scrollSprite = CCScale9Sprite:create( CCRectMake(0,0,0,0), "pic/scroll.png")
		end
		
		if not scrollBgSprite then
			scrollBgSprite = CCScale9Sprite:create( CCRectMake(0,0,0,0), "pic/scroll.png")
		end
		
		if scrollSprite then
			scrollSprite:setColor(ccc3(200, 159, 78))
			luaTableView:setScrollBar(scrollSprite)
			if scrollBgSprite then
				scrollBgSprite:setColor(ccc3(200, 159, 78))
				luaTableView:setScrollTrack(scrollBgSprite)
			end
			luaTableView:reloadData()
		end
	
	end
	
    --
	view = TableView.new(luaTableView)
	

	--hitarea
	local node = CocosObject:create()
	node.name = kHitAreaObjectName
	node.touchEnabled = false
	node.touchChildren = false
	view.alreadySetData = alreadySetData
	view.data = data
	view.hitArea = node
	view:addChild(node)
	view:setViewSize(size)
	view:setContentSize(size)
	view:setVerticalFillOrder(kCCTableViewFillTopDown)
	view.tableViewRenderer = tableViewRenderer
	--[[if view.data and g_enableTableViewCache then
		for i = 0 , #view.data - 1
		do
			view.refCocosObj:updateCellAtIndex(i)
		end
	end--]]
	if Get_ShareData("New_User_Guide_Running") == 1 then -- 新手引导禁止滚动
		view:setDragEnabled(false)
	end
	return view
end

--kTableViewVerticalFillOrder
function TableView:getVerticalFillOrder() return self.refCocosObj:getVerticalFillOrder() end
function TableView:setVerticalFillOrder(v) self.refCocosObj:setVerticalFillOrder(v) end

function TableView:updateCellAtIndex(v) self.refCocosObj:updateCellAtIndex(v) end
function TableView:insertCellAtIndex(v) self.refCocosObj:insertCellAtIndex(v) end
function TableView:removeCellAtIndex(v) self.refCocosObj:removeCellAtIndex(v) end

function TableView:reloadData(v) 
	for k,v in pairs(self.alreadySetData)
	do
		self.alreadySetData[k] = false;
	end
	self.refCocosObj:reloadData(v) 
	--[[if self.data then
		for i = 0 , #self.data - 1
		do
			self.refCocosObj:updateCellAtIndex(i)
		end
	end--]]
end

function TableView:cellAtIndex(v) return self.refCocosObj:cellAtIndex(v) end
function TableView:dequeueCell(v) self.refCocosObj:dequeueCell(v) end

function TableView:isBounceable() return self.refCocosObj:isBounceable() end
function TableView:setBounceable(v) self.refCocosObj:setBounceable(v) end
function TableView:setTouchEnabled(v) self.refCocosObj:setTouchEnabled(v) end
function TableView:setPageEnabled(v) self.refCocosObj:setPageEnabled(v) end
function TableView:setDragEnabled(v) self.refCocosObj:setDragEnabled(v) end

--Sets a new content offset. It ignores max/min offset. It just sets what's given. (just like UIKit's UIScrollView)
--void setContentOffset(CCPoint offset, bool animated = false);
function TableView:getContentOffset() return self.refCocosObj:getContentOffset() end
function TableView:setContentOffset(offset, animated) self.refCocosObj:setContentOffset(offset) end

function TableView:setContentOffsetInDuration(offset, dt) self.refCocosObj:setContentOffsetInDuration(offset, dt) end
function TableView:setScrollViewAnimationParemeter(scrollDeaccelRate, 
													scrollDeaccelDist, 
													bounceDuration, 
													insetRatio, 
													moveInch) 
	self.refCocosObj:setScrollViewAnimationParemeter(scrollDeaccelRate, 
													scrollDeaccelDist, 
													bounceDuration, 
													insetRatio, 
													moveInch) 
end

--CCScrollViewDirection
function TableView:getDirection() return self.refCocosObj:getDirection() end
function TableView:setDirection(v) self.refCocosObj:setDirection(v) end

function TableView:isDragging() return self.refCocosObj:isDragging() end
--Determines if a given node's bounding box is in visible bounds
function TableView:isNodeVisible(node) return self.refCocosObj:isNodeVisible(node) end
function TableView:isTouchMoved() return self.refCocosObj:isTouchMoved() end

--CCSize
--size to clip. CCNode boundingBox uses contentSize directly.
function TableView:getViewSize() return self.refCocosObj:getViewSize() end
function TableView:setViewSize(v) 
	self.refCocosObj:setViewSize(v) 
	if self.hitArea then self.hitArea:setContentSize(CCSizeMake(v.width, v.height)) end
end

------------------------------------------------------------------------------------------------------------------------------------------add by zheng.che

--------------------------------------------
 -- 设置可拖拽触发上下拉伸
 -- dragUpCallback 向下拉伸超出一定程度时触发函数(用于显示上方内容)
 -- dragUpCallback 向上拉伸超出一定程度时触发函数(用于显示下方内容)
 -- drag_height 拉伸触发函数的像素程度 一般可设为一个cell的高度
--------------------------------------------
function TableView:setDragable(dragUpCallback, dragDownCallback, drag_height)
	if not self.onCheckDragPosition then
		function onCheckDragPosition()
			if not self.dragTouched then
				return
			end

			local currentPosition = self:getContentOffset().y
			local item_height = self.tableViewRenderer.height
			local randerList = self.tableViewRenderer.list
			local table_height = self:getViewSize().height

			-- print("checkTablePosition! currentPosition = " .. currentPosition)
			-- print("checkTablePosition! item_height = " .. item_height)
			-- print("checkTablePosition! drag_height = " .. drag_height)
			-- print("checkTablePosition! table_height = " .. table_height)
			-- print("checkTablePosition! #randerList = " .. #randerList)
			if currentPosition > drag_height then
				if (item_height * #randerList) < table_height then
					--显示内容不够一屏
					if currentPosition > (table_height - (item_height * #randerList) + drag_height) then
						--print("(table_height - (item_height * #randerList) + drag_height) = " .. (table_height - (item_height * #randerList) + drag_height))
						if dragDownCallback then
							if not self.pauseDrag then
								self.pauseDrag = true
								dragDownCallback()
							end
						end
					else
						--回归正常
						self.pauseDrag = false
					end
				else
					--显示内容超过一屏
					if dragDownCallback then
						if not self.pauseDrag then
							self.pauseDrag = true
							dragDownCallback()
						end
					end
				end
			else
				local currentOffect = currentPosition + item_height * #randerList - table_height
				if currentOffect < -drag_height then
					if dragUpCallback then
						if not self.pauseDrag then
							self.pauseDrag = true
							dragUpCallback()
						end
					end
				else
					--回归正常
					self.pauseDrag = false
				end
			end
		end
		self.onCheckDragPosition = onCheckDragPosition
	end

	if not self.onListITouchBegin then
		function onListITouchBegin(evt)
			self.dragTouched = true
		end
		self.onListITouchBegin = onListITouchBegin
	end

	if not self.onListITouchEnd then
		function onListITouchEnd(evt)
			self.dragTouched = false
		end
		self.onListITouchEnd = onListITouchEnd
	end

	if not self.checkTablePositionTimer then --计时器不存在时创建
		self.pauseDrag = false
		self.checkTablePositionTimer = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(self.onCheckDragPosition, 0, false)
		self:addEventListener(DisplayEvents.kTouchBegin, self.onListITouchBegin , self)
		self:addEventListener(DisplayEvents.kTouchEnd, self.onListITouchEnd , self)
	end
end

--------------------------------------------
 -- 取消触发上下拉伸
--------------------------------------------
function TableView:clearDragable()
	if self.checkTablePositionTimer then
		CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.checkTablePositionTimer)
	end
end

--------------------------------------------
 -- 自动拉伸至最后一条的位置
--------------------------------------------
function TableView:gotoBottom()
	local yPosition = 0

	local item_height = self.tableViewRenderer.height
	local randerList = self.tableViewRenderer.list
	local table_height = self:getViewSize().height

	if (item_height * #randerList) < table_height then
		--整个列表不足一屏
		yPosition = item_height * #randerList - table_height
	end

	self:setContentOffset(ccp(0, -yPosition), false)
end

--------------------------------------------
 -- 自动拉伸至最后一条的位置
--------------------------------------------
function TableView:hitTestPoint(worldPosition, useGroupTest)
	return false -- 修复遮挡下方按钮的bug
end