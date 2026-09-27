require "hecore.display.CocosObject"
require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "canon.scene.BaseUIScene"


EmailBlankPanel = class(Layer)
local visibleSize = CCDirector:sharedDirector():getVisibleSize();

function EmailBlankPanel:ctor()

end

function EmailBlankPanel:Show()
  
  self.container = Director:sharedDirector():getRunningScene()
  
  local s = EmailBlankPanel.new()
  s:initLayer()
  self.container:addChild(s)
  return s
  
end

function EmailBlankPanel:Show_withContainer( Container )
  local s = EmailBlankPanel.new()
  s.container = Container
  s:initLayer()
  s.container:addChild(s)
  return s
end

function EmailBlankPanel:initLayer()
  EmailBlankPanel.super.initLayer(self)   
  
  --self.Blank_Pic = Sprite:create("email/Blank.png")
    --self.Blank_Pic:setPosition(ccp( visibleSize.width/2, visibleSize.height/2 ))
    --self:addChild( self.Blank_Pic )
    
  self.Blank_Pic = LayerColor:create()
    self.Blank_Pic:setColor(ccc3( 0, 0, 0 ))
    self.Blank_Pic.refCocosObj:setOpacity( 0 )
    self.Blank_Pic:setContentSize(CCSizeMake( visibleSize.width, visibleSize.height ))
    self.Blank_Pic:setPosition(ccp( 0, 0 ))
    self:addChild( self.Blank_Pic )

end

function EmailBlankPanel:Terminate()
  
  self.container:removeChild( self )
  self = nil
  
end








  