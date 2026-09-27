return function()

require "canon.script_and_guide.NewUserGuide"

--仅显示消息框的示例：

Set_ShareData( "New_User_Guide_Running", 1);
Run_New_User_Guide( -99999, -99999, 0, 0, "AAA", false ,100,300);
Run_New_User_Guide( -99999, -99999, 0, 0, "BBB", false ,100,500);
Run_New_User_Guide( -99999, -99999, 0, 0, "CCC", false ,100,200);

Set_ShareData( "Guide_Save_State", 0 );
Set_ShareData( "New_User_Guide_Running", 0);

end
