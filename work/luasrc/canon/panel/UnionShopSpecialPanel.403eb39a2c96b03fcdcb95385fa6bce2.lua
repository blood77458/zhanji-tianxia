require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"
require "canon.request.BuyUnionPropRequest"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()
local table_width = 714
local table_height = 715
local table_posX = 3
local table_posY = 130
local item_width = 702
local item_height = 228

--
-- UnionShopSpecialPanel
--

UnionShopSpecialPanel = class(Layer)

function UnionShopSpecialPanel:ctor()
	self.container = nil
	self.dataList = nil
end

function UnionShopSpecialPanel:create( container, tagIndex )
	local s = UnionShopSpecialPanel.new()
	s:initLayer(container, tagIndex)
	return s
end

function UnionShopSpecialPanel:initLayer(container, tagIndex)
	UnionShopSpecialPanel.super.initLayer(self)
	self.container = container
	self.tagIndex = tagIndex
	self.dataList = UnionManager.getShopSpecialInfoList()

	self.tableView = self:createSpecialTableView()
	self:addChild(self.tableView)
  self.tableView:reloadData()
end

function UnionShopSpecialPanel:createSpecialTableView()
	local cellTag = 1024
	local buttonTag = {-15}
	local aListPanel = self
	local UnionShopSpecialTableViewRenderer = class(TableViewRenderer)
	function UnionShopSpecialTableViewRenderer:ctor(width, height)
		self.list = aListPanel.dataList or {}
	end
	function UnionShopSpecialTableViewRenderer:buildCell(container)
		local builder = LayoutBuilder:createWithContentsOfFile("scene/guild.json")
		builder.useArtLabelTTF = true
		local aCell = builder:build("list_guild_shop")
		container:addChild(aCell)
		aCell:setTag(cellTag)
    
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
    
    aCell:getChildByName("txt_guild_28"):getChildByName("txt"):setString(Localization:getInstance():getText("union_shop_item_remain_union"))
    
		local aLeftNumLabel = aCell:getChildByName("txt_guild_29")
		aLeftNumLabel:setTag(-14)
		aLeftNumLabel = aLeftNumLabel:getChildByName("txt")
		aLeftNumLabel:setTag(-10)
    
    aCell:getChildByName("txt_guild_30"):getChildByName("txt"):setString(Localization:getInstance():getText("union_shop_item_unit"))
    
    aCell:getChildByName("txt_guild_33"):setVisible(false)

		local aExchangeBtnDisplay = aCell:getChildByName("btn_guildoption")
		aExchangeBtnDisplay:setTag(-15)
		aExchangeBtnDisplay:getChildByName("txt"):setString(Localization:getInstance():getText("union_shop_buy_button_text"))
		aExchangeBtnDisplay:getChildByName("btn"):setTag(-10)
    aExchangeBtnDisplay:getChildByName("btn_inactive"):setTag(-11)
	end

	function UnionShopSpecialTableViewRenderer:setData( rawCocosObj, index )
		local aCell = self:getChildByTag(rawCocosObj, cellTag)
		local aData = self.list[index + 1]
    
    local icon = aCell:getChildByTag(-20)
    if icon then
      icon:removeFromParentAndCleanup(true)
    end
    
    local aShopSpecialConfig = UnionManager.getShopSpecialConfigWithId(aData.id)
    
    local aNameLabel = aCell:getChildByTag(-10)
    local aOwnNumLabel = aCell:getChildByTag(-11)
    local aCardDisplay = aCell:getChildByTag(-12)
    local aPriceLabel = aCell:getChildByTag(-13)
    local aLeftNumLabel = aCell:getChildByTag(-14)
    local aExchangeBtnDisplay = aCell:getChildByTag(-15)
    setNodeText(aPriceLabel:getChildByTag(-10), tostring(aShopSpecialConfig.contributeCost))
    setNodeText(aLeftNumLabel:getChildByTag(-10), tostring(aData.leftNum))
    setNodeText(aOwnNumLabel:getChildByTag(-10), tostring(UnionManager.getOwnNumWithTypeAndMetaId(aShopSpecialConfig.itemType, aShopSpecialConfig.metaId)))
    
    local aName
    local aOwnNum
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
    
    if aData.leftNum <= 0 then
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
        self:exchangeSpecialShop(aData)
      end
		end
	end

	local renderer = UnionShopSpecialTableViewRenderer.new(item_width, item_height)
	local aTableView = TableView:create(renderer, table_width, table_height, cellTag, buttonTag, CCScale9Sprite:create("pic/scroll.png"), CCScale9Sprite:create("pic/scroll.png"))
	aTableView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch , self)
	aTableView:setPosition(ccp(table_posX, table_posY))
  
	return aTableView
end

function UnionShopSpecialPanel:exchangeSpecialShop(aData)
  local aShopSpecialConfig = UnionManager.getShopSpecialConfigWithId(aData.id)
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
  
  if UnionManager.isBrought(aData.id) then
    local aContent = Localization:getInstance():getText("union_shop_item_buy_not_satisfied5")--今日已经购买了
    SuspensionLabel:showContent(self.container, aContent)
    return
  end
  
  local function onSucceed(requestEvent)
		BuyUnionPropRequest.onSucceedDefault(requestEvent)
		RewardManager:getReward(requestEvent.data.rewards)
    local aContent = Localization:getInstance():getText("union_shop_item_buy_finish")
    SuspensionLabel:showContent(self.container, aContent)
    
    local function onSucceed2(requestEvent2)
      GetUnionBuildingShopInfoRequest.onSucceedDefault(requestEvent2)
      UnionManager.setMyContribute(UnionManager.getMyContribute() - aShopSpecialConfig.contributeCost)
      self.container:refreshShopInfoAndSpecialShopPanel()
    end
    GetUnionBuildingShopInfoRequest.sendRequest(onSucceed2, GetUnionBuildingShopInfoRequest.onFailedDefault)
	end
  local function onFailed(requestEvent)
    BuyUnionPropRequest.onFailedDefault(requestEvent)
    if (requestEvent.data.retCode == 716366) or (requestEvent.data.retCode == 716367) then
      local function onSucceed2(requestEvent2)
        GetUnionBuildingShopInfoRequest.onSucceedDefault(requestEvent2)
        self.container:refreshShopInfoAndSpecialShopPanel()
      end
      GetUnionBuildingShopInfoRequest.sendRequest(onSucceed2, GetUnionBuildingShopInfoRequest.onFailedDefault)
    end
  end
  local params = {unionPropType = 2, unionPropId = aData.id}
  BuyUnionPropRequest.sendRequest(onSucceed, onFailed, params)
end

function UnionShopSpecialPanel:refreshSpecialTable()
  for k, _ in pairs(self.dataList) do
    self.dataList[k] = nil
  end
  local newData = UnionManager.getShopSpecialInfoList()
  for _, v in ipairs(newData) do
    table.insert(self.dataList, v)
  end
  self.tableView:reloadData()
end

function UnionShopSpecialPanel:dispose()
  UnionShopSpecialPanel.super.dispose(self)
end

function UnionShopSpecialPanel:panelEnter(callback)
  ViewControlUtil.showTableViewAction(self.tableView, visibleSize,callback)
end

function UnionShopSpecialPanel:panelExit(callback)
  ViewControlUtil.disappearTableViewAction(self.tableView, visibleSize, callback)
end

function UnionShopSpecialPanel:setTableViewTouched(enabled)
  self.tableView:setTouchEnabled(enabled)
end