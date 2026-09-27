------------------------ 调用示例 ------------------------
-- RunScript_MultiThread( "/canon/script_and_guide/NewUserGuide.lua", 0 )
--
-- 功能：用多线程运行 "新手引导" 的功能
--       “新手引导”功能可以指导用户操作界面
----------------------------------------------------------

require "hecore.display.Layer"
require "hecore.display.Director"
require "canon.script_and_guide.NewUserGuideCoroutine"
require "canon.script_and_guide.NewUserGuideDialog"
require "canon.script_and_guide.ActorSpeakDialog"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()
local stepNumber = nil
local guideDialog = nil

local sharedData = {}
local clickEvent = {} -- 由Button和TableView触发
local replaceSceneEvent = {} -- 由BaseUIScene:ReplaceScene触发
local sceneChangedEvent = {} -- 用Scheduler检测

local function RegisterNewSceneHandle()
	local waitChangeSceneHandle = nil
	local lastScene = CCDirector:sharedDirector():getRunningScene()
	local function refresh()
		if CCDirector:sharedDirector():getRunningScene() ~= lastScene then
			CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(waitChangeSceneHandle)
			FireReplaceSceneEvent()
			Set_ShareData(sceneChangedEvent, 1)
		end
	end
	waitChangeSceneHandle = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(refresh, 0, false)
end

-- 由于coroutine切换不存在同步问题，因此不需要再专门禁止点击
-- 由scene确保切换过程中禁止点击，完成后打开点击
-- TableView触发回调不一定会触发功能，因此用Wait_For_NewScene配合，实现点击且切换场景后才触发
function Run_New_User_Guide( x, y, width, height, Text, Wait_For_NewScene, Guider_x, Guider_y )
	local step = stepNumber
	stepNumber = nil
	if width == visibleSize.width and Height == visibleSize.Height then
		width = 0
		height = 0
		x = -99999
		y = -99999
	else
		width = width - 10
		height = height - 10
		x = x + 5
		y = visibleSize.height - y - height - 5
	end
	Guider_x = Guider_x or -1
	Guider_y = Guider_y and visibleSize.height - Guider_y or -1
	guideDialog = NewUserGuideDialog:create(x, y, width, height, Text, Guider_x, Guider_y, step)
	guideDialog:setZOrder(9999)
	local scene = Director:sharedDirector():getRunningScene()
	scene:addChild(guideDialog)
	if Wait_For_NewScene then
		RegisterNewSceneHandle()
		Set_ShareData(sceneChangedEvent, 0)
		WaitEvent({[clickEvent] = 1, [replaceSceneEvent] = 1})
		if not guideDialog.isDisposed then
			guideDialog:setVisible(false)
		end
		Wait_For_ShareData(sceneChangedEvent, 1)
	else
		WaitEvent({[clickEvent] = 1})
	end
	guideDialog:removeFromParentAndCleanup(true)
	guideDialog = nil
end

function FireClickEvent()
	FireEvent(clickEvent, 1)
end

function FireReplaceSceneEvent()
	FireEvent(replaceSceneEvent, 1)
end

function Set_ShareData(key, value)
	sharedData[key] = value
	if value ~= nil then
		FireEvent(key, value)
	end
end

function Get_ShareData(key)
	local value = sharedData[key]
	return value ~= nil and value or -99999
end

-- 如果条件已满足则不等待
function Wait_For_ShareData(key, value, timeout)
	if sharedData[key] ~= value then
		WaitEvent({[key] = value}, timeout)
	end
end

function WaitForNewScene()
	RegisterNewSceneHandle()
	Set_ShareData(sceneChangedEvent, 0)
	Wait_For_ShareData(sceneChangedEvent, 1)
end

function WaitForClick(timeout)
	WaitEvent({[clickEvent] = 1}, timeout)
end

-- 由于coroutine切换不存在同步问题，因此通常不需要使用Dialog_SetScreenTouchEnabled
function Dialog_SetScreenTouchEnabled(enable)
	CCDirector:sharedDirector():getTouchDispatcher():setDispatchEvents(enable)
end

function Show_StepNumber_For_Once(number)
	stepNumber = number
end

function Terminate_New_User_Guide()
	Set_ShareData("Terminate_This_NewUserGuide", 1)
	ClearWaitingCoroutine()
end

function Terminate_All_ShowDialogBoxes()
	if guideDialog then
		if not guideDialog.isDisposed then
			guideDialog:removeFromParentAndCleanup(true)
		end
		guideDialog = nil
	end
	All_DialogBoxes_Hide()
end

function Is_New_User_Guide_Terminated()
	return Get_ShareData("Terminate_This_NewUserGuide") == 1
end

function RunScript_MultiThread(file)
	RunGuideScript(file)
end

GuideConfig = {
	kEnterGame = "Guide_EnterGame1",
	kGachaN = "Guide_EnterGame2",
	kOn = "Guide_EnterGame3",
	kRisk1 = "Guide_EnterGame4",
	kCardUpgrade = "Guide_EnterGame5",
	kRisk2 = "Guide_EnterGame6",
	kCardEvol = "Guide_EnterGame7",
	kRisk3 = "Guide_EnterGame8",
	kGift = "Guide_EnterGame9",
	kEquipWear = "Guide_EnterGame10",
	

	kEquipUpgrade = "Guide_EquipUpgrade",
	kElite = "Guide_Elite",
	kCardOn = "Guide_CardOn",
	kEquipQuality = "Guide_EquipQuality",
	kArena = "Guide_Arena",
    kBeast = "Guide_Beast",
    kChangeCard = "Guide_Change_Card",
    kCardTrain = "Guide_CardTrain",
    kSacrifice = "Guide_Sacrifice",
}

Set_ShareData("Dialog_Running", 0) -- 初始化


--[[
return function() -- 封装为一个函数（必须）

--初始化（必须）：
Set_ShareData( "New_User_Guide_Running", 1);


------------------------------ 使用说明 ------------------------------
-- Run_New_User_Guide( x, y, width, height, Text, Wait_For_NewScene, Guider_x, Guider_y )
-- 功能：在(x,y)的位置有一个宽为width高为height的区域可点击，其它区域不可点击
--       此(x,y)坐标是通过“Windows画图板”显示的区域左上角坐标
--       Text是显示的文字提示
--       如果需要“等待直到场景切换”，则设为true，否则设为false（这个参数要多试一下）
--       (Guider_x,Guider_y)是消息框与人物图像一起的左上角坐标，此项可为空
--
-- 例子：Run_New_User_Guide( 496, 794, 172, 70, "从这里进入", true );
--
-- 特殊使用：当width和height设置都设置为0时，屏幕上仅显示消息框和文字
--           此时，点击屏幕任意位置都能跳到下一条引导
--
-- 说明：如果要从Key里取文字，就将具体文字换成 getTextByKey( "......" )
--
----------------------------------------------------------------------


--战斗：
Run_New_User_Guide( 252, 1172, 100, 108, "请点击闯关去营救赵云将军吧！", true );


Run_New_User_Guide( 496, 794, 172, 70, "从这里进入", true );
Set_ShareData( "Menu_Can_Click_In_Map", 0 );
Run_New_User_Guide( 0, 160, 720, 1000, "点击屏幕任何位置前进", false );
Set_ShareData( "Menu_Can_Click_In_Map", 0 );
Wait_For_ShareData( "Menu_Can_Click_In_Map", 1 );
Set_ShareData( "Run_Into_Gacha", 0 );
Run_New_User_Guide( 368, 1172, 100, 108, "战场险恶，我们再去找一名大将来帮忙吧！", true );
Wait_For_ShareData( "Run_Into_Gacha", 1 );

--gacha：
Set_ShareData( "Run_Gacha_Animation", 0 );
Run_New_User_Guide( 54, 610, 256, 76, "至尊求降可以找到高级武将，星越多代表武将越厉害！", false );
Wait_For_ShareData( "Run_Gacha_Animation", 1 );
Run_New_User_Guide( 89, 857, 250, 75, "请点击确定按钮", false );
Run_New_User_Guide( 142, 1172, 100, 108, "我们现在让新武将上场吧", true );

--队列：
Run_New_User_Guide( 179, 394, 112, 150, "点击这个加号让武将上场", false );
Run_New_User_Guide( 0, 355, 720, 175, "从候选武将中选择", false );
Run_New_User_Guide( 252, 1172, 100, 108, "有了新武将的加入，我们赶紧去救赵云将军吧！", true );
Run_New_User_Guide( 496, 794, 172, 70, "从这里进入", true );

--卡牌合成：
Run_New_User_Guide( 24, 1172, 100, 108, "要想战胜敌人，还得先提升武将等级", true );
Run_New_User_Guide( 48, 1050, 104, 108, "点击武将合成按钮", true );
Run_New_User_Guide( 0, 795, 220, 62, "点击按钮去背包选择需要升级的武将", true );
Run_New_User_Guide( 0, 340, 720, 165, "选择需要升级的武将", true );
Run_New_User_Guide( 505, 795, 220, 62, "点击按钮选择材料武将", true );
Run_New_User_Guide( 0, 334, 720, 836, "选择作为素材的武将", false );
Run_New_User_Guide( 545, 264, 172, 58, "点击确定", true );
Run_New_User_Guide( 235, 1077, 252, 78, "开始合成吧！", false );
Run_New_User_Guide( 396, 594, 247, 73, "点击取消按钮", false );
Run_New_User_Guide( 252, 1172, 100, 108, "赵云将军好像又杀进了长坂坡，我们去帮她吧！", true );
Run_New_User_Guide( 490, 920, 172, 70, "从这里进入", true );

--穿着装备
Run_New_User_Guide( 142, 1172, 100, 108, "工欲善其事，必先利其器。给武将配一把趁手的武器吧！", true );
Run_New_User_Guide( 524, 620, 112, 112, "右边的空格可以装备武器和盔甲等", true );
Run_New_User_Guide( 0, 336, 720, 176, "选择一件武器", false );
Run_New_User_Guide( 524, 620, 112, 112, "仅仅是有武器还不够，还需要强化一下更好用！", false );

--装备强化
Run_New_User_Guide( 142, 1172, 100, 108, "这是装备的详细信息，点这个强化按钮", true );
Run_New_User_Guide( 142, 1172, 100, 108, "开始强化装备吧！", false );
Run_New_User_Guide( 142, 1172, 100, 108, "再多强化几级试试？", false );
Run_New_User_Guide( 142, 1172, 100, 108, "武器好了！我们再去杀几个来回吧！", true );

--卡牌进化
Run_New_User_Guide( 24, 1172, 100, 108, "武将转生是最重要的提升武将能力的方法！", true );
Run_New_User_Guide( 154, 1048, 100, 108, "点击武将转生按钮", true );
Run_New_User_Guide( 0, 850, 720, 212, "两张同样的卡牌可以转生为一张新卡牌！能力大大提高！形象也不一样了哦！", false );
Run_New_User_Guide( 93, 777, 176, 70, "首先选择一张主卡牌", true );
Run_New_User_Guide( 0, 334, 720, 836, "选择一张卡牌", false );
Run_New_User_Guide( 456, 777, 176, 70, "现在选择另外一张同样的卡牌", false );
Run_New_User_Guide( 0, 334, 720, 836, "选择一张卡牌", false );
Run_New_User_Guide( 235, 1076, 256, 76, "现在就可以转生了", false );

--装备升阶
Run_New_User_Guide( 24, 708, 666, 190, "这里是装备进阶需要的材料，当材料满足时图标就会点亮。", false );
Run_New_User_Guide( 38, 896, 642, 104, "进阶后装备属性会大幅提升！", false );



--结束（必须）：
Set_ShareData( "New_User_Guide_Running", 0);

end
--]]
