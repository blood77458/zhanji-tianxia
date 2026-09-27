-- EnchantScene.lua
-- 2014-12-15
-- zheng.che
-- 装备附灵主场景

require "canon.scene.BaseUIScene"

local colorBarNameList = {
	"q_white9_panel",
	"q_green9_panel",
	"q_blue9_panel",
	"q_purple9_panel",
	"q_orange9_panel",
	"q_red9_panel",
	"q_yellow9_panel",
}

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

local enter_animation_duration = 0.3
local selectedText = ""

-------------------------------------------------------------------------------
-- 按钮点击
-------------------------------------------------------------------------------


--点击附灵按钮
local function onConfirmClick(evt)
	local self = evt.context
	if tonumber(Get_ShareData( "Sacrifice_Guide_Running")) == 1 then
		Set_ShareData( "Sacrifice_Guide_Running", 0 )
		local enchantInfo = EnchantUtils.findEnchantInfo(self.equipData.metaId, self.equipData.enchantLevel)
		EnchantData.setEnchantPoint(EnchantData.getEnchantPoint() - enchantInfo.cost)
		self.equipData.enchantLevel = self.equipData.enchantLevel + 1
		self.refreshSelf()
		EnchantData.setEnchantPoint(EnchantData.getEnchantPoint() - EnchantData.guideEnchantNum)
		local scene = Director:mgr():run()
		SuspensionLabel:showContent(scene, Localization:getInstance():getText("enchant_10"))--附灵成功！
		local rewardPanel = EnchantGuideRewardPanel:create(self)
		PopoutManager:sharedManager():popout(rewardPanel, kPopoutDir.kScale, true, false , self)
    else
		EnchantUpgradeRequest.sendRequestDefalut(self.equipData, self.refreshSelf)
	end
end
--点击去祭炼按钮
local function onChangeSceneClick(evt)
	local self = evt.context
	self:replaceScene(CardRebirthScene)
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

EnchantScene = class(BaseUIScene)

function EnchantScene:ctor()
end

function EnchantScene:create(argv)
	local s = EnchantScene.new()
	if argv then 
		s.argv = argv 
	else
		s.argv = {enterScene=nil,returnScene=nil,params={}}
	end
	s.curSceneEnum = SceneEnum.EnchantScene
	s.selectedPanel = nil

	s:initScene()
	return s
end

function EnchantScene:onInit()
	BaseUIScene.initBackGround(self)
	--标题
	self.title = Localization:getInstance():getText("enchant_1")--附灵

	self.targetInfoPanel = nil

	--获得基本数据
	if self.argv.enterScene == "EquipQuickUpgradeScene" then
		-- print("~~~~~~~~~~~~~EquipQuickUpgradeScene")
		self.equipData = self.argv.params.equip
	else
		self.equipData = self.argv.params.equipData
	end
	self.equipMetaData = MetaManager.equip_meta[tonumber(self.equipData.metaId, 10)]    
	self.equipLevelConfig = MetaManager.equip_level[self.equipData.level]
	self.enchantInfo = EnchantUtils.findEnchantInfo(self.equipData.metaId, self.equipData.enchantLevel)

	--print("self.equipData = " .. tostringRich(self.equipData))
	
	self.tempLayer = Layer:create()
	self.tempLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
	self:addChild(self.tempLayer)
	self.tempLayer:setAnchorPoint(ccp(0.5, 0.5))

	local builder = LayoutBuilder:createWithContentsOfFile("scene/enchant.json")
	builder.useArtLabelTTF = true
	local ui = builder:build("enchant")
	self.tempLayer:addChild(ui)
	self.ui = ui

	--刷新自身
	function refreshSelf()
		self.enchantInfo = Enchant.findEnchantInfo(self.equipData.metaId, self.equipData.enchantLevel)--获得最新的附灵配置信息
        if self.argv.enterScene == "EquipQuickUpgradeScene"  then
	       -- self.argv.params.container.queue[self.argv.params.cardPos].equips[self.argv.params.EquipPos] = self.equipData
	       self.argv.params.equip = self.equipData
        end
		--显示下一等级效果
		self.ui:getChildByName("txt_6"):setVisible(false)
		self.ui:getChildByName("attribute_04"):setVisible(false)
		self.ui:getChildByName("txt_2"):setVisible(false)
		self.ui:getChildByName("txt_1"):setVisible(false)
		self.ui:getChildByName("txt_enchant_13"):setVisible(false)
		self.ui:getChildByName("txt_enchant_13"):setVisible(false)
		self.ui:getChildByName("txt_5"):setVisible(false)
		
		if not EnchantCheck.isFullSkillLevel(self.equipData.enchantLevel) then
			--没满级
			self.ui:getChildByName("txt_6"):setVisible(true)
			self.ui:getChildByName("attribute_04"):setVisible(true)
			--self.ui:getChildByName("txt_2"):setVisible(true)

			--显示下一等级
			--self.ui:getChildByName("txt_2"):getChildByName("txt"):setString(EnchantUtils.getEnchantLevelStr(self.equipData.enchantLevel + 1))--+[附灵等级]

			--下一等级增加属性信息
			local nextLevelAddAttrInfo = EnchantUtils.getLevelAddAttrInfo(self.equipData.metaId, self.equipData.enchantLevel + 1)
			--显示下一等级增加的属性
			EnchantUtils.setAttrShow(self.ui:getChildByName("attribute_04"), nextLevelAddAttrInfo.attrId, "+" .. math.floor(nextLevelAddAttrInfo.addNum), 1)

			--显示下一等级技能预告
			if self.enchantInfo.nextLevelSkillInfo then
				--有技能
				self.ui:getChildByName("txt_1"):setVisible(true)
				local nextSkillName = EnchantUtils.getSkillName(self.enchantInfo.nextLevelSkillInfo.id)
				if self.enchantInfo.nextLevelSkillInfo.isNew then
					--觉醒
					self.ui:getChildByName("txt_1"):getChildByName("txt"):setString(Localization:getInstance():getText("enchant_4", {skillname = nextSkillName}))--{skillname}将觉醒
				else
					--升级
					self.ui:getChildByName("txt_1"):getChildByName("txt"):setString(Localization:getInstance():getText("enchant_5", {skillname = nextSkillName}))--{skillname}将升级
				end
			end

			--显示升阶消耗
			self.ui:getChildByName("txt_5"):setVisible(true)
			self.ui:getChildByName("txt_5"):getChildByName("txt"):setString(Localization:getInstance():getText("enchant_6") .. self.enchantInfo.cost)--升阶消耗：[]
		else
			--满级
			self.ui:getChildByName("txt_enchant_13"):setVisible(true)
		end

		--显示附灵等级
		self.ui:getChildByName("txt_3"):getChildByName("txt"):setString(EnchantUtils.getEnchantLevelStr(self.equipData.enchantLevel))--+[附灵等级]

		--显示附加的一级属性
		local attrInfos = EquipUtils.findFirstAttrs(self.equipData.metaId, self.equipData.level, self.equipData.enchantLevel)
		for i = 1, (ConstManager.HEAD_ATTR_COUNT) do
			local enchantDisplay = self.ui:getChildByName("attribute_0" .. i)
			if enchantDisplay then
				local attrInfo = attrInfos[i]
				if attrInfo then
					--有附加属性
					enchantDisplay:setVisible(true)
					if i == 1 then
						--普通属性
						EnchantUtils.setAttrShow(enchantDisplay, attrInfo.id, math.floor(attrInfo.num), 1)
					else
						EnchantUtils.setAttrShow(enchantDisplay, attrInfo.id, math.floor(attrInfo.num), 2)
					end
				else
					--无附加属性
					enchantDisplay:setVisible(false)
				end
			end
		end

		--显示剩余灵值
		self.ui:getChildByName("txt_7"):getChildByName("txt"):setString(Localization:getInstance():getText("enchant_7"))--剩余灵值：
		self.ui:getChildByName("txt_4"):getChildByName("txt"):setString(EnchantData.getEnchantPoint())--[剩余灵值]

		--设置附灵条件不同的状态
		if EnchantCheck.canEnchant(self.equipData) then
			--附灵条件满足
			self.confirmButton:setEnable(true)
			self.confirmButton.display:getChildByName("normal"):setVisible(true)

		else
			--不能附灵
			self.confirmButton:setEnable(false)
			self.confirmButton.display:getChildByName("normal"):setVisible(false)
		end

		--刷新列表内容
		for i = #self.dataList, 1, -1 do
			table.remove(self.dataList, i)
		end
		local tempList = {}
		if self.enchantInfo and self.enchantInfo.skills then
			tempList = self.enchantInfo.skills
		end
		for _, v in ipairs(tempList) do
			--要有值才能显示
			table.insert(self.dataList, v)
		end
		self.listTableView:reloadData()
	end
	self.refreshSelf = refreshSelf

	--静态文本
	self.ui:getChildByName("btn_enchant_blue_4words"):getChildByName("txt"):setString(Localization:getInstance():getText("enchant_9"))--去祭炼
	self.ui:getChildByName("btn_mainStory"):getChildByName("txt_guild_66"):getChildByName("txt"):setString(Localization:getInstance():getText("enchant_1"))--附灵
	--self.ui:getChildByName("txt_enchant_03"):getChildByName("txt"):setString(Localization:getInstance():getText("enchant_1"))--附灵
	self.ui:getChildByName("txt_6"):getChildByName("txt"):setString(Localization:getInstance():getText("enchant_3"))--下一阶
	self.ui:getChildByName("txt_1"):getChildByName("txt"):setString(Localization:getInstance():getText("enchant_4"))--技能觉醒
	self.ui:getChildByName("txt_enchant_13"):getChildByName("txt"):setString(Localization:getInstance():getText("enchant_11"))--此装备附灵已经达到满级。

	--按钮
	self.confirmButton = Button:create(self.ui:getChildByName("btn_mainStory"))
	self.confirmButton:addEventListener(Events.kStart, onConfirmClick, self)

	local changeSceneButton = Button:create(self.ui:getChildByName("btn_enchant_blue_4words"))
	changeSceneButton:addEventListener(Events.kStart, onChangeSceneClick, self)

	--显示装备图标
	local equipObject = CanonItem:create()
    equipObject:loadByMetaId(self.equipData.metaId)
	equipObject:setScale(130/150)
	local position = self.ui:getChildByName("normal_card_small_sb"):getPosition()
	equipObject:setPosition(ccp(position.x,position.y))
	self.ui:addChild(equipObject)
	self.ui:getChildByName("normal_card_small_sb"):setVisible(false)

	--显示装备名称
	local euqipName = CanonGoodIcon.getGoodNameWithoutNum(ResourceEnum.EQUIP, self.equipData.metaId)
	self.ui:getChildByName("txt_8"):getChildByName("txt"):setString(euqipName)

	--显示装备等级
	self.ui:getChildByName("txt_equip_lv_num"):getChildByName("font"):setString(self.equipData.level)
	--self.ui:getChildByName("txt_equip_lv_num"):getChildByName("font"):setColor(ccc3(255, 244, 92))
	--self.ui:getChildByName("txt_equip_lv_num"):getChildByName("font"):setAroundColor(ccc3(100, 28, 28))

	--显示是否有卡牌已装备
	local aCardId = self.equipData.cardId
	if (aCardId~=0) then
		local cardsData = DataManager.getCardsData()
		local aCardMeta = CommonManager.getSubTableByKey(
			cardsData,
			{name="cardId", value=aCardId}
		).metaId
		local aCardName = MetaManager.card_meta[aCardMeta].name
		self.ui:getChildByName("txt_equip_equipedby"):getChildByName("txt"):setString(Localization:getInstance():getText("bag_EquippedText",{cardname = getTextByKey(aCardName)}))
		self.ui:getChildByName("zhuangbeizhong"):setZOrder(2001)
	else
		self.ui:getChildByName("txt_equip_equipedby"):getChildByName("txt"):setVisible(false)
		self.ui:getChildByName("zhuangbeizhong"):setVisible(false)
	end
	
	--显示品质颜色横条
	for quality = 1, 7 do
		local aQualityPanel = self.ui:getChildByName(colorBarNameList[quality])
		aQualityPanel:setVisible(false)
	end
	self.ui:getChildByName(colorBarNameList[self.equipMetaData.quality]):setVisible(true)

	--显示星星
	self.ui:getChildByName("icon_star_2"):setVisible(false)
	self.ui:getChildByName("icon_star_3"):setVisible(false)
	self.ui:getChildByName("icon_star_4"):setVisible(false)
	self.ui:getChildByName("icon_star_5"):setVisible(false)
	local POSx = self.ui:getChildByName("icon_star_1"):getPositionX()
	local POSY = self.ui:getChildByName("icon_star_1"):getPositionY()
	for quality = 1, 7 do
		if (quality == self.equipMetaData.quality) then
			break
		end
		local aStarSpt = Sprite:create(UI_RES_PATH.."/common_new/common_star_sb.png")
		aStarSpt:setAnchorPoint(ccp(0,1))
		POSx = POSx - 28
		aStarSpt:setPosition(ccp(POSx,POSY))
		self.ui:addChild(aStarSpt)
	end

	--注册事件
	UiStackManager_EventDispatcher:addEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged, self)

	--显示列表
	self.dataList = {}
	self.listTableView = self:createListTableView()
	self.ui:addChild(self.listTableView)

	self.refreshSelf()

	BaseUIScene.onInit(self)
end

--------------------------------------------------------------------------------------------------------------------------------------tableview

function EnchantScene:createListTableView()
	local cellTag = 1024
	local buttonTag = {}
	local aListPanel = self
	local equipEnchantInfoListTableViewRenderer = class(TableViewRenderer)
	function equipEnchantInfoListTableViewRenderer:ctor(width, height)
		self.list = aListPanel.dataList or {}
	end
	function equipEnchantInfoListTableViewRenderer:buildCell(container)
		local builder = LayoutBuilder:createWithContentsOfFile("scene/enchant.json")
		builder.useArtLabelTTF = true
		local aCell = builder:build("enchant_list_1")
		container:addChild(aCell)
		aCell:setTag(cellTag)

		local aName1Label = aCell:getChildByName("txt_1")
		aName1Label:setTag(-11)
		aName1Label = aName1Label:getChildByName("txt")
		aName1Label:setTag(-11)

		local aName2Label = aCell:getChildByName("txt_4")
		aName2Label:setTag(-12)
		aName2Label = aName2Label:getChildByName("txt")
		aName2Label:setTag(-11)

		local aDescLabel = aCell:getChildByName("txt_3")
		aDescLabel:setTag(-13)
		aDescLabel = aDescLabel:getChildByName("txt")
		aDescLabel:setTag(-11)

		local aDesc2Label = aCell:getChildByName("txt_enchant_14")
		aDesc2Label:setTag(-14)
		aDesc2Label = aDesc2Label:getChildByName("txt")
		aDesc2Label:setTag(-11)

		local aNeedLevelLabel = aCell:getChildByName("txt_2")
		aNeedLevelLabel:setTag(-15)
		aNeedLevelLabel = aNeedLevelLabel:getChildByName("txt")
		aNeedLevelLabel:setTag(-11)
	end

	function equipEnchantInfoListTableViewRenderer:setData( rawCocosObj, index )
		local aCell = self:getChildByTag(rawCocosObj, cellTag)
		local aData = self.list[index + 1]
		-- print("aData = " .. table.tostring(aData))
		-- print("aCell:getPositionY = " .. table.tostring(aCell:getPositionY()))

		--
		local aName1Label = aCell:getChildByTag(-11)
		local aName2Label = aCell:getChildByTag(-12)
		local aDescLabel = aCell:getChildByTag(-13)
		local aDesc2Label = aCell:getChildByTag(-14)
		local aNeedLevelLabel = aCell:getChildByTag(-15)
		-- print("aName1Label:getPositionY = " .. table.tostring(aName1Label:getPositionY()))
		-- print("aName2Label:getPositionY = " .. table.tostring(aName2Label:getPositionY()))

		aName1Label:setVisible(false)
		aName2Label:setVisible(false)
		aDescLabel:setVisible(false)
		aDesc2Label:setVisible(false)
		aNeedLevelLabel:setVisible(false)

		local skillMeta = EnchantConfig.getSkillMeta(aData.id)
		local enchantName = EnchantUtils.getSkillName(aData.id, aData.openTimes)

		
		if aData.openTimes <= 0 then
			--未开启
			aName1Label:setVisible(true)
			setNodeText(aName1Label:getChildByTag(-11), enchantName)

			--显示觉醒所需等级
			aNeedLevelLabel:setVisible(true)
			local needLevelStr = Localization:getInstance():getText("enchant_2", {level = "+" .. aData.nextOpenLevel})--（需附灵{level}觉醒）
			setNodeText(aNeedLevelLabel:getChildByTag(-11), needLevelStr)

			--显示技能说明
			aDescLabel:setVisible(true)
			local addNum = EnchantUtils.findSkillAddNum(aListPanel.equipData.metaId, aData.id, 1)
			local enchantDesc = EnchantUtils.getSkillDesc(aData.id, addNum)
			setNodeText(aDescLabel:getChildByTag(-11), enchantDesc)
		else
			--开启
			aName2Label:setVisible(true)
			setNodeText(aName2Label:getChildByTag(-11), enchantName)

			--显示技能说明
			aDesc2Label:setVisible(true)
			local enchantDesc = EnchantUtils.getSkillDesc(aData.id, aData.num)
			setNodeText(aDesc2Label:getChildByTag(-11), enchantDesc)

			--显示升级所需等级
			if aData.nextOpenLevel ~= -1 then
				--未满级
				aNeedLevelLabel:setVisible(true)
				local needLevelStr = Localization:getInstance():getText("enchant_14", {level = "+" .. aData.nextOpenLevel})--（需附灵{level}升级）
				setNodeText(aNeedLevelLabel:getChildByTag(-11), needLevelStr)
			end
		end
	end

	local tableViewSizes = getTableViewSizes(self.ui:getChildByName("table_enchant_list"))
	self.ui:getChildByName("table_enchant_list"):setVisible(false)
	tableViewSizes.table_width = 660
	tableViewSizes.item_width = 650
	--tableViewSizes.table_posY = -tableViewSizes.table_posY
	local renderer = equipEnchantInfoListTableViewRenderer.new(tableViewSizes.item_width, tableViewSizes.item_height)
	local aTableView = TableView:create(renderer, tableViewSizes.table_width, tableViewSizes.table_height, cellTag, buttonTag, CCScale9Sprite:create("pic/scroll.png"), CCScale9Sprite:create("pic/scroll.png"))
	aTableView:setPosition(ccp(tableViewSizes.table_posX, tableViewSizes.table_posY))

	aTableView.hitTestPoint = function (self, worldPosition, useGroupTest)
		return false -- 修复遮挡下方按钮的bug
	end

	return aTableView
end

-----------------------------------------------内部接口------------------------------------------------------------

-----------------------------------------------外部接口------------------------------------------------------------

function EnchantScene:setTableViewsEnabled(enabled)
end

-----------------------------------------------进出场景动画------------------------------------------------------------
function EnchantScene:doEnterAnimation()
	self:preEnterAnimation()
	self:startEnterAnimation()
end

function EnchantScene:preEnterAnimation()
	BaseUIScene.preEnterAnimation(self)
	--
	CanonPlayBackgroundMusic("music/background.mp3", true)
end

function EnchantScene:startEnterAnimation()
	BaseUIScene.startEnterAnimation(self)
	local function enterActionFinished()
		self:nodeAnimationFinished()
	end

	self.ui:setPositionX(self.ui:getPositionX() - visibleSize.width)
	local arr = CCArray:create()
	arr:addObject(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
	arr:addObject(CCCallFunc:create(enterActionFinished))
	self.ui:runAction(CCSequence:create(arr))
end

function EnchantScene:sufEnterAnimation()
	BaseUIScene.sufEnterAnimation(self)
	--
end

function EnchantScene:doExitAnimation()
	self:preExitAnimation()
	self:startExitAnimation()
end

function EnchantScene:preExitAnimation()
	BaseUIScene.preExitAnimation(self)
end

function EnchantScene:startExitAnimation()
	BaseUIScene.startExitAnimation(self)
	local function enterActionFinished()
		self:nodeAnimationFinished()
	end

	local arr = CCArray:create()
	arr:addObject(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
	arr:addObject(CCCallFunc:create(enterActionFinished))
	self.ui:runAction(CCSequence:create(arr))
end

function EnchantScene:sufExitAnimation()
	BaseUIScene.sufExitAnimation(self)
end
-----------------------------------------------进出场景动画------------------------------------------------------------

-- 退出到外层
function EnchantScene:back()
	if self.argv.returnScene == "BackpackScene" then
		self:replaceScene(BackpackScene,{params = {isCardTrain = false, tabIndex = BAGCATEGORY.equip}})
	elseif self.argv.returnScene == "CardQueueScene" then
		self:replaceScene( CardQueueScene, {enterScene="EnchantScene",returnScene="EnchantScene"} )
	elseif self.argv.returnScene == "EquipQuickUpgradeScene" then
		self.argv.enterScene = "CardQueueScene"
	    self.argv.returnScene = "CardQueueScene"
	    self:replaceScene( EquipQuickUpgradeScene , self.argv)
	else
		self:replaceScene(MainMenuScene)
	end
end

function EnchantScene:dispose()
	--print("EnchantScene:dispose")
	UiStackManager_EventDispatcher:removeEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged)

	if self.tickEntry then
		CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.tickEntry)
	end

	EnchantScene.super.dispose(self)
end

--------------------------------------------------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- 自有逻辑
-------------------------------------------------------------------------------

