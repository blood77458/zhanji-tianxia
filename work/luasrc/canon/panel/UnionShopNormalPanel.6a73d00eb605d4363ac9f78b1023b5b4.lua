require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()
local table_width = 714
local table_height = 715
local table_posX = 3
local table_posY = 130
local item_width = 702
local item_height = 228

--
-- UnionShopNormalPanel
--

UnionShopNormalPanel = class(Layer)

function UnionShopNormalPanel:ctor()
	self.container = nil
	self.dataList = nil
end

function UnionShopNormalPanel:create( container, tagIndex )
	local s = UnionShopNormalPanel.new()
	s:initLayer(container, tagIndex)
	return s
end

function UnionShopNormalPanel:initLayer(container, tagIndex)
	UnionShopNormalPanel.super.initLayer(self)
	self.container = container
	self.tagIndex = tagIndex
	self.dataList = UnionManager.getShopNormalInfoList()

	self.tableView = self:createNormalTableView()
	self:addChild(self.tableView)
  self.tableView:reloadData()
end

function UnionShopNormalPanel:createNormalTableView()
	local cellTag = 1024
	local buttonTag = {-15}
	local aListPanel = self
	local UnionShopNormalTableViewRenderer = class(TableViewRenderer)
	function UnionShopNormalTableViewRenderer:ctor(width, height)
		self.list = aListPanel.dataList or {}
	end
	function UnionShopNormalTableViewRenderer:buildCell(container)
		local builder = LayoutBuilder:createWithContentsOfFile("scene/guild.json")
		builder.useArtLabelTTF = true
		local aCell = builder:build("list_guild_shop")
		container:addChild(aCell)
		aCell:setTag(cellTag)
    
    aCell:getChildByName("icon_rare"):setVisible(false)
    
		local aNameLabel = aCell:getChildByName("txt_guild_31")
		aNameLabel:setTag(-10)
		aNameLabel = aNameLabel:getChildByName("txt")
		aNameLabel:setTag(-10)
    
    aCell:getChildByName("txt_guild_32"):getChildByName("txt"):setString(Localization:getInstance():getText("shop_quantity"))
    
		local aOwnNumLabel = aCell:getChildByName("txt_guild_29_2")
		aOwnNumLabel:setTag(-11)
		aOwnNumLabel = aOwnNumLabel:getChildByName("txt")
		aOwnNumLabel:setTag(-10)
    
    local aCardDisplay = aCell:getChildByName("normal_card_small")
		aCardDisplay:setTag(-12)
    aCardDisplay:setVisible(false)
    
    aCell:getChildByName("txt_guild_26"):getChildByName("txt"):setString(Localization:getInstance():getText("union_shop_item_contribute_cost"))
    
		local aPriceLabel = aCell:getChildByName("txt_guild_27")
		aPriceLabel:setTag(-13)
		aPriceLabel = aPriceLabel:getChildByName("txt")
		aPriceLabel:setTag(-10)
    
    local aLeftNumPrefixLabel = aCell:getChildByName("txt_guild_28")
    aLeftNumPrefixLabel:getChildByName("txt"):setString(Localization:getInstance():getText("union_shop_item_remain_player"))
    aLeftNumPrefixLabel:setTag(-17)
    
		local aLeftNumLabel = aCell:getChildByName("txt_guild_29")
		aLeftNumLabel:setTag(-14)
		aLeftNumLabel = aLeftNumLabel:getChildByName("txt")
		aLeftNumLabel:setTag(-10)
    
    local aLeftNumSuffixLabel = aCell:getChildByName("txt_guild_30")
    aLeftNumSuffixLabel:getChildByName("txt"):setString(Localization:getInstance():getText("union_shop_item_unit"))
    aLeftNumSuffixLabel:setTag(-18)
    
    local aUnlockLabel = aCell:getChildByName("txt_guild_33")
		aUnlockLabel:setTag(-16)
		aUnlockLabel = aUnlockLabel:getChildByName("txt")
		aUnlockLabel:setTag(-10)

		local aExchangeBtnDisplay = aCell:getChildByName("btn_guildoption")
		aExchangeBtnDisplay:setTag(-15)
		aExchangeBtnDisplay:getChildByName("txt"):setString(Localization:getInstance():getText("union_shop_buy_button_text"))
		aExchangeBtnDisplay:getChildByName("btn"):setTag(-10)
    aExchangeBtnDisplay:getChildByName("btn_inactive"):setTag(-11)
	end

	function UnionShopNormalTableViewRenderer:setData( rawCocosObj, index )
		local aCell = self:getChildByTag(rawCocosObj, cellTag)
		local aData = self.list[index + 1]
    
    local icon = aCell:getChildByTag(-20)
    if icon then
      icon:removeFromParentAndCleanup(true)
    end
    
    local aShopSpecialConfig = aData
    
    local aNameLabel = aCell:getChildByTag(-10)
    local aOwnNumLabel = aCell:getChildByTag(-11)
    local aCardDisplay = aCell:getChildByTag(-12)
    local aPriceLabel = aCell:getChildByTag(-13)
    local aLeftNumLabel = aCell:getChildByTag(-14)
    local aExchangeBtnDisplay = aCell:getChildByTag(-15)
    local aUnlockLabel = aCell:getChildByTag(-16)
    setNodeText(aPriceLabel:getChildByTag(-10), tostring(aShopSpecialConfig.contributeCost))
    local aLeftNumPrefixLabel = aCell:getChildByTag(-17)
    local aLeftNumSuffixLabel = aCell:getChildByTag(-18)
    if aData.dailyPurchaseLimit < 0 then
      aLeftNumLabel:setVisible(false)
      aLeftNumPrefixLabel:setVisible(false)
      aLeftNumSuffixLabel:setVisible(false)
    else
      aLeftNumLabel:setVisible(true)
      aLeftNumPrefixLabel:setVisible(true)
      aLeftNumSuffixLabel:setVisible(true)
      local aLeftNum = aData.leftNum
      setNodeText(aLeftNumLabel:getChildByTag(-10), tostring(aLeftNum))
    end
    
    if aShopSpecialConfig.requireShopLevel <= UnionManager.getShopLevel() then
      aUnlockLabel:setVisible(false)
    else
      aUnlockLabel:setVisible(true)
      setNodeText(aUnlockLabel:getChildByTag(-10), Localization:getInstance():getText("union_shop_item_unlock_remind", {num = aShopSpecialConfig.requireShopLevel}))
    end
    setNodeText(aOwnNumLabel:getChildByTag(-10), tostring(UnionManager.getOwnNumWithTypeAndMetaId(aShopSpecialConfig.itemType, aShopSpecialConfig.metaId)))
    
    local aName
    if aShopSpecialConfig.itemType == ResourceEnum.CARD then
      local aCardMetaConfig = MetaManager.card_meta[aShopSpecialConfig.metaId]
      aName = Localization:getInstance():getText(aCardMetaConfig.name)
    elseif aShopSpecialConfig.itemType == ResourceEnum.EQUIP then
      local aEquipMetaConfig = MetaManager.equip_meta[aShopSpecialConfig.metaId]
      aName = Localization:getInstance():getText(aEquipMetaConfig.name)
    elseif aShopSpecialConfig.itemType == ResourceEnum.PROP then
      local aPropMetaConfig = MetaManager.prop_meta[aShopSpecialConfig.metaId]
      aName = Localization:getInstance():getText(aPropMetaConfig.name)
    elseif aShopSpecialConfig.itemType == ResourceEnum.CARD_FRAGMENT then
      local cardMetaId = MetaManager.card_fragment_meta[aShopSpecialConfig.metaId].cardId
      aName = Localization:getInstance():getText(MetaManager.card_meta[cardMetaId].name)
    elseif aShopSpecialConfig.itemType == ResourceEnum.EQUIP_FRAGMENT then
      local equipMetaId = MetaManager.equip_fragment_meta[aShopSpecialConfig.metaId].equipId
      aName = Localization:getInstance():getText(MetaManager.equip_meta[equipMetaId].name)
    end
    aName = aName .. "x" .. aShopSpecialConfig.amount
		setNodeText(aNameLabel:getChildByTag(-10), aName)
    
		local params = {}
		params.sourceDisplay = aCardDisplay
		params.container = aCell
    params.showInCenter = true
		params.zindex = 10

		icon = CanonGoodIcon.createGoodIcon(aShopSpecialConfig.itemType, aShopSpecialConfig.metaId, 0, params)
		if icon then
			icon:setTag(-20)
			icon:dispose()
		end
    
    if (aData.dailyPurchaseLimit > 0 and aData.leftNum <= 0) or (aShopSpecialConfig.requireShopLevel > UnionManager.getShopLevel()) then
      aExchangeBtnDisplay.ignoreTouch = true
      aExchangeBtnDisplay:getChildByTag(-10):setVisible(false)
      aExchangeBtnDisplay:getChildByTag(-11):setVisible(true)
    else
      aExchangeBtnDisplay.ignoreTouch = false
      aExchangeBtnDisplay:getChildByTag(-10):setVisible(true)
      aExchangeBtnDisplay:getChildByTag(-11):setVisible(false)
    end
	end


	local function onListItemTouch( evt )
		local aIndex = evt.data + 1
		local newCell = self.tableView:cellAtIndex(aIndex - 1)
		local posInCell = newCell:convertToNodeSpace(evt.globalPosition)
		local aData = self.dataList[aIndex]

		local aExchangeBtnDisplay = newCell:getChildByTag(cellTag):getChildByTag(-15)
		local exchangeDisplay = aExchangeBtnDisplay:getChildByTag(-10)
		if posInCell.x > aExchangeBtnDisplay:getPositionX() and
		posInCell.x < (aExchangeBtnDisplay:getPositionX() + exchangeDisplay:getContentSize().width) and
		posInCell.y > (aExchangeBtnDisplay:getPositionY() - exchangeDisplay:getContentSize().height) and
		posInCell.y < aExchangeBtnDisplay:getPositionY() then
      if exchangeDisplay:isVisible() then
        self:exchangeNormalShop(aData)
      end
		end
	end

	local renderer = UnionShopNormalTableViewRenderer.new(item_width, item_height)
	local aTableView = TableView:create(renderer, table_width, table_height, cellTag, buttonTag, CCScale9Sprite:create("pic/scroll.png"), CCScale9Sprite:create("pic/scroll.png"))
	aTableView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch , self)
	aTableView:setPosition(ccp(table_posX, table_posY))
  
	return aTableView
end

function UnionShopNormalPanel:exchangeNormalShop(aData)
  local aShopSpecialConfig = aData
  
  if UnionManager.getMyContribute() < aShopSpecialConfig.contributeCost then
    local aContent = Localization:getInstance():getText("union_shop_item_buy_not_satisfied1")
    SuspensionLabel:showContent(self.container, aContent)
    return
  end
  
  if BagCalcManager.isFull() then
    local aContent = Localization:getInstance():getText("union_shop_item_buy_not_satisfied2")
    -- SuspensionLabel:showContent(self.container, aContent)
    NewPackageFullPanel:show()
    return
  end
  
  local function onSucceed(requestEvent)
		BuyUnionPropRequest.onSucceedDefault(requestEvent)
		RewardManager:getReward(requestEvent.data.rewards)
    local aContent = Localization:getInstance():getText("union_shop_item_buy_finish")
    SuspensionLabel:showContent(self.container, aContent)
    
    UnionManager.setMyContribute(UnionManager.getMyContribute() - aShopSpecialConfig.contributeCost)
    if aData.dailyPurchaseLimit > 0 then
      local unionNormalProps = DailyDataManager.getDailyDataUnionNormalProps()
      local existed = false
      for _, v in ipairs(unionNormalProps) do
        if v.goodMetaId == aData.id then
          v.dailyPurchaseTimes = v.dailyPurchaseTimes + 1
          existed = true
          break
        end
      end
      if not existed then
        table.insert(unionNormalProps, {goodMetaId = aData.id, dailyPurchaseTimes = 1})
      end
      DailyDataManager.setDailyDataUnionNormalProps(unionNormalProps)
    end
    self.container:refreshShopInfoAndNormalShopPanel()
	end
  local params = {unionPropType = 1, unionPropId = aData.id}
  BuyUnionPropRequest.sendRequest(onSucceed, BuyUnionPropRequest.onFailedDefault, params)
end

function UnionShopNormalPanel:refreshNormalTable()
  local offsetY = self.tableView:getContentOffset().y
  local newData = UnionManager.getShopNormalInfoList()
  for k, _ in pairs(self.dataList) do
    self.dataList[k] = nil
  end
  for _, v in ipairs(newData) do
    table.insert(self.dataList, v)
  end
  self.tableView:reloadData()
  self.tableView:setContentOffset(ccp(0, offsetY), false)
end

function UnionShopNormalPanel:dispose()
  UnionShopNormalPanel.super.dispose(self)
end

function UnionShopNormalPanel:panelEnter(callback)
  ViewControlUtil.showTableViewAction(self.tableView, visibleSize,callback)
end

function UnionShopNormalPanel:panelExit(callback)
  ViewControlUtil.disappearTableViewAction(self.tableView, visibleSize, callback)
end

function UnionShopNormalPanel:setTableViewTouched(enabled)
  self.tableView:setTouchEnabled(enabled)
end