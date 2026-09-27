return function()

require "canon.script_and_guide.NewUserGuide"
require "canon.manager.DcManager"


Set_ShareData( "New_User_Guide_Running", 1);



--8继续闯关
Show_StepNumber_For_Once( 1 );
Run_New_User_Guide( 240, 1155, 120, 120, getTextByKey("guide_enterGame8_txt1"), true ,100, 600 ) -- 转生完成，让我们看看转生后的武将有多厉害。
DcManager.sendTutorialStepActivity(230)
Wait_For_ShareData( "EnterAnimationFinished", 1 );
Run_New_User_Guide( 502, 916, 157, 59, "", true ,100,200 )
Set_ShareData( "Cloud_Finished", 0);
Set_ShareData( "Walk_Finished", 0 );
DcManager.sendTutorialStepActivity(232)
  Run_New_User_Guide( 0,0, 720,1280, getTextByKey("guide_enterGame8_txt2"), false ,100,400); -- 接下来我们必须不断前进，才能获得更多武将。
  Run_New_User_Guide( 0,0, 720,1280, getTextByKey("guide_enterGame8_txt3"), false ,100,400); -- 如果还有什么疑问，可以在设置界面中找到帮助哦。
DcManager.sendTutorialFinishActivity()
--if Get_ShareData("Walk_Step") == 7 then
  --Set_ShareData( "Walk_Finished", 0 );
  --Run_New_User_Guide( 197, 1034, 322, 92, "曹熊就在前面，跑的真快", false ,100,400);   --走到第第一关，第八步
  --Wait_For_ShareData( "Walk_Finished", 1 );
  --DcManager.sendTutorialStepActivity(235)
--end
--if Get_ShareData("Walk_Step") == 8 then
  --Set_ShareData( "Walk_Finished", 0 );
  --Run_New_User_Guide( 197, 1034, 322, 92, "主公，下令全军加速前进！", false ,100,400);   --走到第第一关，第九步
  --Wait_For_ShareData( "Walk_Finished", 1 );
  --DcManager.sendTutorialStepActivity(240)
--end
--if Get_ShareData("Walk_Step") == 9 then
  --Set_ShareData( "ShowBattleResults", 0 );
  --Run_New_User_Guide( 197, 1034, 322, 92, "她跑不掉了！", false ,100,400);   --走到第第一关，第十步，开战
    --Set_ShareData( "Guide_Save_State", 0 );
  --Wait_For_ShareData( "ShowBattleResults", 1 );
	--DcManager.sendTutorialStepActivity(245)
  --Run_New_User_Guide( 232, 1059, 252, 78, "完胜曹熊！点击确认继续", true ,100,580);
  --DcManager.sendTutorialStepActivity(250)
--end
--Run_New_User_Guide( 31, 1178, 94, 94, "点击首页按钮", true ,30,600 );



Set_ShareData( "Guide_Save_State", 0 );
Set_ShareData( "New_User_Guide_Running", 0);

end
