--------------------------------------------------------------------------------
-- EquipInfoPanel.lua - 装备详情面板
-- author: shaomin.shi & fanzhou.long
-- date: 2013-08-21
--------------------------------------------------------------------------------
require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"
require "canon.panel.ItemSellMessageBoxPanel"

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

local EquipPropertyEnum = {kHp = "Hp", kAttack = "Attack", kDefence = "Defence"}
EquipInfoPanel = class(Layer)

function EquipInfoPanel:ctor()
	self.container = nil
end

function EquipInfoPanel:create( container , enterAndReturnScene , index)
	self.container = container
  self.enterAndReturnScene = enterAndReturnScene
  self.newIndex = index
	local s = EquipInfoPanel.new()
	s:initLayer()
	return s
end

function EquipInfoPanel:refreshData()
	local equipMeta =  MetaManager.equip_meta[tonumber(self.equip.metaId)]
	local aEquip = self.equip
	local area = self.panelUI:getChildByName("common_equipInfo_upper")
	
	--area:getChildByName("txt_skill_Effect"):getChildByName("txt_skill_Effect"):setString(Localization:getInstance():getText("equip_Desc"))

	local aDescArea = area:getChildByName("txt_propInfo_desc_txt"):getChildByName("txt_propInfo_desc_txt")
	local aPanel = CardDescPanel:create(
		self.equip.metaId,
		{height=255, width=572},
		ccc3(255,255,255),
		aEquip.cardId
	)
	aPanel:setViewPosition(aDescArea:getPosition().x,aDescArea:getPosition().y)
	area:getChildByName("txt_propInfo_desc_txt"):addChild(aPanel)
	aDescArea:setVisible(false)
	area:getChildByName("pattern_cardInfor_line"):setVisible(false)
	
	area:getChildByName("txt_skillEnhance_skillName"):getChildByName("txt_skillEnhance_skillName"):setString(Localization:getInstance():getText(equipMeta.name))
	area:getChildByName("txt_equip_lv_num"):getChildByName("font"):setString(self.equip.level)
	local aCardId = self.equip.cardId
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
	--隐藏滚动条
	--area:getChildByName("icon_cardInfo_scroll"):setVisible(false)
	
	for quality = 1, 7 do
		local aQualityPanel = area:getChildByName(colorBarNameList[quality])
		aQualityPanel:setVisible(false)
	end
	area:getChildByName(colorBarNameList[equipMeta.quality]):setVisible(true)

	local POSx = self.panelUI:getChildByName("common_star"):getPositionX()
	local POSY = self.panelUI:getChildByName("common_star"):getPositionY()
	for quality = 1, 7 do
		if (quality == equipMeta.quality) then
			break
		end
		local aStarSpt = Sprite:create(UI_RES_PATH.."/common_new/common_star_sb.png")
		aStarSpt:setAnchorPoint(ccp(0,1))
		POSx = POSx - 28
		aStarSpt:setPosition(ccp(POSx,POSY))
		self.panelUI:addChild(aStarSpt)
	end
	
    self.propertyValue = 0
	local spriteName = nil
    if tonumber(self.equipMetaData.basicAtk, 10) > 0 then
		spriteName = "common/AttackIcon.png"
        self.equipProperty = EquipPropertyEnum.kAttack
        self.propertyValue = self.equipMetaData.basicAtk + self.equipMetaData.atkSCoe * self.equipLevelConfig.atk
    elseif tonumber(self.equipMetaData.basicDefence, 10) > 0 then
        spriteName = "common/DefenceIcon.png"
		self.equipProperty = EquipPropertyEnum.kDefence
        self.propertyValue = self.equipMetaData.basicDefence + self.equipMetaData.defSCoe * self.equipLevelConfig.def
    elseif tonumber(self.equipMetaData.basicHp, 10) > 0 then
        spriteName = "common/HpIcon.png"
		self.equipProperty = EquipPropertyEnum.kHp
        self.propertyValue = self.equipMetaData.basicHp + self.equipMetaData.hpSCoe * self.equipLevelConfig.hp
    end
	
	local iconPos = area:getChildByName("icon_def"):getPosition()
	local iconSpt = Sprite:create(spriteName)
	iconSpt:setPosition(ccp(iconPos.x, iconPos.y))
	iconSpt.refCocosObj:setAnchorPoint(ccp(0, 1))
	area:addChild(iconSpt, 1001)
	area:getChildByName("icon_def"):setVisible(false)
	area:getChildByName("txt_icon_silverCoin_test_num"):getChildByName("font"):setString(math.floor(self.propertyValue))
	
	local argv = {
			enterScene = "BackpackScene",
			returnScene = "BackpackScene",
			params = self.container._data
	}
  
  if self.container.title == Localization:getInstance():getText("formation_title") then
    argv = {
			enterScene = "CardQueueScene",
			returnScene = "CardQueueScene",
			params = self.container._data
    }
  end
	
	local function onClickEvolveBtn(evt)
    PopoutManager:sharedManager():pullin(self.container.targetInfoPanel, kPopoutDir.kScale )
		self.container:replaceScene( EquipEvolveScene, argv ) 
	end
	
	local function onClickUpgradeBtn(evt)
    if aEquip.level >= DataManager.getCurrUser().level then
      SuspensionLabel:showContent(self, getTextByKey("equip_LevelMaxText"))
    else
      PopoutManager:sharedManager():pullin(self.container.targetInfoPanel, kPopoutDir.kScale )
      self.container:replaceScene( EquipUpgradeScene, argv ) 
    end
	end
	
	local function onClickChangeBtn(evt)
		local cardQueue = CommonManager.getQueueData()
		local cardIds = {}
		for aKey, aCardId  in pairs(cardQueue) do
			cardIds[aCardId] = aKey
		end
		HeMemDataHolder:setInteger("CardQueue_RollTo", cardIds[self.equip.cardId])
		HeMemDataHolder:setInteger("EquipChange_Position", equipMeta.position)
		HeMemDataHolder:setInteger("EquipChange_NowEquipId", self.equip.equipId)
		local argv = {
			enterScene="CardQueueScene",
			returnScene="CardQueueScene",
			params={
				--cardPos = cardNo,
				cardId = self.equip.cardId,
				tabIndex = BAGCATEGORY.equip,
				filter = BACKPACK_FILTER.EQUIP,
				filterFunc = CardQueueScene.equipFilterFunc,
				isCardTrain = false,
			}
		}
    if self.enterAndReturnScene then
      --argv.enterScene = self.enterAndReturnScene
      argv.returnScene = self.enterAndReturnScene
    end
    
		PopoutManager:sharedManager():pullin(self.container.targetInfoPanel, kPopoutDir.kScale )
		self.container:replaceScene( BackpackScene , argv)
	end
	
	local function onClickSellBtn(evt)
    local aPanel = ItemSellMessageBoxPanel:create( self.container , {equipData={self.equip.equipId}}, self , self.newIndex)
		self.container:addChild(aPanel)
		aPanel:scaleIn()
	end
	
	--强化 Upgrade
	local envolveBtnDisplay = self.panelUI:getChildByName("common_btn_equip_enhance")
	envolveBtnDisplay:getChildByName("txt_equip_enhance"):setString(Localization:getInstance():getText("equip_Enhance"))
	if ( aEquip.level<MetaManager.equip_evolve_level[equipMeta.evolveLevel].levelMax ) then
		local envolveBtn = Button:create(envolveBtnDisplay)
		envolveBtn:addEventListener(Events.kStart, onClickUpgradeBtn, self) 
		self.panelUI:getChildByName("common_btn_equip_enhance"):getChildByName("disable"):setVisible(false)
		--[[ CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(
			function ()
				print(envolveBtn.enable)
			end,1,false);]]
	else
		self.panelUI:getChildByName("common_btn_equip_enhance"):getChildByName("btn"):setVisible(false)
	end
	
	--升阶
	local upgradeBtnDisplay = self.panelUI:getChildByName("common_btn_equip_Evolve_common")
	upgradeBtnDisplay:getChildByName("txt_equip_Evolve_common"):setString(Localization:getInstance():getText("equip_Evolve"))
	
	if ( aEquip.level==MetaManager.equip_evolve_level[equipMeta.evolveLevel].levelMax and equipMeta.evolveLevel<equipMeta.maxEvolveLevel ) then
		local upgradeBtn = Button:create(upgradeBtnDisplay)
		upgradeBtn:addEventListener(Events.kStart, onClickEvolveBtn, self)
	else
		self.panelUI:getChildByName("common_btn_equip_Evolve_common"):getChildByName("btn"):setVisible(false)
	end
	
	--卖出&更换
	local sellBtnDisplay = self.panelUI:getChildByName("common_btn_equip_SellBtn")
	if (self.equip.cardId ~= 0) then
		sellBtnDisplay:getChildByName("txt_equip_SellBtn"):setString(Localization:getInstance():getText("equipInfo_ChangeBtn"))
		local sellBtn = Button:create(sellBtnDisplay)
		sellBtn:addEventListener(Events.kStart, onClickChangeBtn, self)
	else
		sellBtnDisplay:getChildByName("txt_equip_SellBtn"):setString(Localization:getInstance():getText("equip_SellBtn"))
		local sellBtn = Button:create(sellBtnDisplay)
		sellBtn:addEventListener(Events.kStart, onClickSellBtn, self)  
	end
end

function EquipInfoPanel:initLayer()
	self.container:setTableViewsEnabled(false)
	EquipInfoPanel.super.initLayer(self)
	
	local builder = LayoutBuilder:createWithContentsOfFile("scene/common_new.json")
	builder.useArtLabelTTF = true
	self.panelUI = builder:build("common_popup_equipInfo")
	self.panelUI:getChildByName("common_txt_equipInfo"):getChildByName("txt_equipInfo"):setString(Localization:getInstance():getText("equipInfo_Title"))
	
	--self.panelUI:getChildByName("popup_equipInfo_upper"):getChildByName("txt_equip_Quality"):getChildByName("txt_equip_Quality"):setString(Localization:getInstance():getText("equip_Quality"))
	
	self.equip = self.container._data
    self.equipMetaData = MetaManager.equip_meta[tonumber(self.equip.metaId, 10)]    
    self.equipLevelConfig = MetaManager.equip_level[self.equip.level]
	self:refreshData()
	
	--关闭
	local function onClosePanel(evt)
		self.container:setTableViewsEnabled(true)
		self.container.targetInfoPanel = nil
		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
	end
	
	local bt_panel_close = Button:create(self.panelUI:getChildByName("common_btn_close"))
	bt_panel_close:addEventListener(Events.kStart, onClosePanel)

    self.panelUI:getChildByName("common_equipInfo_upper"):getChildByName("normal_card_small_sb"):setVisible(false)

	--设置装备
	local equipObject = CanonItem:create()
    equipObject:loadByMetaId(self.equip.metaId)
	equipObject:setScale(130/150)
	local position = self.panelUI:getChildByName("common_equipInfo_upper"):getChildByName("normal_card_small_sb"):getPosition()
	equipObject:setPosition(ccp(position.x,position.y))
	self.panelUI:getChildByName("common_equipInfo_upper"):addChild(equipObject) 
    --显示品质
    --[[local qualityDisplay = self.panelUI:getChildByName("equipInfo_upper"):getChildByName("icon_quality_purple")
    local aQualityName = "Item/Quality_33_33_Quality" .. self.equipMetaData.quality .. ".png"
    local aQualityTexture = CCTextureCache:sharedTextureCache():addImage(aQualityName)
    qualityDisplay:setDisplayFrame(CCSpriteFrame:createWithTexture(aQualityTexture, CCRect(0, 0, aQualityTexture:getContentSize().width, aQualityTexture:getContentSize().height))) 
    ]]
	self:addChild(self.panelUI)
end

function EquipInfoPanel:initData()

end

function EquipInfoPanel:updata()

end