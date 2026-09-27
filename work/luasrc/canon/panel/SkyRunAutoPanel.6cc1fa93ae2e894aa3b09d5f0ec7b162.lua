require "hecore.display.CocosObject"
require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "canon.request.StartAutoClimbBabelRequest"
require "canon.request.GainAutoClimbRewardRequest"
require "canon.data.MetaManager"
require "canon.data.DataManager"
require "canon.models.RewardManager"
require "hecore.ui.Button"
require "hecore.display.Layer"
require "canon.panel.BattleResultPanel"
require "canon.scene.CardQueueScene"
require "canon.panel.VipWarningPanel"
require "canon.utils.TimeUtil"

SkyRunAutoPanel = class(Layer)
local visibleSize = CCDirector:sharedDirector():getVisibleSize();

function SkyRunAutoPanel:ctor()

end

function SkyRunAutoPanel:Show( container, SkyScene, Finished_CallBack_Func )
  self.container = container
  self.SkyScene = SkyScene
  self.Finished_CallBack_Func = Finished_CallBack_Func
  
  local s = SkyRunAutoPanel.new()
  s:initLayer()
  
  self.container:addChild( s )
  s:setZOrder( 1 )
  
  return s
end

----------------------------------------
-- 获取服务器当前时间
----------------------------------------
-- 说明：只有在用Request通信后才有效
--   若Request通信后，用户手动改了手机时间
--   则需要再次Request通信更新时间信息
----------------------------------------
function SkyRunAutoPanel:get_Sever_Time()
  local Client_Time = os.time() --客户端时间
  local Diff_T = _G.__g_utcDiffSeconds --时间差：服务器时间 - 客户端时间
  local Sever_Time = Diff_T + Client_Time --服务器时间
--  print(os.date("%c", Sever_Time)) --显示时间
  return Sever_Time
end

function SkyRunAutoPanel:initLayer()
  SkyRunAutoPanel.super.initLayer(self)  

self.BackLayer = LayerColor:create()
self.BackLayer:setColor(ccc3( 0, 0, 0 ))
self.BackLayer.refCocosObj:setOpacity( 200 )
self.BackLayer:setContentSize(CCSizeMake( visibleSize.width, 930 ))
self.BackLayer:setPosition(ccp( 0, 120 ))
self:addChild( self.BackLayer )
self:ShowFlash()
  
  local function On_AutoStop_Click()
--    print( "On_AutoStop_Click" )
    
    local function Success_Auto_Stop( e )
      if e ~= nil then
        self.data = e.data
      else
        self.data = nil
      end
      
      self.Count_Time_End = true
      
      if self.BlankPanel ~= nil then
        self.BlankPanel:Terminate()
        self.BlankPanel = nil
      end
      
      local function OK_Click()
        if self.autoRunSchedule then
          CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.autoRunSchedule)
          self.autoRunSchedule = nil;
        end
        if self.SkyFspt_co ~= nil then
          self.SkyFspt:unregisterEndAnimationScriptHandler()
          self:removeChild(self.SkyFspt_co) --一定要remove掉falsh动画和回调函数，不然可能在后台继续运行flash
          self.SkyFspt_co = nil
        end
        self:Change_To_SkyTowerMainScene( false )
      end
      
      if self.data and self.data.rewards then
        self:AutoClimbEndPanel()
      else
        OK_Click()
      end

    end
    
    local function Failed_Auto_Stop( e )
      self.data = nil
      
      if self.BlankPanel ~= nil then
        self.BlankPanel:Terminate()
        self.BlankPanel = nil
      end
      
      local function OK_Click()
        if self.autoRunSchedule then
          CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.autoRunSchedule)
          self.autoRunSchedule = nil;
        end
        if self.SkyFspt_co ~= nil then
          self.SkyFspt:unregisterEndAnimationScriptHandler()
          self:removeChild(self.SkyFspt_co) --一定要remove掉falsh动画和回调函数，不然可能在后台继续运行flash
          self.SkyFspt_co = nil
        end
        self:Change_To_SkyTowerMainScene( false )
      end
      
      if e.data == 713108 then
        CanonMessageBox:Show( getTextByKey( "babel_autoIsFalse" ), ShowMessageType.ShowText, ShowButtonType.ID_OK, 40 ) --"您并没有在自动爬塔"
      elseif e.data == 710516 then
        CanonMessageBox:Show( "您的背包已满，请先清理背包", ShowMessageType.ShowText, ShowButtonType.ID_OK, 40 )
      else
        CanonMessageBox:showCommUnHandleErrorBox( e.data )
--        CanonMessageBox:Show( "错误！", ShowMessageType.ShowText, ShowButtonType.ID_OK, 40 )
      end
      
      OK_Click() --必须运行这个函数，清除动画（重要）
    end
    
    local function Yes_Run_Auto_Stop()
      self.BlankPanel = EmailBlankPanel:Show_withContainer( self )
      
      local Params_GainAutoClimbReward = { speedUp = false }
      local gainAutoClimbRewardRequest = GainAutoClimbRewardRequest.new(Params_GainAutoClimbReward, rpc.SendingPriority.kHigh)
      gainAutoClimbRewardRequest:addEventListener(RequestNotifyEnum.GainAutoClimbRewardSucceed, Success_Auto_Stop)
      gainAutoClimbRewardRequest:addEventListener(RequestNotifyEnum.GainAutoClimbRewardFailed, Failed_Auto_Stop)
      gainAutoClimbRewardRequest:start()
    end

    CanonMessageBox:Show( getTextByKey("babel_confirmStop"), ShowMessageType.ShowText, ShowButtonType.ID_OK_CANCEL, 40, Yes_Run_Auto_Stop )
    
  end
  
  local function On_AutoAccelerate_Click()
--    print( "On_AutoAccelerate_Click" )
    
    local function Success_Auto_Accelerate( e )
      if e ~= nil then
        self.data = e.data
      else
        self.data = nil
      end
      
      self.Count_Time_End = true
      
      if self.BlankPanel ~= nil then
        self.BlankPanel:Terminate()
        self.BlankPanel = nil
      end
      
      self:AutoClimbEndPanel()
      
    end
    
    local function Failed_Auto_Accelerate( e )
      self.data = nil
      
      if self.BlankPanel ~= nil then
        self.BlankPanel:Terminate()
        self.BlankPanel = nil
      end
      
      local function OK_Click()
        if self.autoRunSchedule then
          CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.autoRunSchedule)
          self.autoRunSchedule = nil;
        end
        if self.SkyFspt_co ~= nil then
          self.SkyFspt:unregisterEndAnimationScriptHandler()
          self:removeChild(self.SkyFspt_co) --一定要remove掉falsh动画和回调函数，不然可能在后台继续运行flash
          self.SkyFspt_co = nil
        end
        self:Change_To_SkyTowerMainScene( false )
      end
      
      if e.data == 713108 then
        CanonMessageBox:Show( "错误，当前没自动爬塔", ShowMessageType.ShowText, ShowButtonType.ID_OK, 40 )
      elseif e.data == 712905 then
        local MinLevelForAccelerate = 50000
        for aIndex, aConfig in pairs( MetaManager.vip_setting ) do
          local unlockString = aConfig.unlockContents
          if string.find( unlockString, ",5" ) ~= nil or string.find( unlockString, ", 5" ) ~= nil then --寻找是否包含5的项
            if aConfig.level < MinLevelForAccelerate then
              MinLevelForAccelerate = aConfig.level
            end
          end
        end
        if MinLevelForAccelerate == 50000 then
          MinLevelForAccelerate = 1
        end
        
--        local ShowErrorText = Localization:getInstance():getText( "babel_cannotAccelerate", { num = MinLevelForAccelerate } )
--        CanonMessageBox:Show( ShowErrorText, ShowMessageType.ShowText, ShowButtonType.ID_OK, 40 )
        self.SkyScene.targetInfoPanel = VipWarningPanel:create( self.SkyScene, MinLevelForAccelerate )
        PopoutManager:sharedManager():popout( self.SkyScene.targetInfoPanel, kPopoutDir.kScale, true, false, self.SkyScene )
        
      else
        CanonMessageBox:showCommUnHandleErrorBox( e.data )
        --CanonMessageBox:Show( "错误！", ShowMessageType.ShowText, ShowButtonType.ID_OK, 40 )
      end
      
    end
    
    local Vip_Level = 0
      local InitData = DataManager.getGameInitData()
      if InitData ~= nil and InitData["sharkUser"] ~= nil then
        Vip_Level = InitData["sharkUser"].vipLevel
      end
      
    local MinLevelForAccelerate = 50000
    for aIndex, aConfig in pairs( MetaManager.vip_setting ) do
      local unlockString = aConfig.unlockContents
      if string.find( unlockString, ",5" ) ~= nil or string.find( unlockString, ", 5" ) ~= nil then --寻找是否包含5的项
        if aConfig.level < MinLevelForAccelerate then
          MinLevelForAccelerate = aConfig.level
        end
      end
    end
    if MinLevelForAccelerate == 50000 then
      MinLevelForAccelerate = 1
    end
      
    if Vip_Level >= MinLevelForAccelerate then
      self.BlankPanel = EmailBlankPanel:Show_withContainer( self )
      
      local Params_GainAutoClimbReward = { speedUp = true }
      local gainAutoClimbRewardRequest = GainAutoClimbRewardRequest.new(Params_GainAutoClimbReward, rpc.SendingPriority.kHigh)
      gainAutoClimbRewardRequest:addEventListener(RequestNotifyEnum.GainAutoClimbRewardSucceed, Success_Auto_Accelerate)
      gainAutoClimbRewardRequest:addEventListener(RequestNotifyEnum.GainAutoClimbRewardFailed, Failed_Auto_Accelerate)
      gainAutoClimbRewardRequest:start()
    else
--      local ShowErrorText = Localization:getInstance():getText( "babel_cannotAccelerate", { num = MinLevelForAccelerate } )
--      CanonMessageBox:Show( ShowErrorText, ShowMessageType.ShowText, ShowButtonType.ID_OK, 40 )
      self.SkyScene.targetInfoPanel = VipWarningPanel:create( self.SkyScene, MinLevelForAccelerate )
      PopoutManager:sharedManager():popout( self.SkyScene.targetInfoPanel, kPopoutDir.kScale, true, false, self.SkyScene )
    end
    
  end
  
  self.UIBuilder = LayoutBuilder:createWithContentsOfFile("scene/sky_tongtianta.json")
  
  self:Update_Container_Button( true )
  
  self.pic_auto_stop = self.UIBuilder:build("btn/btn_auto_stop")
    self.txt_auto_stop = self.pic_auto_stop:getChildByName( "txt_auto_stop" ):getChildByName( "txt" )
      self.txt_auto_stop:setString( getTextByKey("babel_stopBtn") )
    self.pic_auto_stop:setPosition(ccp( 210-168/2, 215 ))
    self:addChild( self.pic_auto_stop )
    self.btn_auto_stop = Button:create( self.pic_auto_stop )
      self.btn_auto_stop:addEventListener( Events.kStart, On_AutoStop_Click, self ) 
    
  self.pic_auto_accelerate = self.UIBuilder:build("btn/btn_auto_accelerate")
    self.txt_auto_accelerate = self.pic_auto_accelerate:getChildByName( "txt_auto_accelerate" ):getChildByName( "txt" )
      self.txt_auto_accelerate:setString( getTextByKey("babel_accelerateBtn") )
    self.pic_auto_accelerate:setPosition(ccp( 510-168/2, 215 ))
    self:addChild( self.pic_auto_accelerate )
    self.btn_auto_accelerate = Button:create( self.pic_auto_accelerate )
      self.btn_auto_accelerate:addEventListener( Events.kStart, On_AutoAccelerate_Click, self ) 
    
  local Max_Hanzi_Num_In_One_Line = 17  --一行中最多有多少个汉字
  
  self.AutoRunTitle = TextField:create( getTextByKey("babel_autoTxt1") )
    self.AutoRunTitle:setFontSize( 40 )
    self.AutoRunTitle:setHorizontalAlignment(kCCTextAlignmentCenter)
    self.AutoRunTitle:setDimensions(CCSizeMake( 40*Max_Hanzi_Num_In_One_Line, 40 ))
    self.AutoRunTitle:setPosition(ccp( visibleSize.width/2, 461 ))
    self:addChild( self.AutoRunTitle )
    
  self.TimeLeftPreText = TextField:create(getTextByKey("babel_autoTxt2") )
    self.TimeLeftPreText:setFontSize( 33 )
    self.TimeLeftPreText:setHorizontalAlignment(kCCTextAlignmentCenter)
    self.TimeLeftPreText:setDimensions(CCSizeMake( 33*Max_Hanzi_Num_In_One_Line, 33 ))
    self.TimeLeftPreText:setPosition(ccp( visibleSize.width/2-80, 384 ))
    self:addChild( self.TimeLeftPreText )
    
  self.TimeLeftText = TextField:create( "" )
    self.TimeLeftText:setFontSize( 33 )
    self.TimeLeftText:setHorizontalAlignment(kCCTextAlignmentLeft)
    self.TimeLeftText:setDimensions(CCSizeMake( 33*Max_Hanzi_Num_In_One_Line, 33 ))
    self.TimeLeftText:setAnchorPoint(ccp( 0, 0.5 ))
    self.TimeLeftText:setPosition(ccp( visibleSize.width/2+100, 384 ))
    self:addChild( self.TimeLeftText )
    
  self:Calc_Time_And_Refresh()
  
  do
    self.Refresh_BabelInfo_Already = false
    self.Finish_AutoClimb_Already = false
    self.Finishing_AutoClimb = false
    
    local function Success_Sky_Data( e )
      if e ~= nil then
        DataManager.GetBabelInfoData = e.data
        DataManager.GetBabelInfoData._DownloadDataTime = TimeUtil.getServerTimeSeconds()
      end

      if self.BlankPanel ~= nil then
        self.BlankPanel:Terminate()
        self.BlankPanel = nil
      end
      
      self.Refresh_BabelInfo_Already = true
      
      self:Calc_Time_And_Refresh()  --计算时间并更新状态
    end
    
    local function Faild_Sky_Data( e )
      
      if self.BlankPanel ~= nil then
        self.BlankPanel:Terminate()
        self.BlankPanel = nil
      end
    end
    
    self.BlankPanel = EmailBlankPanel:Show_withContainer( self )
    
    local getBabelInfoRequest = GetBabelInfoRequest.new(params, rpc.SendingPriority.kHigh)
    getBabelInfoRequest:addEventListener(RequestNotifyEnum.GetBabelInfoSucceed, Success_Sky_Data)
    getBabelInfoRequest:addEventListener(RequestNotifyEnum.GetBabelInfoFailed, Faild_Sky_Data)
    getBabelInfoRequest:start()
  end

end

function SkyRunAutoPanel:Calc_Time_And_Refresh()
  if self.Refresh_BabelInfo_Already ~= true then
    return
  end
  if self.Finish_AutoClimb_Already == true then
    return
  end
  if self.Finishing_AutoClimb == true then
    return
  end
  if self.refCocosObj == nil then --如果检测到场景切换了，但每帧都运行这个函数，则注销调用
    if self.autoRunSchedule ~= nil then
      CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry( self.autoRunSchedule )
      self.autoRunSchedule = nil;
    end
    return
  end
  
  local StartClimb_Server_Time = DataManager.GetBabelInfoData.sharkBabel.autoClimbTime
  local Total_Need_Time = ( DataManager.GetBabelInfoData.sharkBabel.bestFloor - DataManager.GetBabelInfoData.sharkBabel.currFloor )*60
  local Passed_Time = self:get_Sever_Time() - StartClimb_Server_Time
  local Time_Left_To_Finish = Total_Need_Time - Passed_Time
--  print( "Time_Left_To_Finish: " .. Time_Left_To_Finish )
    if Time_Left_To_Finish <= -3 then
      self.Finishing_AutoClimb = true
      
      local function Finish_Success( e )
        if e ~= nil then
          self.data = e.data
        else
          self.data = nil
        end
        
        if self.BlankPanel ~= nil then
          self.BlankPanel:Terminate()
          self.BlankPanel = nil
        end
        
        self.Finish_AutoClimb_Already = true
        
        self:AutoClimbEndPanel()
        
      end
      
      local function Finish_Error( e )
        self.data = nil
        
        if self.BlankPanel ~= nil then
          self.BlankPanel:Terminate()
          self.BlankPanel = nil
        end
        
        CanonMessageBox:showCommUnHandleErrorBox( e.data )
        --CanonMessageBox:Show( "错误！", ShowMessageType.ShowText, ShowButtonType.ID_OK, 40, nil )
      end
      
      self.BlankPanel = EmailBlankPanel:Show_withContainer( self )
      
      local Params_GainAutoClimbReward = { speedUp = false }
      local gainAutoClimbRewardRequest = GainAutoClimbRewardRequest.new(Params_GainAutoClimbReward, rpc.SendingPriority.kHigh)
      gainAutoClimbRewardRequest:addEventListener(RequestNotifyEnum.GainAutoClimbRewardSucceed, Finish_Success)
      gainAutoClimbRewardRequest:addEventListener(RequestNotifyEnum.GainAutoClimbRewardFailed, Finish_Error)
      gainAutoClimbRewardRequest:start()
    end
  
    if Time_Left_To_Finish < 0 then
		Time_Left_To_Finish = 0
	end
	self.TimeLeftText:setString( string.format( "%02d:%02d:%02d", math.floor(Time_Left_To_Finish/3600), math.floor((Time_Left_To_Finish % 3600)/60), math.floor(Time_Left_To_Finish % 60) ) )
	self.TimeLeftText:setColor(ccc3(255, 0, 0))
  
  local Total_Need_Level = DataManager.GetBabelInfoData.sharkBabel.bestFloor - DataManager.GetBabelInfoData.sharkBabel.currFloor
  local Passed_Level = math.floor((self:get_Sever_Time() - StartClimb_Server_Time) / 60)
  if Passed_Level > Total_Need_Level then
    Passed_Level = Total_Need_Level
  end
  if Passed_Level < 0 then
    Passed_Level = 0
  end
  local Showing_Level = self.SkyScene:Get_Showing_Level()
  local Cur_Level = self.SkyScene:Get_Cur_Level()
--  print( "Showing_Level: " .. Showing_Level )
--  print( "Need_Show_Level: " .. Cur_Level + Passed_Level )
  if ( not self.SkyScene:Whether_Moving_Tower_Animation_Running() ) then
    if Cur_Level + Passed_Level ~= Showing_Level then
      self.SkyScene:Show_One_Level( Cur_Level + Passed_Level )
    end
  end
  
  self:Update_Container_Button( true )
  
end

function SkyRunAutoPanel:Start_Auto_Process( Func_After_Started, Func_Failed )
  local function Success_Run_Auto( e )
    if Func_After_Started ~= nil then
      Func_After_Started( e )
    end
  end
  
  local function Failed_Run_Auto( e )
    if e.data == 713100 then  --User grid is full
      NewPackageFullPanel:show()
      -- CanonMessageBox:Show( getTextByKey("babel_inventoryFull"), ShowMessageType.ShowText, ShowButtonType.ID_OK, 40, nil )
    end
    if e.data == 713101 then  --User is in best floor
      CanonMessageBox:Show( getTextByKey("babel_highFloor"), ShowMessageType.ShowText, ShowButtonType.ID_OK, 40, nil )
    end
    
    if Func_Failed ~= nil then
      Func_Failed( e )
    end
  end
  
  local params = nil
  local startAutoClimbBabelRequest = StartAutoClimbBabelRequest.new(params, rpc.SendingPriority.kHigh)
  startAutoClimbBabelRequest:addEventListener(RequestNotifyEnum.StartAutoClimbBabelSucceed, Success_Run_Auto)
  startAutoClimbBabelRequest:addEventListener(RequestNotifyEnum.StartAutoClimbBabelFailed, Failed_Run_Auto)
  startAutoClimbBabelRequest:start()
  
end

function SkyRunAutoPanel:ShowFlash()
  local function onAutoClimbingFlashEnd()
    if self.refCocosObj == nil then --如果检测到场景切换了，但每帧都运行这个函数，则注销此函数
      if self.autoRunSchedule ~= nil then
        CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry( self.autoRunSchedule )
        self.autoRunSchedule = nil;
      end
      return
    end
    
    if self.Count_Time_End ~= true then
      self:Calc_Time_And_Refresh()  --计算时间并更新状态
    else
      if self.autoRunSchedule then
        CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.autoRunSchedule)
        self.autoRunSchedule = nil;
      end
    end
  end
  self.SkyFspt = FlashSprite:create("EVO2/zidongpata")
  self.SkyFspt:changeAnimation(0)
  self.SkyFspt:setLoop(true)
  --self.SkyFspt:registerEndAnimationScriptHandler(onAutoClimbingFlashEnd)--Error
  self.SkyFspt_InArea = CCClippingRegionNode:create( self.SkyFspt, 0, 517, visibleSize.width, 284 )
  self.SkyFspt_co = CocosObject.new(self.SkyFspt_InArea)
  self:addChild(self.SkyFspt_co)
  
  if not self.autoRunSchedule then
    self.autoRunSchedule = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(onAutoClimbingFlashEnd, 1 , false)   
  end
  
  
--参考（仅在一个区域中显示图像）：
--	local ccBg = CCSprite:create("login/login_bg.png")
--	ccBg:setPosition(ccp(visibleSize.width/2,visibleSize.height/2))
--	local clipBg = CCClippingRegionNode:create(ccBg,  200, 800, 300, 300)
--	self.background = CocosObject.new(clipBg)
--	self:addChild(self.background)
end

function SkyRunAutoPanel:AutoClimbEndPanel()
  SELF = self
  
	if self.autoRunSchedule then
		CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.autoRunSchedule)
		self.autoRunSchedule = nil;
	end
  if self.SkyFspt_co ~= nil then
    self.SkyFspt:unregisterEndAnimationScriptHandler()
    self:removeChild(self.SkyFspt_co) --一定要remove掉falsh动画和回调函数，不然可能在后台继续运行flash
    self.SkyFspt_co = nil
  end
  
self.BlankLayer = LayerColor:create()
self.BlankLayer:setColor(ccc3( 0, 0, 0 ))
self.BlankLayer.refCocosObj:setOpacity( 150 )
self.BlankLayer:setContentSize(CCSizeMake( visibleSize.width, visibleSize.height ))
self.BlankLayer:setPosition(ccp( 0, 0 ))
self:addChild( self.BlankLayer )

	local function onStrengthenClick(e)
		self:replaceScene(CardQueueScene:create())
	end
	
	local function onOKClick(e)
		self:removeChild( self.BlankLayer )
		self.BlankLayer = nil
		
    if self.autoRunSchedule then
      CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.autoRunSchedule)
      self.autoRunSchedule = nil;
    end
		if self.SkyFspt_co ~= nil then
		  self.SkyFspt:unregisterEndAnimationScriptHandler()
		  self:removeChild(self.SkyFspt_co) --一定要remove掉falsh动画和回调函数，不然可能在后台继续运行flash
      self.SkyFspt_co = nil
		end
		self:Change_To_SkyTowerMainScene( false )
	end
	
	RewardManager:getReward( SELF.data.rewards )
	local tosendData = self.data
	tosendData.towerFloor = SELF.data.currFloor
	BattleResultPanel:show( BattleResultType.AUTOTOWER_WIN, self.data, onOKClick, onStrengthenClick, self.SkyScene )  
end

function SkyRunAutoPanel:Change_To_SkyTowerMainScene( ignoreAction )
  local function Success_Sky_Data( e )
    if e ~= nil then
      DataManager.GetBabelInfoData = e.data
      DataManager.GetBabelInfoData._DownloadDataTime = TimeUtil.getServerTimeSeconds()
    end
    
    if self.BlankPanel ~= nil then
      self.BlankPanel:Terminate()
      self.BlankPanel = nil
    end
    
--    self:replaceScene( SkyTowerMainScene:create() )
    self.SkyScene:Refresh_Cur_Scene( true )
    self:Terminate()
  end
  
  local function Faild_Sky_Data( e )
    if self.BlankPanel ~= nil then
      self.BlankPanel:Terminate()
      self.BlankPanel = nil
    end
    
    if e.data == 713103 then
      local function OK_Click()
        self:replaceScene( MainMenuScene:create() )
      end
      
      CanonMessageBox:Show( Localization:getInstance():getText("babel_levelInsufficient", {num = MetaManager.game_meta.gameSettingConfig.babelConfig.babelTowerUnlockLevel}), ShowMessageType.ShowText, ShowButtonType.ID_OK, 40, OK_Click )
    end
  end
  
  self.ignoreAction = ignoreAction
  
  self.BlankPanel = EmailBlankPanel:Show_withContainer( self )
  
  local getBabelInfoRequest = GetBabelInfoRequest.new(params, rpc.SendingPriority.kHigh)
  getBabelInfoRequest:addEventListener(RequestNotifyEnum.GetBabelInfoSucceed, Success_Sky_Data)
  getBabelInfoRequest:addEventListener(RequestNotifyEnum.GetBabelInfoFailed, Faild_Sky_Data)
  getBabelInfoRequest:start()
end

function SkyRunAutoPanel:Update_Container_Button( Start_Or_End )
  if Start_Or_End == true then
--    print( "Hide All Buttons" )
    self.SkyScene.btn_battle:setVisible( false )
    self.SkyScene.btn_battle.isVisible = false
--    if self.SkyScene.btn_run_reset_pic ~= nil then
--      self.SkyScene.btn_run_reset_pic:setVisible( false )
--    else
--      self.SkyScene.btn_run_reset_pic_gray:setVisible( false )
--    end
--    self.SkyScene.btn_run_auto:setVisible( false )
    
--    self.SkyScene.question_pic:setVisible( false )
--    self.SkyScene.rankTitleArtText:setVisible( false )
--    self.SkyScene.Small_Rank_Window:setVisible( false )
--    self.SkyScene.small_rank_window_pic:setVisible( false )
    self.SkyScene.Person_Pic_Frame:setVisible( false )
    self.SkyScene.Person_Pic:setVisible( false )
    
    self.SkyScene.txt_cur_level:setVisible( false )
    self.SkyScene.txt_show_cur_level:setVisible( false )
    self.SkyScene.txt_cur_death_num:setVisible( false )
    self.SkyScene.txt_show_death_num:setVisible( false )
    self.SkyScene.txt_show_upper_level:setVisible( false )
    self.SkyScene.txt_show_upper_upper_level:setVisible( false )
    self.SkyScene.sky_loc_show_text_2lines_sb:setVisible( false )
    self.SkyScene.sky_show_level_line_upper:setVisible( false )
    self.SkyScene.sky_show_level_line_upper_upper:setVisible( false )
  else
    self.SkyScene.btn_battle:setVisible( true )
    self.SkyScene.btn_battle.isVisible = true
--    if self.SkyScene.btn_run_reset_pic ~= nil then
--      self.SkyScene.btn_run_reset_pic:setVisible( true )
--    else
--      self.SkyScene.btn_run_reset_pic_gray:setVisible( true )
--    end
--    self.SkyScene.btn_run_auto:setVisible( true )
    
--    self.SkyScene.question_pic:setVisible( true )
--    self.SkyScene.rankTitleArtText:setVisible( true )
--    self.SkyScene.Small_Rank_Window:setVisible( true )
--    self.SkyScene.small_rank_window_pic:setVisible( true )
    self.SkyScene.Person_Pic_Frame:setVisible( true )
    self.SkyScene.Person_Pic:setVisible( true )
    
    self.SkyScene.txt_cur_level:setVisible( true )
    self.SkyScene.txt_show_cur_level:setVisible( true )
    self.SkyScene.txt_cur_death_num:setVisible( true )
    self.SkyScene.txt_show_death_num:setVisible( true )
    self.SkyScene.txt_show_upper_level:setVisible( true )
    self.SkyScene.txt_show_upper_upper_level:setVisible( true )
    self.SkyScene.sky_loc_show_text_2lines_sb:setVisible( true )
    self.SkyScene.sky_show_level_line_upper:setVisible( true )
    self.SkyScene.sky_show_level_line_upper_upper:setVisible( true )
  end
end

function SkyRunAutoPanel:Terminate()
	if self.autoRunSchedule then
		CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.autoRunSchedule)
		self.autoRunSchedule = nil;
	end
  if self.SkyFspt_co ~= nil then
    self.SkyFspt:unregisterEndAnimationScriptHandler()
    self:removeChild(self.SkyFspt_co) --一定要remove掉falsh动画和回调函数，不然可能在后台继续运行flash
    self.SkyFspt_co = nil
  end
  
  if self.BlankPanel ~= nil then
    self.BlankPanel:Terminate()
    self.BlankPanel = nil
  end
  
  self:Update_Container_Button( false )
  
  if self.Finished_CallBack_Func ~= nil then
    self.Finished_CallBack_Func()
  end
  
  self.container:removeChild( self )
  self = nil
end











