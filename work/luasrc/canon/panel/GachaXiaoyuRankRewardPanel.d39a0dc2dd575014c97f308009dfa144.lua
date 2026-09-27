--------------------------------------------------------------------------------
--  跨服小玉嫁到排名奖励面板
--------------------------------------------------------------------------------


local visibleSize = CCDirector:sharedDirector():getVisibleSize()

GachaXiaoyuRankRewardPanel = class(Layer)

function GachaXiaoyuRankRewardPanel:ctor()
    self.container = nil
end

function GachaXiaoyuRankRewardPanel:create( container,rewards,callback )
    self.container = container
	self.data = rewards
	self.callback = callback
    local s = GachaXiaoyuRankRewardPanel.new()
    s:initLayer()
    return s
end

function GachaXiaoyuRankRewardPanel:setRewordDisplay( rewardItem, rewardData )
	if nil == rewardData then
		rewardItem:setVisible(false)
		do return end
	end
	local displayIcon = nil
	local name = nil
	
	displayIcon = CanonGoodIcon.createGoodIcon(rewardData.itemType, rewardData.metaId, 0, params)
	name = CanonGoodIcon.getGoodName(rewardData.itemType, rewardData.metaId, 0, {withoutAmount = true})
		
	if rewardData.itemType == ResourceEnum.COIN then
		

	elseif rewardData.itemType == ResourceEnum.CARD then
		

	elseif rewardData.itemType == ResourceEnum.EQUIP then
		
		displayIcon:setScale(130 / 144)

	elseif rewardData.itemType == ResourceEnum.PROP then
		
		displayIcon:setScale(130 / 144)
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

function GachaXiaoyuRankRewardPanel:initLayer()
	GachaXiaoyuRankRewardPanel.super.initLayer(self)
	local data = self.data
	local builder = LayoutBuilder:createWithContentsOfFile("scene/boss.json")
	
	local function rewardMysteriousSet()
		self.panelUI:getChildByName("txt_huarus_reward"):getChildByName("txt"):setString(getTextByKey("activity_specialRewards")..": ")
		self:setRewordDisplay(self.panelUI:getChildByName("boss_reward_item"), data.mysteriousRewards[1]) 
		self:setRewordDisplay(self.panelUI:getChildByName("boss_reward_item11"), data.mysteriousRewards[2]) 
	end

	local function rewardRankSet(  )
		self.panelUI:getChildByName("txt_damege_reward"):getChildByName("txt"):setString(getTextByKey("activity_rankinButton")..": ")
		self:setRewordDisplay(self.panelUI:getChildByName("boss_reward_item2"), data.rankRewards[1]) 
		self:setRewordDisplay(self.panelUI:getChildByName("boss_reward_item22"), data.rankRewards[2]) 
		self:setRewordDisplay(self.panelUI:getChildByName("boss_reward_item23"), data.rankRewards[3]) 
	end
	
	if (data.rankRewards and #data.rankRewards > 0) and (data.mysteriousRewards and #data.mysteriousRewards > 0) then
		--既有神秘奖励，也有排行奖励
		self.panelUI = builder:build("boss_reward2")
		rewardMysteriousSet()
		rewardRankSet()
	else
		--只有神秘奖励，玩家未上排行榜
		self.panelUI = builder:build("boss_reward1")
		rewardMysteriousSet()
	end

	self.panelUI:getChildByName("txt_bossreward_get"):getChildByName("txt"):setString(getTextByKey("worldBoss_claimReward_txt"))
	
	self:addChild(self.panelUI)

	local function onConfirmPanel(evt)
		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
		self.container.targetRewardPanel = nil  
		if self.callback then
			self.callback()
		end
	end

	self.panelUI:getChildByName("btn_boss_sure"):getChildByName("txt"):setString(getTextByKey("yes"))
	local bt_panel_close = Button:create(self.panelUI:getChildByName("btn_boss_sure"))
    bt_panel_close:addEventListener(Events.kStart, onConfirmPanel)   
	
	
end