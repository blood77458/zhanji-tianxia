--------------------------------------------------------------------------------
-- InspirePanel.lua - 鼓舞信息面板
--------------------------------------------------------------------------------

require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"
require "canon.data.MetaManager"
require "canon.models.CommonManager"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

WorldBossRewardPanel = class(Layer)

function WorldBossRewardPanel:ctor()
    self.container = nil
end

function WorldBossRewardPanel:create( container )
    self.container = container
    local s = WorldBossRewardPanel.new()
    s:initLayer()
    return s
end

function WorldBossRewardPanel:setRewordDisplay( rewardItem, rewardData )
	if nil == rewardData then
		rewardItem:setVisible(false)
		do return end
	end
	local displayIcon = nil
	local name = nil
	if rewardData.itemType == ResourceEnum.COIN then
		displayIcon = Sprite:create("common/CoinIcon.png")
		name = getTextByKey("resource_silverCoin")

	elseif rewardData.itemType == ResourceEnum.CARD then
		displayIcon = getHeadIconCanonCardByMetaId( rewardData.metaId)
		name = getTextByKey(MetaManager.card_meta[rewardData.metaId].name)

	elseif rewardData.itemType == ResourceEnum.EQUIP then
		displayIcon = CanonItem:create()
		displayIcon:loadByMetaId(rewardData.metaId)
		displayIcon:setScale(130 / 144)
		name = getTextByKey(MetaManager.equip_meta[rewardData.metaId].name)

	elseif rewardData.itemType == ResourceEnum.PROP then
		displayIcon = CanonItem:create()
		displayIcon:loadByMetaId(rewardData.metaId)
		displayIcon:setScale(130 / 144)
		name = getTextByKey(MetaManager.prop_meta[rewardData.metaId].name)

	elseif rewardData.itemType == ResourceEnum.GEMS then
		displayIcon = Sprite:create("common/GemIcon_Mission.png")
		name = getTextByKey("resource_goldCoin")
	end

      displayIcon:setPosition(ccp(60, -60))
	rewardItem:getChildByName("bg_card"):addChild(displayIcon)
	local amount = tonumber(rewardData.amount)
	if not amount then
		amount = 1
	end
	rewardItem:getChildByName("txt_item_quantity"):getChildByName("txt_item_quantity"):setString("x" .. amount)
	rewardItem:getChildByName("txt_item_name"):getChildByName("txt_item_name"):setString(name)
end

function WorldBossRewardPanel:initLayer()
	WorldBossRewardPanel.super.initLayer(self)
	local tempData = self.container.rewardData
	-- print(table.tostring(tempData).."哦哦")
	local function gatherReward( tempData )
		local tempData = table.clone(tempData)
		rankRewards = tempData.rankRewards
		local tempRankRewards = {}
		local tempCard = nil
		for k,v in pairs(rankRewards) do
			if v.itemType == ResourceEnum.CARD then
				table.insert(tempRankRewards , v)
			end
		end
		local function sortFunc( a , b )
			if a.metaId > b.metaId then
				return true
			else
				return false
			end
		end

		if #tempRankRewards < 2 then
			return tempData
		end

		table.sort(tempRankRewards , sortFunc)

		local finalRankRewards = {}
		local first = tempRankRewards[1]
		table.insert(finalRankRewards , tempRankRewards[1])
		for i=2,#tempRankRewards do
			if tempRankRewards[i].metaId ~= first.metaId then
				first = tempRankRewards[i]
				table.insert(finalRankRewards , tempRankRewards[i])
			else
				finalRankRewards[#finalRankRewards].amount = finalRankRewards[#finalRankRewards].amount + tempRankRewards[i].amount
			end
		end

		local lastRewards = {}
		for k,v in pairs(finalRankRewards) do
			table.insert(lastRewards , v)
		end
		for k,v in pairs(rankRewards) do
			if v.itemType ~= ResourceEnum.CARD then
				table.insert(lastRewards , v)
			end
		end

		tempData.rankRewards = lastRewards

		return tempData

	end

	local data = gatherReward(tempData)
	-- print(table.tostring(data).."哦哦")
	local builder = LayoutBuilder:createWithContentsOfFile("scene/boss.json")
	
	local function rewardNormalSet()
		local name = getTextByKey(WorldBossScene.worldBossInfo.worldBossMonster.normalTextKey)
		self.panelUI:getChildByName("txt_huarus_reward"):getChildByName("txt"):setString(name)
		self:setRewordDisplay(self.panelUI:getChildByName("boss_reward_item"), data.normalRewards[1]) 
		self:setRewordDisplay(self.panelUI:getChildByName("boss_reward_item11"), data.normalRewards[2]) 
	end

	local function rewardRankSet(  )
		self.panelUI:getChildByName("txt_damege_reward"):getChildByName("txt"):setString(getTextByKey("worldBoss_claimReward_rank", {rank = WorldBossScene.worldBossInfo.rank}))
		self:setRewordDisplay(self.panelUI:getChildByName("boss_reward_item2"), data.rankRewards[1]) 
		self:setRewordDisplay(self.panelUI:getChildByName("boss_reward_item22"), data.rankRewards[2]) 
		self:setRewordDisplay(self.panelUI:getChildByName("boss_reward_item23"), data.rankRewards[3]) 
	end

	local function rewardLastFight2(  )
		self.panelUI:getChildByName("txt_damege_reward"):getChildByName("txt"):setString(getTextByKey("worldBoss_claimReward_kill"))
		self:setRewordDisplay(self.panelUI:getChildByName("boss_reward_item2"), data.lastShotRewards[1]) 
		self:setRewordDisplay(self.panelUI:getChildByName("boss_reward_item22"), data.lastShotRewards[2])
		self:setRewordDisplay(self.panelUI:getChildByName("boss_reward_item23"), data.lastShotRewards[2]) 
	end

	local function rewardLastFight3(  )
		self.panelUI:getChildByName("txt_bosskill_reward"):getChildByName("txt"):setString(getTextByKey("worldBoss_claimReward_kill")) --击杀奖励
		self:setRewordDisplay(self.panelUI:getChildByName("boss_reward_item3"), data.lastShotRewards[1]) 
		self:setRewordDisplay(self.panelUI:getChildByName("boss_reward_item32"), data.lastShotRewards[2]) 
	end

	
	if (data.lastShotRewards and #data.lastShotRewards > 0) and (data.rankRewards and #data.rankRewards > 0) then
		self.panelUI = builder:build("boss_reward3")
		rewardNormalSet()
		rewardRankSet()
		rewardLastFight3()
	elseif data.lastShotRewards and #data.lastShotRewards > 0 then
		self.panelUI = builder:build("boss_reward2")
		rewardNormalSet()
		rewardLastFight2()
	elseif data.rankRewards and #data.rankRewards > 0 then
		self.panelUI = builder:build("boss_reward2")
		rewardNormalSet()
		rewardRankSet()
	else
		self.panelUI = builder:build("boss_reward1")
		rewardNormalSet()
	end

	self.panelUI:getChildByName("txt_bossreward_get"):getChildByName("txt"):setString(getTextByKey("worldBoss_claimReward_txt"))
	
	self:addChild(self.panelUI)

	local function onConfirmPanel(evt)
		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
		self.container.targetRewardPanel = nil
		RewardManager:getReward(self.container.rewardData.normalRewards)
		RewardManager:getReward(self.container.rewardData.lastShotRewards)
		RewardManager:getReward(self.container.rewardData.rankRewards)   
	end

	self.panelUI:getChildByName("btn_boss_sure"):getChildByName("txt"):setString(getTextByKey("yes"))
	local bt_panel_close = Button:create(self.panelUI:getChildByName("btn_boss_sure"))
    bt_panel_close:addEventListener(Events.kStart, onConfirmPanel)   
	
	
end