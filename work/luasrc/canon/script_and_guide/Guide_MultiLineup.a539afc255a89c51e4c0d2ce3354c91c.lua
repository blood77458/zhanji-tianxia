return function()

require "canon.script_and_guide.NewUserGuide"

Set_ShareData( "New_User_Guide_Running", 1);
Set_ShareData( "Guide_MultiLineup", 1);
-- Run_New_User_Guide(132, 1170, 112, 110, getTextByKey("Lineup_guide1"), true ,100,400);
-- Wait_For_ShareData( "Guide_Lineup1", 1 );

Run_New_User_Guide(544, 229, 175, 59, getTextByKey("Lineup_guide2"), false ,100,400);
Run_New_User_Guide(358, 1158, 122, 122, getTextByKey("Lineup_guide3"), true ,100,400);
Wait_For_ShareData( "Guide_Lineup3", 1 );
Run_New_User_Guide(0,0, 720,1280, getTextByKey("Lineup_guide4"), false ,100,400);

Set_ShareData( "Guide_MultiLineup", 0);
Set_ShareData( "Guide_Save_State", 0 );
Set_ShareData( "New_User_Guide_Running", 0);

end