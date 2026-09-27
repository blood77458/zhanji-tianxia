require "hecore.display.CocosObject"
require "hecore.display.Director"
require "hecore.display.Scene"
require "hecore.ui.LayoutBuilder"
require "canon.scene.LoadingScene"
require "canon.customUI/CanonCard"
require "canon.scene.BaseUIScene"
require "canon.panel.CombineSuccessPanel"

require "canon.request.SynthetizeItemRequest"

CombineScene = class(BaseUIScene)
local visibleSize = CCSizeMake(720, 1280)

local function getMiddlePositionByName(cell, posName)
	local posX, posY = cell:getChildByName(posName):getPositionX(), cell:getChildByName(posName):getPositionY()
	return posX , posY + 5
end

local function addNodeReplaceWithName(cell, posName, node, replaceName)
	local previousSprite = cell:getChildByName(replaceName)
	if previousSprite then
		previousSprite:removeFromParentAndCleanup(true)
	end
	node.name = replaceName
	node:setPositionXY(getMiddlePositionByName(cell, posName))
	local zOrder = cell:getChildByName(posName):getZOrder()
	cell:addChild(node, zOrder + 1)
end

function CombineScene:ctor()
	self.title = getTextByKey("home_synthetizeBtn")
	self.curIndex = 1;
	self.materialEnought = false
end

function CombineScene:create( argv )
    if argv then 
        self.argv = argv 
    else
        self.argv = {enterScene=nil,returnScene=nil,params={}}
    end
    
    local scene = CombineScene.new()
		
    scene:initScene()
    return scene
end

function CombineScene:onInit()	
	BaseUIScene.initBackGround(self)
	self.builder = LayoutBuilder:createWithContentsOfFile("scene/book_combine.json")
	self.builder.useArtLabelTTF = true
	
	self.mainUI = self.builder:build("book_combine")
	self.data = table.clone(MetaManager.item_synthetize, true)
	self.materialHave = {}
	for k, data in pairs(self.data) do
		for i = 1, 4 do
			if data["material" .. i .. "Amount"] > 0 then
				local propId = data["material" .. i .. "Id"]
				local haveAmount = 0
				for kk, vv in pairs(DataManager.getPropsData()) do
					if vv.metaId == propId then
						haveAmount = vv.amount
						break;
					end
				end
				self.materialHave[propId] = haveAmount
			end
		end
	end
	self.headTableView = self:createHeadTableView(self.data)
	self.mainUI:addChild(self.headTableView,10)
	
	self.mainUI:getChildByName("book_combine_item"):setVisible(false)
	self.mainUI:getChildByName("book_combine_item2"):setVisible(false)
	
	local combineSprite = self.mainUI:getChildByName("book_combine_item3")
	combineSprite:getChildByName("normal_card_small"):setVisible(false)
	combineSprite:getChildByName("bg_shining_item"):setVisible(false)
	
	for i = 1, 4 do
		local combineSprite = self.mainUI:getChildByName("book_combine_item2_" .. i)
		combineSprite:getChildByName("normal_card_small"):setVisible(false)
		combineSprite:getChildByName("bg_shining_item"):setVisible(false)
	end
	
	local function onClickCombine(evt)
		self:sendCombineRequest(self.data[self.curIndex])
	end
	
	self.combineButton = Button:create(self.mainUI:getChildByName("btn_do_combine"))
	self.combineButton:addEventListener(Events.kStart, onClickCombine)
	self.combineButton.display:getChildByName("txt"):setString(getTextByKey("synthetize_synthetizeBtn"))
	
	self:refreshUI(self.curIndex, true)
	
	self:addChild(self.mainUI)
	BaseUIScene.onInit(self)

end

function CombineScene:sendCombineRequest(combineData)
	if not self.materialEnought then
		local eliteInfo = EliteManager.getMaterialSrc(self.lackPropId) 
		if (eliteInfo.eliteMissionId == 0) then
			CanonMessageBox.showText(
			ShowButtonType.ID_OK,
			getTextByKey("skill_MaterialShortText_cannotBuy")
		)
		else
			local aPanel = MessageBoxPanel:create(self, MessageBoxType.kEquipEvolvePropLimit, {eliteInfo = eliteInfo})
			self:addChild(aPanel)
			aPanel:scaleIn()
		end
		do return end
	end
	
	if BagCalcManager.isFull() then
		local function closeCanonMessageBox()
		end
		self.targetInfoPanel = NewPackageFullPanel:show()
		do return end
	end

	if self.waitResponse then
		do return end
	end
		
		
	local function onSynthetizeItemSucceed(evt)
		self.waitResponse = false
		
		local flash = FlashSprite:create("EVO2/book_combine")
		local flash_co = CocosObject.new(flash)
		local aMeta = MetaManager.prop_meta[combineData.productId]
		
		local name = aMeta["iconName"]			
    local len = string.len(tostring(aMeta["quality"]))
    name = string.sub(name,1,string.len(name)-len) 
		name = "Item/Picture/" .. name .. "0.png"
		flash:addChangeInstance("icon", createSpriteFrame(name))
		flash:changeAnimation(0)
		flash:setLoop(false)
		flash_co:setPositionY(20)
		self:setTableViewsEnabled(false)
		self.previousTargetInfoPanel = self.targetInfoPanel
		self.targetInfoPanel = true
		local function onFlashAnimationEnd(index)
			if flash then
				flash:unregisterEndAnimationScriptHandler()
			end
			if flash_co then
				flash_co:removeFromParentAndCleanup(true)
			end
			self:setTableViewsEnabled(true)
			self.targetInfoPanel = self.previousTargetInfoPanel
			local itemData = DataManager.getPropsData()
			for i = 1, 4 do
				local metaId = combineData["material" .. i .. "Id"]
				local amount = combineData["material" .. i .. "Amount"]
				for k, v in pairs(itemData) do
					if v.metaId == metaId then
						v.amount = v.amount - amount
						if v.amount < 0 then
							v.amount = 0
						end
						
						self.materialHave[metaId] = v.amount
						break;
					end
				end
			end
			
			DataManager.setPropsData(itemData)
			
			local productId = combineData.productId
			local productAmount = combineData.productAmount		
			RewardManager:getReward({{itemType = ResourceEnum.PROP, metaId = productId, amount = productAmount}})
			if not self.materialHave[productId] then
				self.materialHave[productId] = 0
			end
			self.materialHave[productId] = self.materialHave[productId] + productAmount

			self:refreshUI(self.curIndex, true)
			
			self.targetInfoPanel = CombineSuccessPanel:create(self, addNodeReplaceWithName,  combineData)
			PopoutManager:sharedManager():popout(self.targetInfoPanel, kPopoutDir.kScale, true, false ,self)
		end
		flash:registerEndAnimationScriptHandler(onFlashAnimationEnd)
		self.mainUI:addChild(flash_co)
	end
		
	local function onSynthetizeItemFailed(evt)
		self.waitResponse = false
		if evt.data == 710516 then
			local function closeCanonMessageBox()
			end
			self.targetInfoPanel = NewPackageFullPanel:show()
		elseif evt.data == 712301 then
			local function closeCanonMessageBox()
			end
			self.targetInfoPanel = CanonMessageBox:Show(getTextByKey("synthetize_materialInsufficient"), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox)
		else
			CanonMessageBox:showCommUnHandleErrorBox(evt.data)
		end
	end
		
	self.waitResponse = true
	local request = SynthetizeItemRequest.new( {formulaId = combineData.id}, rpc.SendingPriority.kHigh )
	request:addEventListener( RequestNotifyEnum.SynthetizeItemSucceed, onSynthetizeItemSucceed )
	request:addEventListener( RequestNotifyEnum.SynthetizeItemFailed, onSynthetizeItemFailed )
	request:start()
	
end

function CombineScene:refreshUI(index, forceRefresh)
	if index == self.curIndex and not forceRefresh then
		do return end
	end
	self.curIndex = index
	local combineData = self.data[index]
	
	local combineSprite = self.mainUI:getChildByName("book_combine_item3")
	local amount = combineData["productAmount"]
	addNodeReplaceWithName(combineSprite, "normal_card_small", getCanonItemByMetaId(combineData.productId), "realInfo")
	combineSprite:getChildByName("txt_book_combine_3"):getChildByName("txt"):setString("X" .. tostring(amount))
	combineSprite:getChildByName("txt_book_combine_2"):getChildByName("txt"):setString(getTextByKey(MetaManager.prop_meta[combineData.productId].name))
	self.materialEnought = true
	self.lackPropId = nil;
	for i = 1, 4 do
		local amount = combineData["material" .. i .. "Amount"]
		local combineSprite = self.mainUI:getChildByName("book_combine_item2_" .. i)
		local arrowSprite = self.mainUI:getChildByName("icon_at_combine" .. i)
		arrowSprite:stopAllActions()
		if amount <= 0 then
			combineSprite:setVisible(false)
			arrowSprite:setVisible(false)
			local previousSprite = combineSprite:getChildByName("realInfo")
			if previousSprite then
				previousSprite:removeFromParentAndCleanup(true)
			end
		else
			combineSprite:setVisible(true)
			arrowSprite:setVisible(true)
			local propId = combineData["material" .. i .. "Id"]
			local haveAmount = self.materialHave[propId]
			if not haveAmount then
				haveAmount = 0
			end
			addNodeReplaceWithName(combineSprite, "normal_card_small", getCanonItemByMetaId(propId), "realInfo")
		
			combineSprite:getChildByName("txt_book_combine_1"):getChildByName("txt"):setString( tostring(haveAmount) .. "/" .. tostring(amount))
			combineSprite:getChildByName("txt_book_combine_2"):getChildByName("txt"):setString(getTextByKey(MetaManager.prop_meta[propId].name))
			if haveAmount < amount then
				combineSprite:getChildByName("txt_book_combine_1"):getChildByName("txt"):setColor(ccc3(255, 0, 0))
				for k, v in pairs(combineSprite:getChildByName("realInfo").list) do
					if type(v.setColor) == "function" then
						v:setColor(ccc3(180, 180, 180))
					end
				end
				self.materialEnought = false
				if not self.lackPropId then
					self.lackPropId = propId
				end
			else
				combineSprite:getChildByName("txt_book_combine_1"):getChildByName("txt"):setColor(ccc3(89, 188, 62))
				for k, v in pairs(combineSprite:getChildByName("realInfo").list) do
					if type(v.setColor) == "function" then
						v:setColor(ccc3(255, 255, 255))
					end
				end
			end
		end
	end
	
	if combineData.coinCost > tonumber(DataManager.getCurrUser().coins) then
		self.combineButton:setEnable(false)
		self.combineButton.display:getChildByName("btn"):setVisible(false)
	else
		self.combineButton:setEnable(true)
		self.combineButton.display:getChildByName("btn"):setVisible(true)
	end
	
	self:refreshTable(true)
	
end

function CombineScene:refreshTable(keepOffset)
	if keepOffset then
		local tableOffset = self.headTableView:getContentOffset()
		self.headTableView:reloadData()
		self.headTableView:setContentOffset(tableOffset, true)
	else
		self.headTableView:reloadData()
	end
end

local TABLEVIEW_CELL_TAG = -1001
local TXT_HEAD_NAME = 1001
local ICON_FAKE_HEAD = 1002
local ICON_REAL_HEAD = 1003
local ICON_SELECTED = 1004

local function inArea(posX, posY, rect)
	if posX >= rect.x and posX <= rect.x + rect.width and posY >= rect.y and posY <= rect.y + rect.height then
		return true
	end
	return false
end

local function setTextByTag( cell, tag, str)
	local txt = cell:getChildByTag(tag):getChildByTag(tag)
	setNodeText(txt, str);
end
	
local function setNodeVisibleByTag(cell, tag, visible)
	cell:getChildByTag(tag):setVisible(visible)
end

local function getMiddlePosition(cell, tag)
	local posX, posY = cell:getChildByTag(tag):getPosition()
	return ccp(posX, posY)
end

local function addNodeReplaceWithTag(cell, tag, node, nodeTag)
	if cell:getChildByTag(nodeTag) then
		cell:removeChildByTag(nodeTag, true)
	end
	node:setTag(nodeTag)
	node:setPosition(getMiddlePosition(cell, tag))
	local zOrder = cell:getChildByTag(tag):getZOrder()
	cell:addChild(node, zOrder)
end

function CombineScene:createHeadTableView(data)
	local CombineRenderer = class(TableViewRenderer)
	local SELF = self
	function CombineRenderer:ctor(width, height)
		self.list = data
		local builder = LayoutBuilder:createWithContentsOfFile("scene/book_combine.json")
		builder.useArtLabelTTF = true
		self.builder = builder
	end 

	function CombineRenderer:buildCell(container)
		local cell = self.builder:build("sb/book_combine_item")
		cell:setPosition(ccp(0, self.height - 30))		
		cell:setTag(TABLEVIEW_CELL_TAG)
		container:addChild(cell)
		
		cell:getChildByName("txt_item_name"):setTag(TXT_HEAD_NAME)
		cell:getChildByName("txt_item_name"):getChildByName("txt_item_name"):setTag(TXT_HEAD_NAME)
		cell:getChildByName("normal_card_small"):setTag(ICON_FAKE_HEAD)
		cell:getChildByName("normal_card_small"):setVisible(false)
		cell:getChildByName("bg_shining_item"):setTag(ICON_SELECTED)
	end

	function CombineRenderer:setData( rawCocosObj, index )
		local cell = self:getChildByTag(rawCocosObj, TABLEVIEW_CELL_TAG)

		local combineInfo = data[index + 1]
		setNodeVisibleByTag(cell, ICON_SELECTED, (index + 1 == SELF.curIndex))
		local combineSprite = getCanonItemByMetaId(combineInfo.productId)
		addNodeReplaceWithTag(cell, ICON_FAKE_HEAD, combineSprite.refCocosObj, ICON_REAL_HEAD)
		combineSprite:dispose()
		setTextByTag(cell, TXT_HEAD_NAME, getTextByKey(MetaManager.prop_meta[combineInfo.productId].name))
	end
	
	local renderer = CombineRenderer.new(180, 213)
  local list = TableView:create(renderer, 720, 213, TABLEVIEW_CELL_TAG, {}, nil, nil, nil, nil, {noScrollBar = true})
	list:setDirection(kCCScrollViewDirectionHorizontal)
	list:setPageEnabled(true)
	list:reloadData()
	local function onListItemTouch( evt ) 
		local selectedCell = list:cellAtIndex(evt.data):getChildByTag(TABLEVIEW_CELL_TAG)
		self._data = data[evt.data + 1]
		
		--refresh
		SELF:refreshUI(evt.data + 1)
		
		local posInCell = selectedCell:convertToNodeSpace(evt.globalPosition)
	end

  list:addEventListener(DisplayEvents.kTouchItem, onListItemTouch)
  list:setPosition(ccp(0, 840))
  return list
end

function CombineScene:dispose()
	BaseUIScene.dispose(self)
end

function CombineScene:doEnterAnimation()
  self:preEnterAnimation()
  self:startEnterAnimation()
end

function CombineScene:preEnterAnimation()
	CanonPlayBackgroundMusic("music/background.mp3", true)
  BaseUIScene.preEnterAnimation(self)
end

function CombineScene:startEnterAnimation()
  BaseUIScene.startEnterAnimation(self)
  local function enterActionFinished()
    self:nodeAnimationFinished()
  end
  self.mainUI:setPositionX(self.mainUI:getPositionX() - visibleSize.width)
  local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(0.3, ccp(visibleSize.width, 0)))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.mainUI:runAction(CCSequence:create(arr))
end

function CombineScene:sufEnterAnimation()
	BaseUIScene.sufEnterAnimation(self)
end

function CombineScene:doExitAnimation()
  self:preExitAnimation()
  self:startExitAnimation()
end

function CombineScene:preExitAnimation()
  BaseUIScene.preExitAnimation(self)
end

function CombineScene:startExitAnimation()
  BaseUIScene.startExitAnimation(self)
  local function enterActionFinished()
      self:nodeAnimationFinished()
  end
  local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(0.3, ccp(-visibleSize.width, 0)))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.mainUI:runAction(CCSequence:create(arr))	
end

function CombineScene:sufExitAnimation()
	BaseUIScene.sufExitAnimation(self)
end

function CombineScene:back()
	self:replaceScene(MainMenuScene)
end

function CombineScene:setTableViewsEnabled( v )
	if (v) then
		self.touchDisableSetTimes = self.touchDisableSetTimes - 1
		if (self.touchDisableSetTimes <= 0) then
			if self.headTableView then
				self.headTableView:setTouchEnabled(v)
			end
			self.mainUI:setTouchEnabled(v)
		end
	else
		self.touchDisableSetTimes = self.touchDisableSetTimes + 1
		if self.headTableView then
			self.headTableView:setTouchEnabled(v)
		end
		self.mainUI:setTouchEnabled(v)
	end
end