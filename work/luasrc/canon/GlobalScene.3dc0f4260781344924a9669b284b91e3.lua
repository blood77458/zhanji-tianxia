

require "canon.request.RecordTutorialStepRequest"
require "canon.script_and_guide.NewUserGuide"
require "canon.canonUtils"


local GlobalScene = class(Scene)



function GlobalScene:ctor()
	
end

function GlobalScene:create()
  local s = GlobalScene.new()
  s:initScene()
  return s
end

function GlobalScene_globalUpdate(dt) --全局函数，其它文件需要调用
    if Is_New_User_Guide_Terminated() then
      g_curGuide = nil --如果终止了新手引导，则不保存后面的进度，等待重新开始
      g_waittingForUploadGuideFlag = false
      Set_ShareData( "Guide_Save_State", -99999 )
      if (_G.Guide_JudgeInEachFrameSchedule==nil) and (Get_ShareData("New_User_Guide_Running")~=1) then
        Set_ShareData( "Terminate_This_NewUserGuide", -99999 ); --如果没运行新手引导了，就将状态恢复
      end
    end
		if g_waittingForUploadGuideFlag and g_curGuide then
			--print( "reset new user guide tutorial: " .. g_curGuide )
			--print("New_User_Guide_Running:" .. tonumber(Get_ShareData( "New_User_Guide_Running")) )
			if tonumber(Get_ShareData( "Guide_Save_State")) == 0 then
				local info = { funcName = g_curGuide }
				if not tutorialStepIndex then
					  tutorialStepIndex = 1
				end
				local data = DataManager.getGameInitData()
				tutorialStepIndex = tutorialStepIndex + 1
				data.sharkUserExtend.tutorialSteps["guide" .. tutorialStepIndex] = info
				DataManager.setGameInitData(data)
				local params = {funcName = g_curGuide, step = 1}
				local request = RecordTutorialStepRequest.new( params, rpc.SendingPriority.kHigh )
				request:start()
				--print( "******************* reset new user guide tutorial: " .. g_curGuide )
				g_curGuide = nil
				g_waittingForUploadGuideFlag = false
        Set_ShareData( "Guide_Save_State", -99999 )
			end
		end
end

function GlobalScene:onInit()
	CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(GlobalScene_globalUpdate,0,false);
end

g_globalScene = GlobalScene:create()
g_globalScene:retain()


