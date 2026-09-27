--------------------------------------------------------------------------------
-- SkillShowAndUpgradePanel.lua - 技能详情与升级弹窗
-- author: haoyang.zhuang
-- updated: 2013-12-10
--------------------------------------------------------------------------------

require "canon.scene.SkillUpgradeScene"

local colorBarNameList = {
	"r_white9_panel",
	"r_green9_panel",
	"r_blue9_panel",
	"r_purple9_panel",
	"r_orange9_panel",
	"r_red9_panel",
	"r_yellow9_panel",
}

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

SkillShowAndUpgradePanel = class(Layer)

function SkillShowAndUpgradePanel:ctor()
    self.container = nil
end

function SkillShowAndUpgradePanel:create( container, params )
    self.container = container
	self.container.targetInfoPanel = self
    self.params = params
    local s = SkillShowAndUpgradePanel.new()
    s:initLayer()
    return s
end

function SkillShowAndUpgradePanel:initLayer()
  self.container:setTableViewsEnabled(false)
  
  SkillShowAndUpgradePanel.super.initLayer(self)
  
  self.colorLayer = LayerColor:create()
  self.colorLayer:setOpacity(kDarkOpacity)
  self.colorLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
  self:addChild(self.colorLayer)
  
  self.tempLayer = Layer:create()
  self.tempLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
  self:addChild(self.tempLayer)
  self.tempLayer:setAnchorPoint(ccp(0.5, 0.5))
  
  local builder = LayoutBuilder:createWithContentsOfFile("scene/skillup.json")
  self.panelUI = builder:build("skillup")
  self.panelUI:getChildByName("txt_skillup_text"):getChildByName("txt"):setString(getTextByKey("skillInfo_Title"))
  
  local area = self.panelUI:getChildByName("skillEnhance_upper")
  
  local aSkill = MetaManager.skill_meta[self.params.skillId]
  
  --设置固定标签
  area:getChildByName("txt_equip_Desc"):getChildByName("txt_equip_Desc"):setString(getTextByKey( "skill_Effect" )) --"效果"
  self.panelUI:getChildByName("skillEnhance_mid"):getChildByName("txt_equip_Desc2"):getChildByName("txt_equip_Desc"):setString(getTextByKey( "skill_improveEffect" )) --"升级效果"
  self.panelUI:getChildByName("skillEnhance_upper"):getChildByName("skillup_txt_need_person_level"):getChildByName("txt"):setString(getTextByKey("skill_skillUpgradeLevelLimit"))
  
  
  --设置动态标签
  local maxLevel = SkillEvolveScene.getMaxLv(aSkill.skillGroupId)
  self.skillLevelMax = ( aSkill.level >= maxLevel )
  area:getChildByName("txt_equipName"):getChildByName("txt_equipName"):setString(Localization:getInstance():getText(aSkill.name))
  area:getChildByName("txt_lv_num"):getChildByName("font"):setString(aSkill.level .. "/" .. maxLevel)
  local typeName = (aSkill.skillType==1) and getTextByKey("skillInfo_CardSkill") or getTextByKey("skillInfo_MainCardSkill")
  area:getChildByName("txt_skillEnhance_skillName"):getChildByName("txt_skillEnhance_skillName"):setString(typeName)
  
  --设置动态标签2
  local needPersonLevelNum = aSkill.level * 10
  local curPersonLevelNum = self.params.cardLevel
  self.panelUI:getChildByName("skillEnhance_upper"):getChildByName("txt_need_person_level_num"):getChildByName("txt"):setString( needPersonLevelNum )
  if curPersonLevelNum >= needPersonLevelNum then
    self.panelUI:getChildByName("skillEnhance_upper"):getChildByName("txt_need_person_level_num"):getChildByName("txt"):setColor(ccc3( 0, 255, 0 ))
  else
    self.panelUI:getChildByName("skillEnhance_upper"):getChildByName("txt_need_person_level_num"):getChildByName("txt"):setColor(ccc3( 255, 0, 0 ))
  end
  
  local skillStatus = aSkill.statusIdList:split("|") --当前级别
  local numTable = {}
  for i=1,#skillStatus do
    if (skillStatus[i]~="0") then
      local aSkillStatus = MetaManager.skill_status[tonumber(skillStatus[i])]
      numTable["num"..i] = (aSkillStatus.valueType==2) and aSkillStatus.effectValue or (aSkillStatus.effectValue*100 .. "%")
    else
      numTable["num"..i] = nil
    end
  end
  
  if (not self.skillLevelMax) then --下一级别
    self.nextSkillInfo = MetaManager.skill_meta[self.params.skillId+1]
    local skillStatus2 = self.nextSkillInfo.statusIdList:split("|")
    local numTable2 = {}
    for i=1,#skillStatus2 do
      if (skillStatus2[i]~="0") then
        local aSkillStatus = MetaManager.skill_status[tonumber(skillStatus2[i])]
        numTable2["num"..i] = (aSkillStatus.valueType==2) and aSkillStatus.effectValue or (aSkillStatus.effectValue*100 .. "%")
      else
        numTable2["num"..i] = nil
      end
    end
    self.nextSkillInfo.numTable = numTable2
  end
  
  --设置技能效果说明
  area:getChildByName("txt_skill_Desc"):getChildByName("txt_skill_Desc"):setString(Localization:getInstance():getText( aSkill.desc,numTable ))
  if (not self.skillLevelMax) then
    self.panelUI:getChildByName("skillEnhance_mid"):getChildByName("txt_skill_NewEffect"):getChildByName("txt_skill_OldEffect"):setHorizontalAlignment( kCCTextAlignmentLeft )
    self.panelUI:getChildByName("skillEnhance_mid"):getChildByName("txt_skill_NewEffect"):getChildByName("txt_skill_OldEffect"):setString(Localization:getInstance():getText( self.nextSkillInfo.desc, self.nextSkillInfo.numTable ))
  else
    self.panelUI:getChildByName("skillEnhance_mid"):getChildByName("txt_skill_NewEffect"):getChildByName("txt_skill_OldEffect"):setHorizontalAlignment( kCCTextAlignmentCenter )
    self.panelUI:getChildByName("skillEnhance_mid"):getChildByName("txt_skill_NewEffect"):getChildByName("txt_skill_OldEffect"):setString( "\r\n" .. "当前技能已满级" )
  end

  --设置稀有度彩条
  for quality = 1, 7 do
    local aQualityPanel = area:getChildByName(colorBarNameList[quality])
    aQualityPanel:setVisible(false)
  end
  area:getChildByName(colorBarNameList[aSkill.quality]):setVisible(true)

	--设置图标
	local skillFigure = CanonItem:create()
    skillFigure:loadByMetaId(aSkill["id"])
	local position = self.panelUI:getChildByName("skillEnhance_upper"):getChildByName("normal_card_small_sb"):getPosition()
	skillFigure:setPosition(ccp(position.x,position.y))
	self.panelUI:getChildByName("skillEnhance_upper"):addChild(skillFigure)
  self.panelUI:getChildByName("skillEnhance_upper"):getChildByName("normal_card_small_sb"):setVisible( false )
	
  --升级按钮
  local function On_Upgrade_Click(evt)
    print( "On_Upgrade_Click" )
    self:removeFromParentAndCleanup(true)
    local newScene = SkillUpgradeScene:create( self.params.cardId, self.params.skillId, getTextByKey(aSkill.name), aSkill.level, aSkill.level+1, maxLevel )
    Director:sharedDirector():replaceScene( newScene )
  end     
 
  self.panelUI:getChildByName("skillEnhance_mid"):getChildByName("btn_skill_EnhanceBtn"):getChildByName("txt_skill_EnhanceBtn"):setString(getTextByKey("skill_EnhanceBtn")) --"升级"
  if ( aSkill.level < maxLevel ) and ( curPersonLevelNum >= needPersonLevelNum ) then
		local bt_skill_evolve = Button:create(self.panelUI:getChildByName("skillEnhance_mid"):getChildByName("btn_skill_EnhanceBtn"))
		bt_skill_evolve:addEventListener(Events.kStart, On_Upgrade_Click, self)
	else
		self.panelUI:getChildByName("skillEnhance_mid"):getChildByName("btn_skill_EnhanceBtn"):getChildByName("btn"):setVisible(false)
	end
  
  --关闭按钮
  local function onClosePanel(evt)
    self.container:setTableViewsEnabled(true)
    self.container.targetInfoPanel = nil
    self:removeFromParentAndCleanup(true)
  end     
  local bt_panel_close = Button:create(self.panelUI:getChildByName("btn_close"))
  bt_panel_close:addEventListener(Events.kStart, onClosePanel, self)
   
  self.tempLayer:addChild(self.panelUI)
  self.tempLayer:setScale(0.1)
end

function SkillShowAndUpgradePanel:scaleIn()
  self.tempLayer.touchEnabled = false
  self.tempLayer.touchChildren = false
  local function scaleInFinished()
    self.tempLayer.touchEnabled = true
    self.tempLayer.touchChildren = true
  end
  local arr = CCArray:create()
  arr:addObject(CCEaseSineOut:create(CCScaleTo:create(0.3, 1.0)))
  arr:addObject(CCCallFunc:create(scaleInFinished))
  self.tempLayer:runAction(CCSequence:create(arr))
end