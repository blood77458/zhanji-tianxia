return function()

require "canon.script_and_guide.NewUserGuide"
require "canon.manager.DcManager"


Set_ShareData( "New_User_Guide_Running", 1);



--9领礼包
Show_StepNumber_For_Once( 1 );
Run_New_User_Guide( 0,0, 720,1280, "各地土豪听闻主公大名，陆续前来送礼，还请主公笑纳", false ,100,400);
Run_New_User_Guide( 0,0, 720,1280, "第一份礼包已经送到，主公快来领取吧", false ,100,400);
  Set_ShareData( "Guide_Save_State", 0 );
Run_New_User_Guide( 23, 965, 76, 76, "点击礼包打开", false ,100,400);    --领取第一个在线礼包
DcManager.sendTutorialStepActivity(260)
	Run_New_User_Guide( 235,982, 248,70, "好一把锋利的兵器，请主公收好", false ,100,100);
  DcManager.sendTutorialStepActivity(265)
	Run_New_User_Guide( 0,0, 720,1280, "大礼还会源源不断的送到，请主公及时回来领取", false ,100,400);


Set_ShareData( "Guide_Save_State", 0 );
Set_ShareData( "New_User_Guide_Running", 0);

end
