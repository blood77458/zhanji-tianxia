require "hecore.display.CocosObject"
require "hecore.display.Director"
require "hecore.display.Scene"
require "hecore.display.Layer"
require "hecore.ui.LayoutBuilder"
require "canon.script_and_guide.Script_And_Dialog"
require "canon.scene.BattleScene"
require "canon.scene.MainMenuScene"
local event_conversation = require "canon.configs.event_conversation"

DialogOnceSceneA = class(Scene)
local visibleSize = CCDirector:sharedDirector():getVisibleSize()

function DialogOnceSceneA:ctor()

end

function DialogOnceSceneA:create( Show_Type )
  local s = DialogOnceSceneA.new()
  s.Show_Type = Show_Type
  s:initScene()
  return s
end

function DialogOnceSceneA:initScene()
  
  local function RunScene()
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry( self.JudgeInEachFrameSchedule )
    
    if self.Show_Type == 1 then
      local AllText = {}
      local AllText_Num = 0
      local function Get_All_Data()
        local DialogIndex = nil;
        local activeOpportunity = 2;
        
        DialogIndex = 1120
        for _, aConfig in ipairs( event_conversation ) do
          local One_Event = aConfig;
          if One_Event.dialogId == DialogIndex and One_Event.activeOpportunity == activeOpportunity then  --对话n
            local ShowText = Localization_getText( One_Event.dialogContent );
            AllText_Num = AllText_Num + 1
            AllText[AllText_Num] = ShowText
          end
        end
      end
      
      local Cur_Index = 0
      local function Run_Next()
        Cur_Index = Cur_Index + 1
        if Cur_Index <= AllText_Num then
          self.Content_Text:setString( AllText[Cur_Index] )
          print("###########################".. AllText[Cur_Index] )
        end
      end
      
      self.Blank_Pic = LayerColor:create()
        self.Blank_Pic:setColor(ccc3( 0, 0, 0 ))
        self.Blank_Pic.refCocosObj:setOpacity( 0 )
        self.Blank_Pic:setContentSize(CCSizeMake( visibleSize.width, visibleSize.height ))
        self.Blank_Pic:setPosition(ccp( 0, 0 ))
        self:addChild( self.Blank_Pic )
        
      local Max_Hanzi_Num_In_One_Line = 15
      self.Content_Text = TextField:create( "" )
        self.Content_Text:setFontSize( 30 )
        self.Content_Text:setColor(ccc3( 255, 255, 255 ))
        self.Content_Text:setAnchorPoint(ccp( 0.5, 0.5 ))
        self.Content_Text:setHorizontalAlignment(kCCTextAlignmentCenter)
        self.Content_Text:setDimensions(CCSizeMake( 30*Max_Hanzi_Num_In_One_Line, 0 ))
        self.Content_Text:setPosition(ccp( visibleSize.width/2, visibleSize.height/2 + 30 ))
        self.Blank_Pic:addChild( self.Content_Text )
        
      Run_Next()
        
      self.Blank_Button = Button:create( self.Blank_Pic )
      self.Blank_Button:addEventListener( Events.kStart, Run_Next, self ) 
    
    elseif self.Show_Type == 2 then
      
      
    end
  
  end
  
  self.JudgeInEachFrameSchedule = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc( RunScene, 1, false ) 
end

function DialogOnceSceneA:dispose()
  DialogOnceSceneA.super.dispose(self)
end




