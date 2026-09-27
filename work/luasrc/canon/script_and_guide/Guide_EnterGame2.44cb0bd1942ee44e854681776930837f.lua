return function()

require "canon.script_and_guide.NewUserGuide"
require "canon.manager.DcManager"




Set_ShareData( "New_User_Guide_Running", 1);



--2招募武将
Show_StepNumber_For_Once( 7 );
Run_New_User_Guide( 366, 156, 107, 107, getTextByKey("guide_enterGame2_txt1"), true , 100, 500 ) -- 是时候去招募一个武将了！求将是最快的方法。
Wait_For_ShareData( "EnterAnimationFinished", 1 );
DcManager.sendTutorialStepActivity(30)

local HighGacha_Whether_Can_Free = Get_ShareData( "HighGacha_Whether_Can_Free" )

if HighGacha_Whether_Can_Free == 1  then
  Set_ShareData( "Gacha_One_Finished", 0 );
  Set_ShareData( "GachaBroadcast_Request_Running", 1 );
  Run_New_User_Guide( 54, 611, 255, 80, getTextByKey("guide_enterGame2_txt2"), false ,50,700 )  -- 至尊求将可以找到最强大的武将，我们开始吧。
  Dialog_SetScreenTouchEnabled(false)
  Wait_For_ShareData( "Gacha_One_Finished", 1 );
  Dialog_SetScreenTouchEnabled(true)
  DcManager.sendTutorialStepActivity(35)
    Set_ShareData( "Guide_Save_State", 0 );
  --Wait_For_ShareData( "GachaBroadcast_Request_Running", 0 );
    Run_New_User_Guide( 91, 997, 250, 75, getTextByKey("guide_enterGame2_txt3"), false ,100,790); -- 星越多的武将越厉害！能得到四星武将辅佐真是好运！
  DcManager.sendTutorialStepActivity(40)
else
  Set_ShareData( "Guide_Save_State", 0 );
  DcManager.sendTutorialStepActivity(40)
end



Set_ShareData( "Guide_Save_State", 0 );
Set_ShareData( "New_User_Guide_Running", 0);

end
