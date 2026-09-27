return function()

require "canon.script_and_guide.NewUserGuide"

Wait_For_ShareData( "EnterAnimationFinished", 1 );
Set_ShareData( "New_User_Guide_Running", 1);

Run_New_User_Guide( 232, 576, 270, 380, getTextByKey("guide_enterGame5_txt3"), false, 100, 700 ) -- 点击此处打开武将详情。
Run_New_User_Guide( 306, 550, 115, 53, getTextByKey("guide_cardTraining_txt1"), false ,100,500 ) -- 选择培养。

Set_ShareData( "Guide_Save_State", 0 );
Set_ShareData( "New_User_Guide_Running", 0);

end