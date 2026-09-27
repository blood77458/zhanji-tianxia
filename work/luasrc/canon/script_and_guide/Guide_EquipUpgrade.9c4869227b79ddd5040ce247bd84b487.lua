return function()

require "canon.script_and_guide.NewUserGuide"

Set_ShareData( "New_User_Guide_Running", 1);
Run_New_User_Guide( 0,0, 720,1280, "主公，是时候强化一下装备了", false  ,100,400);
Run_New_User_Guide( 31, 1178, 94, 94, "我们先回到主界面", true ,100,400 );
Run_New_User_Guide( 243, 1059, 85, 85, "选择背包", true ,100,400 );
Run_New_User_Guide( 285, 171, 147, 53, "选择装备", false ,100,400 );
Run_New_User_Guide( 512, 414, 169, 59, "选择一把武器进行强化", true ,100,600 );

--Run_New_User_Guide( 145, 1177, 94, 94, "我们先来强化一下装备！", true ,100,700);
--Run_New_User_Guide( 526, 621, 104, 104, "选择需要强化的装备", false ,100,120);
--Run_New_User_Guide( 53, 949, 164, 63, "这是装备的详细信息，点这个强化按钮.", true ,100,450);

Run_New_User_Guide( 224, 1055, 244,70, "开始强化装备吧！", false ,100,500);
Run_New_User_Guide( 224, 1055, 244,70, "再多强化几级试试？", false ,100,500);
Run_New_User_Guide( 257, 1177, 94, 94, "武器好了！我们再去杀几个来回吧！.", true ,100,400);

Set_ShareData( "Guide_Save_State", 0 );
Set_ShareData( "New_User_Guide_Running", 0);

end
