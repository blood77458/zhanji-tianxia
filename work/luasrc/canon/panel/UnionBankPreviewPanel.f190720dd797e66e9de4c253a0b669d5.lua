require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()
local table_width = 686
local table_height = 870
local table_posX = 30
local table_posY = 158
local item_width = 676
local item_height = 270
local cellScaleX = 0.99
local scrollOffsets = -30
--
-- UnionBankPreviewPanel
--

UnionBankPreviewPanel = class(Layer)

function UnionBankPreviewPanel:ctor()
	self.container = nil
	self.dataList = nil
end

function UnionBankPreviewPanel:create( container )
	local s = UnionBankPreviewPanel.new()
	s:initLayer(container)
	return s
end

function UnionBankPreviewPanel:initLayer(container)
	UnionBankPreviewPanel.super.initLayer(self)
	self.container = container
	self.dataList = {}
  for _, aBankConfig in pairs(MetaManager.union_building_bank) do
    local temp = {}
    temp.level = aBankConfig.level
    temp.rewards = {}
    local aRewardPackageConfig = MetaManager.reward_package[aBankConfig.rewardId]
    for i = 1, 4 do
      local aItemType = aRewardPackageConfig[string.format("content%dType", i)]
      local aItemId = aRewardPackageConfig[string.format("content%dId", i)]
      local aItemAmount = aRewardPackageConfig[string.format("content%dAmount", i)]
      if (aItemType == 0) then
        break
      else
        local aReward = {}
        aReward.itemType = aItemType
        aReward.itemId = aItemId
        local aName = ""
        if aItemType == ResourceEnum.COIN then
          aName = Localization:getInstance():getText("resource_silverCoin")
        elseif aItemType == ResourceEnum.GEMS then
          aName = Localization:getInstance():getText("resource_goldCoin")
        elseif aItemType == ResourceEnum.CARD then
          local aCardMetaConfig = MetaManager.card_meta[aItemId]
          aName = Localization:getInstance():getText(aCardMetaConfig.name)
        elseif aItemType == ResourceEnum.EQUIP then
          local aEquipMetaConfig = MetaManager.equip_meta[aItemId]
          aName = Localization:getInstance():getText(aEquipMetaConfig.name)
        elseif aItemType == ResourceEnum.PROP then
          local aPropMetaConfig = MetaManager.prop_meta[aItemId]
          aName = Localization:getInstance():getText(aPropMetaConfig.name)
        elseif aItemType == ResourceEnum.CARD_FRAGMENT then
          local cardMetaId = MetaManager.card_fragment_meta[aItemId].cardId
          aName = Localization:getInstance():getText(MetaManager.card_meta[cardMetaId].name)
        elseif aItemType == ResourceEnum.EQUIP_FRAGMENT then
          local equipMetaId = MetaManager.equip_fragment_meta[aItemId].equipId
          aName = Localization:getInstance():getText(MetaManager.equip_meta[equipMetaId].name)
        elseif aItemType == ResourceEnum.RP_VALUE then
          aName = Localization:getInstance():getText("gacha_rpNum")
        end
        aName = aName .. "x" .. aItemAmount
        aReward.itemName = aName
        table.insert(temp.rewards, aReward)
      end
    end
    temp.name = Localization:getInstance():getText("union_bank_salary_remind_text", {num = temp.level})
    table.insert(self.dataList, temp)
  end
  table.sort(self.dataList, function(a, b)
      return a.level < b.level
    end
  )
  
  self.pre_container_targetInfoPanel = self.container.targetInfoPanel
  self.container.targetInfoPanel = self
  
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
  self.panelUI = builder:build("popup_guild_bank") 
  self.tempLayer:addChild(self.panelUI)
  
  local function closeButtonSelected(evt)
    self:dismissSelf()
  end
	local closeButton = Button:create(self.panelUI:getChildByName("btn_close"))
	closeButton:addEventListener(Events.kStart, closeButtonSelected, self)

	self.tableView = self:createPreviewTableView()
	self.panelUI:addChild(self.tableView)
  self.tableView:reloadData()
  
  self.tempLayer:setScale(0.1)
end

function UnionBankPreviewPanel:createPreviewTableView()
	local cellTag = 1024
	local buttonTag = {}
	local aListPanel = self
	local UnionBankPreviewTableViewRenderer = class(TableViewRenderer)
	function UnionBankPreviewTableViewRenderer:ctor(width, height)
		self.list = aListPanel.dataList or {}
	end
	function UnionBankPreviewTableViewRenderer:buildCell(container)
		local builder = LayoutBuilder:createWithContentsOfFile("scene/guild.json")
		builder.useArtLabelTTF = true
		local aCell = builder:build("list_guild_bank_pay")
		aCell:setScaleX(cellScaleX)
		container:addChild(aCell)
		aCell:setTag(cellTag)
    
		local aNameLabel = aCell:getChildByName("txt_bank_list_title")
		aNameLabel:setTag(-10)
		aNameLabel = aNameLabel:getChildByName("txt")
		aNameLabel:setTag(-10)
    
    for i = 1, 4 do
      local aCardDisplay = aCell:getChildByName(string.format("guild_bank_item%d", i))
      aCardDisplay:setTag(-10-i)
      local aCard = aCardDisplay:getChildByName("normal_card_small")
      aCard:setTag(-10)
      aCard:setVisible(false)
      local aNameLabel = aCardDisplay:getChildByName("txt_bank_item_name")
      aNameLabel:setTag(-11)
      aNameLabel = aNameLabel:getChildByName("txt")
      aNameLabel:setTag(-10)
    end
	end

	function UnionBankPreviewTableViewRenderer:setData( rawCocosObj, index )
		local aCell = self:getChildByTag(rawCocosObj, cellTag)
		local aData = self.list[index + 1]
    
    for i = 1, 4 do
      local aCardDisplay = aCell:getChildByTag(-10-i)
      local icon = aCardDisplay:getChildByTag(-20)
      if icon then
        icon:removeFromParentAndCleanup(true)
      end
    end
    
    local aNameLabel = aCell:getChildByTag(-10)
    setNodeText(aNameLabel:getChildByTag(-10), aData.name)
    
    for i = 1, 4 do
      local aCardDisplay = aCell:getChildByTag(-10-i)
      if aData.rewards[i] then
        aCardDisplay:setVisible(true)
        local aCard = aCardDisplay:getChildByTag(-10)
        local aNameLabel = aCardDisplay:getChildByTag(-11)
        setNodeText(aNameLabel:getChildByTag(-10), aData.rewards[i].itemName)
        local params = {sourceSizes = {130*1/cellScaleX,130}}
        params.sourceDisplay = aCard
        params.container = aCardDisplay
        params.showInCenter = true
        params.zindex = 5
		
        local icon = CanonGoodIcon.createGoodIcon(aData.rewards[i].itemType, aData.rewards[i].itemId, 0, params)
        if icon then
          icon:setTag(-20)
          icon:dispose()
        end
      else
        aCardDisplay:setVisible(false)
      end
    end
  end

	local renderer = UnionBankPreviewTableViewRenderer.new(item_width, item_height)
	local aTableView = TableView:create(renderer, table_width, table_height, cellTag, buttonTag, CCScale9Sprite:create("pic/scroll.png"), CCScale9Sprite:create("pic/scroll.png"),nil,scrollOffsets)
	aTableView:setPosition(ccp(table_posX, table_posY))
  
	return aTableView
end

function UnionBankPreviewPanel:scaleIn()
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

function UnionBankPreviewPanel:dismissSelf()
  if type(self.container.panelDismiss) == "function" then
    self.container:panelDismiss()
  end
  self.container.targetInfoPanel = self.pre_container_targetInfoPanel
  self:removeFromParentAndCleanup(true)
end
