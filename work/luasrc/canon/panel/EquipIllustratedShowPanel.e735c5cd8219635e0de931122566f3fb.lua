--------------------------------------------------------------------------------
-- EquipIllustratedShowPanel.lua - equip illustrated show panel装备图鉴显示面板
-- author: dang chao
-- updated: 2013-09-18
--------------------------------------------------------------------------------

require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"
require "canon.data.MetaManager"
require "canon.models.CommonManager"
require "canon.customUI.CanonItem"

EquipIllustratedShowPanel = class(Layer)

function EquipIllustratedShowPanel:ctor()
    self.container = nil
    self.metaId = nil
	self.showSkillInfo = false
end

function EquipIllustratedShowPanel:create( container, metaId )
    self.container = container
    self.metaId = metaId or self.container._data.id
    
    local s = EquipIllustratedShowPanel.new()
    s:initLayer()
    return s
end
local EquipPropertyEnum = {kHp = "Hp", kAttack = "Attack", kDefence = "Defence"}
function EquipIllustratedShowPanel:initLayer()
	self.container:setTableViewsEnabled(false)
	
    EquipIllustratedShowPanel.super.initLayer(self)
		
	local builder = LayoutBuilder:createWithContentsOfFile("scene/illustrated_new.json")
    self.panelUI = builder:build("illustrated_equipEnhance_equip")
    self.equipLevel = 1
    self.equipMetaData = MetaManager.equip_meta[tonumber(self.metaId, 10)] 
    self.equipLevelConfig = MetaManager.equip_level[self.equipLevel]
    local aEquip =  MetaManager.equip_meta[tonumber(self.metaId)]
    self.propertyValue = 0
    if tonumber(self.equipMetaData.basicAtk, 10) > 0 then
        self.equipProperty = EquipPropertyEnum.kAttack
        self.propertyValue = self.equipMetaData.basicAtk + self.equipLevel * self.equipMetaData.atkSCoe * self.equipLevelConfig.atk
    elseif tonumber(self.equipMetaData.basicDefence, 10) > 0 then
        self.equipProperty = EquipPropertyEnum.kDefence
        self.propertyValue = self.equipMetaData.basicDefence + self.equipLevel * self.equipMetaData.defSCoe * self.equipLevelConfig.def
    elseif tonumber(self.equipMetaData.basicHp, 10) > 0 then
        self.equipProperty = EquipPropertyEnum.kHp
        self.propertyValue = self.equipMetaData.basicHp + self.equipLevel * self.equipMetaData.hpSCoe * self.equipLevelConfig.hp
    end  
 
    local function onClosePanel(evt)
        PopoutManager:sharedManager():pullin(self.container.targetInfoPanel, kPopoutDir.kScale  )
        --self.container.tableUI:reloadData()
        self.container:setTableViewsEnabled(true)
		self.container.targetInfoPanel = nil
    end 
    --init UI
	self.panelUI:getChildByName("txt_equip_equiped"):setVisible(false)

    --美术替换新资源后 顺便添加标题 modified by zheng.che @ 2015-5-14 15:44:10
	--self.panelUI:getChildByName("txt_equipinfo"):setVisible(false)
    self.panelUI:getChildByName("txt_equipinfo"):getChildByName("txt_equipinfo"):setString(Localization:getInstance():getText("equipInfo_Title"))--装备详情

    self.panelUI:getChildByName("normal_card_small"):setVisible(false)	
    self.panelUI:getChildByName("txt_equipName"):getChildByName("txt_equipName"):setString(Localization:getInstance():getText(aEquip.name))
    self.panelUI:getChildByName("txt_lv_num"):getChildByName("font"):setString(1)
    self.panelUI:getChildByName("txt_equip_icon_atk_num"):getChildByName("font"):setString(math.floor(self.propertyValue)) 
	self.panelUI:getChildByName("txt_equip_desc_txt"):setVisible(false)
    --self.panelUI:getChildByName("txt_equip_desc_txt"):getChildByName("txt_equip_Desc_txt"):setString(Localization:getInstance():getText(aEquip.desc))
    self.panelUI:getChildByName("txt_equip_Character"):getChildByName("txt_equip_Desc"):setString(Localization:getInstance():getText("equip_Desc"))
    self.panelUI:getChildByName("icon_hp"):setVisible(false)
    self.panelUI:getChildByName("icon_atk"):setVisible(false)
    self.panelUI:getChildByName("icon_def"):setVisible(false)
    if aEquip.position == 1 then
        self.panelUI:getChildByName("icon_atk"):setVisible(true)
    elseif aEquip.position == 2 then
        self.panelUI:getChildByName("icon_def"):setVisible(true)
    else
        self.panelUI:getChildByName("icon_hp"):setVisible(true)
    end 
    
    local aDescArea = self.panelUI:getChildByName("yellow9_panel")
	local aPanel = CardDescPanel:create(
		self.metaId,
		{height=150, width=aDescArea:getGroupBounds().size.width},
		ccc3(0,0,0)
	)
	aPanel:setScrollViewTouchEnable(true)
	aPanel:setViewPosition(self.panelUI:getChildByName("txt_equip_desc_txt"):getPosition().x,aDescArea:getPosition().y-10)
	self.panelUI:addChild(aPanel)
	self.panelUI:getChildByName("pattern_cardInfor_line"):setVisible(false) 
	self.panelUI:getChildByName("txt_equip_Character_txt1"):setVisible(false) 
	self.panelUI:getChildByName("txt_equip_Character_txt2"):setVisible(false)
    self.panelUI:getChildByName("txt_equip_Character_txt3"):setVisible(false)
    --close
    local btn_close_Btn = Button:create(self.panelUI:getChildByName("btn_close"))
    btn_close_Btn:addEventListener(Events.kStart ,onClosePanel) 
    --show equip pic
    local equipObject = CanonItem:create()
    equipObject:loadByMetaId(self.metaId)
	local position = self.panelUI:getChildByName("normal_card_small"):getPosition()
	equipObject:setPosition(ccp(position.x,position.y))
	self.panelUI:addChild(equipObject) 
	
	self:addChild(self.panelUI)
	
end