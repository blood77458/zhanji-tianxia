return function()

require "canon.script_and_guide.NewUserGuide"
require "canon.manager.DcManager"


Set_ShareData( "New_User_Guide_Running", 1);


--1开始闯关
Set_ShareData( "Cloud_Finished", 0);
Run_New_User_Guide( 0,0, 720,1280, "主公大人，欢迎来到妹子的世界", false  ,100,400);
Run_New_User_Guide( 257, 1178, 94, 94, "兵贵神速，我们立即去抓几个妹子，来帮主公打天下", true ,100,600);
Wait_For_ShareData( "Cloud_Finished", 1);
-- 15号点测试
print("sendTutorialStepActivity")
DcManager.sendTutorialStepActivity(5)
Set_ShareData( "Walk_Finished", 0 );
Run_New_User_Guide( 197, 1034, 322, 92, "点击前进按钮开始闯关！", false ,100,400); --走到第第一关，第一步
Wait_For_ShareData( "Walk_Finished", 1 );
	Run_New_User_Guide( 0,0, 720,1280, "就是这样，做的非常棒", false  ,100,400);
--Set_ShareData( "Walk_Finished", 2 );
Set_ShareData( "ShowBattleResults", 0 );
Run_New_User_Guide( 197, 1034, 322, 92, "主公！前方发现曹军哨兵，请点击前进剿灭", false ,100,400); --走到第第一关，第二步，开战
Wait_For_ShareData( "ShowBattleResults", 1 );
	Run_New_User_Guide( 232, 1059, 252, 78, "恭喜主公大破敌军，点击确认继续", true ,100,580);


--2招募武将
Run_New_User_Guide( 482, 1177, 94, 94, "是时候去招募一个武将了！扭蛋是最快的方法", true ,100,500);
Set_ShareData( "Gacha_One_Finished", 0 );
Run_New_User_Guide( 54, 611, 244, 70, "至尊求将可以找到最强大的武将，我们开始吧", false ,50,700);  --获得一个4星武将
Wait_For_ShareData( "Gacha_One_Finished", 1 );
	Run_New_User_Guide( 91, 895, 244, 70, "星越多的武将越厉害！主公好手气！4星武将入手", false ,100,700);

--3上阵
Run_New_User_Guide( 142, 1172, 100, 108, "我们现在让新武将上场吧", true ,100,700);
Run_New_User_Guide( 212, 382, 130, 130, "点击这个加号让武将上场", true ,100,500);
Run_New_User_Guide( 14, 332, 688, 162, "选择新获得的武将", true ,120,500);   --上阵一个4星武将
	Run_New_User_Guide( 0,0, 720,1280, "具有缘分的武将同时出战时会战力大增，请主公谨记", false ,100,400);   

--4继续闯关，直到第5步
Run_New_User_Guide( 257, 1178, 94, 94, "好了，接下来就让新武将给我们露两手", true ,100,600);

Run_New_User_Guide( 197, 1034, 322, 92, "点击前进继续闯关！", false ,100,400);   --走到第第一关，第三步
Set_ShareData( "Walk_Finished", 0 );
Wait_For_ShareData( "Walk_Finished", 1 );
Run_New_User_Guide( 197, 1034, 322, 92, "前方发现曹军营寨，我们走近打探一下", false ,100,400);  --走到第第一关，第四步
--Set_ShareData( "Walk_Finished", 2 );

Set_ShareData( "Walk_Finished", 0 );
Wait_For_ShareData( "Walk_Finished", 1 );
Set_ShareData( "ShowBattleResults", 0 );
Run_New_User_Guide( 197, 1034, 322, 92, "看那旗号是曹熊，趁他不备，赶紧偷袭", false ,100,400);  --走到第第一关，第五步开战
Wait_For_ShareData( "ShowBattleResults", 1 );
	Run_New_User_Guide( 232, 1059, 252, 78, "恭喜主公捷报连连，点击确认继续", true ,100,580);

--5强化卡牌
Run_New_User_Guide( 0,0, 720,1280, "主公，后面的敌将会越来越强", false ,100,400 );
Run_New_User_Guide( 31, 1178, 94, 94, "要想战胜强敌，还得先强化武将！", true ,30,600 );
Run_New_User_Guide( 17, 1059, 94, 94, "选择武将强化！", true ,50,550 );
Run_New_User_Guide( 262, 417, 187, 264, "点击此处选择需要强化的武将", true );
Run_New_User_Guide( 14, 338, 688, 160, "选择一名武将", true ,200,500 );
Run_New_User_Guide( 78, 1073, 244, 70, "接下来选择材料武将", true ,100,600 );
Run_New_User_Guide( 14, 330, 688, 160, "奶牛卡牌可以提供大量经验，先选她吧", false ,100,550 );
Run_New_User_Guide( 14, 510, 688, 160, "继续选择", false ,100,710 );
Run_New_User_Guide( 14, 695, 688, 160, "越多越好", false ,100,870 );
Run_New_User_Guide( 570, 264, 147, 58, "点击确定", true ,100,300 );
Run_New_User_Guide( 393, 1073, 244, 70, "开始合成吧！", false ,100,300 );
Set_ShareData( "CardMergeFinished", 0 );
Run_New_User_Guide( 83, 590, 250, 75, "奶牛卡片可以提供大量经验，点击确认", false ,100,700 );  --关平的等级>20级
Wait_For_ShareData( "CardMergeFinished", 1 );
	Run_New_User_Guide( 0,0, 720,1280, "武将强化可以大幅提升主公战斗力", false ,100,400);


--6继续闯关，直到第7步
Run_New_User_Guide( 257, 1178, 94, 94, "我们回到闯关，看看强化后的效果吧", true ,100,600);
Set_ShareData( "Walk_Finished", 0 );
Run_New_User_Guide( 197, 1034, 322, 92, "曹熊正在逃跑，快点追上她", false ,100,400);   --走到第第一关，第六步
Wait_For_ShareData( "Walk_Finished", 1 );
--Set_ShareData( "Walk_Finished", 2 );
Set_ShareData( "ShowBattleResults", 0 );
Run_New_User_Guide( 197, 1034, 322, 92, "看到曹军逃兵了，快！", false ,100,400);  --走到第第一关，第七步，开战
Wait_For_ShareData( "ShowBattleResults", 1 );
	Run_New_User_Guide( 232, 1059, 252, 78, "大获全胜，点击确认继续", true ,100,580);


--7进阶卡牌
Run_New_User_Guide( 0,0, 720,1280, "主公，关平已经达到20级，可以转生了", false ,100,400);
Run_New_User_Guide( 0,0, 720,1280, "转生需要另外一张关平卡牌，主公不必担心，我早已准备好", false ,100,400);
Run_New_User_Guide( 32,1178, 94,94, "万事俱备，赶紧去转生吧", true ,200,800);
Run_New_User_Guide( 121, 1059, 94, 94, "选择武将转生！", true ,50,550 );
Run_New_User_Guide( 98,769, 164,60, "请点这里", true ,100,300);
Run_New_User_Guide( 14, 332, 688, 162, "选择关平", true ,100,500);
Run_New_User_Guide( 452,769, 164,60, "现在选择另外一张关平卡牌", true, 100,300 );
Run_New_User_Guide( 14, 332, 688, 162, "转生需要相同的卡牌，选择关平", true ,100,500);
Set_ShareData( "CardJJFinished", 0 );
Run_New_User_Guide( 235,1070, 250,73, "开始转生吧！", true ,100,600);   --关平转生到二阶
Wait_For_ShareData( "CardJJFinished", 1 );


--8继续闯关
Run_New_User_Guide( 257, 1178, 94, 94, "转生完毕，让我们看看转生后的武将有多厉害", true ,100,600);
Set_ShareData( "Walk_Finished", 0 );
Run_New_User_Guide( 197, 1034, 322, 92, "曹熊就在前面，跑的真快", false ,100,400);   --走到第第一关，第八步
Wait_For_ShareData( "Walk_Finished", 1 );
--Set_ShareData( "Walk_Finished", 2 );
Set_ShareData( "Walk_Finished", 0 );
Run_New_User_Guide( 197, 1034, 322, 92, "主公，下令全军加速前进！", false ,100,400);   --走到第第一关，第九步
Wait_For_ShareData( "Walk_Finished", 1 );
--Set_ShareData( "Walk_Finished", 2 );
Set_ShareData( "ShowBattleResults", 0 );
Run_New_User_Guide( 197, 1034, 322, 92, "她跑不掉了！", false ,100,400);   --走到第第一关，第十步，开战
Wait_For_ShareData( "ShowBattleResults", 1 );
	Run_New_User_Guide( 232, 1059, 252, 78, "完胜曹熊！点击确认继续", true ,100,580);


--9领礼包
Run_New_User_Guide( 0,0, 720,1280, "各地土豪听闻主公大名，陆续前来送礼，还请主公笑纳", false ,100,400);
Run_New_User_Guide( 32,1178, 94,94, "第一份礼包已经送到，主公快来领取吧", true ,100,400);
Run_New_User_Guide( 20, 962, 80, 80, "点击礼包打开", false ,100,400);    --领取第一个在线礼包
	Run_New_User_Guide( 237,980, 250,73, "好一把锋利的兵器，请主公收好", false ,100,100);
	Run_New_User_Guide( 0,0, 720,1280, "大礼还会源源不断的送到，请主公及时回来领取", false ,100,400);

--10穿装备
Run_New_User_Guide( 145, 1177, 94, 94, "工欲善其事，必先利其器。我们赶紧给武将穿上装备", true ,100,700);
Run_New_User_Guide( 526, 621, 104, 104, "右边的空格可以装备武器和盔甲等", true ,100,120);
Run_New_User_Guide( 14, 332, 688, 162, "选择一件武器", true ,120,500);        --关平穿上一件武器
Run_New_User_Guide( 252, 1172, 100, 108, "武器好了！我们继续闯关吧！", true ,100,700);
	Run_New_User_Guide( 0,0, 720,1280, "主公，接下来我们必须不断前进，才能获得更多武将", false ,100,400);
	Run_New_User_Guide( 0,0, 720,1280, "水镜先行告退，后面还会继续引导主公征战天下", false ,100,400);


Set_ShareData( "Guide_Save_State", 0 );
Set_ShareData( "New_User_Guide_Running", 0)
end
