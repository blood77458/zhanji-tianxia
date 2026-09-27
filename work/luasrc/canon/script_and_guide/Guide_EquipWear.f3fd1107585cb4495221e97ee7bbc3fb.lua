return function()

require "canon.script_and_guide.NewUserGuide"

Set_ShareData( "New_User_Guide_Running", 1);
Run_New_User_Guide( 145, 1177, 94, 94, "工欲善其事，必先利其器。给武将配一把趁手的武器吧！", true ,100,700);
Run_New_User_Guide( 526, 621, 104, 104, "右边的空格可以装备武器和盔甲等", true ,100,120);
Run_New_User_Guide( 14, 332, 688, 162, "选择一件武器", true ,120,500);
Run_New_User_Guide( 252, 1172, 100, 108, "武器好了！我们再去杀几个来回吧！", true ,100,700);

Set_ShareData( "Guide_Save_State", 0 );
Set_ShareData( "New_User_Guide_Running", 0);

end
