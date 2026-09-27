return function()

require "canon.script_and_guide.NewUserGuide"
require "canon.manager.DcManager"


Set_ShareData( "New_User_Guide_Running", 1);



--35级装备附灵

Run_New_User_Guide( 302, 320, 120, 120, getTextByKey("guide_enchant001"), true ,100, 468 ) -- 点击选择用来祭炼的装备。

Run_New_User_Guide( 607, 440, 55, 55, getTextByKey("guide_enchant002"), false ,100,454 ) -- 点击选择要分解的装备。只有蓝色及以上品质的装备能被分解哦！
Run_New_User_Guide( 520,1055, 170,75, getTextByKey("guide_enchant003"), true ,100,454); -- 确认选择。
Run_New_User_Guide( 245,787, 223,75, getTextByKey("guide_enchant004"), false ,100,233); -- 点击祭炼按钮，可以分解装备获得灵值。
Run_New_User_Guide( 225,958, 255,80, getTextByKey("guide_enchant009"), false ,100,450); -- 祭炼成功！
Run_New_User_Guide( 609,447, 101,101, getTextByKey("guide_enchant005"), true ,100,233); -- 点击附灵按钮，进入附灵界面。
Run_New_User_Guide( 13,365, 140,140, getTextByKey("guide_enchant006"), false ,100,521); -- 点击蓝色及以上品质装备，打开装备详细界面。
Run_New_User_Guide( 276,900, 168,66, getTextByKey("guide_enchant007"), true ,100,263); -- 点击附灵按钮，进入附灵界面。
Run_New_User_Guide( 55,1061, 250,74, getTextByKey("guide_enchant008"), false ,100,389); -- 点击按钮进行附灵，这样就可以消耗灵值加强蓝色及以上品质的装备啦！ 


Set_ShareData( "Guide_Save_State", 0 );
Set_ShareData( "New_User_Guide_Running", 0);

end
