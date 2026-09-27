require "hecore.display.CocosObject"
require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "canon.scene.BaseUIScene"
require "canon.request.StartAutoClimbBabelRequest"
require "canon.request.GainAutoClimbRewardRequest"
require "canon.data.MetaManager"
require "canon.data.DataManager"
require "canon.models.RewardManager"
require "hecore.ui.Button"
require "hecore.display.Layer"
require "canon.panel.BattleResultPanel"
require "canon.scene.CardQueueScene"
require "canon.utils.TimeUtil"

SkyRunAutoScene = class(BaseUIScene)
local visibleSize = CCDirector:sharedDirector():getVisibleSize();

function SkyRunAutoScene:ctor()
  self.title = getTextByKey("babel_title")
end

function SkyRunAutoScene:create()
  local s = SkyRunAutoScene.new()
  s:initScene()
  return s
end

----------------------------------------
-- 获取服务器当前时间
----------------------------------------
-- 说明：只有在用Request通信后才有效
--   若Request通信后，用户手动改了手机时间
--   则需要再次Request通信更新时间信息
----------------------------------------
function SkyRunAutoScene:get_Sever_Time()
  local Client_Time = os.time() --客户端时间
  local Diff_T = _G.__g_utcDiffSeconds --时间差：服务器时间 - 客户端时间
  local Sever_Time = Diff_T + Client_Time --服务器时间
--  print(os.date("%c", Sever_Time)) --显示时间
  return Sever_Time
end

function SkyRunAutoScene:onInit()
  BaseUIScene.initBackGround(self)
  self:addChild(self.mainUI)
self.BackLayer = LayerColor:create()
self.BackLayer:setColor(ccc3( 0, 0, 0 ))
self.BackLayer.refCocosObj:setOpacity( 170 )
self.BackLayer:setContentSize(CCSizeMake( visibleSize.width, visibleSize.height ))
self.BackLayer:setPosition(ccp( 0, 0 ))
self:addChild( self.BackLayer )
self:ShowFlash()
	BaseUIScene.onInit(self) 
  
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
        if self.SkyFspt_co ~= nil then
          self.SkyFspt:unregisterEndAnimationScriptHandler()
          self:removeChild(self.SkyFspt_co) --一定要remove掉falsh动画和回调函数，不然可能在后台继续运行flash
        end
        self:Change_To_SkyTowerMainScene( false )
      end
      
	  if not self.data or not self.data.rewards then
		OK_Click()
	  else 
		self:AutoClimbEndPanel( "成功！" )
	  end
	  
      

    end
    
    local function Failed_Auto_Stop( e )
      self.data = nil
      
      if self.BlankPanel ~= nil then
        self.BlankPanel:Terminate()
        self.BlankPanel = nil
      end
      
      local function OK_Click()
        if self.SkyFspt_co ~= nil then
          self.SkyFspt:unregisterEndAnimationScriptHandler()
          self:removeChild(self.SkyFspt_co) --一定要remove掉falsh动画和回调函数，不然可能在后台继续运行flash
        end
        self:Change_To_SkyTowerMainScene( false )
      end
      
      if e.data == 713108 then
        CanonMessageBox:Show( "错误，当前没自动爬塔", ShowMessageType.ShowText, ShowButtonType.ID_OK, 40, OK_Click )
      else
        CanonMessageBox:Show( "错误！", ShowMessageType.ShowText, ShowButtonType.ID_OK, 40, OK_Click )
      end
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
      
      local function OK_Click()
        if self.SkyFspt_co ~= nil then
          self.SkyFspt:unregisterEndAnimationScriptHandler()
          self:removeChild(self.SkyFspt_co) --一定要remove掉falsh动画和回调函数，不然可能在后台继续运行flash
        end
        self:Change_To_SkyTowerMainScene( false )
      end
      
      self:AutoClimbEndPanel( "成功！" )
      
--      CanonMessageBox:Show( "成功！", ShowMessageType.ShowText, ShowButtonType.ID_OK, 40, OK_Click )
    end
    
    local function Failed_Auto_Accelerate( e )
      self.data = nil
      
      if self.BlankPanel ~= nil then
        self.BlankPanel:Terminate()
        self.BlankPanel = nil
      end
      
      local function OK_Click()
        if self.SkyFspt_co ~= nil then
          self.SkyFspt:unregisterEndAnimationScriptHandler()
          self:removeChild(self.SkyFspt_co) --一定要remove掉falsh动画和回调函数，不然可能在后台继续运行flash
        end
        self:Change_To_SkyTowerMainScene( false )
      end
      
      if e.data == 713108 then
        CanonMessageBox:Show( "错误，当前没自动爬塔", ShowMessageType.ShowText, ShowButtonType.ID_OK, 40, OK_Click )
      else
        CanonMessageBox:Show( "错误！", ShowMessageType.ShowText, ShowButtonType.ID_OK, 40, OK_Click )
      end
    end
    
    local Vip_Level = 0
      local InitData = DataManager.getGameInitData()
      if InitData ~= nil and InitData["sharkUser"] ~= nil then
        Vip_Level = InitData["sharkUser"].vipLevel
      end
      
    if Vip_Level > 0 then
      self.BlankPanel = EmailBlankPanel:Show_withContainer( self )
      
      local Params_GainAutoClimbReward = { speedUp = true }
      local gainAutoClimbRewardRequest = GainAutoClimbRewardRequest.new(Params_GainAutoClimbReward, rpc.SendingPriority.kHigh)
      gainAutoClimbRewardRequest:addEventListener(RequestNotifyEnum.GainAutoClimbRewardSucceed, Success_Auto_Accelerate)
      gainAutoClimbRewardRequest:addEventListener(RequestNotifyEnum.GainAutoClimbRewardFailed, Failed_Auto_Accelerate)
      gainAutoClimbRewardRequest:start()
    else
      CanonMessageBox:Show( "只有VIP玩家才能加速", ShowMessageType.ShowText, ShowButtonType.ID_OK, 40, OK_Click )
    end
    
  end
  
  self.UIBuilder = LayoutBuilder:createWithContentsOfFile("scene/sky_tongtianta.json")
  
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

function SkyRunAutoScene:Calc_Time_And_Refresh()
  if self.Refresh_BabelInfo_Already ~= true then
    return
  end
  if self.Finish_AutoClimb_Already == true then
    return
  end
  if self.Finishing_AutoClimb == true then
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
      
        local function OK_Click()
          if self.SkyFspt_co ~= nil then
            self.SkyFspt:unregisterEndAnimationScriptHandler()
            self:removeChild(self.SkyFspt_co) --一定要remove掉falsh动画和回调函数，不然可能在后台继续运行flash
          end
          self:Change_To_SkyTowerMainScene( false )
        end
        self:AutoClimbEndPanel( "成功！" )
--        CanonMessageBox:Show( "自动爬塔结束，恭喜您获得了奖励！", ShowMessageType.ShowText, ShowButtonType.ID_OK, 40, OK_Click )
      end
      
      local function Finish_Error( e )
        self.data = nil
        
        if self.BlankPanel ~= nil then
          self.BlankPanel:Terminate()
          self.BlankPanel = nil
        end
        
        CanonMessageBox:Show( "错误！", ShowMessageType.ShowText, ShowButtonType.ID_OK, 40, nil )
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
  
end

function SkyRunAutoScene:Start_Auto_Process( Func_After_Started, Func_Failed )
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

function SkyRunAutoScene:ShowFlash()
  local function onAutoClimbingFlashEnd()
    if self.Count_Time_End ~= true then
      self:Calc_Time_And_Refresh()  --计算时间并更新状态
    end
  end
  self.SkyFspt = FlashSprite:create("EVO2/zidongpata")
  self.SkyFspt:changeAnimation(0)
  self.SkyFspt:setLoop(true)
  self.SkyFspt:registerEndAnimationScriptHandler(onAutoClimbingFlashEnd)
  self.SkyFspt_InArea = CCClippingRegionNode:create( self.SkyFspt, 0, 517, visibleSize.width, 284 )
  self.SkyFspt_co = CocosObject.new(self.SkyFspt_InArea)
  self:addChild(self.SkyFspt_co)
  
  
--参考（仅在一个区域中显示图像）：
--	local ccBg = CCSprite:create("login/login_bg.png")
--	ccBg:setPosition(ccp(visibleSize.width/2,visibleSize.height/2))
--	local clipBg = CCClippingRegionNode:create(ccBg,  200, 800, 300, 300)
--	self.background = CocosObject.new(clipBg)
--	self:addChild(self.background)
end

function SkyRunAutoScene:AutoClimbEndPanel() --( resultStr )
  SELF = self
  
  if self.SkyFspt_co ~= nil then
    self.SkyFspt:unregisterEndAnimationScriptHandler()
    self:removeChild(self.SkyFspt_co) --一定要remove掉falsh动画和回调函数，不然可能在后台继续运行flash
  end
  
self.BlankLayer = LayerColor:create()
self.BlankLayer:setColor(ccc3( 0, 0, 0 ))
self.BlankLayer.refCocosObj:setOpacity( 150 )
self.BlankLayer:setContentSize(CCSizeMake( visibleSize.width, visibleSize.height ))
self.BlankLayer:setPosition(ccp( 0, 0 ))
self:addChild( self.BlankLayer )
  
--	local panelBg = CCSprite:create("battle/pic/battlePanel.png")
--	panelBg:setPosition(ccp( visibleSize.width / 2, visibleSize.height / 2) )
--	SELF:addChild(CocosObject.new(panelBg))

	local function onStrengthenClick(e)
		self:replaceScene(CardQueueScene:create())
	end
	
	local function onOKClick(e)
		self:removeChild( self.BlankLayer )
		self.BlankLayer = nil
		
		self.targetInfoPanel = self.pre_targetInfoPanel
		
		if self.SkyFspt_co ~= nil then
		  self.SkyFspt:unregisterEndAnimationScriptHandler()
		  self:removeChild(self.SkyFspt_co) --一定要remove掉falsh动画和回调函数，不然可能在后台继续运行flash
		end
		self:Change_To_SkyTowerMainScene( false )
	end
	
	RewardManager:getReward( SELF.data.rewards )
	local tosendData = self.data
	tosendData.towerFloor = SELF.data.currFloor
	BattleResultPanel:show(BattleResultType.AUTOTOWER_WIN, self.data, onOKClick, onStrengthenClick, self)  
end

function SkyRunAutoScene:Change_To_SkyTowerMainScene( ignoreAction )
  local function Success_Sky_Data( e )
    if e ~= nil then
      DataManager.GetBabelInfoData = e.data
      DataManager.GetBabelInfoData._DownloadDataTime = TimeUtil.getServerTimeSeconds()
    end
    
    if self.BlankPanel ~= nil then
      self.BlankPanel:Terminate()
      self.BlankPanel = nil
    end
    
    self:replaceScene( SkyTowerMainScene:create() )
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

function SkyRunAutoScene:back()
--  print("SkyRunAutoScene:back")

  if self.SkyFspt_co ~= nil then
    self.SkyFspt:unregisterEndAnimationScriptHandler()
    self:removeChild(self.SkyFspt_co) --一定要remove掉falsh动画和回调函数，不然可能在后台继续运行flash
  end
    
  self:replaceScene( MainMenuScene )
end


function SkyRunAutoScene:doEnterAnimation()
  self:preEnterAnimation()
  self:startEnterAnimation()
end

function SkyRunAutoScene:preEnterAnimation()
  BaseUIScene.preEnterAnimation(self)
end

function SkyRunAutoScene:startEnterAnimation()
  BaseUIScene.startEnterAnimation(self)
end

function SkyRunAutoScene:sufEnterAnimation()
  BaseUIScene.sufEnterAnimation(self)
end

function SkyRunAutoScene:doExitAnimation()
  self:preExitAnimation()
  self:startExitAnimation() 
end

function SkyRunAutoScene:preExitAnimation()
  BaseUIScene.preExitAnimation(self)
end

function SkyRunAutoScene:startExitAnimation()
  BaseUIScene.startExitAnimation(self)
end

function SkyRunAutoScene:sufExitAnimation()
  BaseUIScene.sufExitAnimation(self)
end








