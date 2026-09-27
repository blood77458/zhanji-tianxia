return function()

require "canon.script_and_guide.NewUserGuide"

Set_ShareData( "New_User_Guide_Running", 1);
Run_New_User_Guide( 252, 1172, 100, 108, getTextByKey("guide_battle_txt1"), true ); -- 请点击闯关开始冒险！
Run_New_User_Guide( 208, 1050, 310, 84, getTextByKey("guide_battle_txt2"), false ); -- 点击前进按钮前进！

Set_ShareData( "Guide_Save_State", 0 );
Set_ShareData( "New_User_Guide_Running", 0);

end
