return function()

require "canon.script_and_guide.NewUserGuide"

Set_ShareData( "New_User_Guide_Running", 1);
Run_New_User_Guide( 0, 0, 720, 1280, getTextByKey("guide_cardFate_txt1"), false ,100,400) -- 利用缘分互通，可以获得更强的战力哦~
Run_New_User_Guide( 542, 340, 135, 135, getTextByKey("guide_cardFate_txt2"), true ,50,550 ) -- 进入缘分互通。

Set_ShareData( "Guide_Save_State", 0 );
Set_ShareData( "New_User_Guide_Running", 0);

end