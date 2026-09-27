--------------------------------------------------------------------------------
-- SkillInfoPanel.lua - 技能详情弹窗
-- author: fanzhou.long
-- updated: 2013-08-20
--------------------------------------------------------------------------------

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

SkillInfoPanel = class(Layer)

function SkillInfoPanel:ctor()
    self.container = nil
end

function SkillInfoPanel:create( container, params )
    self.container = container
    self.params = params
    local s = SkillInfoPanel.new()
    s:initLayer()
    return s
end

function SkillInfoPanel:initLayer()
  self.container:setTableViewsEnabled(false)
  
  SkillInfoPanel.super.initLayer(self)

  local previousTargetInfoPanel = self.container.targetInfoPanel
  self.container.targetInfoPanel = self
  
  self.colorLayer = LayerColor:create()
  self.colorLayer:setOpacity(kDarkOpacity)
  self.colorLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
  self:addChild(self.colorLayer)
  
  self.tempLayer = Layer:create()
  self.tempLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
  self:addChild(self.tempLayer)
  self.tempLayer:setAnchorPoint(ccp(0.5, 0.5))
  
  local builder = LayoutBuilder:createWithContentsOfFile("scene/common_new.json")
  self.panelUI = builder:build("common_popup_skillInfo")
  
  --设置固定标签
  self.panelUI:getChildByName("common_txt_skillInfo_Title"):getChildByName("txt_skillInfo_Title"):setString(Localization:getInstance():getText("skillInfo_Title"))
  
  local area = self.panelUI:getChildByName("common_popup_skillInfo_upper")
  
  local aSkill = MetaManager.skill_meta[self.params.skillId]
  
  --设置动态标签
  local maxLevel = SkillEvolveScene.getMaxLv(aSkill.skillGroupId)
  area:getChildByName("txt_skillEnhance_skillName"):getChildByName("txt_skillEnhance_skillName"):setString(Localization:getInstance():getText(aSkill.name))
  area:getChildByName("txt_equip_lv_num"):getChildByName("font"):setString(aSkill.level .. "/" .. maxLevel)
  local typeName = (aSkill.skillType==1) and getTextByKey("skillInfo_CardSkill") or getTextByKey("skillInfo_MainCardSkill")
  area:getChildByName("txt_skillEnhance_playerName"):getChildByName("txt_skillEnhance_playerName"):setString(typeName)
  local skillStatus = aSkill.statusIdList:split("|")
  local numTable = {}
  for i=1,#skillStatus do
    if (skillStatus[i]~="0") then
      local aSkillStatus = MetaManager.skill_status[tonumber(skillStatus[i])]
	  numTable["num"..i] = (aSkillStatus.valueType==2) and aSkillStatus.effectValue or (aSkillStatus.effectValue*100 .. "%")
	else
	   numTable["num"..i] = nil
	end
  end
  --设置技能效果说明
  area:getChildByName("txt_skill_Effect_txt"):getChildByName("txt_skill_Effect_txt"):setString(Localization:getInstance():getText(aSkill.desc,numTable))

  --设置稀有度彩条
  for quality = 1, 7 do
    local aQualityPanel = area:getChildByName(colorBarNameList[quality])
    aQualityPanel:setVisible(false)
  end
  area:getChildByName(colorBarNameList[aSkill.quality]):setVisible(true)

	--设置图标
	local skillFigure = CanonItem:create()
    skillFigure:loadByMetaId(aSkill["id"])
	local position = self.panelUI:getChildByName("common_popup_skillInfo_upper"):getChildByName("icon_equip_test"):getPosition()
	skillFigure:setPosition(ccp(position.x,position.y))
	self.panelUI:getChildByName("common_popup_skillInfo_upper"):addChild(skillFigure)
	self.panelUI:getChildByName("common_popup_skillInfo_upper"):getChildByName("icon_equip_test"):setVisible(false)
	--self.panelUI:getChildByName("popup_skillInfo_upper"):getChildByName("Item_144_144_Quality4"):setVisible(false)
	
  --升级按钮
  local function onEvolve(evt)
    local aPanel = evt.context
    self.container:replaceScene(
      SkillEvolveScene,
      { enterScene = self.container.enterScene,
        returnScene = self.container.returnScene,
        params={
          cardId = self.params.cardId,
          skillId = self.params.skillId,
        }
      }
    )
	aPanel:removeFromParentAndCleanup(true)
  end     
 
 --[[ if ( aSkill.level < maxLevel ) then
		local bt_skill_evolve = Button:create(self.panelUI:getChildByName("btn_skillInfo_common"))
		bt_skill_evolve:addEventListener(Events.kStart, onEvolve, self)
	else
		self.panelUI:getChildByName("btn_skillInfo_common"):getChildByName("btn"):setVisible(false)
	end]]
  
  --关闭按钮
  local function onClosePanel(evt)
  	self.container:setTableViewsEnabled(true)
  	self.container.targetInfoPanel = previousTargetInfoPanel
  	self:removeFromParentAndCleanup(true)
    if self.params.callback then
      self.params.callback()
    end
  end     
  local bt_panel_close = Button:create(self.panelUI:getChildByName("common_btn_close"))
  bt_panel_close:addEventListener(Events.kStart, onClosePanel, self)
   
  self.tempLayer:addChild(self.panelUI)
  self.tempLayer:setScale(0.1)
end

function SkillInfoPanel:scaleIn()
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