return function()

require "canon.script_and_guide.NewUserGuide"

Set_ShareData( "New_User_Guide_Running", 1);
Run_New_User_Guide( 31, 1178, 94, 94, "要想战胜敌人，还得先提升武将等级！", true ,30,700 );
Run_New_User_Guide( 17, 1059, 94, 94, "点击武将强化按钮！", true ,50,550 );
Run_New_User_Guide( 262, 417, 187, 264, "点击按钮去背包选择需要强化的武将", true );
Run_New_User_Guide( 14, 338, 688, 160, "选择需要强化的武将", true ,200,500 );
Run_New_User_Guide( 78, 1073, 244, 70, "点击按钮选择材料武将", true ,100,600 );
Run_New_User_Guide( 14, 330, 688, 942, "选择作为素材的武将", false ,100,300 );

Set_ShareData( "Guide_Save_State", 0 );
Set_ShareData( "New_User_Guide_Running", 0);

end
