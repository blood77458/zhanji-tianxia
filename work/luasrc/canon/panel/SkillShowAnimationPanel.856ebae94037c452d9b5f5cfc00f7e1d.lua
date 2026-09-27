require "hecore.display.CocosObject"
require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "canon.scene.BaseUIScene"
require "canon.customUI.CanonItem"
require "canon.data.MetaManager"
require "hecore.ui.LayoutBuilder"
require "canon.canonUtils"

SkillShowAnimationPanel = class(Layer)
local visibleSize = CCDirector:sharedDirector():getVisibleSize();

function SkillShowAnimationPanel:ctor()

end

function SkillShowAnimationPanel:Show( skillId, whetherSuccess, curLevel, nextLevel, callBackFunc )
  if whetherSuccess == nil then
    whetherSuccess = false
  end
  self.skillId = skillId
  self.whetherSuccess = whetherSuccess
  self.curLevel = curLevel
  self.nextLevel = nextLevel
  self.callBackFunc = callBackFunc
  
  self.container = Director:sharedDirector():getRunningScene()
  
  self.container.targetInfoPanel = self
  
  local s = SkillShowAnimationPanel.new()
  s:initLayer()
  self.container:addChild(s)
  return s
end

function SkillShowAnimationPanel:initLayer()
  SkillShowAnimationPanel.super.initLayer(self)
  
  self.BackLayer = LayerColor:create()
  self.BackLayer:setColor(ccc3( 0, 0, 0 ))
  self.BackLayer.refCocosObj:setOpacity( 150 )
  self.BackLayer:setContentSize(CCSizeMake( visibleSize.width, visibleSize.height ))
  self:addChild( self.BackLayer )
  
  if self.container.setTableViewsEnabled ~= nil then
    self.container:setTableViewsEnabled( false )
  end
  
	local function onFlashAnimationEnd()
    self.fightFlash:unregisterEndAnimationScriptHandler()
    
    self.builder = LayoutBuilder:createWithContentsOfFile("scene/skillup.json")
    
    local function On_OK_Click()
      local callBackFunc = self.callBackFunc
      self:removeChild( self.flash_co )
      self.container.targetInfoPanel = nil
      if self.container.setTableViewsEnabled ~= nil then
        self.container:setTableViewsEnabled( true )
      end
      self.container:removeChild( self )
      if callBackFunc ~= nil then
        callBackFunc()
      end
    end
    
    if self.whetherSuccess then
      self.builder = LayoutBuilder:createWithContentsOfFile( "scene/skillup.json" )
      self.showButtonLayer = self.builder:build( "skillup_result" )
      self.showButtonLayer:getChildByName( "txt_level_yest" ):getChildByName( "txt" ):setString( "" .. self.curLevel )
      self.showButtonLayer:getChildByName( "txt_level_now" ):getChildByName( "txt" ):setString( "" .. self.nextLevel )
      self.OK_Pic = self.showButtonLayer:getChildByName( "btn_skillup_sure" )
      self.OK_Pic:getChildByName( "txt" ):setString(getTextByKey( "yes" )) --“确定”
      self:addChild( self.showButtonLayer )
    else
      self.builder = LayoutBuilder:createWithContentsOfFile( "scene/skillup.json" )
      self.showButtonLayer = self.builder:build( "skillup_result_failed" )
      self.OK_Pic = self.showButtonLayer:getChildByName( "btn_skillup_sure" )
      self.OK_Pic:getChildByName( "txt" ):setString(getTextByKey( "yes" )) --“确定”
      self:addChild( self.showButtonLayer )
    end
    
    self.buttonOK = Button:create( self.OK_Pic )
    self.buttonOK:addEventListener( Events.kStart, On_OK_Click, self ) 
	end
  
  local function getPictureName( metaId )
    local aMeta = MetaManager.skill_meta[metaId]
    local name = aMeta["icon"]
    local len = string.len(tostring(aMeta["level"]))
    name = string.sub(name,1,string.len(name)-len)
    local pathAndName = "" .. name .. "0.png"
    print( "pathAndName: ", pathAndName )
    return pathAndName
  end
  
	self.fightFlash = FlashSprite:create( "EVO2/skillup" )
--	local cardSpriteFrame =  CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName( "Skill_zhuiji0.png" )
  local PictureName = tostring(getPictureName( self.skillId ))
  local cardSpriteFrame =  createSpriteFrame("Item/Picture/" .. PictureName)
	self.fightFlash:addChangeInstance( "icon", cardSpriteFrame )
  if self.whetherSuccess then
	  self.fightFlash:changeAnimation( 0 )
  else
    self.fightFlash:changeAnimation( 1 )
  end
  self.fightFlash:setLoop( false )
	self.fightFlash:registerEndAnimationScriptHandler( onFlashAnimationEnd )
	self.flash_co = CocosObject.new( self.fightFlash )
  self.flash_co:setPositionY( 60 )
	self:addChild( self.flash_co )
  
end

function SkillShowAnimationPanel:dispose()
  self.fightFlash:unregisterEndAnimationScriptHandler()
  Layer.dispose(self)
end







