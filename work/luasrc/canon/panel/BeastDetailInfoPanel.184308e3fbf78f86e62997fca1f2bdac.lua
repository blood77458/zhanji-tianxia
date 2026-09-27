require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

BeastDetailInfoPanel = class(Layer)

function BeastDetailInfoPanel:ctor()
	self.container = nil
end

function BeastDetailInfoPanel:create( container, beastInfo)
	self.container = container
	self.beastInfo = beastInfo
	
	local s = BeastDetailInfoPanel.new()
	s:initLayer()
	return s
end

function BeastDetailInfoPanel:initLayer()
	self.container:setTableViewsEnabled(false)
	BeastDetailInfoPanel.super.initLayer(self)
	
	local builder = LayoutBuilder:createWithContentsOfFile("scene/rob.json")
	self.panelUI = builder:build("rob_info")
	
	local showLevel = self.beastInfo.level
	if showLevel < 1 then
		showLevel = 1
	end
	local levelText = Localization:getInstance():getText("beastSkillLevel", {num = showLevel})
	self.panelUI:getChildByName("txt_rob_info_lv"):getChildByName("txt"):setString(levelText)
	self.panelUI:getChildByName("txt_rob_info_1"):getChildByName("txt"):setString(getTextByKey(self.beastInfo.items[showLevel].beastSkillDesc))
	self.panelUI:getChildByName("btn_knock"):getChildByName("txt"):setString(getTextByKey("yes"))
	local titleText = Localization:getInstance():getText("beastSkillDesc_title", {beastname = getTextByKey(self.beastInfo.beastNameKey)})
	self.panelUI:getChildByName("txt_rob_info_title"):getChildByName("txt"):setString(titleText)
	
	self.panelUI:getChildByName("txt_rob_info_lv"):setVisible(false)
	self.panelUI:getChildByName("txt_rob_info_1"):setVisible(false)
	
	local function onClosePanel(evt)
		self.container:setTableViewsEnabled(true)
		self.container.targetInfoPanel = nil
		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
	end	 
	local bt_panel_close = Button:create(self.panelUI:getChildByName("btn_knock"))
	bt_panel_close:addEventListener(Events.kStart, onClosePanel)
	
	local bt_panel_close = Button:create(self.panelUI:getChildByName("btn_close"))
	bt_panel_close:addEventListener(Events.kStart, onClosePanel)
	
	local tableView = self:createBeastEffectTableView(self.beastInfo.items)
	
	self:addChild(self.panelUI)
	self:addChild(tableView)
	
	--[[local tableOffset = tableView:getContentOffset()
	tableOffset.y = tableOffset.y - 20
	tableView:setContentOffset(tableOffset, true)--]]
end

local TABLEVIEW_CELL_TAG = -1001
local TAG_NUM_LABEL = 1001
local TAG_DESC_LABEL = 1002

function BeastDetailInfoPanel:createBeastEffectTableView(data)
	local BeastEffectRenderer = class(TableViewRenderer)
	
	function BeastEffectRenderer:ctor(width, height)
		self.list = data
	end 

	function BeastEffectRenderer:buildCell(container)		
		local cell = Layer:create()
		cell:setPosition(ccp(0, self.height))
		cell:setTag(TABLEVIEW_CELL_TAG)
		container:addChild(cell)
		
		local levelLabel = TextField:create("", "Arial", 25)
		levelLabel:setTag(TAG_NUM_LABEL)
		levelLabel:setAnchorPoint(ccp(0, 1))
		levelLabel:setColor(ccc3(255, 255, 255))
		levelLabel:setPositionY(-20)
		cell:addChild(levelLabel)
		
		local descLabel = TextField:create("", "Arial", 25, CCSizeMake(480, 0))
		descLabel:setTag(TAG_DESC_LABEL)
		descLabel:setPositionX(80)
		descLabel:setPositionY(-20)
		descLabel:setAnchorPoint(ccp(0, 1))
		descLabel:setColor(ccc3(255, 255, 255))
		cell:addChild(descLabel)
	end
	
	local function setTextByTag( cell, tag, str)
		local txt = cell:getChildByTag(tag):getChildByTag(tag)
		setNodeText(txt, str);
	end
	
	local function setNodeVisibleByTag(cell, tag, visible)
		cell:getChildByTag(tag):setVisible(visible)
	end

	function BeastEffectRenderer:setData( rawCocosObj, index )
		local cell = self:getChildByTag(rawCocosObj, TABLEVIEW_CELL_TAG)
		local selectdata = data[index + 1]
		local levelText = Localization:getInstance():getText("beastSkillLevel", {num = selectdata.level})
		setNodeText(cell:getChildByTag(TAG_NUM_LABEL), levelText)
		setNodeText(cell:getChildByTag(TAG_DESC_LABEL), getTextByKey(selectdata.beastSkillDesc))
	end
	
	
	local renderer = BeastEffectRenderer.new(560, 55)
  local list = TableView:create(renderer, 530, 275, TABLEVIEW_CELL_TAG, {})

  list:setPosition(ccp(120, 530))
  return list
end
