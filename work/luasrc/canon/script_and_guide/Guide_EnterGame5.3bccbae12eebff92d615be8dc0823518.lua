return function()

require "canon.script_and_guide.NewUserGuide"
require "canon.manager.DcManager"


Set_ShareData( "New_User_Guide_Running", 1);




--5强化卡牌
--Run_New_User_Guide( 0,0, 720,1280, "后面的敌人会越来越强。", false ,100,400 );
Show_StepNumber_For_Once( 4 );
Run_New_User_Guide( 0,0, 720,1280, getTextByKey("guide_enterGame5_txt1"), false ,100,400 ) -- 敌人越来越强，要战胜强敌，就得强化武将！
if Get_ShareData( "isXiaomiAndroid" ) == 1 then --如果有“小米”按钮，则
  Run_New_User_Guide( 120, 1155, 120, 120, getTextByKey("guide_enterGame5_txt2"), true ,50,550 ) -- 选择队伍。
else
  Run_New_User_Guide( 120, 1155, 120, 120, getTextByKey("guide_enterGame5_txt2"), true ,50,550 ) -- 选择队伍。
end
Wait_For_ShareData( "EnterAnimationFinished", 1 );
DcManager.sendTutorialStepActivity(120)
Run_New_User_Guide( 232, 576, 270, 380, getTextByKey("guide_enterGame5_txt3"), false, 100, 700 ) -- 点击此处打开武将详情。
DcManager.sendTutorialStepActivity(125)
--Wait_For_ShareData( "EnterAnimationFinished", 1 );
Run_New_User_Guide( 180, 550, 105, 50, getTextByKey("guide_enterGame5_txt4"), false ,100,500 ) -- 选择强化。
DcManager.sendTutorialStepActivity(130)
--Wait_For_ShareData( "EnterAnimationFinished", 1 );
Run_New_User_Guide( 70, 663, 120, 120, getTextByKey("guide_enterGame5_txt6"), false ); -- 接下来选择材料，奶牛战士可以提供大量经验，先选她吧。
Run_New_User_Guide( 225, 663, 120, 120, getTextByKey("guide_enterGame5_txt7"), false ); -- 继续选择。
Run_New_User_Guide( 376, 663, 120, 120, getTextByKey("guide_enterGame5_txt8"), false ); -- 越多越好。
Run_New_User_Guide( 370, 1090, 220, 75, getTextByKey("guide_enterGame5_txt9"), false ,100,300 ) -- 点击按钮开始强化！

Set_ShareData( "CardMergeFinished", 0 );
DcManager.sendTutorialStepActivity(145)
Set_ShareData( "Guide_Save_State", 0 );

--Wait_For_ShareData( "PopoutFinished_And_Can_Click_Now", 1 );
--Run_New_User_Guide( 83, 599, 245, 65, "我们选择了比较稀有的奶牛，不过没关系，点击确定。", false ,100,700 );  --关平的等级>20级
Wait_For_ShareData( "CardMergeFinished", 1 );
DcManager.sendTutorialStepActivity(150)
Run_New_User_Guide( 650, 65, 100, 65, getTextByKey("guide_enterGame5_txt5"), false ,100,300 ) -- 强化完成，关闭当前界面。
	Run_New_User_Guide( 0,0, 720,1280, getTextByKey("guide_enterGame5_txt11"), false ,100,400); -- 武将强化可以大幅提升主公战斗力。



Set_ShareData( "Guide_Save_State", 0 );
Set_ShareData( "New_User_Guide_Running", 0);

end
