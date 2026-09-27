require "hecore.display.CocosObject"
require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "canon.scene.BaseUIScene"
require "canon.panel.CanonMessageBox"
require "canon.data.DataManager"
require "canon.data.MetaManager"
require "hecore.ui.Button"
require "canon.canonUtils"
require "canon.request.GetBabelInfoRequest"
require "canon.request.ResetBabelRequest"
require "canon.request.ChallengeBabelRequest"
require "canon.manager.BagCalcManager"
require "canon.models.RewardManager"
require "canon.models.CalculationManager"
require "canon.panel.AssistantMessageBoxPanel"
require "canon.panel.SkyQuestionPanel"
require "canon.panel.SkyRankPanel"
require "canon.utils.TimeUtil"
require "canon.scene.BattleScene"
require "canon.models.BattleManager"
require "canon.panel.SkyRunAutoPanel"
require "canon.scene.SkyRunAutoScene"

SkyTowerMainScene = class(BaseUIScene)
local visibleSize = CCDirector:sharedDirector():getVisibleSize();

function SkyTowerMainScene:ctor()
  self.title = getTextByKey("babel_title") --"通天塔"
  self.curSceneEnum = SceneEnum.SkyTowerMainScene
end

function SkyTowerMainScene:create()
  local s = SkyTowerMainScene.new()
  s:initScene()
  return s
end

function SkyTowerMainScene:Show_Refresh()
  self:Refresh_Cur_Scene( true )
end

----------------------------------------
-- 获取服务器当前时间
----------------------------------------
-- 说明：只有在用Request通信后才有效
--   若Request通信后，用户手动改了手机时间
--   则需要再次Request通信更新时间信息
----------------------------------------
function SkyTowerMainScene:get_Sever_Time()
  local Client_Time = os.time() --客户端时间
  local Diff_T = _G.__g_utcDiffSeconds --时间差：服务器时间 - 客户端时间
  local Sever_Time = Diff_T + Client_Time --服务器时间
--  print(os.date("%c", Sever_Time)) --显示时间
  return Sever_Time
end

function SkyTowerMainScene:onInit()
  BaseUIScene.initBackGround(self)
  self.BaseUIScene = BaseUIScene
  self:addChild(self.mainUI)
  
  if DataManager.GetBabelInfoData ~= nil then
    local oldTime = DataManager.GetBabelInfoData._DownloadDataTime
    if oldTime ~= nil then
      local function whetherSwithDay( oldTime ) --判断游戏是否跨天
        local oldDateTable = os.date("*t", oldTime)
        local oldYear = oldDateTable.year
        local oldMonth = oldDateTable.month
        local oldDay = oldDateTable.day
        local oldTotalSeconds = os.time{year=oldYear,month=oldMonth,day=oldDay,hour=0}
        
        local currentTime = TimeUtil.getServerTimeSeconds()
        local currentDateTable = os.date("*t", currentTime)
        local currentYear = currentDateTable.year
        local currentMonth = currentDateTable.month
        local currentDay = currentDateTable.day
        local currentTotalSeconds = os.time{year=currentYear,month=currentMonth,day=currentDay,hour=0}
        
        if oldDay ~= currentDay then
          return true
        end
        return false
      end
      if whetherSwithDay(oldTime) then --如果游戏跨天，则重新读数据
        DataManager.GetBabelInfoData = nil
      end
    end
  end
  if DataManager.GetBabelInfoData == nil then
	BaseUIScene.onInit(self)
    self:Refresh_Cur_Scene( true )
    return
  end
  
  do  --主功能代码（放在这个位置，从而不会遮挡菜单）
    self.Total_Drawing_Layer = LayerColor:create()
    self.Total_Drawing_Layer:setContentSize(CCSizeMake( visibleSize.width, visibleSize.height ))
    self.Total_Drawing_Layer:setPosition(ccp(0, 0))
    self:addChild( self.Total_Drawing_Layer )
    
    self.Show_Auto_Layer = LayerColor:create()
    self:addChild( self.Show_Auto_Layer )
    self.Show_Auto_Layer.setTableViewsEnabled = function(s,v) end
    
    self.UIBuilder = LayoutBuilder:createWithContentsOfFile("scene/sky_tongtianta.json")

    self:Init_Sky_Layers()
  end

--  BaseUIScene.onInit(self)

end

function SkyTowerMainScene:Init_Sky_Layers()
  local Cur_Level = DataManager.GetBabelInfoData.sharkBabel.currFloor
  local Last_Level = Get_ShareData( "Sky_TongTianTa_Last_Level" )
  
  self.Showing_Level = Cur_Level --记录当前显示的Level
  
  self:Init_BackGround( Cur_Level, Last_Level ) --显示背景
  
  self:Show_Sky_Layers( DataManager.GetBabelInfoData.sharkBabel.autoClimb ) --这一句必须在Init_BackGround之后
  
  if DataManager.GetBabelInfoData.sharkBabel.autoClimb == true then
--    self:replaceScene( SkyRunAutoScene ) --显示自动爬塔界面
      local function SkyRunAutoPanel_Finished()
        self.Sky_RunAuto_Panel = nil
      end
      self.Sky_RunAuto_Panel = SkyRunAutoPanel:Show( self.Show_Auto_Layer, self, Sky_RunAuto_Panel_Finished )
  end
  
end

function SkyTowerMainScene:Show_Sky_Layers( AutoClimb_State )
    if DataManager.GetBabelInfoData == nil then
       return
    end
    
    local Cur_Level = DataManager.GetBabelInfoData.sharkBabel.currFloor
    local Last_Level = Get_ShareData( "Sky_TongTianTa_Last_Level" )
    
    if Cur_Level%2 == 0 then 
      if AutoClimb_State then
        self:Show_Left_Sky_Layer( Cur_Level, Last_Level, false )
      else
        self:Show_Left_Sky_Layer( Cur_Level, Last_Level, true )
      end
    else
      if AutoClimb_State then
        self:Show_Right_Sky_Layer( Cur_Level, Last_Level, false )
      else
        self:Show_Right_Sky_Layer( Cur_Level, Last_Level, true )
      end
    end
    
    Set_ShareData( "Sky_TongTianTa_Last_Level", Cur_Level )
    
end

function SkyTowerMainScene:Show_Left_Sky_Layer( Using_Level, Last_Level, Whether_Show_Button_Layer )
    local function On_RunReset_Click()
--      print( "On_RunReset_Click" )
      self:Run_Reset_Level()
    end
    
    local function On_RunAuto_Click()
--      print( "On_RunAuto_Click" )
      self:Sky_Run_Auto()
    end
  
  local function On_BtnBattle_Click()
--    print( "On_BtnBattle_Click" )  
    self:Start_Challenge()
  end

  local function On_SmallRankWindow_Click()
--    print( "On_SmallRankWindow_Click" )
	if self.RankPanel then
		do return end
	end
    self.ListPanel_Can_Touch = true
    self.RankPanel = SkyRankPanel:Show( self.UIBuilder, self )
    self.targetInfoPanel = self.RankPanel
  end
  
  local function On_Question_Click()
--    print( "On_Question_Click" )
    self.targetInfoPanel = SkyQuestionPanel:Show( self.UIBuilder, self )
  end
  
  if self.Sky_Layer ~= nil then
    if self.Person_Pic ~= nil then
      self.Sky_Layer:removeChild( self.Person_Pic )
      self.Person_Pic = nil
    end

    if self.small_rank_window_pic ~= nil then
      self.Sky_Layer:removeChild( self.small_rank_window_pic )
      self.small_rank_window_pic = nil
    end
    
    if self.Small_Rank_Window ~= nil then
      for i, v in ipairs(self.Content_Text) do
        self.Small_Rank_Window:removeChild( v )
      end
      for i, v in ipairs(self.Level_Text) do
        self.Small_Rank_Window:removeChild( v )
      end
    end
    
    self.Total_Drawing_Layer:removeChild( self.Sky_Layer )
    self.Sky_Layer = nil
  end
  if self.Button_Layer ~= nil then
      self:removeChild( self.Button_Layer )
      self.Button_Layer = nil
  end
  
  local Best_Level = DataManager.GetBabelInfoData.sharkBabel.bestFloor
  local Min_Level = 0
  local Max_Level = 0
    for _, OneLevel in ipairs( MetaManager.babel_setting ) do
      if OneLevel.id+0 > Max_Level then
        Max_Level = OneLevel.id+0
      end
    end
  local Game_Setting_Config = MetaManager.getGameSettingConfig()
  local Max_Death_Per_Day = 3
    if Game_Setting_Config ~= nil and Game_Setting_Config.babel ~= nil then
      Max_Death_Per_Day = Game_Setting_Config.babel.babelMaxDeathPerDay+0
    end
  local Cur_Death_Num = DataManager.GetBabelInfoData.sharkBabelStatus.failNum
  
  local Upper_Level = Using_Level + 1
  local Upper_Upper_Level = Upper_Level + 1
  local Upper_Upper_Upper_Level = Upper_Upper_Level + 1
    if Upper_Level > Max_Level then
      Upper_Level = -1
    end
    if Upper_Upper_Level > Max_Level then
      Upper_Upper_Level = -1
    end
    if Upper_Upper_Upper_Level  > Max_Level then
      Upper_Upper_Upper_Level = -1
    end

  
  self.Sky_Layer = self.UIBuilder:build("layer/sky_main_layer_left") --与方向相关
  if Whether_Show_Button_Layer then --按钮层
    self.Button_Layer = self.UIBuilder:build("layer/sky_button_layer")
  end
  
  if Whether_Show_Button_Layer then --按钮层
    self.Small_Rank_Window_Title = self.Button_Layer:getChildByName( "txt_small_rank_title" ):getChildByName( "txt" )
      --self.Small_Rank_Window_Title:setString( getTextByKey("babel_rankingTitle") ) --"排行榜"
    self.Small_Rank_Window_Title:setVisible(false)
    
    local zOrder = self.Small_Rank_Window_Title.refCocosObj:getZOrder() + 1
    local posX, posY = self.Small_Rank_Window_Title.refCocosObj:getPosition()
    
    self.rankTitleArtText = ArtLabelTTF:create(getTextByKey("babel_rankingTitle"))
    local rankTitleArtText = self.rankTitleArtText
    rankTitleArtText:setPosition(posX,posY)
    rankTitleArtText:setTextAnchorPoint(ccp(0, 1))
    rankTitleArtText:construct()
    self.Button_Layer:getChildByName( "txt_small_rank_title" ):addChildAt(CocosObject.new(rankTitleArtText), zOrder)
  end
    
  self.btn_battle_pic = self.Sky_Layer:getChildByName( "btn_battle" )
    self.txt_battle = self.btn_battle_pic:getChildByName( "txt_battle" ):getChildByName( "txt" )
      self.txt_battle:setString( getTextByKey("babel_challengeBtn") ) --"挑 战"
    self.btn_battle = Button:create( self.btn_battle_pic )
    self.btn_battle:addEventListener( Events.kStart, On_BtnBattle_Click, self )  
    self.btn_battle.isVisible = true
    if Max_Level==Using_Level or (not Whether_Show_Button_Layer) then --按钮
      self.btn_battle:setVisible( false )
      self.btn_battle.isVisible = false
    end
    
  if Whether_Show_Button_Layer then --按钮层
    if Using_Level > 0 then
      self.btn_run_reset_pic = self.Button_Layer:getChildByName( "btn_run_reset" )
        self.txt_run_reset = self.btn_run_reset_pic:getChildByName( "txt_run_reset" ):getChildByName( "txt" )
          self.txt_run_reset:setString( getTextByKey("babel_resetBtn") ) --"重 置"
        self.btn_run_reset = Button:create( self.btn_run_reset_pic )
        self.btn_run_reset:addEventListener( Events.kStart, On_RunReset_Click, self )  
        
      self.Button_Layer:getChildByName( "btn_run_reset_gray" ):setVisible( false )
    else
      self.btn_run_reset_pic_gray = self.Button_Layer:getChildByName( "btn_run_reset_gray" )
        self.txt_run_reset = self.btn_run_reset_pic_gray:getChildByName( "txt_run_reset" ):getChildByName( "txt" )
          self.txt_run_reset:setString( getTextByKey("babel_resetBtn") )--"重 置"
      
      self.Button_Layer:getChildByName( "btn_run_reset" ):setVisible( false )
    end
      
    self.btn_run_auto_pic = self.Button_Layer:getChildByName( "btn_run_auto" )
      self.txt_run_auto = self.btn_run_auto_pic:getChildByName( "txt_run_auto" ):getChildByName( "txt" )
        self.txt_run_auto:setString( getTextByKey("babel_autoBtn") ) --"自动爬塔"
      self.btn_run_auto = Button:create( self.btn_run_auto_pic )
      self.btn_run_auto:addEventListener( Events.kStart, On_RunAuto_Click, self )  

    self.small_rank_window_pic = self.Button_Layer:getChildByName( "sky_small_rank_window_sb_2" )
    self.small_rank_window_pic:setVisible(false)
     self.btn_small_rank_window = Button:create( self.small_rank_window_pic )
      self.btn_small_rank_window:addEventListener( Events.kStart, On_SmallRankWindow_Click, self )  
      
    self.question_pic = self.Button_Layer:getChildByName( "sky_btn_qa_sb" ) 
      self.btn_question = Button:create( self.question_pic )
      self.btn_question:addEventListener( Events.kStart, On_Question_Click, self )  
  end
    
  self.txt_cur_level = self.Sky_Layer:getChildByName( "txt_cur_level" ):getChildByName( "txt" )
    self.txt_cur_level:setString( getTextByKey("babel_presentFloor") ) --"当前位置："
  
  self.txt_cur_death_num = self.Sky_Layer:getChildByName( "txt_cur_death_num" ):getChildByName( "txt" )
    self.txt_cur_death_num:setString( getTextByKey("babel_deathCount") ) --"今日死亡次数："
    
  self.txt_show_cur_level = self.Sky_Layer:getChildByName( "txt_show_cur_level" ):getChildByName( "txt" )
    self.txt_show_cur_level:setString(Localization:getInstance():getText("babel_floor", {num = Using_Level}))
    if Using_Level == 0 then
      self.txt_show_cur_level:setString( getTextByKey("babel_bottomFloor") )
    end
  
  self.txt_show_upper_level = self.Sky_Layer:getChildByName( "txt_show_upper_level" ):getChildByName( "txt" )
    self.txt_show_upper_level:setString(Localization:getInstance():getText("babel_floor", {num = Upper_Level}) )
	if Upper_Level == -1 or tonumber(MetaManager.babel_setting[Upper_Level].floorType) ~= 2 then
		self.Sky_Layer:getChildByName("skull_left1"):setVisible(false)
	end
    
  self.txt_show_upper_upper_level = self.Sky_Layer:getChildByName( "txt_show_upper_upper_level" ):getChildByName( "txt" )
    self.txt_show_upper_upper_level:setString(Localization:getInstance():getText("babel_floor", {num = Upper_Upper_Level}))
	if Upper_Upper_Level == -1 or tonumber(MetaManager.babel_setting[Upper_Upper_Level].floorType) ~= 2 then
		self.Sky_Layer:getChildByName("skull_left2"):setVisible(false)
	end
    
  self.txt_show_death_num = self.Sky_Layer:getChildByName( "txt_show_death_num" ):getChildByName( "txt" )
    self.txt_show_death_num:setString( Cur_Death_Num .. "/" .. Max_Death_Per_Day )
    
  self.sky_loc_show_text_2lines_sb = self.Sky_Layer:getChildByName( "sky_loc_show_text_2lines_sb" )
  self.sky_show_level_line_upper = self.Sky_Layer:getChildByName( "sky_show_level_line_upper" )
  self.sky_show_level_line_upper_upper = self.Sky_Layer:getChildByName( "sky_show_level_line_upper_upper" )
    
    
  self.Sky_Layer:getChildByName( "sky_show_level_line_upper" ):setVisible( true )
  self.Sky_Layer:getChildByName( "sky_show_level_line_upper_upper" ):setVisible( true )
  self.Sky_Layer:getChildByName( "txt_show_upper_level" ):setVisible( true )
  self.Sky_Layer:getChildByName( "txt_show_upper_upper_level" ):setVisible( true )
    
  self.Sky_Layer:getChildByName( "sky_tading_plus_4" ):setVisible( false )
  self.Sky_Layer:getChildByName( "sky_tading_plus_3" ):setVisible( false )
  self.Sky_Layer:getChildByName( "sky_tading_plus_2" ):setVisible( false )
  self.Sky_Layer:getChildByName( "sky_tading_plus_1" ):setVisible( false )
  self.Sky_Layer:getChildByName( "sky_tading_plus_0" ):setVisible( false )
  
  local Level_Diff = Max_Level - Using_Level
  
  if Level_Diff == 0 then  --塔的显示
    self.Sky_Layer:getChildByName( "sky_tading_plus_4" ):setVisible( false )
    self.Sky_Layer:getChildByName( "sky_tading_plus_3" ):setVisible( false )
    self.Sky_Layer:getChildByName( "sky_tading_plus_2" ):setVisible( false )
    self.Sky_Layer:getChildByName( "sky_tading_plus_1" ):setVisible( false )
    self.Sky_Layer:getChildByName( "sky_tading_plus_0" ):setVisible( true )

    self.Sky_Layer:getChildByName( "sky_ta_plus_4_5" ):setVisible( false )
    self.Sky_Layer:getChildByName( "sky_ta_plus_3" ):setVisible( false )
    self.Sky_Layer:getChildByName( "sky_ta_plus_1" ):setVisible( false )
  end
    
  if Level_Diff == 1 then  --塔的显示
    self.Sky_Layer:getChildByName( "sky_tading_plus_4" ):setVisible( false )
    self.Sky_Layer:getChildByName( "sky_tading_plus_3" ):setVisible( false )
    self.Sky_Layer:getChildByName( "sky_tading_plus_2" ):setVisible( false )
    self.Sky_Layer:getChildByName( "sky_tading_plus_1" ):setVisible( true )
    self.Sky_Layer:getChildByName( "sky_tading_plus_0" ):setVisible( false )

    self.Sky_Layer:getChildByName( "sky_ta_plus_4_5" ):setVisible( false )
    self.Sky_Layer:getChildByName( "sky_ta_plus_3" ):setVisible( false )
    self.Sky_Layer:getChildByName( "sky_ta_plus_1" ):setVisible( false )
  end
  
  if Level_Diff == 2 then  --塔的显示
    self.Sky_Layer:getChildByName( "sky_tading_plus_4" ):setVisible( false )
    self.Sky_Layer:getChildByName( "sky_tading_plus_3" ):setVisible( false )
    self.Sky_Layer:getChildByName( "sky_tading_plus_2" ):setVisible( true )
    self.Sky_Layer:getChildByName( "sky_tading_plus_1" ):setVisible( false )
    self.Sky_Layer:getChildByName( "sky_tading_plus_0" ):setVisible( false )

    self.Sky_Layer:getChildByName( "sky_ta_plus_4_5" ):setVisible( false )
    self.Sky_Layer:getChildByName( "sky_ta_plus_3" ):setVisible( false )
    self.Sky_Layer:getChildByName( "sky_ta_plus_1" ):setVisible( true )
  end
  
  if Level_Diff == 3 then  --塔的显示
    self.Sky_Layer:getChildByName( "sky_tading_plus_4" ):setVisible( false )
    self.Sky_Layer:getChildByName( "sky_tading_plus_3" ):setVisible( true )
    self.Sky_Layer:getChildByName( "sky_tading_plus_2" ):setVisible( false )
    self.Sky_Layer:getChildByName( "sky_tading_plus_1" ):setVisible( false )
    self.Sky_Layer:getChildByName( "sky_tading_plus_0" ):setVisible( false )

    self.Sky_Layer:getChildByName( "sky_ta_plus_4_5" ):setVisible( false )
    self.Sky_Layer:getChildByName( "sky_ta_plus_3" ):setVisible( false )
    self.Sky_Layer:getChildByName( "sky_ta_plus_1" ):setVisible( true )
  end
  
  if Level_Diff == 4 then  --塔的显示
    self.Sky_Layer:getChildByName( "sky_tading_plus_4" ):setVisible( true )
    self.Sky_Layer:getChildByName( "sky_tading_plus_3" ):setVisible( false )
    self.Sky_Layer:getChildByName( "sky_tading_plus_2" ):setVisible( false )
    self.Sky_Layer:getChildByName( "sky_tading_plus_1" ):setVisible( false )
    self.Sky_Layer:getChildByName( "sky_tading_plus_0" ):setVisible( false )

    self.Sky_Layer:getChildByName( "sky_ta_plus_4_5" ):setVisible( false )
    self.Sky_Layer:getChildByName( "sky_ta_plus_3" ):setVisible( true )
    self.Sky_Layer:getChildByName( "sky_ta_plus_1" ):setVisible( true )
  end
  
  if Level_Diff >= 5 then  --塔的显示
    self.Sky_Layer:getChildByName( "sky_tading_plus_4" ):setVisible( false )
    self.Sky_Layer:getChildByName( "sky_tading_plus_3" ):setVisible( false )
    self.Sky_Layer:getChildByName( "sky_tading_plus_2" ):setVisible( false )
    self.Sky_Layer:getChildByName( "sky_tading_plus_1" ):setVisible( false )
    self.Sky_Layer:getChildByName( "sky_tading_plus_0" ):setVisible( false )

    self.Sky_Layer:getChildByName( "sky_ta_plus_4_5" ):setVisible( true )
    self.Sky_Layer:getChildByName( "sky_ta_plus_3" ):setVisible( true )
    self.Sky_Layer:getChildByName( "sky_ta_plus_1" ):setVisible( true )
  end
  
  
  if Level_Diff == 0 then  --文字、按钮
    if Whether_Show_Button_Layer then --按钮层
      self.btn_run_auto:setVisible( false )
--      local Btn_Run_Reset_Width = 187.0
--      local Btn_Run_Reset_Position = self.Button_Layer:getChildByName( "btn_run_reset" ):getPosition()
--      self.Button_Layer:getChildByName( "btn_run_reset" ):setPosition(ccp( visibleSize.width/2-Btn_Run_Reset_Width/2, Btn_Run_Reset_Position.y ))
    end
    
    self.Sky_Layer:getChildByName( "sky_show_level_line_upper" ):setVisible( false )
    self.Sky_Layer:getChildByName( "sky_show_level_line_upper_upper" ):setVisible( false )
    self.Sky_Layer:getChildByName( "txt_show_upper_level" ):setVisible( false )
    self.Sky_Layer:getChildByName( "txt_show_upper_upper_level" ):setVisible( false )
  end
  
  if Level_Diff == 1 then  --文字、按钮
    self.Sky_Layer:getChildByName( "sky_show_level_line_upper_upper" ):setVisible( false )
    self.Sky_Layer:getChildByName( "txt_show_upper_upper_level" ):setVisible( false )
  end
  

  local aMainCardId = -1
    local InitData = DataManager.getGameInitData()
    if InitData ~= nil and InitData["sharkUser"] ~= nil then
      aMainCardId = InitData["sharkUser"].mainCardId+0
    end
  
  if aMainCardId >= 0 then
    local aSharkCards = DataManager.getGameInitData().sharkCards.sharkCards
    local aMainCardMetaId
    for _, aValue in pairs(aSharkCards) do
      if aValue.cardId == aMainCardId then
        aMainCardMetaId = aValue.metaId
        break
      end
    end
    
  self.Person_Pic_Frame = self.Sky_Layer:getChildByName( "sky_bg_full_sb" )
  local Person_Pic_Frame = self.Person_Pic_Frame
	Person_Pic_Frame:setAnchorPoint(ccp(0.5, 0.5))
    local Person_Pic_Frame_Left_X = Person_Pic_Frame:getPositionX()
    local Person_Pic_Frame_Top_Y = Person_Pic_Frame:getPositionY()
    local Person_Pic_Frame_Width = 0
    local Person_Pic_Frame_Height = 0
    local Person_Pic_Frame_Center_X = Person_Pic_Frame_Left_X + Person_Pic_Frame_Width/2
    local Person_Pic_Frame_Center_Y = Person_Pic_Frame_Top_Y - Person_Pic_Frame_Height/2
    
    local Want_HeadCard_Width = 115
    local Want_HeadCard_Height = 115
      self.Person_Pic = getHeadIconCanonCardByMetaId(aMainCardMetaId)
        self.Person_Pic:setAnchorPoint(ccp( 0.5, 0.5 ))
        self.Person_Pic:setPosition(ccp( Person_Pic_Frame_Center_X, Person_Pic_Frame_Center_Y ))
      self.Sky_Layer:addChild( self.Person_Pic )
  end

  
  if Whether_Show_Button_Layer then --按钮层
    self.Small_Rank_Window = self.Button_Layer:getChildByName( "sky_small_rank_window_sb" )
      self.Small_Rank_Size = self.Small_Rank_Window:getTextureRect().size
    local i = 1
    local RankShowText = ""
    local NickName = ""
    local MaxI = 5
    self.Content_Text = {}
    self.Level_Text = {}
    local Max_Hanzi_Num_In_One_Line = 17  --一行中最多有多少个汉字
    for _, aConfig in ipairs( DataManager.GetBabelInfoData.lstSharkBabelRankInfo ) do
      if i <= MaxI then
        NickName = aConfig.nickName
        local Cnt_Chi, Cnt_Eng = self:utfstrlen_Chi_Eng( NickName )
        local TotalCnt = Cnt_Chi*2 + Cnt_Eng
        if TotalCnt > 10 then
          NickName = self:truncateUTF8String( NickName, 9 ) .. ".."
        end
        RankShowText = Localization:getInstance():getText("babel_rankingRank", {num = i}) ..  " " .. NickName
        self.Content_Text[i] = TextField:create( RankShowText )
          self.Content_Text[i]:setFontSize( 18 )
          self.Content_Text[i]:setAnchorPoint(ccp( 0, 0 ))
          self.Content_Text[i]:setHorizontalAlignment(kCCTextAlignmentLeft)
          self.Content_Text[i]:setDimensions(CCSizeMake( 18*Max_Hanzi_Num_In_One_Line, 0 ))
          self.Content_Text[i]:setPosition(ccp( 8, 26*(MaxI-i)+16 ))
      self.Content_Text[i]:setColor(ccc3(0, 0, 0))
        self.Small_Rank_Window:addChild( self.Content_Text[i] )
        self.Level_Text[i] = TextField:create(Localization:getInstance():getText("babel_rankingFloor", {num = aConfig.bestFloor}) )
          self.Level_Text[i]:setFontSize( 18 )
          self.Level_Text[i]:setAnchorPoint(ccp( 1, 0 ))
          self.Level_Text[i]:setHorizontalAlignment(kCCTextAlignmentRight)
          self.Level_Text[i]:setDimensions(CCSizeMake( 18*Max_Hanzi_Num_In_One_Line, 0 ))
          self.Level_Text[i]:setPosition(ccp( 205-11, 26*(MaxI-i)+16 ))
      self.Level_Text[i]:setColor(ccc3(0, 0, 0))
        self.Small_Rank_Window:addChild( self.Level_Text[i] )
        i = i + 1
      end
    end
  end
  
  self.Sky_Layer:setAnchorPoint(ccp( 0, 0 ))
  self.Sky_Layer:setPosition(ccp( 0, -2 ))

  self.Total_Drawing_Layer:addChild( self.Sky_Layer )
  if Whether_Show_Button_Layer then --按钮层
    self:addChild( self.Button_Layer )
  end
  
  --播放塔移动的动画：
  if Last_Level>=0 and Last_Level==Using_Level-1 then
    local Btn_Battle_Show_State = self.btn_battle.isVisible
    
    self.btn_battle:setVisible( false )
    local LocationSkyLayer = self.Sky_Layer:getPosition()
    self.Sky_Layer:setPosition(ccp( LocationSkyLayer.x, LocationSkyLayer.y + 167))
    
    local function After_Tower_Moving_Ended()
      if Btn_Battle_Show_State then
        self.btn_battle:setVisible( true )
      end
      self.Moving_Tower_Animation_Running = false
    end
    
    local arr = CCArray:create()
    arr:addObject(CCMoveBy:create(0.5, ccp(0, -167)))
    arr:addObject(CCCallFunc:create(After_Tower_Moving_Ended))
    self.Sky_Layer:runAction(CCSequence:create(arr))
    self.Moving_Tower_Animation_Running = true
  end
  
end

function SkyTowerMainScene:Show_Right_Sky_Layer( Using_Level, Last_Level, Whether_Show_Button_Layer )
    local function On_RunReset_Click()
--      print( "On_RunReset_Click" )
      self:Run_Reset_Level()
    end
    
    local function On_RunAuto_Click()
--      print( "On_RunAuto_Click" )
      self:Sky_Run_Auto()
    end
  
  local function On_BtnBattle_Click()
--    print( "On_BtnBattle_Click" )  
    self:Start_Challenge()
  end
  
  local function On_SmallRankWindow_Click()
--    print( "On_SmallRankWindow_Click" )
	if self.RankPanel then
		do return end
	end
    self.ListPanel_Can_Touch = true
    self.RankPanel = SkyRankPanel:Show( self.UIBuilder, self )
    self.targetInfoPanel = self.RankPanel
  end
  
  local function On_Question_Click()
--    print( "On_Question_Click" )
    self.targetInfoPanel = SkyQuestionPanel:Show( self.UIBuilder, self )
  end
  
  if self.Sky_Layer ~= nil then
    if self.Person_Pic ~= nil then
      self.Sky_Layer:removeChild( self.Person_Pic )
      self.Person_Pic = nil
    end

    if self.small_rank_window_pic ~= nil then
      self.Sky_Layer:removeChild( self.small_rank_window_pic )
      self.small_rank_window_pic = nil
    end
    
    if self.Small_Rank_Window ~= nil then
      for i, v in ipairs(self.Content_Text) do
        self.Small_Rank_Window:removeChild( v )
      end
      for i, v in ipairs(self.Level_Text) do
        self.Small_Rank_Window:removeChild( v )
      end
    end
    
    self.Total_Drawing_Layer:removeChild( self.Sky_Layer )
    self.Sky_Layer = nil
  end
  if self.Button_Layer ~= nil then
    self:removeChild( self.Button_Layer )
    self.Button_Layer = nil
  end
  
  local Best_Level = DataManager.GetBabelInfoData.sharkBabel.bestFloor
  local Min_Level = 0
  local Max_Level = 0
    for _, OneLevel in ipairs( MetaManager.babel_setting ) do
      if OneLevel.id+0 > Max_Level then
        Max_Level = OneLevel.id+0
      end
    end
  local Game_Setting_Config = MetaManager.getGameSettingConfig()
  local Max_Death_Per_Day = 3
    if Game_Setting_Config ~= nil and Game_Setting_Config.babel ~= nil then
      Max_Death_Per_Day = Game_Setting_Config.babel.babelMaxDeathPerDay+0
    end
  local Cur_Death_Num = DataManager.GetBabelInfoData.sharkBabelStatus.failNum
  
  local Upper_Level = Using_Level + 1
  local Upper_Upper_Level = Upper_Level + 1
  local Upper_Upper_Upper_Level = Upper_Upper_Level + 1
    if Upper_Level > Max_Level then
      Upper_Level = -1
    end
    if Upper_Upper_Level > Max_Level then
      Upper_Upper_Level = -1
    end
    if Upper_Upper_Upper_Level  > Max_Level then
      Upper_Upper_Upper_Level = -1
    end

  
  self.Sky_Layer = self.UIBuilder:build("layer/sky_main_layer_right") --与方向相关
  if Whether_Show_Button_Layer then --按钮层
    self.Button_Layer = self.UIBuilder:build("layer/sky_button_layer")
  end
  
  if Whether_Show_Button_Layer then --按钮层
    self.Small_Rank_Window_Title = self.Button_Layer:getChildByName( "txt_small_rank_title" ):getChildByName( "txt" )
      --self.Small_Rank_Window_Title:setString( getTextByKey("babel_rankingTitle") ) --"排行榜"
    
    self.Small_Rank_Window_Title:setVisible(false)
    
    local zOrder = self.Small_Rank_Window_Title.refCocosObj:getZOrder() + 1
    local posX, posY = self.Small_Rank_Window_Title.refCocosObj:getPosition()
    
    self.rankTitleArtText = ArtLabelTTF:create(getTextByKey("babel_rankingTitle"))
    local rankTitleArtText = self.rankTitleArtText
    rankTitleArtText:setPosition(posX,posY)
    rankTitleArtText:setTextAnchorPoint(ccp(0, 1))
    rankTitleArtText:construct()
    self.Button_Layer:getChildByName( "txt_small_rank_title" ):addChildAt(CocosObject.new(rankTitleArtText), zOrder)
  end
    
  self.btn_battle_pic = self.Sky_Layer:getChildByName( "btn_battle" )
    self.txt_battle = self.btn_battle_pic:getChildByName( "txt_battle" ):getChildByName( "txt" )
      self.txt_battle:setString( getTextByKey("babel_challengeBtn") ) --"挑 战"
    self.btn_battle = Button:create( self.btn_battle_pic )
    self.btn_battle:addEventListener( Events.kStart, On_BtnBattle_Click, self )  
    self.btn_battle.isVisible = true
    if Max_Level==Using_Level or (not Whether_Show_Button_Layer) then --按钮
      self.btn_battle:setVisible( false )
      self.btn_battle.isVisible = false
    end
    
  if Whether_Show_Button_Layer then --按钮层
    if Using_Level > 0 then
      self.btn_run_reset_pic = self.Button_Layer:getChildByName( "btn_run_reset" )
        self.txt_run_reset = self.btn_run_reset_pic:getChildByName( "txt_run_reset" ):getChildByName( "txt" )
          self.txt_run_reset:setString( getTextByKey("babel_resetBtn") ) --"重 置"
        self.btn_run_reset = Button:create( self.btn_run_reset_pic )
        self.btn_run_reset:addEventListener( Events.kStart, On_RunReset_Click, self )  
        
      self.Button_Layer:getChildByName( "btn_run_reset_gray" ):setVisible( false )
    else
      self.btn_run_reset_pic_gray = self.Button_Layer:getChildByName( "btn_run_reset_gray" )
        self.txt_run_reset = self.btn_run_reset_pic_gray:getChildByName( "txt_run_reset" ):getChildByName( "txt" )
          self.txt_run_reset:setString( getTextByKey("babel_resetBtn") ) --"重 置"
      
      self.Button_Layer:getChildByName( "btn_run_reset" ):setVisible( false )
    end
      
    self.btn_run_auto_pic = self.Button_Layer:getChildByName( "btn_run_auto" )
      self.txt_run_auto = self.btn_run_auto_pic:getChildByName( "txt_run_auto" ):getChildByName( "txt" )
        self.txt_run_auto:setString( getTextByKey("babel_autoBtn") ) --"自动爬塔"
      self.btn_run_auto = Button:create( self.btn_run_auto_pic )
      self.btn_run_auto:addEventListener( Events.kStart, On_RunAuto_Click, self )  
   
    self.small_rank_window_pic = self.Button_Layer:getChildByName( "sky_small_rank_window_sb_2" )
    self.small_rank_window_pic:setVisible(false)
      self.btn_small_rank_window = Button:create( self.small_rank_window_pic )
      self.btn_small_rank_window:addEventListener( Events.kStart, On_SmallRankWindow_Click, self ) 
      
    self.question_pic = self.Button_Layer:getChildByName( "sky_btn_qa_sb" ) 
      self.btn_question = Button:create( self.question_pic )
      self.btn_question:addEventListener( Events.kStart, On_Question_Click, self )
  end
    
  self.txt_cur_level = self.Sky_Layer:getChildByName( "txt_cur_level" ):getChildByName( "txt" )
    self.txt_cur_level:setString( getTextByKey("babel_presentFloor") ) --"当前位置：" 
  
  self.txt_cur_death_num = self.Sky_Layer:getChildByName( "txt_cur_death_num" ):getChildByName( "txt" )
    self.txt_cur_death_num:setString( getTextByKey("babel_deathCount") ) --"今日死亡次数："
    
  self.txt_show_cur_level = self.Sky_Layer:getChildByName( "txt_show_cur_level" ):getChildByName( "txt" )
    self.txt_show_cur_level:setString(Localization:getInstance():getText("babel_floor", {num = Using_Level}) )
    if Using_Level == 0 then
      self.txt_show_cur_level:setString( getTextByKey("babel_bottomFloor") )
    end
  
  self.txt_show_upper_level = self.Sky_Layer:getChildByName( "txt_show_upper_level" ):getChildByName( "txt" )
    self.txt_show_upper_level:setString(Localization:getInstance():getText("babel_floor", {num = Upper_Level}))
	if Upper_Level == -1 or tonumber(MetaManager.babel_setting[Upper_Level].floorType) ~= 2 then
		self.Sky_Layer:getChildByName("skull_right1"):setVisible(false)
	end
    
  self.txt_show_upper_upper_level = self.Sky_Layer:getChildByName( "txt_show_upper_upper_level" ):getChildByName( "txt" )
    self.txt_show_upper_upper_level:setString(Localization:getInstance():getText("babel_floor", {num = Upper_Upper_Level}) )
	
	if Upper_Upper_Level == -1 or tonumber(MetaManager.babel_setting[Upper_Upper_Level].floorType) ~= 2 then
		self.Sky_Layer:getChildByName("skull_right2"):setVisible(false)
	end
    
  self.txt_show_death_num = self.Sky_Layer:getChildByName( "txt_show_death_num" ):getChildByName( "txt" )
    self.txt_show_death_num:setString( Cur_Death_Num .. "/" .. Max_Death_Per_Day )
    
  self.sky_loc_show_text_2lines_sb = self.Sky_Layer:getChildByName( "sky_loc_show_text_2lines_sb" )
  self.sky_show_level_line_upper = self.Sky_Layer:getChildByName( "sky_show_level_line_upper" )
  self.sky_show_level_line_upper_upper = self.Sky_Layer:getChildByName( "sky_show_level_line_upper_upper" )
    
    
  self.Sky_Layer:getChildByName( "sky_show_level_line_upper" ):setVisible( true )
  self.Sky_Layer:getChildByName( "sky_show_level_line_upper_upper" ):setVisible( true )
  self.Sky_Layer:getChildByName( "txt_show_upper_level" ):setVisible( true )
  self.Sky_Layer:getChildByName( "txt_show_upper_upper_level" ):setVisible( true )
    
  self.Sky_Layer:getChildByName( "sky_tading_plus_4" ):setVisible( false )
  self.Sky_Layer:getChildByName( "sky_tading_plus_3" ):setVisible( false )
  self.Sky_Layer:getChildByName( "sky_tading_plus_2" ):setVisible( false )
  self.Sky_Layer:getChildByName( "sky_tading_plus_1" ):setVisible( false )
  self.Sky_Layer:getChildByName( "sky_tading_plus_0" ):setVisible( false )
  
  local Level_Diff = Max_Level - Using_Level
  
  if Level_Diff == 0 then  --塔的显示
    self.Sky_Layer:getChildByName( "sky_tading_plus_4" ):setVisible( false )
    self.Sky_Layer:getChildByName( "sky_tading_plus_3" ):setVisible( false )
    self.Sky_Layer:getChildByName( "sky_tading_plus_2" ):setVisible( false )
    self.Sky_Layer:getChildByName( "sky_tading_plus_1" ):setVisible( false )
    self.Sky_Layer:getChildByName( "sky_tading_plus_0" ):setVisible( true )

    self.Sky_Layer:getChildByName( "sky_ta_plus_4" ):setVisible( false )
    self.Sky_Layer:getChildByName( "sky_ta_plus_2" ):setVisible( false )
    self.Sky_Layer:getChildByName( "sky_ta" ):setVisible( false )
  end 
  
  if Level_Diff == 1 then  --塔的显示
    self.Sky_Layer:getChildByName( "sky_tading_plus_4" ):setVisible( false )
    self.Sky_Layer:getChildByName( "sky_tading_plus_3" ):setVisible( false )
    self.Sky_Layer:getChildByName( "sky_tading_plus_2" ):setVisible( false )
    self.Sky_Layer:getChildByName( "sky_tading_plus_1" ):setVisible( true )
    self.Sky_Layer:getChildByName( "sky_tading_plus_0" ):setVisible( false )

    self.Sky_Layer:getChildByName( "sky_ta_plus_4" ):setVisible( false )
    self.Sky_Layer:getChildByName( "sky_ta_plus_2" ):setVisible( false )
    self.Sky_Layer:getChildByName( "sky_ta" ):setVisible( true )
  end 
  
  if Level_Diff == 2 then  --塔的显示
    self.Sky_Layer:getChildByName( "sky_tading_plus_4" ):setVisible( false )
    self.Sky_Layer:getChildByName( "sky_tading_plus_3" ):setVisible( false )
    self.Sky_Layer:getChildByName( "sky_tading_plus_2" ):setVisible( true )
    self.Sky_Layer:getChildByName( "sky_tading_plus_1" ):setVisible( false )
    self.Sky_Layer:getChildByName( "sky_tading_plus_0" ):setVisible( false )

    self.Sky_Layer:getChildByName( "sky_ta_plus_4" ):setVisible( false )
    self.Sky_Layer:getChildByName( "sky_ta_plus_2" ):setVisible( false )
    self.Sky_Layer:getChildByName( "sky_ta" ):setVisible( true )
  end 
  
  if Level_Diff == 3 then  --塔的显示
    self.Sky_Layer:getChildByName( "sky_tading_plus_4" ):setVisible( false )
    self.Sky_Layer:getChildByName( "sky_tading_plus_3" ):setVisible( true )
    self.Sky_Layer:getChildByName( "sky_tading_plus_2" ):setVisible( false )
    self.Sky_Layer:getChildByName( "sky_tading_plus_1" ):setVisible( false )
    self.Sky_Layer:getChildByName( "sky_tading_plus_0" ):setVisible( false )

    self.Sky_Layer:getChildByName( "sky_ta_plus_4" ):setVisible( false )
    self.Sky_Layer:getChildByName( "sky_ta_plus_2" ):setVisible( true )
    self.Sky_Layer:getChildByName( "sky_ta" ):setVisible( true )
  end 
  
  if Level_Diff == 4 then  --塔的显示
    self.Sky_Layer:getChildByName( "sky_tading_plus_4" ):setVisible( true )
    self.Sky_Layer:getChildByName( "sky_tading_plus_3" ):setVisible( false )
    self.Sky_Layer:getChildByName( "sky_tading_plus_2" ):setVisible( false )
    self.Sky_Layer:getChildByName( "sky_tading_plus_1" ):setVisible( false )
    self.Sky_Layer:getChildByName( "sky_tading_plus_0" ):setVisible( false )

    self.Sky_Layer:getChildByName( "sky_ta_plus_4" ):setVisible( false )
    self.Sky_Layer:getChildByName( "sky_ta_plus_2" ):setVisible( true )
    self.Sky_Layer:getChildByName( "sky_ta" ):setVisible( true )
  end 
  
  if Level_Diff >= 5 then  --塔的显示
    self.Sky_Layer:getChildByName( "sky_tading_plus_4" ):setVisible( false )
    self.Sky_Layer:getChildByName( "sky_tading_plus_3" ):setVisible( false )
    self.Sky_Layer:getChildByName( "sky_tading_plus_2" ):setVisible( false )
    self.Sky_Layer:getChildByName( "sky_tading_plus_1" ):setVisible( false )
    self.Sky_Layer:getChildByName( "sky_tading_plus_0" ):setVisible( false )

    self.Sky_Layer:getChildByName( "sky_ta_plus_4" ):setVisible( true )
    self.Sky_Layer:getChildByName( "sky_ta_plus_2" ):setVisible( true )
    self.Sky_Layer:getChildByName( "sky_ta" ):setVisible( true )
  end 
  
  
  if Level_Diff == 0 then  --文字、按钮
    if Whether_Show_Button_Layer then --按钮层
      self.btn_run_auto:setVisible( false )
--      local Btn_Run_Reset_Width = 187.0
--      local Btn_Run_Reset_Position = self.Button_Layer:getChildByName( "btn_run_reset" ):getPosition()
--      self.Button_Layer:getChildByName( "btn_run_reset" ):setPosition(ccp( visibleSize.width/2-Btn_Run_Reset_Width/2, Btn_Run_Reset_Position.y ))
    end
    
    self.Sky_Layer:getChildByName( "sky_show_level_line_upper" ):setVisible( false )
    self.Sky_Layer:getChildByName( "sky_show_level_line_upper_upper" ):setVisible( false )
    self.Sky_Layer:getChildByName( "txt_show_upper_level" ):setVisible( false )
    self.Sky_Layer:getChildByName( "txt_show_upper_upper_level" ):setVisible( false )
  end
  
  if Level_Diff == 1 then  --文字、按钮
    self.Sky_Layer:getChildByName( "sky_show_level_line_upper_upper" ):setVisible( false )
    self.Sky_Layer:getChildByName( "txt_show_upper_upper_level" ):setVisible( false )
  end
  

  local aMainCardId = -1
    local InitData = DataManager.getGameInitData()
    if InitData ~= nil and InitData["sharkUser"] ~= nil then
      aMainCardId = InitData["sharkUser"].mainCardId+0
    end
  
  if aMainCardId >= 0 then
    local aSharkCards = DataManager.getGameInitData().sharkCards.sharkCards
    local aMainCardMetaId
    for _, aValue in pairs(aSharkCards) do
      if aValue.cardId == aMainCardId then
        aMainCardMetaId = aValue.metaId
        break
      end
    end
    
  self.Person_Pic_Frame = self.Sky_Layer:getChildByName( "sky_bg_full_sb" )
  local Person_Pic_Frame = self.Person_Pic_Frame
	Person_Pic_Frame:setAnchorPoint(ccp(0.5, 0.5))
    local Person_Pic_Frame_Left_X = Person_Pic_Frame:getPositionX()
    local Person_Pic_Frame_Top_Y = Person_Pic_Frame:getPositionY()
    local Person_Pic_Frame_Width = 0
    local Person_Pic_Frame_Height = 0
    local Person_Pic_Frame_Center_X = Person_Pic_Frame_Left_X + Person_Pic_Frame_Width/2
    local Person_Pic_Frame_Center_Y = Person_Pic_Frame_Top_Y - Person_Pic_Frame_Height/2
    
    --local Want_HeadCard_Width = 115
    --local Want_HeadCard_Height = 115
    --local smallCanonCard = getIconCardSpriteFrame( aMainCardMetaId )
    --print( "aMainCardMetaId: ", aMainCardMetaId )
      --self.Sprite_Person_Pic = CCSprite:createWithSpriteFrame(smallCanonCard)
      --self.Person_Pic = Sprite.new(self.Sprite_Person_Pic)
        --local cardBounds = self.Person_Pic:getBounds().size
          --self.Person_Pic:setScaleX( Want_HeadCard_Width/cardBounds.width )
          --self.Person_Pic:setScaleY( Want_HeadCard_Height/cardBounds.height )
      self.Person_Pic = getHeadIconCanonCardByMetaId(aMainCardMetaId)
        self.Person_Pic:setAnchorPoint(ccp( 0.5, 0.5 ))
        self.Person_Pic:setPosition(ccp( Person_Pic_Frame_Center_X, Person_Pic_Frame_Center_Y ))
      self.Sky_Layer:addChild( self.Person_Pic )
  end


  if Whether_Show_Button_Layer then --按钮层
    self.Small_Rank_Window = self.Button_Layer:getChildByName( "sky_small_rank_window_sb" )
      self.Small_Rank_Size = self.Small_Rank_Window:getTextureRect().size
    local i = 1
    local RankShowText = ""
    local NickName = ""
    local MaxI = 5
    self.Content_Text = {}
    self.Level_Text = {}
    local Max_Hanzi_Num_In_One_Line = 17  --一行中最多有多少个汉字
    for _, aConfig in ipairs( DataManager.GetBabelInfoData.lstSharkBabelRankInfo ) do
      if i <= MaxI then
        NickName = aConfig.nickName
        local Cnt_Chi, Cnt_Eng = self:utfstrlen_Chi_Eng( NickName )
        local TotalCnt = Cnt_Chi*2 + Cnt_Eng
        if TotalCnt > 10 then
          NickName = self:truncateUTF8String( NickName, 9 ) .. ".."
        end
        RankShowText = Localization:getInstance():getText("babel_rankingRank", {num = i}) ..  " " .. NickName
        self.Content_Text[i] = TextField:create( RankShowText )
          self.Content_Text[i]:setFontSize( 18 )
          self.Content_Text[i]:setAnchorPoint(ccp( 0, 0 ))
          self.Content_Text[i]:setHorizontalAlignment(kCCTextAlignmentLeft)
          self.Content_Text[i]:setDimensions(CCSizeMake( 18*Max_Hanzi_Num_In_One_Line, 0 ))
          self.Content_Text[i]:setPosition(ccp( 8, 26*(MaxI-i)+16 ))
      self.Content_Text[i]:setColor(ccc3(0, 0, 0))
        self.Small_Rank_Window:addChild( self.Content_Text[i] )
        self.Level_Text[i] = TextField:create(Localization:getInstance():getText("babel_rankingFloor", {num = aConfig.bestFloor}) )
          self.Level_Text[i]:setFontSize( 18 )
          self.Level_Text[i]:setAnchorPoint(ccp( 1, 0 ))
          self.Level_Text[i]:setHorizontalAlignment(kCCTextAlignmentRight)
          self.Level_Text[i]:setDimensions(CCSizeMake( 18*Max_Hanzi_Num_In_One_Line, 0 ))
          self.Level_Text[i]:setPosition(ccp( 205-11, 26*(MaxI-i)+16 ))
      self.Level_Text[i]:setColor(ccc3(0, 0, 0))
        self.Small_Rank_Window:addChild( self.Level_Text[i] )
        i = i + 1
      end
    end
  end
  
  self.Sky_Layer:setAnchorPoint(ccp( 0, 0 ))
  self.Sky_Layer:setPosition(ccp( 0, -4 ))

  self.Total_Drawing_Layer:addChild( self.Sky_Layer )
  if Whether_Show_Button_Layer then --按钮层
    self:addChild( self.Button_Layer )
  end
  
  --播放塔移动的动画：
  if Last_Level>=0 and Last_Level==Using_Level-1 then
    local Btn_Battle_Show_State = self.btn_battle.isVisible
    
    self.btn_battle:setVisible( false )
    local LocationSkyLayer = self.Sky_Layer:getPosition()
    self.Sky_Layer:setPosition(ccp( LocationSkyLayer.x, LocationSkyLayer.y + 167))
    
    local function After_Tower_Moving_Ended()
      if Btn_Battle_Show_State then
        self.btn_battle:setVisible( true )
      end
      self.Moving_Tower_Animation_Running = false
    end
    
    local arr = CCArray:create()
    arr:addObject(CCMoveBy:create(0.5, ccp(0, -167)))
    arr:addObject(CCCallFunc:create(After_Tower_Moving_Ended))
    self.Sky_Layer:runAction(CCSequence:create(arr))
    self.Moving_Tower_Animation_Running = true
  end
  
end

function SkyTowerMainScene:Whether_Moving_Tower_Animation_Running()
  if self.Moving_Tower_Animation_Running or self.Moving_BackGround_Animation_Running then
    return true
  else
    return false
  end
end

function SkyTowerMainScene:Run_Reset_Level()
  
  local Use_Gem_Num = 0
  
  local function On_ResetOK_Click()
    
    local function Finish_After_Success()
      if self.BlankPanel ~= nil then
        self.BlankPanel:Terminate()
        self.BlankPanel = nil
      end
      
      self:Refresh_Cur_Scene( true )
      
    end
    
    local function Finish_After_Failed()
      if self.BlankPanel ~= nil then
        self.BlankPanel:Terminate()
        self.BlankPanel = nil
      end
    end
    
    local function Success_Reset()
      if Use_Gem_Num > 0 then
        local negativeReward = {
          {	
            itemType = ResourceEnum.GEMS,
            amount = - Use_Gem_Num,
          },
        }
        RewardManager:getReward(negativeReward)
      end
      
      local Cur_resetNum = DataManager.GetBabelInfoData.sharkBabelStatus.resetNum
      DataManager.GetBabelInfoData.sharkBabelStatus.resetNum = Cur_resetNum + 1
      
      DataManager.GetBabelInfoData.sharkBabel.currFloor = 0
      
	 -- Finish_After_Success();
	  --SuspensionLabel:showContent(self, getTextByKey("babel_resetSuccess"))
      CanonMessageBox:Show( getTextByKey("babel_resetSuccess"), ShowMessageType.ShowText, ShowButtonType.ID_OK, 40, Finish_After_Success ) 
                  --"通天塔重置成功！"
    end
  
    local function Failed_Reset( e )
      CanonMessageBox:showCommUnHandleErrorBox( e.data )
      --CanonMessageBox:Show( "错误！", ShowMessageType.ShowText, ShowButtonType.ID_OK, 40, Finish_After_Failed )
    end
    
    local Cur_Gem = 0+CalculationManager.calcComplex_getGemsNow()--方舟改了Gems计算方式
    if Cur_Gem < Use_Gem_Num then
      local aPanel = AssistantMessageBoxPanel:create( self, AsMessageBoxType.addCoin )
      self:addChild(aPanel)
      aPanel:scaleIn()
      return
    end
    
--    print( "On_ResetOK_Click" )
    local NumPre = DataManager.GetBabelInfoData.sharkBabelStatus.resetNum
    DataManager.GetBabelInfoData.sharkBabelStatus.resetNum = NumPre + 1
    
    self.BlankPanel = EmailBlankPanel:Show_withContainer( self )
    
    local params = nil
    local resetBabelRequest = ResetBabelRequest.new(params, rpc.SendingPriority.kHigh)
    resetBabelRequest:addEventListener(RequestNotifyEnum.ResetBabelSucceed, Success_Reset)
    resetBabelRequest:addEventListener(RequestNotifyEnum.ResetBabelFailed, Failed_Reset)
    resetBabelRequest:start()
  end
  
  local function On_ResetCancel_Click()
--    print( "On_ResetCancel_Click" )
  end
  
  local Cur_resetNum = DataManager.GetBabelInfoData.sharkBabelStatus.resetNum
  
  local Common_Allow_resetNum = 1
    if Game_Setting_Config ~= nil and Game_Setting_Config.babel ~= nil then
      Common_Allow_resetNum = Game_Setting_Config.babel.babelFreeResetPerDay+0
    end
  local Vip_Level = 0
    local InitData = DataManager.getGameInitData()
    if InitData ~= nil and InitData["sharkUser"] ~= nil then
      Vip_Level = InitData["sharkUser"].vipLevel
    end
  local Vip_Allow_resetNum = 0
    for _, aConfig in ipairs( MetaManager.vip_setting ) do
      if aConfig.level+0 == Vip_Level then
        Vip_Allow_resetNum = aConfig.extraBabelResetPerDay+0
        break
      end
    end
  local Total_Allow_resetNum = Common_Allow_resetNum + Vip_Allow_resetNum
  
--  print( "Vip_Level: " .. Vip_Level )
--  print( "Cur_resetNum: " .. Cur_resetNum )
--  print( "Total_Allow_resetNum: " .. Total_Allow_resetNum )
    
  local Show_AskReset_Text = ""
  if Cur_resetNum+1 <= Common_Allow_resetNum then
    Use_Gem_Num = 0
    Show_AskReset_Text = getTextByKey("babel_confirmReset")
    CanonMessageBox:Show( Show_AskReset_Text, ShowMessageType.ShowText, ShowButtonType.ID_OK_CANCEL, 40, On_ResetOK_Click, On_ResetCancel_Click )
  else
    if Cur_resetNum+1 <= Total_Allow_resetNum then
      local Pay_Index = (Cur_resetNum+1) - Common_Allow_resetNum
      for _, aConfig in ipairs( MetaManager.babel_reset_price ) do
        local Min = aConfig.minReset+0
        local Max = aConfig.maxReset+0
        if (Pay_Index>=Min and Pay_Index<=Max) or (Max==-1 and Pay_Index>=Min) then
          Use_Gem_Num = aConfig.resetPrice+0
          break
        end
      end
      Show_AskReset_Text = Localization:getInstance():getText("babel_confirmResetGold", {num = Use_Gem_Num})
      CanonMessageBox:Show( Show_AskReset_Text, ShowMessageType.ShowText, ShowButtonType.ID_OK_CANCEL, 33, On_ResetOK_Click, On_ResetCancel_Click )
    else
      Show_AskReset_Text = getTextByKey("babel_cannotReset")
      CanonMessageBox:Show( Show_AskReset_Text, ShowMessageType.ShowText, ShowButtonType.ID_OK, 40, On_ResetCancel_Click )
    end
  end
  
end

function SkyTowerMainScene:Sky_Run_Auto()
  local Best_Level = DataManager.GetBabelInfoData.sharkBabel.bestFloor
  local Cur_Level = DataManager.GetBabelInfoData.sharkBabel.currFloor
  if Cur_Level >= Best_Level then
    CanonMessageBox:Show( getTextByKey("babel_highFloor"), ShowMessageType.ShowText, ShowButtonType.ID_OK, 40, nil )
    return
  end
  
  if DataManager.GetBabelInfoData.sharkBabel.autoClimb == true then
--    self:replaceScene( SkyRunAutoScene ) --显示自动爬塔界面
      local function SkyRunAutoPanel_Finished()
        self.Sky_RunAuto_Panel = nil
      end
      self.Sky_RunAuto_Panel = SkyRunAutoPanel:Show( self.Show_Auto_Layer, self, Sky_RunAuto_Panel_Finished )
    return
  end
  
  local function Func_After_Started( e )
    if self.BlankPanel ~= nil then
      self.BlankPanel:Terminate()
      self.BlankPanel = nil
    end
    
--    self:replaceScene( SkyRunAutoScene ) --显示自动爬塔界面
    local function SkyRunAutoPanel_Finished()
      self.Sky_RunAuto_Panel = nil
    end
    self.Sky_RunAuto_Panel = SkyRunAutoPanel:Show( self.Show_Auto_Layer, self, Sky_RunAuto_Panel_Finished )
  end
        
  local function Func_Failed( e )
    if self.BlankPanel ~= nil then
      self.BlankPanel:Terminate()
      self.BlankPanel = nil
    end
    
    if e.data ~= 713100 and e.data ~= 713101 then
      CanonMessageBox:showCommUnHandleErrorBox( e.data )
      --CanonMessageBox:Show( "错误！", ShowMessageType.ShowText, ShowButtonType.ID_OK, 40, nil )
    end
  end
  
  self.BlankPanel = EmailBlankPanel:Show_withContainer( self )
  
  if self.Button_Layer ~= nil then
    self:removeChild( self.Button_Layer )
    self.Button_Layer = nil
  end
  
  SkyRunAutoPanel:Start_Auto_Process( Func_After_Started, Func_Failed ) --启动自动爬塔
  
end

function SkyTowerMainScene:Sky_Run_Auto_2()
  if DataManager.GetBabelInfoData.sharkBabel.autoClimb == true then
--    self:replaceScene( SkyRunAutoScene ) --显示自动爬塔界面
      local function SkyRunAutoPanel_Finished()
        self.Sky_RunAuto_Panel = nil
      end
      self.Sky_RunAuto_Panel = SkyRunAutoPanel:Show( self.Show_Auto_Layer, self, Sky_RunAuto_Panel_Finished )
    return
  end
  
  local function CallBack_BagsInfo( TotalSpace, UsedSpace ) --计算完后运行这个回调函数
    if TotalSpace > UsedSpace then
      local Cur_Level = DataManager.GetBabelInfoData.sharkBabel.currFloor
      local Best_Level = DataManager.GetBabelInfoData.sharkBabel.bestFloor
      if Cur_Level < Best_Level then
        
        local function Func_After_Started()
          if self.BlankPanel ~= nil then
            self.BlankPanel:Terminate()
            self.BlankPanel = nil
          end
--          self:replaceScene( SkyRunAutoScene ) --显示自动爬塔界面
          local function SkyRunAutoPanel_Finished()
            self.Sky_RunAuto_Panel = nil
          end
          self.Sky_RunAuto_Panel = SkyRunAutoPanel:Show( self.Show_Auto_Layer, self, Sky_RunAuto_Panel_Finished )
        end
        
        local function Func_Failed()
          if self.BlankPanel ~= nil then
            self.BlankPanel:Terminate()
            self.BlankPanel = nil
          end
          CanonMessageBox:Show( "错误！", ShowMessageType.ShowText, ShowButtonType.ID_OK, 40, nil )
        end
        
--        SkyRunAutoScene:Start_Auto_Process( Func_After_Started, Func_Failed ) --开始自动爬塔
        SkyRunAutoPanel:Start_Auto_Process( Func_After_Started, Func_Failed ) --开始自动爬塔
      else
        CanonMessageBox:Show( getTextByKey("babel_highFloor"), ShowMessageType.ShowText, ShowButtonType.ID_OK, 40, nil )
        if self.BlankPanel ~= nil then
          self.BlankPanel:Terminate()
          self.BlankPanel = nil
        end
      end
    else
      NewPackageFullPanel:show()
      -- CanonMessageBox:Show( getTextByKey("babel_inventoryFull"), ShowMessageType.ShowText, ShowButtonType.ID_OK, 40, nil )
      if self.BlankPanel ~= nil then
        self.BlankPanel:Terminate()
        self.BlankPanel = nil
      end
    end
  end
  
  self.BlankPanel = EmailBlankPanel:Show_withContainer( self )
  
  local usedSpace = BagCalcManager.calcUsedGridNum()
	local totalSpace = BagCalcManager.calcTotalGridNum()
  CallBack_BagsInfo(totalSpace, usedSpace)
end

function SkyTowerMainScene:Start_Challenge()
  if DataManager.GetBabelInfoData.sharkBabel.autoClimb == true then
    local function Message_OK_Click()
--      self:replaceScene( SkyRunAutoScene ) --显示自动爬塔界面
      local function SkyRunAutoPanel_Finished()
        self.Sky_RunAuto_Panel = nil
      end
      self.Sky_RunAuto_Panel = SkyRunAutoPanel:Show( self.Show_Auto_Layer, self, Sky_RunAuto_Panel_Finished )
    end
    CanonMessageBox:Show( getTextByKey("babel_autoTxt1"), ShowMessageType.ShowText, ShowButtonType.ID_OK, 40, Message_OK_Click )
    return
  end
  
  local function Success_Challenge( e )
	e.data.selectId = DataManager.GetBabelInfoData.sharkBabel.currFloor + 1
	
    DataManager.GetBabelInfoData = nil --需要重读数据
    
    Director:sharedDirector():replaceScene(BattleScene:create(e.data, BattleBackType.kTongTianTa, BattleEnterEnum.kTongTianTa))
    do return end
    
    local function OK_Click()
      self:Refresh_Cur_Scene( true )
    end
    
    CanonMessageBox:Show( "挑战成功！", ShowMessageType.ShowText, ShowButtonType.ID_OK, 40, OK_Click )
    
  end
  
  local function Failed_Challenge( e )
    if self.BlankPanel ~= nil then
      self.BlankPanel:Terminate()
      self.BlankPanel = nil
    end
    
    if e.data == 713100 then  --User grid is full
      NewPackageFullPanel:show()
      -- CanonMessageBox:Show( getTextByKey("babel_inventoryFull"), ShowMessageType.ShowText, ShowButtonType.ID_OK, 40, nil )
    end
    if e.data == 713104 then  --User fail number is max
      CanonMessageBox:Show( getTextByKey("babel_cannotChallenge"), ShowMessageType.ShowText, ShowButtonType.ID_OK, 40, nil )
    end
    if e.data == 713105 then  --User is in max floor
      CanonMessageBox:Show( getTextByKey("babel_topFloor"), ShowMessageType.ShowText, ShowButtonType.ID_OK, 40, nil )
    end
    if e.data~=713100 and e.data~=713104 and e.data~=713105 then
      CanonMessageBox:showCommUnHandleErrorBox( e.data )
      --CanonMessageBox:Show( "错误！", ShowMessageType.ShowText, ShowButtonType.ID_OK, 40, nil )
    end
  end
  
  self.BlankPanel = EmailBlankPanel:Show_withContainer( self )

  local params = nil
  local challengeBabelRequest = ChallengeBabelRequest.new(params, rpc.SendingPriority.kHigh)
  challengeBabelRequest:addEventListener(RequestNotifyEnum.ChallengeBabelSucceed, Success_Challenge)
  challengeBabelRequest:addEventListener(RequestNotifyEnum.ChallengeBabelFailed, Failed_Challenge)
  challengeBabelRequest:start()

end

function SkyTowerMainScene:truncateUTF8String(s, n)  --不影响汉字的utf8字符截断
  local r = string.sub(s, 1, n)
  local last = string.byte(r, n)
  if not last then return r end
  while last >= 128 and last <= 192 do
    n = n - 1
    r = string.sub(r, 1, n)
    last = string.byte(r, n)
  end  
  if last >= 128 then
    r = string.sub(r, 1, n-1)
  end  
  return r 
end 

function SkyTowerMainScene:utfstrlen(str)  --运行返回汉字或字母个数
  local len = #str;
  local left = len;
  local cnt = 0;
  local arr={0,0xc0,0xe0,0xf0,0xf8,0xfc};
  while left ~= 0 do
    local tmp=string.byte(str,-left);
    local i=#arr;
    while arr[i] do
      if tmp>=arr[i] then 
        left=left-i;
        break;
      end
      i=i-1;
    end
    cnt=cnt+1;
  end
  return cnt;
end

function SkyTowerMainScene:utfstrlen_Chi_Eng(str)  --运行返回“汉字”与“非汉字”的个数（2个数）
  local len = #str;
  local left = len;
  local Cnt_Eng = 0;
  local Cnt_Chi = 0;
  local arr={0,0xc0,0xe0,0xf0,0xf8,0xfc};
  while left ~= 0 do
    local tmp=string.byte(str,-left);
    local i=#arr;
    Cnt_Thres = 0;
    while arr[i] do
      if tmp>=arr[i] then 
        left=left-i;
        break;
      end
      i=i-1;
    end
    if i > 1 then
      Cnt_Chi = Cnt_Chi + 1
    else
      Cnt_Eng = Cnt_Eng + 1
    end
  end
  return Cnt_Chi, Cnt_Eng;
end

function SkyTowerMainScene:setTableViewsEnabled( v )
  self.ListPanel_Can_Touch = v
  if self.RankPanel then
    self.RankPanel:setTouchEnabled(v)
    self.RankPanel.ListView:setTouchEnabled(v)
    self.targetInfoPanel = self.RankPanel
  end
end

function SkyTowerMainScene:Init_BackGround( Using_Level, Last_Level )

  self:Refresh_BackGround( Using_Level, Last_Level )
  
  BaseUIScene.onInit(self)
  
end

function SkyTowerMainScene:Refresh_BackGround( Using_Level, Last_Level )
  
  local Max_Level = #MetaManager.babel_setting + 1 --考虑到第0层
  if Using_Level > Max_Level - 1 then
    Using_Level = Max_Level - 1
  end
  
  local Whole_BackGround_Height = 4110
  local Up_Blank_BackGround_Height = 747
  local Down_Blank_BackGround_Height = 269
  local One_Level_BackGround_Move_Height = ( Whole_BackGround_Height - Up_Blank_BackGround_Height - Down_Blank_BackGround_Height ) / ( Max_Level - 1 )
  local Screen_Use_Height = 1016  --只需要用到110到1126这段空间（y从下往上递增）
  local Screen_Use_Start_Y = 110
  local Screen_Use_End_Y = 1126 - 1
  
    Screen_Use_Height = Screen_Use_Height - One_Level_BackGround_Move_Height --要播放背景移动的动画，因此，下面要留出一段
    Screen_Use_Start_Y = Screen_Use_Start_Y - One_Level_BackGround_Move_Height --要播放背景移动的动画，因此，下面要留出一段
                          --这里要保证One_Level_BackGround_Move_Height小于Screen_Use_Start_Y
  
  local BackGround_Pic_Start_Y = 0 + Using_Level * One_Level_BackGround_Move_Height
  local BackGround_Pic_End_Y = Screen_Use_Height + Using_Level * One_Level_BackGround_Move_Height
  
  if BackGround_Pic_Start_Y >= Whole_BackGround_Height then
    BackGround_Pic_Start_Y = Whole_BackGround_Height - 1
  end
  if BackGround_Pic_Start_Y < 0 then
    BackGround_Pic_Start_Y = 0
  end
  if BackGround_Pic_End_Y >= Whole_BackGround_Height then
    BackGround_Pic_End_Y = Whole_BackGround_Height - 1
  end
  if BackGround_Pic_End_Y < 0 then
    BackGround_Pic_End_Y = 0
  end
  
  local One_Big_Area_Height = 822
  
  local Start_Index = -1
  local End_Index = -1
  local i
  for i = 0, 4, 1 do
    local This_Area_Start_Y = i * One_Big_Area_Height
    local This_Area_End_Y = (i+1) * One_Big_Area_Height - 1
    
    if BackGround_Pic_Start_Y >= This_Area_Start_Y and BackGround_Pic_Start_Y <= This_Area_End_Y then
      Start_Index = i
    end
    if BackGround_Pic_End_Y >= This_Area_Start_Y and BackGround_Pic_End_Y <= This_Area_End_Y then
      End_Index = i
    end
    
  end
  if Start_Index == -1 or End_Index == -1 then
--    print( "BackGround Error !" )
    return
  end
  
  if self.Total_BackGround_Layer == nil then --初始化Total_BackGround_Layer层
    self.Total_BackGround_Layer = LayerColor:create()
    self.Total_BackGround_Layer:setContentSize(CCSizeMake( visibleSize.width, visibleSize.height ))
    self.Total_BackGround_Layer:setPosition(ccp(0, 0))
    self.Total_Drawing_Layer:addChild( self.Total_BackGround_Layer )
  end
  
  local function Show_One_Pic( Index, Loc_Y )  --显示一个图片
                        --Index从1至5表示图片序号，Loc_Y表示图片位置
    if Index < 1 or Index > 5 then
      return
    end
    
    if Index == 1 then
      Picture_FileName = "sky/TTT05.png"
    elseif Index == 2 then
      Picture_FileName = "sky/TTT04.png"
    elseif Index == 3 then
      Picture_FileName = "sky/TTT03.png"
    elseif Index == 4 then
      Picture_FileName = "sky/TTT02.png"
    elseif Index == 5 then
      Picture_FileName = "sky/TTT01.png"
    end
    
    if self.Using_BackGround_1 == nil then
      self.Using_BackGround_1 = Sprite:create( Picture_FileName )
	  self.Using_BackGround_1:setScale(2)
      self.Using_BackGround_1:setAnchorPoint(ccp( 0, 0 ))
      self.Using_BackGround_1:setPosition(ccp( 0, Loc_Y ))
      self.Total_BackGround_Layer:addChild( self.Using_BackGround_1 )
    elseif self.Using_BackGround_2 == nil then
      self.Using_BackGround_2 = Sprite:create( Picture_FileName )
	  self.Using_BackGround_2:setScale(2)
      self.Using_BackGround_2:setAnchorPoint(ccp( 0, 0 ))
      self.Using_BackGround_2:setPosition(ccp( 0, Loc_Y ))
      self.Total_BackGround_Layer:addChild( self.Using_BackGround_2 )
    elseif self.Using_BackGround_3 == nil then
      self.Using_BackGround_3 = Sprite:create( Picture_FileName )
	  self.Using_BackGround_3:setScale(2)
      self.Using_BackGround_3:setAnchorPoint(ccp( 0, 0 ))
      self.Using_BackGround_3:setPosition(ccp( 0, Loc_Y ))
      self.Total_BackGround_Layer:addChild( self.Using_BackGround_3 )
    end
  end
  
  local Used_State = {}
  
  if Start_Index == End_Index then --需要一个图片
    local Put_Pic_Y = Screen_Use_Start_Y - ( Using_Level*One_Level_BackGround_Move_Height - Start_Index*One_Big_Area_Height )

    if self.Using_BackGround_Index_1 == Start_Index then
      self.Using_BackGround_1:setPosition(ccp( 0, Put_Pic_Y ))
      Used_State[1] = 1
    elseif self.Using_BackGround_Index_2 == Start_Index then
      self.Using_BackGround_2:setPosition(ccp( 0, Put_Pic_Y ))
      Used_State[1] = 1
    elseif self.Using_BackGround_Index_3 == Start_Index then
      self.Using_BackGround_3:setPosition(ccp( 0, Put_Pic_Y ))
      Used_State[1] = 1
    end
    
    if self.Using_BackGround_Index_1 ~= Start_Index then
      if self.Using_BackGround_1 ~= nil then
        self.Total_BackGround_Layer:removeChild( self.Using_BackGround_1 )
        self.Using_BackGround_1 = nil
      end
      self.Using_BackGround_Index_1 = -1
    end
    if self.Using_BackGround_Index_2 ~= Start_Index then
      if self.Using_BackGround_2 ~= nil then
        self.Total_BackGround_Layer:removeChild( self.Using_BackGround_2 )
        self.Using_BackGround_2 = nil
      end
      self.Using_BackGround_Index_2 = -1
    end
    if self.Using_BackGround_Index_3 ~= Start_Index then
      if self.Using_BackGround_3 ~= nil then
        self.Total_BackGround_Layer:removeChild( self.Using_BackGround_3 )
        self.Using_BackGround_3 = nil
      end
      self.Using_BackGround_Index_3 = -1
    end
    
    if Used_State[1] ~= 1 then
      Show_One_Pic( Start_Index + 1, Put_Pic_Y )
    end
    
  elseif End_Index - Start_Index == 1 then --需要两个图片
    local Put_Pic_Y_1 = Screen_Use_Start_Y - ( Using_Level*One_Level_BackGround_Move_Height - Start_Index*One_Big_Area_Height )
    local Put_Pic_Y_2 = Screen_Use_Start_Y - ( Using_Level*One_Level_BackGround_Move_Height - End_Index*One_Big_Area_Height )

    if self.Using_BackGround_Index_1 == Start_Index then
      self.Using_BackGround_1:setPosition(ccp( 0, Put_Pic_Y_1 ))
      Used_State[1] = 1
    elseif self.Using_BackGround_Index_2 == Start_Index then
      self.Using_BackGround_2:setPosition(ccp( 0, Put_Pic_Y_1 ))
      Used_State[1] = 1
    elseif self.Using_BackGround_Index_3 == Start_Index then
      self.Using_BackGround_3:setPosition(ccp( 0, Put_Pic_Y_1 ))
      Used_State[1] = 1
    end
    
    if self.Using_BackGround_Index_1 == End_Index then
      self.Using_BackGround_1:setPosition(ccp( 0, Put_Pic_Y_2 ))
      Used_State[2] = 1
    elseif self.Using_BackGround_Index_2 == End_Index then
      self.Using_BackGround_2:setPosition(ccp( 0, Put_Pic_Y_2 ))
      Used_State[2] = 1
    elseif self.Using_BackGround_Index_3 == End_Index then
      self.Using_BackGround_3:setPosition(ccp( 0, Put_Pic_Y_2 ))
      Used_State[2] = 1
    end
    
    if self.Using_BackGround_Index_1 ~= Start_Index and self.Using_BackGround_Index_1 ~= End_Index then
      if self.Using_BackGround_1 ~= nil then
        self.Total_BackGround_Layer:removeChild( self.Using_BackGround_1 )
        self.Using_BackGround_1 = nil
      end
      self.Using_BackGround_Index_1 = -1
    end
    if self.Using_BackGround_Index_2 ~= Start_Index and self.Using_BackGround_Index_2 ~= End_Index then
      if self.Using_BackGround_2 ~= nil then
        self.Total_BackGround_Layer:removeChild( self.Using_BackGround_2 )
        self.Using_BackGround_2 = nil
      end
      self.Using_BackGround_Index_2 = -1
    end
    if self.Using_BackGround_Index_3 ~= Start_Index and self.Using_BackGround_Index_3 ~= End_Index then
      if self.Using_BackGround_3 ~= nil then
        self.Total_BackGround_Layer:removeChild( self.Using_BackGround_3 )
        self.Using_BackGround_3 = nil
      end
      self.Using_BackGround_Index_3 = -1
    end
    
    if Used_State[1] ~= 1 then
      Show_One_Pic( Start_Index + 1, Put_Pic_Y_1 )
    end
    if Used_State[2] ~= 1 then
      Show_One_Pic( End_Index + 1, Put_Pic_Y_2 )
    end
    
  elseif End_Index - Start_Index == 2 then --需要三个图片
    local Put_Pic_Y_1 = Screen_Use_Start_Y - ( Using_Level*One_Level_BackGround_Move_Height - Start_Index*One_Big_Area_Height )
    local Put_Pic_Y_2 = Screen_Use_Start_Y - ( Using_Level*One_Level_BackGround_Move_Height - (Start_Index+1)*One_Big_Area_Height )
    local Put_Pic_Y_3 = Screen_Use_Start_Y - ( Using_Level*One_Level_BackGround_Move_Height - End_Index*One_Big_Area_Height )

    if self.Using_BackGround_Index_1 == Start_Index then
      self.Using_BackGround_1:setPosition(ccp( 0, Put_Pic_Y_1 ))
      Used_State[1] = 1
    elseif self.Using_BackGround_Index_2 == Start_Index then
      self.Using_BackGround_2:setPosition(ccp( 0, Put_Pic_Y_1 ))
      Used_State[1] = 1
    elseif self.Using_BackGround_Index_3 == Start_Index then
      self.Using_BackGround_3:setPosition(ccp( 0, Put_Pic_Y_1 ))
      Used_State[1] = 1
    end
    
    if self.Using_BackGround_Index_1 == Start_Index + 1 then
      self.Using_BackGround_1:setPosition(ccp( 0, Put_Pic_Y_2 ))
      Used_State[2] = 1
    elseif self.Using_BackGround_Index_2 == Start_Index + 1 then
      self.Using_BackGround_2:setPosition(ccp( 0, Put_Pic_Y_2 ))
      Used_State[2] = 1
    elseif self.Using_BackGround_Index_3 == Start_Index + 1 then
      self.Using_BackGround_3:setPosition(ccp( 0, Put_Pic_Y_2 ))
      Used_State[2] = 1
    end
    
    if self.Using_BackGround_Index_1 == End_Index then
      self.Using_BackGround_1:setPosition(ccp( 0, Put_Pic_Y_3 ))
      Used_State[3] = 1
    elseif self.Using_BackGround_Index_2 == End_Index then
      self.Using_BackGround_2:setPosition(ccp( 0, Put_Pic_Y_3 ))
      Used_State[3] = 1
    elseif self.Using_BackGround_Index_3 == End_Index then
      self.Using_BackGround_3:setPosition(ccp( 0, Put_Pic_Y_3 ))
      Used_State[3] = 1
    end
    
    if self.Using_BackGround_Index_1 ~= Start_Index and self.Using_BackGround_Index_1 ~= Start_Index+1 and self.Using_BackGround_Index_1 ~= End_Index then
      if self.Using_BackGround_1 ~= nil then
        self.Total_BackGround_Layer:removeChild( self.Using_BackGround_1 )
        self.Using_BackGround_1 = nil
      end
      self.Using_BackGround_Index_1 = -1
    end
    if self.Using_BackGround_Index_2 ~= Start_Index and self.Using_BackGround_Index_2 ~= Start_Index+1 and self.Using_BackGround_Index_2 ~= End_Index then
      if self.Using_BackGround_2 ~= nil then
        self.Total_BackGround_Layer:removeChild( self.Using_BackGround_2 )
        self.Using_BackGround_2 = nil
      end
      self.Using_BackGround_Index_2 = -1
    end
    if self.Using_BackGround_Index_3 ~= Start_Index and self.Using_BackGround_Index_3 ~= Start_Index+1 and self.Using_BackGround_Index_3 ~= End_Index then
      if self.Using_BackGround_3 ~= nil then
        self.Total_BackGround_Layer:removeChild( self.Using_BackGround_3 )
        self.Using_BackGround_3 = nil
      end
      self.Using_BackGround_Index_3 = -1
    end
    
    if Used_State[1] ~= 1 then
      Show_One_Pic( Start_Index + 1, Put_Pic_Y_1 )
    end
    if Used_State[2] ~= 1 then
      Show_One_Pic( (Start_Index+1) + 1, Put_Pic_Y_2 )
    end
    if Used_State[3] ~= 1 then
      Show_One_Pic( End_Index + 1, Put_Pic_Y_3 )
    end
    
  else
--    print( "BackGround Error !" )
    return
  end
  
  --播放背景移动的动画：
  if Last_Level>=0 and Last_Level==Using_Level-1 then
    
    local LocationBackGroundLayer = self.Total_BackGround_Layer:getPosition()
    self.Total_BackGround_Layer:setPosition(ccp( LocationBackGroundLayer.x, LocationBackGroundLayer.y + One_Level_BackGround_Move_Height))
    
    local function After_Tower_Moving_Ended()
      self.Moving_BackGround_Animation_Running = false
    end
    
    local arr = CCArray:create()
    arr:addObject(CCMoveBy:create(0.5, ccp(0, 0-One_Level_BackGround_Move_Height)))
    arr:addObject(CCCallFunc:create(After_Tower_Moving_Ended))
    self.Total_BackGround_Layer:runAction(CCSequence:create(arr))
    self.Moving_BackGround_Animation_Running = true
  end

end

function SkyTowerMainScene:Test_Whole_BackGround()
  local function onAutoClimbingFlashEnd()
    if self.Init_BackGround_Data == nil then
      self.Init_BackGround_Data = 0
    end
--    print( "Level: " .. self.Init_BackGround_Data )
    self:Init_BackGround( self.Init_BackGround_Data, -999999 )
    self.Init_BackGround_Data = self.Init_BackGround_Data + 1
  end
  self.SkyFspt = FlashSprite:create("EVO2/zidongpata")
  self.SkyFspt:changeAnimation(0)
  self.SkyFspt:setLoop(true)
  self.SkyFspt:registerEndAnimationScriptHandler(onAutoClimbingFlashEnd)
  self.SkyFspt_co = CocosObject.new(self.SkyFspt)
  self:addChild(self.SkyFspt_co)
end

function SkyTowerMainScene:Refresh_Cur_Scene( ignoreAction )
  local function Success_Sky_Data( e )
    if e ~= nil then
      DataManager.GetBabelInfoData = e.data
      DataManager.GetBabelInfoData._DownloadDataTime = TimeUtil.getServerTimeSeconds()
    end
    
    if self.BlankPanel ~= nil then
      self.BlankPanel:Terminate()
      self.BlankPanel = nil
    end
    
    if (self.reportUpdateFunc) then --解决文字变快问题
      CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.reportUpdateFunc)
    end
    Director:sharedDirector():replaceScene( SkyTowerMainScene:create() )
  end
  
  local function Faild_Sky_Data( e )
    if self.BlankPanel ~= nil then
      self.BlankPanel:Terminate()
      self.BlankPanel = nil
    end
    
    if e.data == 713103 then
      local function OK_Click()
        Director:sharedDirector():replaceScene( MainMenuScene:create() )
      end
      
      CanonMessageBox:Show(Localization:getInstance():getText("babel_levelInsufficient", {num = MetaManager.game_meta.gameSettingConfig.babelConfig.babelTowerUnlockLevel}), ShowMessageType.ShowText, ShowButtonType.ID_OK, 40, OK_Click )
    end
  end
  
  self.NoAnimationRun = ignoreAction
  self.ignoreAction = ignoreAction
  
  self.BlankPanel = EmailBlankPanel:Show_withContainer( self )
  
  local getBabelInfoRequest = GetBabelInfoRequest.new(params, rpc.SendingPriority.kHigh)
  getBabelInfoRequest:addEventListener(RequestNotifyEnum.GetBabelInfoSucceed, Success_Sky_Data)
  getBabelInfoRequest:addEventListener(RequestNotifyEnum.GetBabelInfoFailed, Faild_Sky_Data)
  getBabelInfoRequest:start()
end

function SkyTowerMainScene:Show_One_Level( Using_Level )
--  print( "Show_One_Level( " .. Using_Level .. " )" )
  
  local Last_Level = Get_ShareData( "Sky_TongTianTa_Last_Level" )
  
  self:Refresh_BackGround( Using_Level, Last_Level )
  
  if Using_Level%2 == 0 then 
    self:Show_Left_Sky_Layer( Using_Level, Last_Level, false )
  else
    self:Show_Right_Sky_Layer( Using_Level, Last_Level, false )
  end
  
  self.Showing_Level = Using_Level --记录当前显示的Level
  
  Set_ShareData( "Sky_TongTianTa_Last_Level", Using_Level )
  
end

function SkyTowerMainScene:Get_Showing_Level()
    return self.Showing_Level
end

function SkyTowerMainScene:Get_Cur_Level()
    local Cur_Level = DataManager.GetBabelInfoData.sharkBabel.currFloor
    return Cur_Level
end

function SkyTowerMainScene:setBackScene( BackScene )
  self.BackScene = BackScene
end

function SkyTowerMainScene:back()
--  print("SkyTowerMainScene:back")

  if self.Sky_RunAuto_Panel ~= nil then
    self.Sky_RunAuto_Panel:Terminate()
    self.Sky_RunAuto_Panel = nil
  end
  
  print( "self.BackScene: ", self.BackScene )

  if self.BackScene == "ChallengeEntersScene" then
    self:replaceScene( ChallengeEntersScene )
  elseif self.BackScene == "CardComposeScene" then
    self:replaceScene( CardComposeScene )
  else
    self:replaceScene( MainMenuScene )
  end
end


function SkyTowerMainScene:doEnterAnimation()
  self:preEnterAnimation()
  self:startEnterAnimation()
  self:sufEnterAnimation()
end

function SkyTowerMainScene:preEnterAnimation()
  BaseUIScene.preEnterAnimation(self)
end

function SkyTowerMainScene:startEnterAnimation()
  BaseUIScene.startEnterAnimation(self)
end

function SkyTowerMainScene:sufEnterAnimation()
  BaseUIScene.sufEnterAnimation(self)
end

function SkyTowerMainScene:doExitAnimation()
  if self.Sky_RunAuto_Panel ~= nil then
    self.Sky_RunAuto_Panel:Terminate()
    self.Sky_RunAuto_Panel = nil
  end
  
  if self.NoAnimationRun ~= true then
    self:preExitAnimation()
    self:startExitAnimation() 
  end
  self:sufExitAnimation()
end

function SkyTowerMainScene:preExitAnimation()
  BaseUIScene.preExitAnimation(self)
end

function SkyTowerMainScene:startExitAnimation()
  BaseUIScene.startExitAnimation(self)
end

function SkyTowerMainScene:sufExitAnimation()
  BaseUIScene.sufExitAnimation(self)
end






