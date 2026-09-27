return function()

require "canon.script_and_guide.NewUserGuide"
require "canon.manager.DcManager"


Set_ShareData( "New_User_Guide_Running", 1);




--7进阶卡牌
Show_StepNumber_For_Once( 2 );
Run_New_User_Guide( 0,0, 720,1280, getTextByKey("guide_enterGame7_txt1"), false ,100,400 ) -- 关平已到20级，再有一张关平的卡牌就可以转生了。
--Run_New_User_Guide( 0,0, 720,1280, "转生需要另外一张关平卡牌，我已经为你准备好了。", false ,100,400);
--Run_New_User_Guide( 0,0, 720,1280, "万事俱备, 赶紧去转生吧。", false ,100,400);
if Get_ShareData( "isXiaomiAndroid" ) == 1 then --如果有“小米”按钮，则
  Run_New_User_Guide( 115, 1155, 120, 120, getTextByKey("guide_enterGame5_txt2"), true ,50,550 ) -- 选择队伍。
else
  Run_New_User_Guide( 115, 1155, 120, 120, getTextByKey("guide_enterGame5_txt2"), true ,50,550 ) -- 选择队伍。
end
Wait_For_ShareData( "EnterAnimationFinished", 1 );
DcManager.sendTutorialStepActivity(200)
Run_New_User_Guide( 232, 576, 270, 380, getTextByKey("guide_enterGame7_txt3"), false, 100, 700 ) -- 点击此处打开武将详情。
DcManager.sendTutorialStepActivity(205)
Wait_For_ShareData( "EnterAnimationFinished", 1 );
Run_New_User_Guide( 430, 550, 105, 50, getTextByKey("guide_enterGame7_txt4"), false ,100,700 ) -- 选择转生。
DcManager.sendTutorialStepActivity(210)
Wait_For_ShareData( "EnterAnimationFinished", 1 );
Run_New_User_Guide( 70,663, 120,120, getTextByKey("guide_enterGame7_txt5"), false, 100,600 ) -- 现在选择另外一张关平卡牌。
Wait_For_ShareData( "EnterAnimationFinished", 1 );
DcManager.sendTutorialStepActivity(212)
Run_New_User_Guide( 235, 1090, 215, 75,getTextByKey("guide_enterGame7_txt7"), false ,100, 600 ) -- 开始转生吧！
  Set_ShareData( "Guide_Save_State", 0 );
Wait_For_ShareData( "CardJJFinished", 1 );
DcManager.sendTutorialStepActivity(220)
Run_New_User_Guide( 650, 68, 100, 62, getTextByKey("guide_enterGame7_txt6"), false ,100,300 ) -- 强化完成，关闭当前界面。



Set_ShareData( "Guide_Save_State", 0 );
Set_ShareData( "New_User_Guide_Running", 0);

end
