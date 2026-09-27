return function()

require "canon.script_and_guide.NewUserGuide"

Wait_For_ShareData("Dialog_Running", 0) --等待对话完成
Set_ShareData( "New_User_Guide_Running", 1);
Run_New_User_Guide( 0,0, 720,1280, getTextByKey("guide_cardOn_txt1"), false ,100,400); -- 我们又可以上阵新的武将了。
Run_New_User_Guide( 115, 1155, 120, 120, getTextByKey("guide_cardOn_txt2"), true ,100,700); -- 点击队伍按钮。
Run_New_User_Guide( 377, 345, 130, 130, getTextByKey("guide_cardOn_txt3"), false ,100,500); -- 点击这个加号让武将出战。

Set_ShareData( "Guide_Save_State", 0 );
Set_ShareData( "New_User_Guide_Running", 0);

end
