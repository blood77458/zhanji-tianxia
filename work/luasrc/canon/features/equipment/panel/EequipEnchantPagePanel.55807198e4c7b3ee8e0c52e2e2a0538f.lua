-- EequipEnchantPagePanel.lua
-- 2014-12-9
-- zheng.che
-- 装备详情 -> 附灵页签

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

EequipEnchantPagePanel = class(Layer)

--------------------------------------------------------------------------------------------------------

function EequipEnchantPagePanel:ctor()
	self.container = nil
	self.dataList = nil
end

function EequipEnchantPagePanel:create(container, equipData )
	local s = EequipEnchantPagePanel.new()
	s:initLayer(container, equipData)
	return s
end

function EequipEnchantPagePanel:initLayer(container, equipData)
	local function refreshSelf()
	end
	self.refreshSelf = refreshSelf

	EequipEnchantPagePanel.super.initLayer(self)
	self.container = container
	self.equipData = equipData

	--显示列表
	--print("self.equipData = " .. tostringRich(self.equipData))
	local enchantInfo = Enchant.findEnchantInfo(self.equipData.metaId, self.equipData.enchantLevel)--获得附灵配置信息
	--print("enchantInfo10_2 = " .. tostringRich(enchantInfo))
	if enchantInfo and enchantInfo.skills then
		self.dataList = enchantInfo.skills
	else
		self.dataList = {}
	end
	self.listTableView = self:createListTableView()
	self.container:addChild(self.listTableView)
	self.listTableView:reloadData()

	self.refreshSelf()
end

--------------------------------------------------------------------------------------------------------------------------------------tableview

function EequipEnchantPagePanel:createListTableView()
	local cellTag = 1024
	local buttonTag = {}
	local aListPanel = self
	local equipEnchantInfoListTableViewRenderer = class(TableViewRenderer)
	function equipEnchantInfoListTableViewRenderer:ctor(width, height)
		self.list = aListPanel.dataList or {}
	end
	function equipEnchantInfoListTableViewRenderer:buildCell(container)
		local builder = LayoutBuilder:createWithContentsOfFile("scene/common_new.json")
		builder.useArtLabelTTF = true
		local aCell = builder:build("enchant_list")
		container:addChild(aCell)
		aCell:setTag(cellTag)

		local aName1Label = aCell:getChildByName("txt_1")
		aName1Label:setTag(-11)
		aName1Label = aName1Label:getChildByName("txt")
		aName1Label:setTag(-11)

		local aName2Label = aCell:getChildByName("txt_2")
		aName2Label:setTag(-12)
		aName2Label = aName2Label:getChildByName("txt")
		aName2Label:setTag(-11)
	end

	function equipEnchantInfoListTableViewRenderer:setData( rawCocosObj, index )
		local aCell = self:getChildByTag(rawCocosObj, cellTag)
		local aData = self.list[index + 1]
		--print("aData = " .. table.tostring(aData))
		--print("aCell:getPositionY = " .. table.tostring(aCell:getPositionY()))

		--
		local aName1Label = aCell:getChildByTag(-11)
		local aName2Label = aCell:getChildByTag(-12)
		--print("aName1Label:getPositionY = " .. table.tostring(aName1Label:getPositionY()))
		--print("aName2Label:getPositionY = " .. table.tostring(aName2Label:getPositionY()))

		aName1Label:setVisible(false)
		aName2Label:setVisible(false)

		local skillMeta = EnchantConfig.getSkillMeta(aData.id)
		local enchantName = EnchantUtils.getSkillName(aData.id, aData.openTimes)
		local addNum = aData.num--说明里增加的点数
		local needLevelStr = ""--这句可能不显示 所以默认空
		
		if aData.openTimes <= 0 then
			--未开启
			needLevelStr = Localization:getInstance():getText("enchant_2", {level = "+" .. aData.nextOpenLevel})--（需附灵{level}觉醒）

			aName1Label:setVisible(true)

			addNum = EnchantUtils.findSkillAddNum(aListPanel.equipData.metaId, aData.id, 1)
		else
			--开启
			aName2Label:setVisible(true)

			--显示升级所需等级
			if aData.nextOpenLevel ~= -1 then
				--未满级
				needLevelStr = Localization:getInstance():getText("enchant_14", {level = "+" .. aData.nextOpenLevel})--（需附灵{level}升级）
			end
		end
		local enchantDesc = EnchantUtils.getSkillDesc(aData.id, addNum)
		local showStr = enchantName .. Localization:getInstance():getText("enchant_8") .. enchantDesc
		showStr = showStr .. needLevelStr
		--print("showStr = " .. table.tostring(showStr))
		setNodeText(aName1Label:getChildByTag(-11), showStr)
		setNodeText(aName2Label:getChildByTag(-11), showStr)
	end

	local tableViewSizes = getTableViewSizes(self.container:getChildByName("table_equipInfo02_list_enchant"))
	self.container:getChildByName("table_equipInfo02_list_enchant"):setVisible(false)
	--print("tableViewSizes = " .. tostringRich(tableViewSizes))
	tableViewSizes.table_width = 580.95
	tableViewSizes.item_width = 580.95
	tableViewSizes.table_height = tableViewSizes.table_height + 40
	--tableViewSizes.table_posY = -tableViewSizes.table_posY
	local renderer = equipEnchantInfoListTableViewRenderer.new(tableViewSizes.item_width, tableViewSizes.item_height)
	local aTableView = TableView:create(renderer, tableViewSizes.table_width, tableViewSizes.table_height, cellTag, buttonTag, CCScale9Sprite:create("pic/scroll.png"), CCScale9Sprite:create("pic/scroll.png"))
	aTableView:setPosition(ccp(tableViewSizes.table_posX, tableViewSizes.table_posY))

	aTableView.hitTestPoint = function (self, worldPosition, useGroupTest)
		return false -- 修复遮挡下方按钮的bug
	end

	return aTableView
end

--------------------------------------------------------------------------------------------------------------------------------------others

function EequipEnchantPagePanel:dispose()
	--print("EequipEnchantPagePanel:dispose")

	if self.listTableView then
		self.listTableView:removeFromParentAndCleanup(true)
	end

	EequipEnchantPagePanel.super.dispose(self)
end

--设置触摸是否开启
function EequipEnchantPagePanel:setTableViewTouched(enabled)
	self.listTableView:setTouchEnabled(enabled)
end