return function()

require "canon.script_and_guide.NewUserGuide"

Set_ShareData( "New_User_Guide_Running", 1);
Run_New_User_Guide( 0, 0, 720, 1280, getTextByKey("guide_beast_txt1"), false ,100,400) -- 召唤神兽能增加武将的属性
Run_New_User_Guide( 0, 0, 720, 1280, getTextByKey("guide_beast_txt2"), false ,100,400) -- 神兽需要碎片才能合成，我们这就去抢夺碎片
Run_New_User_Guide( 310, 493, 105, 100, "", false ,100,400)

Set_ShareData( "Guide_Save_State", 0 );
Set_ShareData( "New_User_Guide_Running", 0);

end
