-- UnionColosseumRankPopPanel.lua
-- 2014-6-3 zheng.che
-- 军团斗兽场排名弹出窗口

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

--焦点变化事件
local function onFocusChanged(evt)
	evt.context:setTableViewsEnabled(evt.data == evt.context)
end

--清除场景事件
local function onSceneClear(evt)
	PopoutManager:sharedManager():pullin(evt.context, kPopoutDir.kScale )
end

--点击关闭
local function onClose(evt)
	print("onClose")
	local self = evt.context
	PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
end
------------------------------------------------------------------------------------------------------

UnionColosseumRankPopPanel = class(Layer)

function UnionColosseumRankPopPanel:ctor()
	self.container = nil
	self.content = nil
end

function UnionColosseumRankPopPanel:create( container, buildingId )
	local s = UnionColosseumRankPopPanel.new()
	s:initLayer(container, buildingId)
	return s
end

function UnionColosseumRankPopPanel:initLayer(container, buildingId)
	UnionColosseumRankPopPanel.super.initLayer(self)
    
	self.container = container
	self.buildingId = buildingId

	local builder = LayoutBuilder:createWithContentsOfFile("scene/guild.json")
	builder.useArtLabelTTF = true
	self.panelUI = builder:build("popup_distribution") 

	self:addChild(self.panelUI)

	--固定文字
	self.panelUI:getChildByName("txt_guild_56"):getChildByName("txt"):setString(Localization:getInstance():getText("union_monster_hurt_turns_button"))--排名
	self.panelUI:getChildByName("txt_guild_57"):getChildByName("txt"):setString(Localization:getInstance():getText("union_monster_hurt_turns_name_txt"))--名字
	self.panelUI:getChildByName("txt_guild_58"):getChildByName("txt"):setString(Localization:getInstance():getText("union_monster_hurt_turns_txt"))--伤害
	self.panelUI:getChildByName("txt_guild_59"):getChildByName("txt"):setString(getTextByKey("union_monster_hurt_turns_mine_txt"))--我的排名
	local myRank = UnionManager.findMyRank()
	if myRank ~= -1 then
		self.panelUI:getChildByName("txt_guild_52"):getChildByName("txt"):setString(myRank)--[我的排名]
	else
		self.panelUI:getChildByName("txt_guild_52"):getChildByName("txt"):setString(getTextByKey("union_monster_hurt_turns_no"))--未参与
	end

	--按钮
	local closeButton = Button:create(self.panelUI:getChildByName("login_btn_close"))
	closeButton:addEventListener(Events.kStart,onClose, self)

	--加侦听
	UiStackManager_EventDispatcher:addEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged, self)
	BaseUINotify:addEventListener(UI_NOTIFY_EVENT_ENUM.SCENE_CLEAR, onSceneClear, self)

	--初始化
	self.dataList = UnionManager.getColosseumRanks()
	print("self.dataList = " .. tostringRich(self.dataList))
	self.listTableView = self:createRankTableView()
	self:addChild(self.listTableView)
	self.listTableView:reloadData()

	local test = self.panelUI:getChildByName("table_damage_rank_list"):getChildByName("list_begin"):getChildByName("txt_guild_member_name"):getChildByName("txt")
	local tableViewSize = test:getGroupBounds(test:getParent()).size
	print("tableViewSize.width = " .. tostring(tableViewSize.width))
	print("tableViewSize.height = " .. tostring(tableViewSize.height))
end

function UnionColosseumRankPopPanel:dispose()
	UiStackManager_EventDispatcher:removeEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged)
	BaseUINotify:removeEventListener(UI_NOTIFY_EVENT_ENUM.SCENE_CLEAR, onSceneClear)

	UnionColosseumRankPopPanel.super.dispose(self)
end

function UnionColosseumRankPopPanel:setTableViewsEnabled(v)
end


------------------------------------------------------------------------------------------------------

function UnionColosseumRankPopPanel:createRankTableView()
	local cellTag = 1024
	local buttonTag = {}
	local aPanel = self
	local RankTableViewRenderer = class(TableViewRenderer)
	function RankTableViewRenderer:ctor(width, height)
		self.list = aPanel.dataList or {}
	end

	function RankTableViewRenderer:buildCell(container)
		local builder = LayoutBuilder:createWithContentsOfFile("scene/guild.json")
		local aCell = builder:build("list_damage_rank")
		container:addChild(aCell)
		aCell:setTag(cellTag)

		local aNumLabel = aCell:getChildByName("txt_guild_60")
		aNumLabel:setTag(-10)
		aNumLabel = aNumLabel:getChildByName("txt")
		aNumLabel:setTag(-10)

		local aNameLabel = aCell:getChildByName("txt_guild_member_name")
		aNameLabel:setTag(-11)
		aNameLabel = aNameLabel:getChildByName("txt")
		aNameLabel:setTag(-10)

		local aScoreLabel = aCell:getChildByName("txt_guild_61")
		aScoreLabel:setTag(-12)
		aScoreLabel = aScoreLabel:getChildByName("txt")
		aScoreLabel:setTag(-10)
	end

	function RankTableViewRenderer:setData( rawCocosObj, index )
		local aCell = self:getChildByTag(rawCocosObj, cellTag)
		local aData = self.list[index + 1]

		local aNumLabel = aCell:getChildByTag(-10):getChildByTag(-10)
		setNodeText(aNumLabel, string.format("%d", index + 1))

		local aNameLabel = aCell:getChildByTag(-11):getChildByTag(-10)
		setNodeText(aNameLabel, aData.nickName)

		local aScoreLabel = aCell:getChildByTag(-12):getChildByTag(-10)
		setNodeText(aScoreLabel, string.format("%d", aData.totalDamage))
	end

	self.panelUI:getChildByName("table_damage_rank_list"):setVisible(false)
	--占位内容 只影响计算尺寸的结果
	self.panelUI:getChildByName("table_damage_rank_list"):getChildByName("list_begin"):getChildByName("txt_guild_61"):getChildByName("txt"):setString("00000000000")
	self.panelUI:getChildByName("table_damage_rank_list"):getChildByName("list_end"):getChildByName("txt_guild_61"):getChildByName("txt"):setString("00000000000")
	local tableViewSizes = getTableViewSizes(self.panelUI:getChildByName("table_damage_rank_list"))
	local renderer = RankTableViewRenderer.new(tableViewSizes.item_width, tableViewSizes.item_height)
	local aTableView = TableView:create(renderer, tableViewSizes.table_width, tableViewSizes.table_height, cellTag, buttonTag, CCScale9Sprite:create("pic/scroll.png"), CCScale9Sprite:create("pic/scroll.png"))
	aTableView:setPosition(ccp(tableViewSizes.table_posX, tableViewSizes.table_posY))
	return aTableView
end