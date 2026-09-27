require "hecore.display.CocosObject"
require "hecore.display.Director"
require "hecore.ui.TableView"
require "hecore.ui.LayoutBuilder"
require "canon.data.MetaManager"
require "canon.scene.BaseUIScene"
require "canon.canonUtils"
require "canon.request.GetFriendDetailRequest"
require "hecore.ui.Button"
require "canon.panel.UserDetailPanel"
require "hecore.display.Layer"

SkyRankPanel = class(Layer)
local visibleSize = CCDirector:sharedDirector():getVisibleSize();

function SkyRankPanel:ctor()

end

function SkyRankPanel:Show( UIBuilder, MainScene )
  self.UIBuilder = UIBuilder
  self.MainScene = MainScene
  if self.UIBuilder == nil then
    self.UIBuilder = LayoutBuilder:createWithContentsOfFile("scene/sky_tongtianta.json")
  end
  self.container = Director:sharedDirector():getRunningScene()
  
  local s = SkyRankPanel.new()
  s:initLayer()
  s:setPosition(ccp(0, -80))
  self.container:addChild(s)
  
  local function Run_Popout()
    self.container:addChild(s)
    s.touchEnabled = false
    s.touchChildren = false
    local function onPopoutEnterAnimationFinished()
      if not s then return end
      s.touchEnabled = true
      s.touchChildren = true
    end
    local winSize = CCDirector:sharedDirector():getWinSize()
    local ScaleTo = CCEaseSineOut:create(CCScaleTo:create(0.3, 1))
    s.ContentLayer:setContentSize(CCSizeMake(winSize.width, winSize.height))
    s.ContentLayer:setAnchorPoint(ccp( 0.5, 0.5 ))
    s.ContentLayer:setScale(0.1)
    s.ContentLayer:stopAllActions()
    s.ContentLayer:runAction(CCSequence:createWithTwoActions(ScaleTo, CCCallFunc:create(onPopoutEnterAnimationFinished)))
  end
  
  Run_Popout()
  
  
  return s
end

function SkyRankPanel:Load_RankTableView()
  
  RankInstance = self
  self.TouchEnable = true
  
  local SimpleTableViewRenderer = class(TableViewRenderer)
  function SimpleTableViewRenderer:ctor(width, height)

    self.SkyData = {}

    local i = 1
    for _, aConfig in ipairs( DataManager.GetBabelInfoData.lstSharkBabelRankInfo ) do
      if i <= RankInstance.RankNum then
        self.list[i] = i
        self.SkyData[i] = aConfig
        i = i + 1
      end
    end
    
    self.TotalNum = i - 1
    self.UIBuilder = RankInstance.UIBuilder

  end
  function SimpleTableViewRenderer:buildCell(container)

      local RankItem_1 = self.UIBuilder:build("list_item/list_item_rank")
      container:addChild( RankItem_1 )
      RankItem_1:setTag(-6001)
      
      local text1 = RankItem_1:getChildByName("txt_rank_list_item_rank")
         text1:setTag( -11 )
         local text1_value = text1:getChildByName("txt")
           text1_value:setTag(-10)
      local text2 = RankItem_1:getChildByName("txt_rank_list_item_max_floor")
        text2:setTag( -12 )
        local text2_value = text2:getChildByName("txt")
          text2_value:setTag( -10 )
      local text3 = RankItem_1:getChildByName("txt_level_num")
        text3:setTag( -13 )
        local text3_value = text3:getChildByName("txt")
          text3_value:setTag( -10 )
      local text4 = RankItem_1:getChildByName("txt_rank_list_item_nickname")
        text4:setTag( -14 )
        local text4_value = text4:getChildByName("txt")
          text4_value:setTag( -10 )
          
      local btn1 = RankItem_1:getChildByName("btn_rank_list_item_view")
        btn1:setTag( -6611 )
        local btn1_text = btn1:getChildByName("txt_rank_list_item_view")
          btn1_text:setTag( -21 )
          local btn1_text_value = btn1_text:getChildByName("txt")
            btn1_text_value:setTag( -10 )
            
      local Person_Pic_Frame = RankItem_1:getChildByName("sky_list_item_person_pic.png")
        Person_Pic_Frame:setTag( -3311 )
            
  end
  function SimpleTableViewRenderer:setData( rawCocosObj, index )

      local RankItem_1 = self:getChildByTag(rawCocosObj, -6001)
      
      self:Set_Rank_Data( index+1, RankItem_1, rawCocosObj )
      
  end
  function SimpleTableViewRenderer:Set_Rank_Data( Rank_Id, RankItem_1, rawCocosObj )

    local txt1 = RankItem_1:getChildByTag(-11):getChildByTag(-10)
    local txt2 = RankItem_1:getChildByTag(-12):getChildByTag(-10)
    local txt3 = RankItem_1:getChildByTag(-13):getChildByTag(-10)
    local txt4 = RankItem_1:getChildByTag(-14):getChildByTag(-10)
    
    local btn1 = RankItem_1:getChildByTag(-6611)
    local btn1_txt = btn1:getChildByTag(-21):getChildByTag(-10)
    
    if txt1 ~= nil and txt1.setString ~= nil then
      txt1:setString(Localization:getInstance():getText("babel_rankingRank", {num = Rank_Id}) )
    end
    if txt2 ~= nil and txt2.setString ~= nil then
      txt2:setString(getTextByKey("babel_rankingHighFloor") .. self.SkyData[Rank_Id].bestFloor)
    end
    if txt3 ~= nil and txt3.setString ~= nil then
      txt3:setString( self.SkyData[Rank_Id].level )
    end
    if txt4 ~= nil and txt4.setString ~= nil then
      txt4:setString( self.SkyData[Rank_Id].nickName )
    end
    if btn1_txt ~= nil and btn1_txt.setString ~= nil then
      btn1_txt:setString(getTextByKey("babel_rankingViewBtn"))
    end
    
    local Btn1 = RankItem_1:getChildByTag(-6611)
    local InitData = DataManager.getGameInitData()
    if InitData["sharkUser"] ~= nil then
      if self.SkyData[Rank_Id].uid == InitData["sharkUser"].uid then
        Btn1:setVisible( false )
      end
    end
    
    local Person_Pic_Frame = RankItem_1:getChildByTag(-3311)
    local Person_Pic_Frame_Left_X = Person_Pic_Frame:getPositionX()
    local Person_Pic_Frame_Top_Y = Person_Pic_Frame:getPositionY()
    local Person_Pic_Frame_Width = 93
    local Person_Pic_Frame_Height = 93
    local Person_Pic_Frame_Center_X = Person_Pic_Frame_Left_X --+ Person_Pic_Frame_Width/2
    local Person_Pic_Frame_Center_Y = Person_Pic_Frame_Top_Y --- Person_Pic_Frame_Height/2
    
    local Want_HeadCard_Width = 85.0
    local Want_HeadCard_Height = 85.0
    --local smallCanonCard = getIconCardSpriteFrame( self.SkyData[Rank_Id].mainCardMetaId )
    --print( "aMainCardMetaId: ", self.SkyData[Rank_Id].mainCardMetaId )
      --local Sprite_Person_Pic = CCSprite:createWithSpriteFrame(smallCanonCard)
      --local Person_Pic = Sprite.new(Sprite_Person_Pic)
	  local Person_Pic = getHeadIconCanonCardByMetaId(self.SkyData[Rank_Id].mainCardMetaId)
	  Person_Pic:setScale(0.7)
        --local cardBounds = Person_Pic:getBounds().size
          --Person_Pic:setScaleX( Want_HeadCard_Width/cardBounds.width )
          --Person_Pic:setScaleY( Want_HeadCard_Height/cardBounds.height )
        Person_Pic:setAnchorPoint(ccp( 0.5, 0.5 ))
        Person_Pic:setPosition(ccp( Person_Pic_Frame_Center_X, Person_Pic_Frame_Center_Y ))
      RankItem_1:addChild( Person_Pic.refCocosObj, 1001 )
    
  end
  
  local function onListItemTouch( evt )
    if self.TouchEnable == false or self.MainScene.ListPanel_Can_Touch == false then
      return
    end
--    print("list item touched: [type, index]", evt.name, evt.data)
    
    local function isInArea_LeftTop(position, button) 
      return position.x > button:getPositionX() and
        position.x < ( button:getPositionX() + button:getContentSize().width ) and 
        position.y > ( button:getPositionY() - button:getContentSize().height ) and 
        position.y < button:getPositionY()
    end

    local TotalNum = self.renderer.TotalNum
    local aIndex = evt.data + 1
    
    local aCell = self.ListView:cellAtIndex(aIndex - 1)
    local posInCell = aCell:convertToNodeSpace(evt.globalPosition)
--    print(posInCell.x, posInCell.y)
    
    local btn1 = aCell:getChildByTag(-6001):getChildByTag(-6611)
    btn1:setContentSize(CCSize( 168, 66 ))
--    print( btn1:getContentSize().width, btn1:getContentSize().height )

    local function On_Btn1_Click( UsingIndex )
--      print( "On_Btn1_Click: " .. UsingIndex )
  
      local function Close_CallBack()
--        print( "Close_CallBack" )
        self.Run_UserDetailPanel_Already = nil
      end
  
      if ( not self.Run_UserDetailPanel_Already ) then
        self.Run_UserDetailPanel_Already = true
        
        local userDetailPanel = UserDetailPanel:create( self.container, {friendUid = self.renderer.SkyData[UsingIndex].uid} )
        userDetailPanel.Close_CallBack = Close_CallBack
        self.container.targetInfoPanel = userDetailPanel
        PopoutManager:sharedManager():popout(self.container.targetInfoPanel, kPopoutDir.kScale, true, false, self.container)
      end
    end
    
    if isInArea_LeftTop(posInCell, btn1) then
      if btn1:isVisible() then
        On_Btn1_Click( aIndex )
      end
    end
    
  end
  
  local function Start_Run()
    local ListView_Width = 650
    local ListView_Height = 770
    local Item_Width = 612
    local Item_Height = 152
    self.renderer = SimpleTableViewRenderer.new(Item_Width, Item_Height)
    local cellTag = -6001
    local buttonTag = {-6611}
    self.ListView = TableView:create( self.renderer, ListView_Width, ListView_Height, cellTag, buttonTag )
	self.ListView:setBounceable(false)
    self.ListView:setPosition(ccp( visibleSize.width/2-ListView_Width/2+13, visibleSize.height/2-ListView_Height/2+10 ))
    self.ListView.name = "list"
    self.ListView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch , self)
      
    self.ContentLayer:addChild( self.ListView )
  end
  
  Start_Run()

end

function SkyRankPanel:initLayer()
  SkyRankPanel.super.initLayer(self)  
  
  local function On_Close_Click()
--    print( "On_Close_Click" )
    
    local function onPopoutExitAnimationFinished()
      self.container.targetInfoPanel = nil
      
      self.MainScene.RankPanel = nil
      
      self:removeChild( self.BackLayer )
      self.BackLayer = nil
      
      self:removeChild( self.RankLayer )
      self.RankLayer = nil
      
      self.container:removeChild( self )
      self = nil
    end
    
    onPopoutExitAnimationFinished()
  
--[[
    local winSize = CCDirector:sharedDirector():getWinSize()
    local pos = self:getPosition()
    local moveTo = CCMoveTo:create(0.6, ccp(pos.x, pos.y + winSize.height))
    local ease = CCEaseBackOut:create(moveTo)
    self:stopAllActions()
    self:runAction(CCSequence:createWithTwoActions(ease, CCCallFunc:create(onPopoutExitAnimationFinished)))
--]]
    
  end
  
  self.BackLayer = LayerColor:create()
  self.BackLayer:setColor(ccc3( 0, 0, 0 ))
  self.BackLayer.refCocosObj:setOpacity( 100 )
  self.BackLayer:setContentSize(CCSizeMake( visibleSize.width, 2*visibleSize.height ))
  self.BackLayer:setPosition(ccp(0, 0))
  self:addChild( self.BackLayer )
  
  self.ContentLayer = Layer:create()
  self:addChild( self.ContentLayer )
  
  
  self.RankLayer = self.UIBuilder:build("window/window_sky_rank_show")
  
  self.pic_close = self.RankLayer:getChildByName( "sky_btn_close_sb" )
    self.btn_close = Button:create( self.pic_close )
    self.btn_close:addEventListener( Events.kStart, On_Close_Click, self ) 
    
  self.txt_rank_title = self.RankLayer:getChildByName( "txt_rank_title" ):getChildByName( "txt" )
    self.txt_rank_title:setString( getTextByKey("babel_rankingTitle") )

	--self.RankLayer:setPosition(ccp(0, -100))
  self.ContentLayer:addChild( self.RankLayer )
  
  
  local Game_Setting_Config = MetaManager.getGameSettingConfig()
  self.RankNum = 5
    if Game_Setting_Config ~= nil and Game_Setting_Config.babel ~= nil then
      self.RankNum = Game_Setting_Config.babel.babelRankingMaxPlayer+0
    end
    
  self:Load_RankTableView()
  
end





