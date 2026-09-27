return function()

require "canon.script_and_guide.NewUserGuide"

Set_ShareData( "New_User_Guide_Running", 1);
Run_New_User_Guide( 0, 0, 720, 1280, getTextByKey("guide_arena_txt1"), false ,100,400) -- 竞技场排名越靠前奖励越多，可以通过挑战其他玩家提升排名。
Run_New_User_Guide( 159, 265, 150, 55, getTextByKey("guide_arena_txt2"), true ,100,400) -- 竞技场每天22点结算积分奖励，积分可以兑换魂石。
Run_New_User_Guide( 0, 0, 720, 1280, getTextByKey("guide_arena_txt3"), false ,100,350) -- 有了魂石就能培养武将了，我们赶紧兑换吧。

Set_ShareData( "Guide_Save_State", 0 );
Set_ShareData( "New_User_Guide_Running", 0);

end
