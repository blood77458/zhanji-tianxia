require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

NewBabelFloorRewardPanel = class(Layer)

function NewBabelFloorRewardPanel:ctor()
	self.container = nil
end

function NewBabelFloorRewardPanel:create( container, sharkSkyTowerData, floorRewards, callback)
	local s = NewBabelFloorRewardPanel.new()
	s.container = container
	s.preTargetInfoPanel = s.container.targetInfoPanel
	s.sharkSkyTowerData = sharkSkyTowerData
	s.floorRewards = floorRewards
	s.callback = callback
	s:initLayer()
	return s
end

function NewBabelFloorRewardPanel:initLayer()
	self.container:setTableViewsEnabled(false)
	NewBabelFloorRewardPanel.super.initLayer(self)
	
	local builder = LayoutBuilder:createWithContentsOfFile("scene/towerBabel.json")
	self.panelUI = builder:build("popup_towerBabel_result")
	
	local curFloor = 0
	if self.sharkSkyTowerData and self.sharkSkyTowerData.currStatus then
		curFloor = self.sharkSkyTowerData.currStatus.currFloor
	end

	if curFloor <= 0 then
		curFloor = table.getn(MetaManager.sky_tower_level)
	end
	
	self.panelUI:getChildByName("btn_be_sure"):getChildByName("txt"):setString(getTextByKey("yes"))
	self.panelUI:getChildByName("txt_result1"):getChildByName("txt"):setString(Localization:getInstance():getText("skyTower_noRewardTxt1", {num = curFloor}) .. "\n" .. getTextByKey("skyTower_noRewardTxt2"))
	self.panelUI:getChildByName("txt_result_title1"):getChildByName("txt"):setString(getTextByKey("skyTower_rewardTxt1"))
	self.panelUI:getChildByName("txt_result_title2"):getChildByName("txt"):setString(tostring(curFloor))
	self.panelUI:getChildByName("txt_result_title3"):getChildByName("txt"):setString(getTextByKey("skyTower_rewardTxt2"))
	self.panelUI:getChildByName("txt_result2"):getChildByName("txt"):setString(getTextByKey("skyTower_rewardTxt3"))
	
	self.panelUI:getChildByName("reward_item1"):setVisible(false)
	
	if type(self.floorRewards) ~= "table" or table.getn(self.floorRewards) == 0 then
		self.panelUI:getChildByName("txt_result2"):setVisible(false)
	else
		self.panelUI:getChildByName("txt_result1"):setVisible(false)
		local rewardItemTable = {}
		if type(self.floorRewards) == "table" then
			for k, v in ipairs(self.floorRewards) do
				local rewardItem = builder:build("reward_item")
				local fakeIcon = rewardItem:getChildByName("normal_card_small")
				fakeIcon:setVisible(false)
				rewardItem:getChildByName("txt_reward_item_value"):getChildByName("txt"):setString(tostring(v.amount))
				local canonItem
				local nameText = ""
				local itemScale = 130 / 144
				if v.itemType == ResourceEnum.COIN then
					canonItem = CanonItem:create()
					canonItem.icon =  Sprite:create("common/CoinIcon_Mission.png")
					canonItem.icon:setScale(130 / canonItem.icon:getContentSize().width)
					canonItem:setQuality(1, false)
					nameText = getTextByKey("resource_silverCoin")
				elseif v.itemType == ResourceEnum.GEMS then
					canonItem = CanonItem:create()
					canonItem.icon =  Sprite:create("common/GemIcon_Mission.png")
					canonItem.icon:setScale(130 / canonItem.icon:getContentSize().width)
					canonItem:setQuality(1, false)
					nameText = getTextByKey("resource_goldCoin")
				elseif v.itemType == ResourceEnum.CARD then
					canonItem = getHeadIconCanonCardByMetaId(v.metaId)
					itemScale = 1
					nameText = getTextByKey(MetaManager.card_meta[v.metaId].name)
				elseif v.itemType == ResourceEnum.EQUIP then
					canonItem = CanonItem:create()
					canonItem:loadByMetaId(v.metaId)
					nameText = getTextByKey(MetaManager.equip_meta[v.metaId].name)
				elseif v.itemType == ResourceEnum.PROP then
					canonItem = CanonItem:create()
					canonItem:loadByMetaId(v.metaId)
					nameText = getTextByKey(MetaManager.prop_meta[v.metaId].name)
				elseif v.itemType == ResourceEnum.FRIENDPOINT then
					canonItem = CanonItem:create()
					canonItem.icon =  Sprite:create("common/FriendpointIcon_Mission.png")
					canonItem.icon:setScale(130 / canonItem.icon:getContentSize().width)
					canonItem:setQuality(1, false)
					nameText = getTextByKey("resource_friendshipPoint")
				elseif v.itemType == ResourceEnum.BEAST_FRAGMENT then
					canonItem = CanonItem:create()
					canonItem.icon =  Sprite:create("#" .. MetaManager.beast_fragment[v.metaId].icon .. ".png")
					canonItem.icon:setScale(130 / canonItem.icon:getContentSize().width)
					canonItem:addChild(canonItem.icon)
					nameText = BeastScene.getBeastFragmentNameByData(v)
				end
				canonItem:setScale(itemScale)
				rewardItem:getChildByName("txt_reward_item_name"):getChildByName("txt"):setString(nameText)
				canonItem:setPositionXY(fakeIcon:getPositionX(), fakeIcon:getPositionY())
				rewardItem:addChildAt(canonItem, fakeIcon:getZOrder() + 1)
				table.insert(rewardItemTable, rewardItem)
			end
		end
		
		for k, data in ipairs(rewardItemTable) do
			data:setPositionXY(self.panelUI:getChildByName("reward_item1"):getPositionX() + (k -(#rewardItemTable + 1) / 2 + 1) * 160, self.panelUI:getChildByName("reward_item1"):getPositionY())
			self.panelUI:addChildAt(data, self.panelUI:getChildByName("reward_item1"):getZOrder() + 1)
		end
	end
	
	local function onClosePanel(evt)
		if type(self.floorRewards) == "table" then
			RewardManager:getReward(self.floorRewards)
		end
		self.container:setTableViewsEnabled(true)
		self.container.targetInfoPanel = self.preTargetInfoPanel
		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
		if curFloor == table.getn(MetaManager.sky_tower_level) then
			--facebook share sky tower clean
			FacebookShareManager.facebookShareSkyTowerClean(self.callback)
			return
		else
			if self.callback then
				self.callback()
			end
		end
		--if self.callback then
		--	self.callback()
		--end
	end	 
	
	local bt_panel_close = Button:create(self.panelUI:getChildByName("btn_be_sure"))
	bt_panel_close:addEventListener(Events.kStart, onClosePanel)

	self:addChild(self.panelUI)
	
end


