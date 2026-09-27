return function()

require "canon.script_and_guide.NewUserGuide"

Set_ShareData( "New_User_Guide_Running", 1);
Run_New_User_Guide( 18, 364, 678, 176, getTextByKey("guide_elite_txt1"), false ,150,550); -- 通过过关斩将，可以获得各种神兵利器。

Set_ShareData( "Guide_Save_State", 0 );
Set_ShareData( "New_User_Guide_Running", 0);

end
