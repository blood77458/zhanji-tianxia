return function()

require "canon.script_and_guide.NewUserGuide"
require "canon.manager.DcManager"


Set_ShareData( "New_User_Guide_Running", 1);


--10穿装备
Show_StepNumber_For_Once( 1 );
Run_New_User_Guide( 145, 1178, 94, 94, "工欲善其事，必先利其器。我们赶紧给武将穿上装备", true ,100,600);
DcManager.sendTutorialStepActivity(280)
Run_New_User_Guide( 526, 621, 104, 104, "右边的空格可以装备武器和盔甲等", true ,100,120);
  Set_ShareData( "Guide_Save_State", 0 );
DcManager.sendTutorialStepActivity(285)
Run_New_User_Guide( 14, 332, 688, 162, "选择一件武器", true ,120,500);        --关平穿上一件武器
DcManager.sendTutorialStepActivity(290)
Run_New_User_Guide( 252, 1178, 100, 108, "武器好了！我们继续闯关吧！", true ,100,700);
	Run_New_User_Guide( 0,0, 720,1280, "主公，接下来我们必须不断前进，才能获得更多武将", false ,100,400);
	Run_New_User_Guide( 0,0, 720,1280, "水镜先行告退，后面还会继续引导主公征战天下", false ,100,400);
DcManager.sendTutorialStepActivity(300)
DcManager.sendTutorialFinishActivity()




Set_ShareData( "Guide_Save_State", 0 );
Set_ShareData( "New_User_Guide_Running", 0);

end
