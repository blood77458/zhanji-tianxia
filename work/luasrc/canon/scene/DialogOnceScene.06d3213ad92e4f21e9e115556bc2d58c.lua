require "hecore.display.CocosObject"
require "hecore.display.Director"
require "hecore.display.Scene"
require "hecore.ui.LayoutBuilder"
require "canon.script_and_guide.Script_And_Dialog"
require "canon.request.GetGachaBroadcastRequest"
require "canon.scene.BattleScene"
require "canon.scene.MainMenuScene"
require "canon.manager.DcManager"

DialogOnceScene = class(Scene)
local visibleSize = CCDirector:sharedDirector():getVisibleSize()

function DialogOnceScene:ctor()

end

function DialogOnceScene:create( Show_Type )
  self.Show_Type = Show_Type
  
  if isUCAndroid() then
	 --uc need pass user extend info
	submitExtendDataToUC("loginGameRole")
  elseif isOppoAndroid() then
	--oppo need pass user extend info just when create character
	submitExtendDataToOppo()
  end
		  
  local s = DialogOnceScene.new()
  s:initScene()
  return s
end

function DialogOnceScene:onInit()
	local function Judge_In_Each_Frame()
		if Director:sharedDirector():getRunningScene() == self then
			CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry( self.JudgeInEachFrameSchedule )

			if self.Show_Type == 1 then
				CanonPlayBackgroundMusic("music/background.mp3", true)
				local function OnOneGuideFinished()
					if Get_ShareData( "DialogOnceScene_Script_Running" ) == 0 then
						RegisterOnGuideFinishCallback(nil)
						local function After_BattleAnimation_Finished()
							local scene = DialogOnceScene:create( 2 )
							Director:sharedDirector():replaceScene( scene )
						end
						DcManager.sendTutorialStepActivity(2)
						local scene = BattleScene:create( readBattleInfo(), BattleBackType.kFakeBattle, BattleEnterEnum.kFakeBattle, nil, nil, nil, After_BattleAnimation_Finished )
						Director:sharedDirector():replaceScene( scene )
					end
				end
				Set_ShareData( "DialogOnceScene_Script_Running", 1 );
				RegisterOnGuideFinishCallback(OnOneGuideFinished)
				Run_Script_In_File( "canon/script_and_guide/DialogOnceScene_Script_1.lua" )
			elseif self.Show_Type == 2 then
				local function OnOneGuideFinished()
					if Get_ShareData( "DialogOnceScene_Script_Running" ) == 0 then
						RegisterOnGuideFinishCallback(nil)
						local scene = MainMenuScene:create()
						Director:sharedDirector():replaceScene( scene )
					end
				end
				DcManager.sendTutorialStepActivity(3)
				Set_ShareData( "DialogOnceScene_Script_Running", 1 );
				RegisterOnGuideFinishCallback(OnOneGuideFinished)
				Run_Script_In_File( "canon/script_and_guide/DialogOnceScene_Script_2.lua" )   
			end
		end
	end
	self.JudgeInEachFrameSchedule = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc( Judge_In_Each_Frame, 0, false ) 

  local request = GetGachaBroadcastRequest.new( {}, rpc.SendingPriority.kHigh )
  request:addEventListener( RequestNotifyEnum.GetGachaBroadcastSucceed, On_GachaBroadcast_Succeed )
  request:start()
  
end

function DialogOnceScene:dispose()
  DialogOnceScene.super.dispose(self)
end








