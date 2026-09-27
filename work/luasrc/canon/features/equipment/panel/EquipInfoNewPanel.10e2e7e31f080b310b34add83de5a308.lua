-- EquipInfoNewPanel.lua
-- 2014-12-4
-- zheng.che
-- 新装备详情

--self.container._data

require "canon.panel.ItemSellMessageBoxPanel"
require "canon.features.equipment.panel.EequipDescPagePanel"
require "canon.features.equipment.panel.EequipEnchantPagePanel"
require "canon.features.equipment.manager.EquipUtils"

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


local function onClickEvolveBtn(evt)
	local self = evt.context
	local scene = Director:mgr():run()
	PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )

	scene:replaceScene( EquipEvolveScene, self.argv )
end

local function onClickUpgradeBtn(evt)
	local self = evt.context
	local scene = Director:mgr():run()
	if self.equipData.level >= DataManager.getCurrUser().level then
		SuspensionLabel:showContent(self, getTextByKey("equip_LevelMaxText"))
	else
		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
		scene:replaceScene( EquipUpgradeScene, self.argv )
	end
end

--附灵
local function onClickEnchantSceneBtn(evt)
	local self = evt.context
	local scene = Director:mgr():run()
	if (DataManager.getCurrUser().level >= MetaManager.getGameSettingConfig().sacrificeUnlockLevel) and (not IsGuideExecuted(GuideConfig.kSacrifice)) and (tonumber(Get_ShareData( "Sacrifice_Guide_Running")) ~= 1) then
		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
		scene:replaceScene(CardRebirthScene)
		return
	end

	if Enchant.canEnterEnchant(true) then
		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
        if self.argv.enterScene == "EquipQuickUpgradeScene" then
        	Enchant.gotoEnchantScene(self.equipData, self.argv.enterScene, self.argv.returnScene,self.argv)
        else
			Enchant.gotoEnchantScene(self.equipData, self.argv.enterScene, self.argv.returnScene)
	    end
	end
end

local function onClickChangeBtn(evt)
	local self = evt.context
	local scene = Director:mgr():run()
	local cardQueue = CommonManager.getQueueData()
	local cardIds = {}
	for aKey, aCardId  in pairs(cardQueue) do
		cardIds[aCardId] = aKey
	end
	HeMemDataHolder:setInteger("CardQueue_RollTo", cardIds[self.equipData.cardId])
	HeMemDataHolder:setInteger("EquipChange_Position", self.equipMetaData.position)
	HeMemDataHolder:setInteger("EquipChange_NowEquipId", self.equipData.equipId)
	local argv = {}
	if self.argv.enterScene == "EquipQuickUpgradeScene" then
		 argv = {
			enterScene="CardQueueScene",
			returnScene="CardQueueScene",
			params={
				--cardPos = cardNo,
				cardId = self.equipData.cardId,
				tabIndex = BAGCATEGORY.equip,
				filter = BACKPACK_FILTER.EQUIP,
				filterFunc = CardQueueScene.equipFilterFunc,
				isCardTrain = false,
				argvs = self.argv,
			}
		}
	else
		argv = {
			enterScene="CardQueueScene",
			returnScene="CardQueueScene",
			params={
				--cardPos = cardNo,
				cardId = self.equipData.cardId,
				tabIndex = BAGCATEGORY.equip,
				filter = BACKPACK_FILTER.EQUIP,
				filterFunc = CardQueueScene.equipFilterFunc,
				isCardTrain = false,
			}
		}
	end
	if self.argv.returnScene and self.argv.returnScene ~= "EquipQuickUpgradeScene"  then
		print("~~~~~~~~~~~~~~~~进来了")
		argv.returnScene = self.argv.returnScene
	end

	PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
	scene:replaceScene( BackpackScene , argv)
end

local function onClickSellBtn(evt)
	local self = evt.context
	local scene = Director:mgr():run()
    local aPanel = ItemSellMessageBoxPanel:create( scene , {equipData={self.equipData.equipId}}, self , self.argv.params.index)
	scene:addChild(aPanel)
	aPanel:scaleIn()
end

local function onClosePanel(evt)
	local self = evt.context
	local scene = Director:mgr():run()
	if scene.setTableViewsEnabled then
		scene:setTableViewsEnabled(true)
	end
	scene.targetInfoPanel = nil
	PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
end

--点击简介
local function onClickDescBtn(evt)
	local self = evt.context
	self.tabChangeComponent:changeToPanelByIndex(EquipInfoNewPanel.TAB_DESC)
end

--点击附灵
local function onClickEnchantBtn(evt)
	local self = evt.context
	self.tabChangeComponent:changeToPanelByIndex(EquipInfoNewPanel.TAB_ENCHANT)
end

-----------------------------------------------------------------------------------------------------------------------------------------------------------

EquipInfoNewPanel = class(Layer)

--翻页定义
EquipInfoNewPanel.TAB_DESC = 1--装备说明
EquipInfoNewPanel.TAB_ENCHANT = 2--装备附灵

function EquipInfoNewPanel:ctor()
	self.equipData = nil
	self.argv = nil
end

function EquipInfoNewPanel:create( equipData , argv)
	self.equipData = equipData
	if argv then 
		self.argv = argv 
	else
		self.argv = {enterScene=nil,returnScene=nil,params={}}
	end
	--print("EquipInfoNewPanel:create! argv = " .. tostringRich(argv))

	local s = EquipInfoNewPanel.new()
	s:initLayer()
	return s
end

function EquipInfoNewPanel:initLayer()
	local scene = Director:mgr():run()
	if scene.setTableViewsEnabled then
		scene:setTableViewsEnabled(false)
	end

	EquipInfoNewPanel.super.initLayer(self)

	--用于生成新panle
	local function onCreatePanel(aIndex)
		if aIndex == EquipInfoNewPanel.TAB_DESC then
			return EequipDescPagePanel:create(self.panelUI:getChildByName("common_equipInfo_upper"):getChildByName("Introduction_pagin"), self.equipData)
		elseif aIndex == EquipInfoNewPanel.TAB_ENCHANT then
			return EequipEnchantPagePanel:create(self.panelUI:getChildByName("common_equipInfo_upper"), self.equipData)
		end
		print("无效的panle编号! aIndex = " .. aIndex)
	end
	
	local builder = LayoutBuilder:createWithContentsOfFile("scene/common_new.json")
	builder.useArtLabelTTF = true
	self.panelUI = builder:build("common_popup_equipInfo_02")
	self:addChild(self.panelUI)

	--固定文本
	self.panelUI:getChildByName("common_txt_equipInfo"):getChildByName("txt_equipInfo"):setString(Localization:getInstance():getText("equipInfo_Title"))

	self.equipMetaData = MetaManager.equip_meta[tonumber(self.equipData.metaId, 10)]    
	self.equipLevelConfig = MetaManager.equip_level[self.equipData.level]
	self:refreshData()

	--关闭按钮
	local bt_panel_close = Button:create(self.panelUI:getChildByName("common_btn_close"))
	bt_panel_close:addEventListener(Events.kStart, onClosePanel, self)

	self.panelUI:getChildByName("common_equipInfo_upper"):getChildByName("normal_card_small_sb"):setVisible(false)

	--设置装备
	local equipObject = CanonItem:create()
	equipObject:loadByMetaId(self.equipData.metaId)
	equipObject:setScale(130/150)
	local position = self.panelUI:getChildByName("common_equipInfo_upper"):getChildByName("normal_card_small_sb"):getPosition()
	equipObject:setPosition(ccp(position.x,position.y))
	self.panelUI:getChildByName("common_equipInfo_upper"):addChild(equipObject)

	--处理tab翻页组件
	self.tabChangeComponent = TabPanelChangeComponent.new(self, onCreatePanel, nil, nil, nil)

	--显示tab
	self.uiGroup1 = self.panelUI:getChildByName("equipInfo_02_title"):getChildByName("btn_introduction")
	self.tab1Button = Button:create(self.uiGroup1)
	self.tab1Button:addEventListener(Events.kStart, onClickDescBtn, self)
	self.tabChangeComponent:addTab(self.tab1Button)

	--区分能否附灵显示状态
	if Enchant.isSupportToEnchant(self.equipData.metaId) then
		--允许附灵
		self.uiGroup2 = self.panelUI:getChildByName("equipInfo_02_title"):getChildByName("btn_enchant")
		self.tab2Button = Button:create(self.uiGroup2)
		self.tab2Button:addEventListener(Events.kStart, onClickEnchantBtn, self)
		self.tabChangeComponent:addTab(self.tab2Button)
	else
		--不允许附灵
		self.panelUI:getChildByName("equipInfo_02_title"):getChildByName("btn_enchant"):setVisible(false)

		--不显示附灵等级
		local area = self.panelUI:getChildByName("common_equipInfo_upper")
		--area:getChildByName("txt_1"):setVisible(false)
		area:getChildByName("txt_3"):setVisible(false)
	end

	--设定初始显示的页面为第一页
	self.tabChangeComponent:changeToPanelByIndex(EquipInfoNewPanel.TAB_DESC)
end

--显示装备固有信息
function EquipInfoNewPanel:refreshData()
	local area = self.panelUI:getChildByName("common_equipInfo_upper")

	--显示装备名称
	local euqipName = CanonGoodIcon.getGoodNameWithoutNum(ResourceEnum.EQUIP, self.equipData.metaId)
	area:getChildByName("txt_skillEnhance_skillName"):getChildByName("txt_skillEnhance_skillName"):setString(euqipName)

	--显示附灵等级
	if self.equipData.enchantLevel > 0 then
		--有附灵等级
		area:getChildByName("lbl_enchant"):setVisible(true)
		area:getChildByName("txt_3"):setVisible(true)
		area:getChildByName("txt_3"):getChildByName("txt"):setString(EnchantUtils.getEnchantLevelStr(self.equipData.enchantLevel))--+[附灵等级]
	else
		area:getChildByName("lbl_enchant"):setVisible(false)
		area:getChildByName("txt_3"):setVisible(false)
	end

	--显示附加的一级属性
	local attrInfos = EquipUtils.findFirstAttrs(self.equipData.metaId, self.equipData.level, self.equipData.enchantLevel)
	for i = 1, (ConstManager.HEAD_ATTR_COUNT) do
		local enchantDisplay = area:getChildByName("attribute_0" .. i)
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
	
	--显示装备属性/等级
	area:getChildByName("txt_equip_lv_num"):getChildByName("font"):setString(self.equipData.level)
	area:getChildByName("txt_equip_lv_num"):getChildByName("font"):setColor(ccc3(255, 244, 92))
	area:getChildByName("txt_equip_lv_num"):getChildByName("font"):setAroundColor(ccc3(100, 28, 28))
	local aCardId = self.equipData.cardId
	if (aCardId~=0) then
		local cardsData = DataManager.getCardsData()
		local aCardMeta = CommonManager.getSubTableByKey(
			cardsData,
			{name="cardId", value=aCardId}
		).metaId
		local aCardName = MetaManager.card_meta[aCardMeta].name
		area:getChildByName("txt_equip_equipedby"):getChildByName("txt_equip_equipedby"):setString(Localization:getInstance():getText("bag_EquippedText",{cardname = getTextByKey(aCardName)}))
		area:getChildByName("zhuangbeizhong"):setZOrder(2001)
	else
		area:getChildByName("txt_equip_equipedby"):getChildByName("txt_equip_equipedby"):setVisible(false)
		area:getChildByName("zhuangbeizhong"):setVisible(false)
	end
	
	for quality = 1, 7 do
		local aQualityPanel = area:getChildByName(colorBarNameList[quality])
		aQualityPanel:setVisible(false)
	end
	area:getChildByName(colorBarNameList[self.equipMetaData.quality]):setVisible(true)

	local POSx = self.panelUI:getChildByName("common_star"):getPositionX()
	local POSY = self.panelUI:getChildByName("common_star"):getPositionY()
	for quality = 1, 7 do
		if (quality == self.equipMetaData.quality) then
			break
		end
		local aStarSpt = Sprite:create(UI_RES_PATH.."/common_new/common_star_sb.png")
		aStarSpt:setAnchorPoint(ccp(0,1))
		POSx = POSx - 28
		aStarSpt:setPosition(ccp(POSx,POSY))
		self.panelUI:addChild(aStarSpt)
	end
	if  (not self.argv.originalScene )  or self.argv.originalScene ~= "EquipQuickUpgradeScene" then
       self.argv.params = self.equipData
    end
	
	--左边按钮 强化/升阶
	local leftBtnDisplay = self.panelUI:getChildByName("common_btn_equip_enhance")
	if ( self.equipData.level >= MetaManager.equip_evolve_level[self.equipMetaData.evolveLevel].levelMax ) then
		--满级 升阶
		leftBtnDisplay:getChildByName("txt_equip_enhance"):setString(Localization:getInstance():getText("equip_Evolve"))--升阶
		if self.equipMetaData.evolveLevel<self.equipMetaData.maxEvolveLevel then
			--允许升阶
			local envolveBtn = Button:create(leftBtnDisplay)
			envolveBtn:addEventListener(Events.kStart, onClickUpgradeBtn, self)
		else
			--没达到升阶条件
			leftBtnDisplay:getChildByName("btn"):setVisible(false)
		end
	else
		--非满级 强化
		leftBtnDisplay:getChildByName("txt_equip_enhance"):setString(Localization:getInstance():getText("equip_Enhance"))--强化
		local upgradeBtn = Button:create(leftBtnDisplay)
		upgradeBtn:addEventListener(Events.kStart, onClickEvolveBtn, self)
	end

	--中间按钮 附灵
	local centerBtnDisplay = self.panelUI:getChildByName("common_btn_equip_Evolve_common")
	if Enchant.isSupportToEnchant(self.equipData.metaId) then
		--此装备允许附灵
		if Enchant.canEnterEnchant(false) then
			--玩家允许进入附灵场景
			centerBtnDisplay:getChildByName("txt_equip_Evolve_common"):setString(Localization:getInstance():getText("enchant_1"))--附灵
			local enchantBtn = Button:create(centerBtnDisplay)
			enchantBtn:addEventListener(Events.kStart, onClickEnchantSceneBtn, self)
		else
			--不允许进入 置灰处理
			centerBtnDisplay:getChildByName("btn"):setVisible(false)
		end
	else
		--不允许附灵 隐蔽
		centerBtnDisplay:setVisible(false)
	end

	--阵容状态
	local queueList = {}
	local gameData = DataManager.getGameInitData()
	for BattleArrayId = 1,3 do
		local quedata = gameData.sharkUserBattleArray[BattleArrayId] and gameData.sharkUserBattleArray[BattleArrayId].sharkUserQueue or {}
		for k,v in pairs(quedata) do
			if (not v.equips) then v.equips = {} end
			for _,value in pairs(v.equips) do
				queueList[value] = true
			end		
		end	
	end
	--end by l1ghtsaber		
	--卖出&更换
	local sellBtnDisplay = self.panelUI:getChildByName("common_btn_equip_SellBtn")
	if (self.equipData.cardId ~= 0) then
		sellBtnDisplay:getChildByName("txt_equip_SellBtn"):setString(Localization:getInstance():getText("equipInfo_ChangeBtn"))
		local sellBtn = Button:create(sellBtnDisplay)
		sellBtn:addEventListener(Events.kStart, onClickChangeBtn, self)
	else
		sellBtnDisplay:getChildByName("txt_equip_SellBtn"):setString(Localization:getInstance():getText("equip_SellBtn"))
		if queueList[self.equipData.equipId] == true then  --不能卖出也不能更换的置灰处理 add by l1ghtsaber		
			sellBtnDisplay:getChildByName("normal"):setVisible(false)
		else
			local sellBtn = Button:create(sellBtnDisplay)
			sellBtn:addEventListener(Events.kStart, onClickSellBtn, self)
		end
		-- sellBtnDisplay:getChildByName("txt_equip_SellBtn"):setString(Localization:getInstance():getText("equip_SellBtn"))
		-- local sellBtn = Button:create(sellBtnDisplay)
		-- sellBtn:addEventListener(Events.kStart, onClickSellBtn, self)  
	end
end

function EquipInfoNewPanel:dispose()
	self.tabChangeComponent:dispose()
	self.tabChangeComponent = nil

	EquipInfoNewPanel.super.dispose(self)
end