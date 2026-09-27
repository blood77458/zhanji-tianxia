--
-- CrossUnionPkGroupRankPanel.lua
-- zheng.che
-- 2015-4-23
-- gvg 小组赛排名UI
--

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

------------------------------------------------------------------------------------------------------

CrossUnionPkGroupRankPanel = class(Layer)

function CrossUnionPkGroupRankPanel:ctor()
end

-- rankInfo 战报信息 (来源 xxx)
function CrossUnionPkGroupRankPanel:create(rankInfo)
	local s = CrossUnionPkGroupRankPanel.new()
	s.cityId = cityId
	s.rankInfo = rankInfo
	s:initLayer()
	return s
end

function CrossUnionPkGroupRankPanel:initLayer()
	CrossUnionPkGroupRankPanel.super.initLayer(self)

	local builder = LayoutBuilder:createWithContentsOfFile("scene/Gvg.json")
	builder.useArtLabelTTF = true
	self.panelUI = builder:build("popup_Gvg_04") 
	self:addChild(self.panelUI)

	local function closeBtnAction(evt)
	  self:close()
	end
	local closeBtnDisplay = self.panelUI:getChildByName("common_btn_close")
	local closeBtn = Button:create(closeBtnDisplay)
	closeBtn:addEventListener( Events.kStart, closeBtnAction, self )

	local confirmBtnDisplay = self.panelUI:getChildByName("btn")
	confirmBtnDisplay:getChildByName("txt_propInfo_useBtn"):setString(getTextByKey("yes"))--确定
	local confirmBtn = Button:create(confirmBtnDisplay)
	confirmBtn:addEventListener( Events.kStart, closeBtnAction, self )

	self.panelUI:getChildByName("txt_1"):getChildByName("txt"):setString(getTextByKey("WGVG_Detail48"))--只有前四名的军团有资格参加跨服军团战淘汰赛阶段
	self.panelUI:getChildByName("txt_2"):getChildByName("txt"):setString(getTextByKey("union_monster_hurt_turns_button"))--排名
	self.panelUI:getChildByName("txt_3"):getChildByName("txt"):setString(getTextByKey("UnionWar_sign_war"))--对战军团
	self.panelUI:getChildByName("txt_4"):getChildByName("txt"):setString(getTextByKey("arena_pointsTableTxt"))--积分

	self.panelUI:getChildByName("txt_guild_pk_19"):getChildByName("txt"):setString(CrossUnionPkUtils.getRankStr(self.rankInfo.selfScore.rank))--排名
	self.panelUI:getChildByName("txt_5"):getChildByName("txt"):setString(CrossArenaUtils.getUnionNameStrById(self.rankInfo.selfScore.unionName))--[军团名]
	self.panelUI:getChildByName("txt_6"):getChildByName("txt"):setString(CrossArenaUtils.getUnionNameStrById(self.rankInfo.selfScore.unionName))--[军团名]
	self.panelUI:getChildByName("txt_guild_pk_20"):getChildByName("txt"):setString(self.rankInfo.selfScore.score)--积分

	--选择显示颜色
	if self.rankInfo.selfScore.rank <= 4 then
		--前四 晋级 黄色
		self.panelUI:getChildByName("txt_5"):setVisible(true)
		self.panelUI:getChildByName("txt_6"):setVisible(false)
	else
		--未晋级 白色
		self.panelUI:getChildByName("txt_5"):setVisible(false)
		self.panelUI:getChildByName("txt_6"):setVisible(true)
	end

	self.dataList = self.rankInfo.top10ScoreList
	self.tableView = self:createTableView(self.dataList)
	self.panelUI:addChild(self.tableView)
end

function CrossUnionPkGroupRankPanel:createTableView(data)
	local cellTag = 1024
	local buttonTag = {}

	local tableViewRenderer = class(TableViewRenderer)

  	function tableViewRenderer:ctor(width, height, creater)
		self.list = data or {}
		self.creater = creater
	end
	function tableViewRenderer:buildCell(container)
		local builder = LayoutBuilder:createWithContentsOfFile("scene/Gvg.json")
		builder.useArtLabelTTF = true
		local aCell = builder:build("list/list_registered")
		container:addChild(aCell)
		aCell:setTag(cellTag)

        --扫描cell并自动添加tag
        self:addTags(aCell)
	end

	function tableViewRenderer:setData( rawCocosObj, index )
		local aCell = self:getChildByTag(rawCocosObj, cellTag)
		local aData = self.list[index + 1]

		-- <bean desc="跨服gvg某军团积分信息">
		-- 	<property code="unionId" type="int" desc="军团id" />
		-- 	<property code="unionName" type="String" desc="军团名" />
		-- 	<property code="score" type="int" desc="军团当前积分" />
		-- 	<property code="rank" type="int" desc="当前积分排名" />
		-- </bean>
		--显示文本
		self:setTxtByNames(aCell, "txt_guild_pk_19/txt", CrossUnionPkUtils.getRankStr(aData.rank))--排名
		self:setTxtByNames(aCell, "txt_1/txt", CrossArenaUtils.getUnionNameStrById(aData.unionName))--[军团名]
		self:setTxtByNames(aCell, "txt_2/txt", CrossArenaUtils.getUnionNameStrById(aData.unionName))--[军团名]
		self:setTxtByNames(aCell, "txt_guild_pk_20/txt", aData.score)--积分

		--选择显示颜色
		if aData.rank <= 4 then
			--前四 晋级 黄色
			self:getChildByNames(aCell, "txt_1"):setVisible(true)
			self:getChildByNames(aCell, "txt_2"):setVisible(false)
		else
			--未晋级 白色
			self:getChildByNames(aCell, "txt_1"):setVisible(false)
			self:getChildByNames(aCell, "txt_2"):setVisible(true)
		end
	end
	self.panelUI:getChildByName("table_registered_list"):setVisible(false)
	local tableViewSizes = getTableViewSizes(self.panelUI:getChildByName("table_registered_list"))
	tableViewSizes.item_width = tableViewSizes.item_width + 112--因为只有文本框 导出后文字消失导致长度不够 补充最右边文本框宽度
	tableViewSizes.table_width = tableViewSizes.table_width + 112--因为只有文本框 导出后文字消失导致长度不够 补充最右边文本框宽度
	tableViewSizes.table_height = tableViewSizes.table_height + 32--因为只有文本框 导出后文字消失导致高度不够 补充一行高度

	self.renderer = tableViewRenderer.new(tableViewSizes.item_width, tableViewSizes.item_height,self)

	--添加tag
    local builder = LayoutBuilder:createWithContentsOfFile("scene/Gvg.json")
    local aCell = builder:build("list/list_registered")
    self.renderer:scanTags(aCell)
    table.insert(buttonTag, self.renderer:getTagByLayerName("icon_VV"))--按钮

	local aTableView = TableView:create(self.renderer, tableViewSizes.table_width, tableViewSizes.table_height, cellTag, buttonTag, CCScale9Sprite:create("pic/scroll.png"), CCScale9Sprite:create("pic/scroll.png"))
	aTableView:setPosition(ccp(tableViewSizes.table_posX, tableViewSizes.table_posY))

	return aTableView
end

function CrossUnionPkGroupRankPanel:dispose()
	CrossUnionPkGroupRankPanel.super.dispose(self)
end

--关闭对话框
function CrossUnionPkGroupRankPanel:close()
	PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
end