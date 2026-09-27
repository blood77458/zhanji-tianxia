return function()

require "canon.script_and_guide.NewUserGuide"
require "canon.manager.DcManager"




Set_ShareData( "New_User_Guide_Running", 1);



--4继续闯关，直到第5步
Show_StepNumber_For_Once( 5 );
Run_New_User_Guide( 240, 1155, 120, 120, getTextByKey("guide_enterGame4_txt1"), true ,100,600 ) -- 好了，接下来就让新武将给我们露两手！
DcManager.sendTutorialStepActivity(80)
Wait_For_ShareData( "EnterAnimationFinished", 1 );
Run_New_User_Guide( 502, 791, 157, 59, "", true ,100,200 )
DcManager.sendTutorialStepActivity(82)
Set_ShareData( "Cloud_Finished", 0);
Wait_For_ShareData( "Cloud_Finished", 1, 5000 );
if Get_ShareData("Walk_Step") == 2 then
  Set_ShareData( "Walk_Finished", 0 );
  Run_New_User_Guide( 200, 1034, 318, 100, getTextByKey("guide_enterGame4_txt2"), false ,100,400);   --走到第第一关，第三步 -- 点击前进继续闯关！
  Wait_For_ShareData( "Walk_Finished", 1 );
  DcManager.sendTutorialStepActivity(85)
else
  print( "!!!", Get_ShareData("Walk_Step"), " need to be 2" )
end
if Get_ShareData("Walk_Step") == 3 then
  Set_ShareData( "Walk_Finished", 0 );
  Run_New_User_Guide( 200, 1034, 318, 100, getTextByKey("guide_enterGame4_txt3"), false ,100,400);  --走到第第一关，第四步 -- 前方发现敌方小队，我们走近打探一下。
  Wait_For_ShareData( "Walk_Finished", 1 );
  DcManager.sendTutorialStepActivity(90)
else
  print( "!!!", Get_ShareData("Walk_Step"), " need to be 3" )
end
Set_ShareData( "Cloud_Finished", 0);
if Get_ShareData("Walk_Step") == 4 then
  Set_ShareData( "Run_BattleScene", 0 );
  Set_ShareData( "ShowBattleResults", 0 );
  Set_ShareData( "Battle_Result_Finished", 0 );
  Run_New_User_Guide( 200, 1034, 318, 100, getTextByKey("guide_enterGame4_txt4"), false ,100,400 );  --走到第第一关，第五步开战 -- 让我们乘胜追击！
    Set_ShareData( "Guide_Save_State", 0 );
  Wait_For_ShareData( "Run_BattleScene", 1 );
  Wait_For_ShareData( "ShowBattleResults", 1 );
  Run_New_User_Guide( 395, 1060, 252, 80, "", true ,100,380);
  DcManager.sendTutorialStepActivity(95)
  Wait_For_ShareData( "Battle_Result_Finished", 1 );
  DcManager.sendTutorialStepActivity(100)
else
  print( "!!!", Get_ShareData("Walk_Step"), " need to be 4" )
end
Wait_For_ShareData( "Cloud_Finished", 1, 5000 );
Wait_For_ShareData("Dialog_Running", 0) --等待对话完成
Run_New_User_Guide( 0, 160, 68, 60, "", true, 100, 400 )
DcManager.sendTutorialStepActivity(105)

Set_ShareData( "Guide_Save_State", 0 );
Set_ShareData( "New_User_Guide_Running", 0);

end
