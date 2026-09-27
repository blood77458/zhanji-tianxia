return function()

require "canon.script_and_guide.NewUserGuide"
require "canon.manager.DcManager"




Set_ShareData( "New_User_Guide_Running", 1);



--3上阵
Set_ShareData( "CardQueue_Show_Icon", 0 )
Show_StepNumber_For_Once( 6 );
Run_New_User_Guide( 120, 1155, 120, 120, getTextByKey("guide_enterGame3_txt1"), true ,100,500 ) -- 我们现在让新武将出战吧！
Wait_For_ShareData( "EnterAnimationFinished", 1 );
DcManager.sendTutorialStepActivity(50)
print( "Item Type: ", Get_ShareData( "CardQueue_Show_Icon" ) )
if Get_ShareData( "CardQueue_Show_Icon" ) == 3 then --判断当前状态，只有显示加号图标时，才运行这个功能
  Run_New_User_Guide( 216, 345, 120, 120, getTextByKey("guide_enterGame3_txt2"), true ,100,500 ) -- 点击这个加号让武将上场。
  Wait_For_ShareData( "EnterAnimationFinished", 1 );
  DcManager.sendTutorialStepActivity(55)
  Run_New_User_Guide( 14, 330, 688, 190, getTextByKey("guide_enterGame3_txt3"), true ,120,500 )   -- 选择新获得的武将。
  Wait_For_ShareData( "EnterAnimationFinished", 1 );
end
DcManager.sendTutorialStepActivity(60)
  Set_ShareData( "Guide_Save_State", 0 );
Run_New_User_Guide( 0,0, 720,1280, getTextByKey("guide_enterGame3_txt4"), false ,100,400);  -- 具有缘分的武将同时出战时会激活组合技能，大幅增加战斗力，请记好哦。
--DcManager.sendTutorialStepActivity(65)


Set_ShareData( "Guide_Save_State", 0 );
Set_ShareData( "New_User_Guide_Running", 0);

end
