require "hecore.display.CocosObject"
require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "canon.scene.BaseUIScene"
require "canon.panel.EmailBlankPanel"
require "hecore.ui.Button"
require "hecore.display.Layer"

SkyQuestionPanel = class(Layer)
local visibleSize = CCDirector:sharedDirector():getVisibleSize();

function SkyQuestionPanel:ctor()

end

function SkyQuestionPanel:Show( UIBuilder, MainScene )
  self.UIBuilder = UIBuilder
  self.MainScene = MainScene
  if self.UIBuilder == nil then
    self.UIBuilder = LayoutBuilder:createWithContentsOfFile("scene/sky_tongtianta.json")
  end
  self.container = Director:sharedDirector():getRunningScene()
  
  local s = SkyQuestionPanel.new()
  s:initLayer()
  self.container:addChild(s)
  return s
  
end

function SkyQuestionPanel:initLayer()
  SkyQuestionPanel.super.initLayer(self)  
  
  local function On_OK_Click()
--    print( "On_OK_Click" )
    
    self.container.targetInfoPanel = nil
    
    self:removeChild( self.BackLayer )
    self.BackLayer = nil
    
    self:removeChild( self.QuestionLayer )
    self.QuestionLayer = nil
    
    self.container:removeChild( self )
    self = nil
  end
  
  local function On_Close_Click()
--    print( "On_Close_Click" )
    
    self.container.targetInfoPanel = nil

    self:removeChild( self.BackLayer )
    self.BackLayer = nil
    
    self:removeChild( self.QuestionLayer )
    self.QuestionLayer = nil
    
    self.container:removeChild( self )
    self = nil
  end
    
  self.BackLayer = LayerColor:create()
  self.BackLayer:setColor(ccc3( 0, 0, 0 ))
  self.BackLayer.refCocosObj:setOpacity( 100 )
  self.BackLayer:setContentSize(CCSizeMake( visibleSize.width, visibleSize.height ))
  self:addChild( self.BackLayer )
  
  self.QuestionLayer = self.UIBuilder:build("window/window_sky_regulation_show")
  
  self.pic_OK = self.QuestionLayer:getChildByName( "btn_msg_ok" )
    self.txt_OK = self.pic_OK:getChildByName( "txt_OK" ):getChildByName( "txt" )
      self.txt_OK:setString(getTextByKey("yes") )
    self.btn_OK = Button:create( self.pic_OK )
    self.btn_OK:addEventListener( Events.kStart, On_OK_Click, self ) 
    
  self.pic_close = self.QuestionLayer:getChildByName( "sky_btn_close_sb" )
    self.btn_close = Button:create( self.pic_close )
    self.btn_close:addEventListener( Events.kStart, On_Close_Click, self ) 
    
  self.txt_sky_regulation_title = self.QuestionLayer:getChildByName( "txt_sky_regulation_title" ):getChildByName( "txt" )
    self.txt_sky_regulation_title:setString(getTextByKey("babel_ruleTitle"))
    
  self.txt_sky_regulation = self.QuestionLayer:getChildByName( "txt_sky_regulation" ):getChildByName( "txt" )
    self.txt_sky_regulation:setString( "" )
    
  self.QuestionLayer:setAnchorPoint(ccp( 0, 0 ))
  self.QuestionLayer:setPosition(ccp( 0, 0 ))
  self:addChild( self.QuestionLayer )
    
  local Max_Hanzi_Num_In_One_Line = 24  --一行中最多有多少个汉字
  local ShowText1 = getTextByKey("babel_ruleTxt1") .. "\n\n" .. getTextByKey("babel_ruleTxt2") .. "\n\n" .. getTextByKey("babel_ruleTxt3") .. "\n\n" .. getTextByKey("babel_ruleTxt4")
  self.Content_Text = TextField:create( ShowText1 )
    self.Content_Text:setFontSize( 24 )
    self.Content_Text:setColor(ccc3( 0, 0, 0 ))
    self.Content_Text:setAnchorPoint(ccp( 0.5, 1 ))
    self.Content_Text:setHorizontalAlignment(kCCTextAlignmentLeft)
    self.Content_Text:setDimensions(CCSizeMake( 24*Max_Hanzi_Num_In_One_Line, 0 ))
    self.Content_Text:setPosition(ccp( visibleSize.width/2, visibleSize.height/2 + 240 ))
    self:addChild( self.Content_Text )
    
end






