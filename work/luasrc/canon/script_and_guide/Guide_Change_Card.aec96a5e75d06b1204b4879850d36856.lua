return function()

require "canon.script_and_guide.NewUserGuide"

Set_ShareData( "New_User_Guide_Running", 1);
Run_New_User_Guide( 221, 591, 271, 381, getTextByKey("guide_changeCard_txt1"), false ,150,100); -- 点击武将可以对武将进行更换，培养，强化，进阶操作

Set_ShareData( "Guide_Save_State", 0 );
Set_ShareData( "New_User_Guide_Running", 0);

end
