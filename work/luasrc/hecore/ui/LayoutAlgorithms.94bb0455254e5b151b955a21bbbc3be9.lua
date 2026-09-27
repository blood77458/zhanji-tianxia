kLayoutAlgorithm = {kAbsolute = "absolute", kLinear = "linear", kTile = "tile"}
kLayoutDirection = {kVertical = "vertical", kHorizontal = "horizontal"}
kVerticalLayoutAlignment = {kVerticalTop = "top", kVerticalCenter = "center", kVerticalBottom = "bottom"}
kHorizontalLayoutAlignment = {kHorizontalLeft = "left", kHorizontalCenter = "center", kHorizontalRight = "right"}

local function getFormatedPercentage( src )
	if type(src) == "string" then
		local length = string.len(src)
		if length <= 0 then return 0, false
		else
			local ended = string.byte(src, length)
			--char code of 37 is '%'
			if ended == 37 then
				local sub = string.sub(src, 1, -2)
				return tonumber(sub), true
			else return tonumber(src), false end
		end
	end
	if type(src) == "number" then return src, false end
	return 0, false
end

local function getPercentSize( parentSize, value )
	local val, percent = getFormatedPercentage(value)
	if percent then val = parentSize * val * 0.01 end
	return val
end

local function absoluteLayout( element, config )
end 

local function linearLayout( element, config )
	local contentSize = element:getContentSize()
	local direction = config.direction or kLayoutDirection.kHorizontal
	local vAlign = config.vAlign or kVerticalLayoutAlignment.kVerticalTop
	local hAlign = config.hAlign or kHorizontalLayoutAlignment.kHorizontalLeft
	local vGap = getPercentSize(contentSize.width, config.vGap) or 5
	local hGap = getPercentSize(contentSize.height, config.hGap) or 5

	local px, py = 0,0
	local totalWidth, totalHeight = 0,0
	for i,v in ipairs(element.list) do
		local itemSize = v:getContentSize()
		local anchor = v:getAnchorPoint()
		if direction == kLayoutDirection.kHorizontal then
			px = px + itemSize.width * anchor.x
			if vAlign == kVerticalLayoutAlignment.kVerticalTop then 
				py = contentSize.height - itemSize.height + itemSize.height * anchor.y
			elseif vAlign == kVerticalLayoutAlignment.kVerticalCenter then
				py = (contentSize.height - itemSize.height) / 2 + itemSize.height * anchor.y
			elseif vAlign == kVerticalLayoutAlignment.kVerticalBottom then
				py = itemSize.height * anchor.y
			end
			v:setPositionXY(px, py)
			px = px + itemSize.width + hGap - itemSize.width * anchor.x
			totalWidth = totalWidth + itemSize.width
		else
			py = py + itemSize.height * anchor.y
			if hAlign == kHorizontalLayoutAlignment.kHorizontalRight then
				px = contentSize.width - itemSize.width + itemSize.width * anchor.x
			elseif hAlign == kHorizontalLayoutAlignment.kHorizontalCenter then
				px = (contentSize.width - itemSize.width) / 2 + itemSize.width * anchor.x
			elseif hAlign == kHorizontalLayoutAlignment.kHorizontalLeft then
				px = itemSize.width * anchor.x
			end
			v:setPositionXY(px, py)
			py = py + itemSize.height + vGap - itemSize.height * anchor.y
			totalHeight = totalHeight + itemSize.height
		end
	end

	local totalChildren = #element.list - 1
	totalWidth = totalWidth + hGap * totalChildren
	totalHeight = totalHeight + vGap * totalChildren

	local ox, oy = 0,0
	if direction == kLayoutDirection.kHorizontal then
		if hAlign == kHorizontalLayoutAlignment.kHorizontalCenter then
			ox = (contentSize.width - totalWidth)/2
		elseif hAlign == kHorizontalLayoutAlignment.kHorizontalRight then
			ox = contentSize.width - totalWidth
		end
	else
		if vAlign == kVerticalLayoutAlignment.kVerticalCenter then
			oy = (contentSize.height - totalHeight) / 2
		elseif vAlign == kVerticalLayoutAlignment.kVerticalTop then
			oy = contentSize.height - totalHeight
		end
	end

	for i,v in ipairs(element.list) do
		local position = v:getPosition()
		v:setPositionXY(position.x + ox, position.y + oy)
	end
end 

local function tiledLayout( element, config )
	local contentSize = element:getContentSize()
	local vAlign = config.vAlign or kVerticalLayoutAlignment.kVerticalTop
	local hAlign = config.hAlign or kHorizontalLayoutAlignment.kHorizontalLeft
	local vGap = getPercentSize(contentSize.height, config.vGap) or 5
	local hGap = getPercentSize(contentSize.width, config.hGap) or 5

	local itemWidth, itemWidthPercent = getPercentSize(contentSize.width, config.itemWidth) or 50, false
	local itemHeight, itemHeightPercent = getPercentSize(contentSize.height, config.itemHeight) or 50, false
	if itemWidthPercent then itemWidth = contentSize.width * itemWidth * 0.01 end
	if itemHeightPercent then itemHeight = contentSize.height * itemHeight * 0.01 end

	local children = element.list
	local totalChildren = #element.list
	local ix = math.floor(contentSize.width/(itemWidth + hGap))
	local iy = math.floor(contentSize.height/(itemHeight + vGap))
	if ix < 1 then ix = 1 end
	if iy < 1 then iy = 1 end

	local totalWidth = itemWidth * ix + hGap * (ix - 1)
	local totalHeight = itemHeight * iy + vGap * (iy - 1)

	local offsetX, offsetY = 0, 0
	if hAlign == kHorizontalLayoutAlignment.kHorizontalCenter then
		offsetX = (contentSize.width - totalWidth) / 2
	elseif hAlign == kHorizontalLayoutAlignment.kHorizontalRight then
		offsetX = contentSize.width - totalWidth
	end

	if vAlign == kVerticalLayoutAlignment.kVerticalCenter then
		offsetY = (contentSize.height - totalHeight) / 2
	elseif vAlign == kVerticalLayoutAlignment.kVerticalTop then
		offsetY = contentSize.height - totalHeight
	end

	print(ix, iy, itemWidth, itemHeight, hGap, vGap, "|", contentSize.width, contentSize.height, "|", totalWidth, totalHeight, offsetX, offsetY)
	--offsetX, offsetY = 0, 0

	local k = 1
	for i = iy - 1, 0, -1 do
		for j = 0, ix - 1 do
			if k <= totalChildren then
				local child = children[k]
				local childSize = child:getContentSize()
				local childAnchor = child:getAnchorPoint()
				local x = j * (itemWidth + hGap)
				local y = i * (itemHeight + vGap)

				if hAlign == kHorizontalLayoutAlignment.kHorizontalLeft then
					x = x + childSize.width * childAnchor.x
				elseif hAlign == kHorizontalLayoutAlignment.kHorizontalCenter then
					x = x + (itemWidth - childSize.width)/2 + childSize.width * childAnchor.x
				elseif hAlign == kHorizontalLayoutAlignment.kHorizontalRight then
					x = x + itemWidth - childSize.width + childSize.width * childAnchor.x
				end

				if vAlign == kVerticalLayoutAlignment.kVerticalTop then
					y = y + itemHeight - childSize.height + childSize.height * childAnchor.y
				elseif vAlign == kVerticalLayoutAlignment.kVerticalCenter then
					y = y + (itemHeight - childSize.height)/2 + childSize.height * childAnchor.y
				elseif vAlign == kVerticalLayoutAlignment.kVerticalBottom then
					y = y + childSize.height * childAnchor.y
				end
				
				child:setPositionXY(x + offsetX, y + offsetY)
			else break end
			k = k + 1
		end
	end
end 

local Algorithms= {}
Algorithms.layout = function ( element, config )
	local algorithm = config.type or kLayoutAlgorithm.kAbsolute
	if algorithm == kLayoutAlgorithm.kAbsolute then absoluteLayout(element, config)
	elseif algorithm == kLayoutAlgorithm.kLinear then linearLayout(element, config)
	elseif algorithm == kLayoutAlgorithm.kTile then tiledLayout(element, config) end
end
return Algorithms