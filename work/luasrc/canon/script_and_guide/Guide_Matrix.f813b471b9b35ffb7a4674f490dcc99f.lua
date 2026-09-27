return function()

require "canon.script_and_guide.NewUserGuide"

Set_ShareData( "New_User_Guide_Running", 1);
Run_New_User_Guide( 0, 0, 720, 1280, getTextByKey("guide_matrix_txt1"), false ,100,400) -- 上阵后的武将，可以为出战武将提供属性。升级阵法可以上阵更多武将哦

Set_ShareData( "Guide_Save_State", 0 );
Set_ShareData( "New_User_Guide_Running", 0);

end
