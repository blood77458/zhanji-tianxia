--
-- CrossUnionPkGroupReportsPanel.lua
-- zheng.che
-- 2015-4-23
-- gvg 小组赛战报UI
--

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

-- 跨天
local function onPassDay( evt )
	local self = evt.context
	--清空列表
	for i = #self.dataList, 1, -1 do
		table.remove(self.dataList, i)
	end
	self.tableView:reloadData()
end

------------------------------------------------------------------------------------------------------

CrossUnionPkGroupReportsPanel = class(Layer)

function CrossUnionPkGroupReportsPanel:ctor()
end

-- reportsInfo 战报信息 (来源 CrossUnionPkGetGroupReportsRequest)
function CrossUnionPkGroupReportsPanel:create(reportsInfo)
	local s = CrossUnionPkGroupReportsPanel.new()
	s.cityId = cityId
	s.reportsInfo = reportsInfo
	s:initLayer()
	return s
end

function CrossUnionPkGroupReportsPanel:initLayer()
	CrossUnionPkGroupReportsPanel.super.initLayer(self)

	local builder = LayoutBuilder:createWithContentsOfFile("scene/Gvg.json")
	builder.useArtLabelTTF = true
	self.panelUI = builder:build("popup_Gvg_02") 
	self:addChild(self.panelUI)

	local function closeBtnAction(evt)
	  self:close()
	end
	local closeBtnDisplay = self.panelUI:getChildByName("login_btn_close")
	local closeBtn = Button:create(closeBtnDisplay)
	closeBtn:addEventListener( Events.kStart, closeBtnAction, self )

	self.panelUI:getChildByName("txt_1"):getChildByName("txt"):setString(getTextByKey("WGVG_title01"))--跨服军团战（小组赛）
	self.panelUI:getChildByName("txt_2"):getChildByName("txt"):setString(getTextByKey("UnionWar_sign_screen"))--名次
	self.panelUI:getChildByName("txt_3"):getChildByName("txt"):setString(getTextByKey("WGVG_Name05"))--攻方
	self.panelUI:getChildByName("txt_5"):getChildByName("txt"):setString(getTextByKey("WGVG_Name06"))--守方
	self.panelUI:getChildByName("txt_4"):getChildByName("txt"):setString(getTextByKey("cross_race_video"))--查看录像

	self.dataList = self.reportsInfo.reports
	self.tableView = self:createTableView(self.dataList)
	self.panelUI:addChild(self.tableView)

	NotificationManager:addEventListener(PassDayManager.PASS_DAY, onPassDay, self) --跨天监听
end

function CrossUnionPkGroupReportsPanel:createTableView(data)
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
		local aCell = builder:build("list/list_previou_fight")
		container:addChild(aCell)
		aCell:setTag(cellTag)

        --扫描cell并自动添加tag
        self:addTags(aCell)
	end

	function tableViewRenderer:setData( rawCocosObj, index )
		local aCell = self:getChildByTag(rawCocosObj, cellTag)
		local aData = self.list[index + 1]

		-- <bean desc="战报信息">
		-- 	<property code="uuid" type="int" desc="战报id" />
		-- 	<property code="attUnionName" type="string" desc="进攻方公会名称" />
		-- 	<property code="defUnionName" type="string" desc="防守方公会名称" />
		-- 	<property code="win" type="boolean" desc="进攻方是否胜利" />
		-- </bean>

		--显示文本
		self:setTxtByNames(aCell, "txt_1/txt", CrossArenaUtils.getUnionNameStrById(aData.attUnionName))--[军团名]
		self:setTxtByNames(aCell, "txt_2/txt", CrossArenaUtils.getUnionNameStrById(aData.defUnionName))--[军团名]

		local roundIndex = index + 1
		local digitGroup1Display = self:getChildByNames(aCell, "session_1digit")
		local digitGroup2Display = self:getChildByNames(aCell, "session_2digit")
		digitGroup1Display:setVisible(false)
		digitGroup2Display:setVisible(false)
		if roundIndex < 10 then
			--个位数
			digitGroup1Display:setVisible(true)
			local digit1Display = self:getChildByNames(aCell, "session_1digit/digit")
			CrossUnionPkGroupReportsPanel.setDigitNum(self, digit1Display, "lbl_Gvg_", roundIndex)
		else
			--两位数
			digitGroup2Display:setVisible(true)

			local num1 = tonumber(string.sub(tostring(roundIndex), 1, 1))
			local digit1Display = self:getChildByNames(aCell, "session_2digit/digit")
			CrossUnionPkGroupReportsPanel.setDigitNum(self, digit1Display, "lbl_Gvg_", num1)

			local num2 = tonumber(string.sub(tostring(roundIndex), 2, 2))
			local digit2Display = self:getChildByNames(aCell, "session_2digit/digit2")
			CrossUnionPkGroupReportsPanel.setDigitNum(self, digit2Display, "lbl_Gvg_", num2)
		end

		--显示胜利/失败
		self:getChildByNames(aCell, "signInIcon_victory_f_1"):setVisible(aData.win)
		self:getChildByNames(aCell, "signInIcon_negative_f_2"):setVisible(not aData.win)
		self:getChildByNames(aCell, "signInIcon_victory_f_2"):setVisible(not aData.win)
		self:getChildByNames(aCell, "signInIcon_negative_f_1"):setVisible(aData.win)
	end


	local function onListItemTouch( evt )
		local aIndex = evt.data + 1
		local newCell = self.tableView:cellAtIndex(aIndex - 1)
		local aCell = newCell:getChildByTag(cellTag)
		local posInCell = newCell:convertToNodeSpace(evt.globalPosition)
		local aData = self.dataList[aIndex]


		local btnDisplay = self.renderer:getChildByNames(aCell, "icon_VV")
		if isHittedDisplay(posInCell, btnDisplay) then
			--点击按钮
			CrossUnionPkGetBattleReportRequest.sendRequestDefalut(aData.uuid, false)--会进战场
		end
	end

	self.panelUI:getChildByName("table_previou_fight_list"):setVisible(false)
	local tableViewSizes = getTableViewSizes(self.panelUI:getChildByName("table_previou_fight_list"))
	tableViewSizes.table_width = tableViewSizes.table_width + 10--加宽 用于解决滚动条挡住右侧问题
	tableViewSizes.table_height = tableViewSizes.table_height + 50--加高 因为原美术资源有用到缩放 但自动匹配尺寸对缩放支持不好 需要手动补正

	self.renderer = tableViewRenderer.new(tableViewSizes.item_width, tableViewSizes.item_height,self)

	--添加tag
    local builder = LayoutBuilder:createWithContentsOfFile("scene/Gvg.json")
    local aCell = builder:build("list/list_previou_fight")
    self.renderer:scanTags(aCell)
    table.insert(buttonTag, self.renderer:getTagByLayerName("icon_VV"))--按钮

	local aTableView = TableView:create(self.renderer, tableViewSizes.table_width, tableViewSizes.table_height, cellTag, buttonTag, CCScale9Sprite:create("pic/scroll.png"), CCScale9Sprite:create("pic/scroll.png"))
	aTableView:setPosition(ccp(tableViewSizes.table_posX, tableViewSizes.table_posY))
	aTableView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch , self)

	return aTableView
end

function CrossUnionPkGroupReportsPanel:dispose()
	NotificationManager:removeEventListener(PassDayManager.PASS_DAY, onPassDay, self)

	CrossUnionPkGroupReportsPanel.super.dispose(self)
end

--关闭对话框
function CrossUnionPkGroupReportsPanel:close()
	PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
end

-------------------------------------------------------------------------------------------------------------

function CrossUnionPkGroupReportsPanel.setDigitNum(renderer, digitDisplay, layerNamePattern, num)
	for i = 0, 9, 1 do
		local tag = renderer:getTagByLayerName(layerNamePattern .. i)
		if i == num then
			digitDisplay:getChildByTag(tag):setVisible(true)
		else
			digitDisplay:getChildByTag(tag):setVisible(false)
		end
	end
end