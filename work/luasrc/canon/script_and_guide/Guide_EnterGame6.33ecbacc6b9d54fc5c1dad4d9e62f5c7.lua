return function()

require "canon.script_and_guide.NewUserGuide"
require "canon.manager.DcManager"


Set_ShareData( "New_User_Guide_Running", 1);




--6继续闯关，直到第7步
Show_StepNumber_For_Once( 3 );
Run_New_User_Guide( 240, 1155, 120, 120, getTextByKey("guide_enterGame6_txt1"), true ,100,600 ) -- 我们回到闯关，看看武将强化后的效果吧。
DcManager.sendTutorialStepActivity(160)
Wait_For_ShareData( "EnterAnimationFinished", 1 );
Run_New_User_Guide( 502, 916, 157, 59, "", true ,100,200 )
Set_ShareData( "Cloud_Finished", 0);
Wait_For_ShareData( "Cloud_Finished", 1, 5000 );
DcManager.sendTutorialStepActivity(162)
if Get_ShareData("Walk_Step") == 5 then
  Set_ShareData( "Walk_Finished", 0 );
  Run_New_User_Guide( 200, 1034, 318, 100, getTextByKey("guide_enterGame6_txt2"), false ,100,400);   --走到第第一关，第六步 -- 夏侯渊正在逃跑，快点追上她。
  Wait_For_ShareData( "Walk_Finished", 1 );
  DcManager.sendTutorialStepActivity(165)
end
Set_ShareData( "Cloud_Finished", 0);
if Get_ShareData("Walk_Step") == 6 then
  Set_ShareData( "ShowBattleResults", 0 );
  Set_ShareData( "Battle_Result_Finished", 0 );
  Run_New_User_Guide( 200, 1034, 318, 100, getTextByKey("guide_enterGame6_txt3"), false ,100,400);  --走到第第一关，第七步，开战 -- 看到她的的逃兵了，快点！
    Set_ShareData( "Guide_Save_State", 0 );
  Wait_For_ShareData( "ShowBattleResults", 1 );
	DcManager.sendTutorialStepActivity(170)
--  Run_New_User_Guide( 234, 1062, 252, 73, "", true ,100,580);
  Wait_For_ShareData( "Battle_Result_Finished", 1 );
  DcManager.sendTutorialStepActivity(175)
end
Wait_For_ShareData( "Cloud_Finished", 1, 5000 );
Run_New_User_Guide( 0, 160, 68, 60, "", true, 100, 400 )
DcManager.sendTutorialStepActivity(180)


Set_ShareData( "Guide_Save_State", 0 );
Set_ShareData( "New_User_Guide_Running", 0);

end
