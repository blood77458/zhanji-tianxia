return function()

require "canon.script_and_guide.NewUserGuide"

Set_ShareData( "New_User_Guide_Running", 1);
Run_New_User_Guide( 0,0, 720,1280, "武将转生是最重要的提升武将能力的方法！", false );
Run_New_User_Guide( 0,0, 720,1280, "两张相同的卡牌可以转生，转生后能力大增！", false );
--Run_New_User_Guide( 98,769, 164,60, "点击武将转生按钮", true ,100,300);
--Run_New_User_Guide( 14, 332, 688, 162, "选择你需要进阶的卡牌", true ,100,500);
--Run_New_User_Guide( 452,769, 164,60, "现在选择另外一张与主卡同样的卡牌", true, 100,300 );
--Run_New_User_Guide( 0,0, 720,1280, "转生需要相同的材料卡牌，赶紧选择相同的材料卡牌吧", true ,100,500);

Set_ShareData( "Guide_Save_State", 0 );
Set_ShareData( "New_User_Guide_Running", 0);

end
