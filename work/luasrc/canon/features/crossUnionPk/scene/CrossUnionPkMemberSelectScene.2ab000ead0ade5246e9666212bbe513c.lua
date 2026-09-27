-- CrossUnionPkMemberSelectScene.lua
-- zheng.che
-- 2014-7-24
-- 军团战场景

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

local enter_animation_duration = 0.3
local selectedText = ""

-------------------------------------------------------------------------------
-- 按钮点击
-------------------------------------------------------------------------------


--点击返回
local function onBackBtnClick(evt)
	local self = evt.context
	self:back()
end

--点击问号
local function onQaBtnClick(evt)
	local self = evt.context
  -- self:setTableViewsEnabled(false)
  --ReNameCoolingPanel
  local aInfoPanel = ActivityInfoPanel:create(self, getTextByKey("WGVG_Detail44"))
  self:addChild(aInfoPanel)
  aInfoPanel:scaleIn()
end

-------------------------------------------------------------------------------
-- 事件侦听
-------------------------------------------------------------------------------

--焦点变化事件
local function onFocusChanged(evt)
	evt.context:setTableViewsEnabled(evt.data == nil)
end


--------------------------------------------------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- 初始化处理
-------------------------------------------------------------------------------

CrossUnionPkMemberSelectScene = class(BaseUIScene)

function CrossUnionPkMemberSelectScene:ctor()
end

function CrossUnionPkMemberSelectScene:create(argv)
	local s = CrossUnionPkMemberSelectScene.new()
	if argv then 
		s.argv = argv 
	else
		s.argv = {enterScene=nil,returnScene=nil,params={}}
	end
	s.curSceneEnum = SceneEnum.CrossUnionPkMemberSelectScene

	--当前显示中的列表内容(注意: 子panel可能读取)
	s.selectedDataList = {}
	s:initScene()
	return s
end

function CrossUnionPkMemberSelectScene:onInit()
	self.enterStage = CrossUnionPkUtils.findCurrentTimeLevel()
	BaseUIScene.initBackGround(self)

	local builder = LayoutBuilder:createWithContentsOfFile("scene/Gvg.json")
	builder.useArtLabelTTF = true

	-- local topUI = builder:build("endbattle/GvG_endbattle")
	-- self:addChild(topUI)

	-- topUI:getChildByName("Gvg_colosseuml_title"):getChildByName("bg_Gvg_title"):setVisible(false)

	local ui = builder:build("GVG_menber")
	self:addChild(ui)
	self.mainUI = ui

	local backBtn = Button:create(self.mainUI:getChildByName("r_click"))
	backBtn:addEventListener(Events.kStart, onBackBtnClick, self)

	self.mainUI:getChildByName("icon_gold"):setVisible(false)
	self.mainUI:getChildByName("sky_btn_qa"):setVisible(false)
	self.mainUI:getChildByName("icon_silverCoin"):setVisible(false)

	--静态文本

	--按钮

	BaseUIScene.onInit(self, SceneMenuTypeEnum.UNION)

	--其他初始化操作

	local function sortFunc( a , b )
		return a.fightCapacity > b.fightCapacity
	end

	local menbersData = CrossUnionPkData.getAllSignedMenbers()
	local inBattleMenbers = {}
	local offBattleMenbers = {}

	for k,v in pairs(menbersData) do
		if v.position > 0 then
			table.insert(inBattleMenbers , v)
		else
			table.insert(offBattleMenbers , v)
		end
	end

	table.sort(inBattleMenbers , sortFunc)
	table.sort(offBattleMenbers , sortFunc)

	local finalMenbers  = {}

	for k,v in pairs(inBattleMenbers) do
		table.insert(finalMenbers , v)
	end

	for k,v in pairs(offBattleMenbers) do
		table.insert(finalMenbers , v)
	end

	local display = self.mainUI:getChildByName("table_Gvg_list4")
	self.tableView = self:createTableView(display , finalMenbers)
	self.mainUI:addChild(self.tableView)
end

-----------------------------------------------内部接口------------------------------------------------------------


function CrossUnionPkMemberSelectScene:createTableView(display , dataList)
    local cellTag = 1024

    local CrossUnionPKTeamAdjustRenderer = class(TableViewRenderer)

    function CrossUnionPKTeamAdjustRenderer:ctor(width , height )
        self.width = width
        self.height = height
        self.list = dataList or {}
    end

    function CrossUnionPKTeamAdjustRenderer:buildCell(container)
        local builder = LayoutBuilder:createWithContentsOfFile("scene/Gvg.json")
        local aCell = builder:build("list/list_Gvg_list4")
        container:addChild(aCell)
        aCell:setTag(cellTag)

        --扫描cell并自动添加tag
        self:addTags(aCell)
    end

    function CrossUnionPKTeamAdjustRenderer:setData(rawCocosObj, index)
        local aCell = self:getChildByTag(rawCocosObj, cellTag)
        local aData = self.list[index + 1]

        --print("aData = " .. tostringRich(aData))

        local aCardDisplay = self:getChildByNames(aCell, "normal_card_small")
        local oldIcon = aCell:getChildByTag(-100)
        if oldIcon then
          oldIcon:removeFromParentAndCleanup(true)
        end
        local params = {}
        params.sourceDisplay = aCardDisplay
        params.showInCenter = true

        local meta = nil
        if aData then
        	meta = CommonManager:getSelfAvatarMetaByUid( aData.uid )
	        if not meta then
	        	meta = aData.mainCardMetaId
	        end
        end
        
        local icon = CanonGoodIcon.createGoodIcon(ResourceEnum.CARD, meta, 0, params)
        aCell:addChild(icon.refCocosObj, aCardDisplay:getZOrder())
        if icon then
          icon:setTag(-100)
          icon:dispose()
        end
        aCardDisplay:setVisible(false)

        self:setTxtByNames(aCell, "txt_guild_member_name/txt", aData.userName)
        self:setTxtByNames(aCell, "txt_guild_14/txt", aData.level)
        self:setTxtByNames(aCell, "txt_guild_15_1/txt", getTextByKey("union_arena_rank_text"))
        self:setTxtByNames(aCell, "txt_guild_16_1/txt", aData.pkRank)
        self:setTxtByNames(aCell, "txt_jj_26/txt", aData.fightCapacity)
        self:setTxtByNames(aCell, "lbl_ztl_jj/txt", getTextByKey("crossArena_battleCapacity"))
        
        self:setTxtByNames(aCell, "common_btn_propInfo_useBtn/txt_propInfo_useBtn", getTextByKey("friend_InfoBtn"))

        if aData.uid == DataManager.getCurrUser().uid then
        	self:getChildByNames(aCell, "common_btn_propInfo_useBtn/normal"):setVisible(false)
			self:getChildByNames(aCell, "common_btn_propInfo_useBtn").ignoreTouch = true
		else
			self:getChildByNames(aCell, "common_btn_propInfo_useBtn/normal"):setVisible(true)
			self:getChildByNames(aCell, "common_btn_propInfo_useBtn").ignoreTouch = false
        end

--         UnionManager.TITLE_NONE 			= 0--无职位(历史职位可能出现此值)
-- UnionManager.TITLE_MANAGER 			= 1--军团长
-- UnionManager.TITLE_VICE_MANAGER 	= 2--副军团长
-- UnionManager.TITLE_ELITE_MEMBER 	= 3--精英成员
-- UnionManager.TITLE_MEMBER 			= 4--普通成员

		local tempTable = {
		"lbl_1st",
		"lbl_2rd",
		"lbl_elite",
		"lbl_mem"
	}
		for k,v in pairs(tempTable) do
			self:getChildByNames(aCell, v):setVisible(false)
		end
		self:getChildByNames(aCell, tempTable[aData.title]):setVisible(true)

		if aData.position ~= 0 then
			if aData.position == 1 then
				self:setTxtByNames(aCell, "txt_guild_15_2/txt", getTextByKey("WGVG_Detail47"))--先锋
			end
			if aData.position >= 10 then
				local row = math.modf(aData.position / 10)
				local line = aData.position - row * 10 + 1
				local lineTxt = ""
				if row == 1 then
					lineTxt = getTextByKey("UnionWar_battle_firstArray")
				elseif row == 2 then
					lineTxt = getTextByKey("UnionWar_battle_array")
				elseif row == 3 then
					lineTxt = getTextByKey("UnionWar_battle_lastArray")
				end
				local finalTxt = lineTxt.. " - "..line..getTextByKey("WGVG_formation9")
				local finalTxt = lineTxt.. getTextByKey("WGVG_formation4") ..line.. getTextByKey("WGVG_formation9")--xx-x号位
				self:setTxtByNames(aCell, "txt_guild_15_2/txt", finalTxt)
			end
		else
			self:setTxtByNames(aCell, "txt_guild_15_2/txt", getTextByKey("WGVG_Detail19"))
		end

		if aData.position == CrossUnionPkData.getCurrentSelectedPos() then--这个玩家就在这个格子上
			self:getChildByNames(aCell, "btn_guildoption/btn"):setVisible(false)
			self:getChildByNames(aCell, "btn_guildoption").ignoreTouch = true
			self:setTxtByNames(aCell, "btn_guildoption/txt", getTextByKey("WGVG_formation1"))--参战成员
		else
			self:getChildByNames(aCell, "btn_guildoption/btn"):setVisible(true)
			self:getChildByNames(aCell, "btn_guildoption").ignoreTouch = false
			if aData.position == 0 then
				self:setTxtByNames(aCell, "btn_guildoption/txt", getTextByKey("WGVG_Detail46"))
				self:setTxtByNames(aCell, "btn_guildoption/txt", getTextByKey("WGVG_Detail46"))--上阵
			else
				self:setTxtByNames(aCell, "btn_guildoption/txt", getTextByKey("WGVG_formation2"))
			end
		end

		--金币鼓舞 / 银币鼓舞
		self:setTxtByNames(aCell, "txt_Gvg_24/txt", getTextByKey("UnionWar_battle_gold") .. getTextByKey("WGVG_Detail45") .. aData.gemInspireNum .. getTextByKey("activity_fireworks_remain1"))--金币鼓舞：x次
		self:setTxtByNames(aCell, "txt_Gvg_25/txt", getTextByKey("UnionWar_battle_silver") .. getTextByKey("WGVG_Detail45") .. "+" .. (aData.coinInspireNum * UnionPkConfig.silverBuff()) .. "%")--银币鼓舞: +xx%

		if aData.striveInspireNum >= 1 then
			--有奋力一击
			self:getChildByNames(aCell, "icon_blow"):setVisible(true)
		else
			--无奋力一击
			self:getChildByNames(aCell, "icon_blow"):setVisible(false)
		end

        -- --不显示按钮
        -- self:getChildByNames(aCell, "btn"):setVisible(false)
    end

    local function onListItemTouch( evt )
		local aIndex = evt.data + 1
		local newCell = self.tableView:cellAtIndex(aIndex - 1)
		local aCell = newCell:getChildByTag(cellTag)
		local posInCell = newCell:convertToNodeSpace(evt.globalPosition)

		local btn_guildoption = self.renderer:getChildByNames(aCell,"btn_guildoption")
		local btn_guildoptionDisplay = self.renderer:getChildByNames(aCell,"btn_guildoption/btn")
		if posInCell.x > btn_guildoption:getPositionX() and
		    posInCell.x < (btn_guildoption:getPositionX() + btn_guildoptionDisplay:getContentSize().width) and
		    posInCell.y > (btn_guildoption:getPositionY() - btn_guildoptionDisplay:getContentSize().height) and
		    posInCell.y < btn_guildoption:getPositionY() and not btn_guildoption.ignoreTouch then
		    print("点到btn_guildoption")
		    local signMembers = dataList
		    local selectPos = CrossUnionPkData.getCurrentSelectedPos()
		    local oldMemberIndex = 0
		    for k,v in pairs(signMembers) do
		    	if v.position == selectPos then
		    		oldMemberIndex = k
		    		break
		    	end
		    end
		    if oldMemberIndex ~= 0 then
		    	local temp = signMembers[oldMemberIndex].position
	    		signMembers[oldMemberIndex].position = signMembers[aIndex].position
	    		signMembers[aIndex].position = temp
	    	else
	    		signMembers[aIndex].position = selectPos
		    end 
		    CrossUnionPkData.setAllSignedMenbers(signMembers)
		    CrossUnionPkData.setTeamAdjustLightOn(true)
		    self:back()
		end

		local btn_Info = self.renderer:getChildByNames(aCell,"common_btn_propInfo_useBtn")
		local btn_InfoDisplay = self.renderer:getChildByNames(aCell,"common_btn_propInfo_useBtn/normal")
		if posInCell.x > btn_Info:getPositionX() and
		    posInCell.x < (btn_Info:getPositionX() + btn_InfoDisplay:getContentSize().width) and
		    posInCell.y > (btn_Info:getPositionY() - btn_InfoDisplay:getContentSize().height) and
		    posInCell.y < btn_Info:getPositionY() then
		    print("common_btn_propInfo_useBtn")
		    local signMembers = dataList
		    CrossArena.gotoUserFormationScene(signMembers[aIndex].uid ,nil,nil, "CrossUnionPkMemberSelectScene")
		end
    end

    local builder = LayoutBuilder:createWithContentsOfFile("scene/Gvg.json")
    local aCell = builder:build("list/list_Gvg_list4")

    local tableViewSizes = getTableViewSizes(display)
    display:setVisible(false)

    self.renderer = CrossUnionPKTeamAdjustRenderer.new(tableViewSizes.item_width, tableViewSizes.item_height)
    self.renderer:scanTags(aCell)

    local btnTag1 = self.renderer:getTagByLayerName("btn_guildoption")
    local btnTag2 = self.renderer:getTagByLayerName("common_btn_propInfo_useBtn")

    local aTableView = TableView:create(self.renderer, tableViewSizes.table_width, tableViewSizes.table_height, cellTag, {btnTag1 , btnTag2}, CCScale9Sprite:create("pic/scroll.png"), CCScale9Sprite:create("pic/scroll.png"))
    aTableView:setPosition(ccp(tableViewSizes.table_posX, tableViewSizes.table_posY))
    aTableView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch , self)
    -- self.mainUI:addChild(aTableView)
    return aTableView
end

-----------------------------------------------外部接口------------------------------------------------------------

function CrossUnionPkMemberSelectScene:setTableViewsEnabled(enabled)
	
end

-----------------------------------------------进出场景动画------------------------------------------------------------
function CrossUnionPkMemberSelectScene:doEnterAnimation()
	self:preEnterAnimation()
	self:startEnterAnimation()
end 

function CrossUnionPkMemberSelectScene:preEnterAnimation()
	BaseUIScene.preEnterAnimation(self)
	--
	CanonPlayBackgroundMusic("music/m_unionPk.mp3", true)
end

function CrossUnionPkMemberSelectScene:startEnterAnimation()
	BaseUIScene.startEnterAnimation(self)
	local function enterActionFinished()
		self:nodeAnimationFinished()
	end

	self.mainUI:setPositionX(self.mainUI:getPositionX() - visibleSize.width)
	local arr = CCArray:create()
	arr:addObject(CCMoveBy:create(0.3, ccp(visibleSize.width, 0)))
	arr:addObject(CCCallFunc:create(enterActionFinished))
	self.mainUI:runAction(CCSequence:create(arr))

end

function CrossUnionPkMemberSelectScene:sufEnterAnimation()
	BaseUIScene.sufEnterAnimation(self)
end

function CrossUnionPkMemberSelectScene:doExitAnimation()
	self:preExitAnimation()
	self:startExitAnimation()
end

function CrossUnionPkMemberSelectScene:preExitAnimation()
	BaseUIScene.preExitAnimation(self)
end

function CrossUnionPkMemberSelectScene:startExitAnimation()
	BaseUIScene.startExitAnimation(self)
	local function enterActionFinished()
		self:nodeAnimationFinished()
	end

	local arr = CCArray:create()
	arr:addObject(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
	arr:addObject(CCCallFunc:create(enterActionFinished))
	self.mainUI:runAction(CCSequence:create(arr))
end

function CrossUnionPkMemberSelectScene:sufExitAnimation()
	BaseUIScene.sufExitAnimation(self)
end
-----------------------------------------------进出场景动画------------------------------------------------------------

-- 退出到外层
function CrossUnionPkMemberSelectScene:back()
	local scene = Director:mgr():run()
	local backStage = CrossUnionPkUtils.findCurrentTimeLevel()
	if self.enterStage == CrossUnionPkConsts.TIME_ARMY1_PREPARE or
		self.enterStage == CrossUnionPkConsts.TIME_ARMY1_FIGHTING then
		if backStage == CrossUnionPkConsts.TIME_ARMY1_PREPARE or
			backStage == CrossUnionPkConsts.TIME_ARMY1_FIGHTING then
			scene:replaceScene(CrossUnionPKTeamAdjustScene)
		else
			CrossUnionPk.gotoCrossLoginUnionPkScene()
		end
	elseif self.enterStage == CrossUnionPkConsts.TIME_ARMY2_PREPARE then
		if backStage ~= CrossUnionPkConsts.TIME_ARMY2_PREPARE then
			CrossUnionPk.gotoCrossLoginUnionPkScene()
		else
			scene:replaceScene(CrossUnionPKTeamAdjustScene)
		end
	else
		CrossUnionPk.gotoCrossLoginUnionPkScene()
	end
end

function CrossUnionPkMemberSelectScene:dispose()

	CrossUnionPkMemberSelectScene.super.dispose(self)
end

