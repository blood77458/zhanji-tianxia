return function()

require "canon.script_and_guide.NewUserGuide"
require "canon.manager.DcManager"




Set_ShareData( "New_User_Guide_Running", 1);



--1开始闯关
Show_StepNumber_For_Once( 8 );
Set_ShareData( "Cloud_Finished", 0);
Run_New_User_Guide( 0,0, 720,1280, getTextByKey("guide_enterGame1_txt1"), false  ,100 ,400 ) -- 好消息，完成引导可以获得名将魏延，我们马上开始吧
Run_New_User_Guide( 242, 1155, 120, 120, getTextByKey("guide_enterGame1_txt2"), true ,100,600 ) -- 跟着我来，我会告诉你该怎么做。先点击闯关。
-- 15号点测试
print("sendTutorialStepActivity")
DcManager.sendTutorialStepActivity(5)
Wait_For_ShareData( "EnterAnimationFinished", 1 );
Run_New_User_Guide( 502, 791, 157, 59, "", true ,100,200 )
Wait_For_ShareData( "Cloud_Finished", 1, 5000 );
DcManager.sendTutorialStepActivity(7)
print("Walk_Step " .. Get_ShareData("Walk_Step"))
if Get_ShareData("Walk_Step") == 0 then
  Set_ShareData( "Walk_Finished", 0 );
  Run_New_User_Guide( 200, 1034, 318, 100, getTextByKey("guide_enterGame1_txt3"), false ,100,400); --走到第第一关，第一步 -- 点击前进按钮开始闯关！
  Wait_For_ShareData( "Walk_Finished", 1 );
  DcManager.sendTutorialStepActivity(10)
else
  print( "!!!", Get_ShareData("Walk_Step"), " need to be 0" )
end
--Run_New_User_Guide( 0,0, 720,1280, "做的非常棒！", false  ,100 ,400 )
Set_ShareData( "Cloud_Finished", 0);
if Get_ShareData("Walk_Step") == 1 then
  Set_ShareData( "ShowBattleResults", 0 );
  Set_ShareData( "Battle_Result_Finished", 0 );
  Run_New_User_Guide( 200, 1034, 318, 100, getTextByKey("guide_enterGame1_txt4"), false ,100,400 ) --走到第第一关，第二步，开战 -- 做的非常棒！发现敌方哨兵，点击前进打倒她吧。
    Set_ShareData( "Guide_Save_State", 0 );
  Wait_For_ShareData( "ShowBattleResults", 1 );
  DcManager.sendTutorialStepActivity(15)
--  Run_New_User_Guide( 234, 1062, 252, 73, "", true ,100,580);
  Wait_For_ShareData( "Battle_Result_Finished", 1 );
  DcManager.sendTutorialStepActivity(20)
else
  print( "!!!", Get_ShareData("Walk_Step"), " need to be 1" )
end
Wait_For_ShareData( "Cloud_Finished", 1, 5000 );
Run_New_User_Guide( 0, 160, 68, 60, getTextByKey("guide_enterGame1_txt5"), true, 100, 400 ) -- 点击返回按钮。
DcManager.sendTutorialStepActivity(25)


Set_ShareData( "Guide_Save_State", 0 );
Set_ShareData( "New_User_Guide_Running", 0);

end
