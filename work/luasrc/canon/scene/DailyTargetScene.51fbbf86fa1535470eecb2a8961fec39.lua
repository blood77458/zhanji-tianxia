-- DailyTargetScene.lua
-- 2014-9-24
-- zheng.che
-- 成就/每日目标

-- DailyAchieve.xml
-- <bean desc="玩家每日活跃任务计数器">
-- 	<property code="taskId" type="int" desc="任务ID" />
-- 	<property code="num" type="int" desc="任务完成次数" />
-- 	<property code="complete" type="boolean" desc="任务是否完成" />
-- 	<property code="gain" type="boolean" desc="是否已领取" />
-- </bean>

local enter_animation_duration = 0.3
local enter_animation_cell_duration = 0.15

local visibleSize = CCDirector:sharedDirector():getVisibleSize()



--------------------------------------------------------------------------------------事件函数

--排序 false 交换
--已完成但是没有领取奖励的任务>未完成任务>已完成并且领取奖励的任务
local function sortFunc(a, b)
	if a.gain ~= b.gain then
  	if a.gain and (not b.gain) then
			return false
		else
			return true
		end
	end

	if a.complete ~= b.complete then
  	if a.complete and (not b.complete) then
			return true
		else
			return false
		end
	end

	return a.taskId < b.taskId
end

--跨天事件
local function onPassDay(evt)
	local self = evt.context

	--刷新数据
	local targetList = self.argv.params.data.dailyAchieveInfo
	for k, v in ipairs(targetList) do
		local configData = DailyTargetScene.getTargetConfigById(v.taskId)
		v.num = 0
		v.complete = false
		v.gain = false
	end

	--改变顺序
	table.sort(self.argv.params.data.dailyAchieveInfo, sortFunc)

	--刷新显示
	local tableOffset = self.tableView:getContentOffset()
	self.tableView:reloadData()
	self.tableView:setContentOffset(tableOffset, true)

	self:reFreshTipNum()
end

--------------------------------------------------------------------------------------类名定义

DailyTargetScene = class(BaseUIScene)

--------------------------------------------------------------------------------------枚举

DailyTargetScene.TYPE_GACHA = 1--至尊求将
DailyTargetScene.TYPE_BOX = 2--开启金宝箱
DailyTargetScene.TYPE_SPIRIT = 3--凝神

--------------------------------------------------------------------------------------公共数据

--角标数
DailyTargetScene.tipNum = 0

--------------------------------------------------------------------------------------类开始

function DailyTargetScene:ctor()
end

function DailyTargetScene:create(argv)
  local s = DailyTargetScene.new()
  if argv then 
      self.argv = argv 
  else
      self.argv = {enterScene=nil,returnScene=nil,params={}}
  end
  self.ignoreAction = self.argv.params.ignoreAction
  s:initScene()
  return s
end

function DailyTargetScene:onInit()
	--print("DailyTargetScene.getConfigData() = " .. tostringRich(DailyTargetScene.getConfigData()))
	BaseUIScene.initBackGround(self)
  
  --新UI加黑底
  local colorLayer = LayerColor:create()
  colorLayer:setOpacity(kDarkOpacity)
  colorLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
  self:addChild(colorLayer)

  self.title = Localization:getInstance():getText("activity_dailytask_title")
  
  self.builder = LayoutBuilder:createWithContentsOfFile("scene/daily_activity.json")
  self.builder.useArtLabelTTF = true
  self.mainUI = self.builder:build("daily_goals")
  self:addChild(self.mainUI)
  
  local function onClickDailyActiveTaskButton()
    local function getDailyActiveInfoSucceedResponse( evt )
      self.ignoreAction = true
      local argv = {enterScene=nil,returnScene=nil,params={data = evt.data, ignoreAction = true , secretaryTips = self.argv.params.secretaryTips}}
      self:replaceScene(SecretaryScene,argv)
    end
    local function getDailyActiveInfoFailedResponse( evt )
      
    end
    local request = GetDailyActiveInfoRequest.new( {}, rpc.SendingPriority.kHigh )
    request:addEventListener( RequestNotifyEnum.GetDailyActiveInfoSucceed, getDailyActiveInfoSucceedResponse )
    request:addEventListener( RequestNotifyEnum.GetDailyActiveInfoFailed, getDailyActiveInfoFailedResponse )
    request:start()
  end
  
  local function onClickDailyActiveTargetButton()
  end
  
  local function onClickAchievementButton()
    self.ignoreAction = true
    self:replaceScene(AchievementScene, {enterScene="SecretaryScene",returnScene=nil,params={ignoreAction = true , secretaryTips = self.argv.params.secretaryTips}})
  end

  ---------------------------------------------------------------------------------------------------------------
  
  if(DataManager.getCurrUser().level < DataManager.GameMetaData.dailyActiveConfig.levelLimit) then
    --不够打开第一页的等级
    self.secretaryTabDisplay = nil
    self.achievementTabDisplay = self.mainUI:getChildByName("btn_tab_activity1")
    self.targetTabDisplay = self.mainUI:getChildByName("btn_tab_activity2")
    self.mainUI:getChildByName("btn_tab_activity3"):setVisible(false)
  else
    self.secretaryTabDisplay = self.mainUI:getChildByName("btn_tab_activity1")
    self.achievementTabDisplay = self.mainUI:getChildByName("btn_tab_activity2")
    self.targetTabDisplay = self.mainUI:getChildByName("btn_tab_activity3")
  end

  if self.secretaryTabDisplay then
    self.dailyActiveTaskButton = Button:create(self.secretaryTabDisplay)
    self.dailyActiveTaskButton:addEventListener(Events.kStart,onClickDailyActiveTaskButton)
    self.secretaryTabDisplay:getChildByName("txt"):setString(getTextByKey("activity_daily_title1"))
    self.secretaryTabDisplay:getChildByName("icn_tixing_kong"):setVisible(false)
    self.secretaryTabDisplay:getChildByName("txt2"):setVisible(false)
    self.secretaryTabDisplay:getChildByName("btn_arena_active"):setVisible(false)
    local secretaryTipNum = (g_homeInfo and g_homeInfo.enableGainDailyActiveRewardNum or 0)
    if secretaryTipNum > 0 then
      self.secretaryTabDisplay:getChildByName("icn_tixing_kong"):setVisible(true)
      self.secretaryTabDisplay:getChildByName("txt2"):setVisible(true)
      self.secretaryTabDisplay:getChildByName("txt2"):setString(tostring(secretaryTipNum))
    else
      self.secretaryTabDisplay:getChildByName("icn_tixing_kong"):setVisible(false)
      self.secretaryTabDisplay:getChildByName("txt2"):setVisible(false)
    end
  end

  self.dailyActiveRewardButton = Button:create(self.achievementTabDisplay)
  self.dailyActiveRewardButton:addEventListener(Events.kStart,onClickAchievementButton)
  self.achievementTabDisplay:getChildByName("txt"):setString(getTextByKey("achieve_task_title"))
  self.achievementTabDisplay:getChildByName("btn_arena_active"):setVisible(false)
  local aTipNum = AchievementScene.getTipNum()
  if aTipNum > 0 then
    self.achievementTabDisplay:getChildByName("icn_tixing_kong"):setVisible(true)
    self.achievementTabDisplay:getChildByName("txt2"):setVisible(true)
    self.achievementTabDisplay:getChildByName("txt2"):setString(tostring(aTipNum))
  else
    self.achievementTabDisplay:getChildByName("icn_tixing_kong"):setVisible(false)
    self.achievementTabDisplay:getChildByName("txt2"):setVisible(false)
  end

  --每日目标按钮
  self.targetTabDisplay:getChildByName("txt"):setString(getTextByKey("activity_dailytask_title"))--每日目标
  self.targetTabDisplay:getChildByName("icn_tixing_kong"):setVisible(false)
  self.targetTabDisplay:getChildByName("txt2"):setVisible(false)
  self.targetTabDisplay:getChildByName("btn_arena_active"):setVisible(true)--

  ---

  self.mainUI:getChildByName("txt_daily_activity3"):getChildByName("txt"):setString(getTextByKey("activity_dailytask_txt"))--完成每日目标能够获得大量金币，每日目标任务0点刷新，主公记得天天来看我哦！
  
  self.dailyTargetButton = Button:create(self.targetTabDisplay)
  self.dailyTargetButton:addEventListener(Events.kStart,onClickDailyActiveTargetButton)
  self.dailyTargetButton:setEnable(false)
  self.targetTabDisplay:getChildByName("btn_arena_disable"):setVisible(false)
  
  --去掉调试用资源
  self.mainUI:getChildByName("list_daily_goals"):setVisible(false)


  table.sort(self.argv.params.data.dailyAchieveInfo, sortFunc)
  self.tableData = self.argv.params.data.dailyAchieveInfo

  self.tableView = self:createTableView()
  self.tableView.name = "table_view"
  self.mainUI:addChild(self.tableView)
  self.tableView:reloadData()

  self:reFreshTipNum()

  NotificationManager:addEventListener(PassDayManager.PASS_DAY, onPassDay, self)
  
  BaseUIScene.onInit(self)
end



function DailyTargetScene:dispose()
  --print("DailyTargetScene:dispose!!!!!!")
  NotificationManager:removeEventListener(PassDayManager.PASS_DAY, onPassDay, self)

  DailyTargetScene.super.dispose(self)
end

local table_width = 680
local table_height = 525 + 106
local table_posX = 12 + 10
local table_posY = 245 - 122
local item_width = 672
local item_height = 152

local function getStatusForAchievement(aAchievementConfig)
  --1:abled;2:unabled;3:haved
  return 1
end

function DailyTargetScene:createTableView()
  local cellTag = 1024
  local buttonTag = {-14}
  local aScene = self
  local AchievementTableViewRenderer = class(TableViewRenderer)
  function AchievementTableViewRenderer:ctor(width, height)
    self.list = aScene.tableData
  end
  function AchievementTableViewRenderer:buildCell(container)
    local builder = LayoutBuilder:createWithContentsOfFile("scene/daily_activity.json")
    builder.useArtLabelTTF = true
    local aCell = builder:build("list_daily_goals")
    --aCell:setAnchorPoint(ccp(0,1))
    container:addChild(aCell)
    aCell:setTag(cellTag)

    --不需要灰色情况 去掉
    aCell:getChildByName("btn_getcdreward_inactive"):setVisible(false)
    
    local aCardDisplay = aCell:getChildByName("normal_card_small")
    aCardDisplay:setTag(-10)
    aCardDisplay:setVisible(false)
    
    local aNumLabel = aCell:getChildByName("txt_task_reward1")
    aNumLabel:setTag(-11)
    aNumLabel = aNumLabel:getChildByName("txt")
    aNumLabel:setTag(-10)
    aNumLabel:setAroundColor(ccc3(102,0,0))
    
    local aDesLabel = aCell:getChildByName("txt_task_reward2")
    aDesLabel:setTag(-12)
    aDesLabel = aDesLabel:getChildByName("txt")
    aDesLabel:setTag(-10)
    
    local aNotOpenLabel = aCell:getChildByName("txt_saily_activity4")
    aNotOpenLabel:setTag(-13)
    aNotOpenLabel = aNotOpenLabel:getChildByName("txt")
    aNotOpenLabel:setTag(-10)
    
    local aButtonDisplay = aCell:getChildByName("btn_getcdreward")
    aButtonDisplay:setTag(-14)
    local challangeLabel = aButtonDisplay:getChildByName("txt")
    challangeLabel:setTag(-10)
    local challangBg = aButtonDisplay:getChildByName("btn")
    challangBg:setTag(-11)
  end
  function AchievementTableViewRenderer:setData( rawCocosObj, index )
    local aCell = self:getChildByTag(rawCocosObj, cellTag)
    local icon = aCell:getChildByTag(-20)
    if icon then
      icon:removeFromParentAndCleanup(true)
    end
    
    local aData = self.list[index + 1]
    local aConfigData = DailyTargetScene.getTargetConfigById(aData.taskId)
    local aRewardPackageConfig = MetaManager.reward_package[aConfigData.achieveReward]
    -- print("aRewardPackageConfig = " .. tostringRich(aRewardPackageConfig))
    
    local aCardDisplay = aCell:getChildByTag(-10)
    local params = {}
	params.sourceDisplay = aCardDisplay
	params.container = aCell
    params.showInCenter = true
	params.zindex = 10
	icon = CanonGoodIcon.createGoodIcon(aRewardPackageConfig.content1Type, aRewardPackageConfig.content1Id, 0, params)
	if icon then
		icon:setTag(-20)
		icon:dispose()
	end
    
    local aName = CanonGoodIcon.getGoodName(aRewardPackageConfig.content1Type, aRewardPackageConfig.content1Id, aRewardPackageConfig.content1Amount, nil)
    local aNumLabel = aCell:getChildByTag(-11):getChildByTag(-10)
	setNodeText(aNumLabel, aName)
    
    local aDes
    local aDesLabel = aCell:getChildByTag(-12):getChildByTag(-10)

    local showNum = 0
    if aData.num >= aConfigData.achieveNum then
    	showNum = aConfigData.achieveNum
    else
    	showNum = aData.num
    end
    if aConfigData.achieveType == DailyTargetScene.TYPE_GACHA then
    	--至尊求将
		aDes = Localization:getInstance():getText("activity_dailytask_type1", {num1=showNum, num2=aConfigData.achieveNum})--使用金币至尊求将{num1}/{num2}次
    elseif aConfigData.achieveType == DailyTargetScene.TYPE_BOX then
    	--开启金宝箱
		aDes = Localization:getInstance():getText("activity_dailytask_type2", {num1=showNum, num2=aConfigData.achieveNum})--开启{num1}/{num2}次金宝箱
    elseif aConfigData.achieveType == DailyTargetScene.TYPE_SPIRIT then
    	--凝神
		aDes = Localization:getInstance():getText("activity_dailytask_type3", {num1=showNum, num2=aConfigData.achieveNum})--使用金币凝神{num1}/{num2}次
    end
    --print("aDes = " .. tostringRich(aDes))
    setNodeText(aDesLabel, aDes)


    local aNotOpenLabel = aCell:getChildByTag(-13):getChildByTag(-10)
    local aButtonDisplay = aCell:getChildByTag(-14)
    local challangeLabel = aButtonDisplay:getChildByTag(-10)
    local challangBg = aButtonDisplay:getChildByTag(-11)
    aNotOpenLabel:setVisible(false)
    aButtonDisplay:setVisible(true)
    
    aDesLabel:setColor(ccc3(0, 0, 0))
    if aData.gain then
      aButtonDisplay.ignoreTouch = true
      setNodeText(challangeLabel, Localization:getInstance():getText("activity_dailytask_receive"))--已领取
      challangBg:setVisible(false)
    elseif aData.num < aConfigData.achieveNum then
    	if aConfigData.achieveType == DailyTargetScene.TYPE_SPIRIT and DataManager.getCurrUser().level < getDestinyFightUnlockLevel() then
    		--凝神等级不足
    		aNotOpenLabel:setVisible(true)
    		aButtonDisplay:setVisible(false)
    		setNodeText(aNotOpenLabel, Localization:getInstance():getText("activity_dailytask_level", {level = getDestinyFightUnlockLevel()}))--{level}级开启
    	else
			aButtonDisplay.ignoreTouch = false
			setNodeText(challangeLabel, Localization:getInstance():getText("activity_dailytask_go"))--前往
			challangBg:setVisible(true)
    	end
    else
    	aDesLabel:setColor(ccc3(42, 186, 8))
		aButtonDisplay.ignoreTouch = false
		setNodeText(challangeLabel, Localization:getInstance():getText("activity_dailytask_get"))--领取
		challangBg:setVisible(true)
    end
  end
  local function onListItemTouch( evt )
    local aIndex = evt.data + 1
    local newCell = self.tableView:cellAtIndex(aIndex - 1)
    local posInCell = newCell:convertToNodeSpace(evt.globalPosition)
    local buttonDisplay = newCell:getChildByTag(cellTag):getChildByTag(-14)
    local challengeDisplay = buttonDisplay:getChildByTag(-11)
    if posInCell.x > buttonDisplay:getPositionX() and
      posInCell.x < (buttonDisplay:getPositionX() + challengeDisplay:getContentSize().width) and
      posInCell.y > (buttonDisplay:getPositionY() - challengeDisplay:getContentSize().height) and
      posInCell.y < buttonDisplay:getPositionY() then
      if challengeDisplay:isVisible() then
        self:onGoBtnCilck(self.tableData[aIndex])
      end
    end
  end
  local renderer = AchievementTableViewRenderer.new(item_width, item_height)
  local aTableView = TableView:create(renderer, table_width, table_height, cellTag, buttonTag, CCScale9Sprite:create("pic/scroll.png"), CCScale9Sprite:create("pic/scroll.png"))
  --aTableView:setDirection(kCCScrollViewDirectionHorizontal)
  aTableView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch , self)
  aTableView:setPosition(ccp(table_posX, table_posY))
  return aTableView
end

--点击列表中的按钮
function DailyTargetScene:onGoBtnCilck(aData)
    local aConfigData = DailyTargetScene.getTargetConfigById(aData.taskId)
    if aData.gain then
    	--已领取
    	--不用管
    elseif aData.num < aConfigData.achieveNum then
		--前往
		if aConfigData.achieveType == DailyTargetScene.TYPE_GACHA then
			--至尊求将
			--去求将
			self:replaceScene(GachaScene, {returnScene = "DailyTargetScene"})
		elseif aConfigData.achieveType == DailyTargetScene.TYPE_BOX then
			--开启金宝箱
			--去vip商城
			self:replaceScene(ShopScene, {enterScene="DailyTargetScene",returnScene="DailyTargetScene", params = {tabIndex = TABLEVIEW_TAB_INDEX.VIP_SHOP}})
		elseif aConfigData.achieveType == DailyTargetScene.TYPE_SPIRIT then
			--凝神
	    	if aConfigData.achieveType == DailyTargetScene.TYPE_SPIRIT and DataManager.getCurrUser().level < getDestinyFightUnlockLevel() then
	    		--凝神等级不足
	    		--没有效果
			else
				Director:sharedDirector():replaceScene(ChallengeEntersScene:create({returnScene="DailyTargetScene", params = {showPanelName = "destiny"}}))
			end
		end
    else
    	--领取
    	self:receiveAchievement(aData)
    end
end

function DailyTargetScene:receiveAchievement(aData)
	local aConfigData = DailyTargetScene.getTargetConfigById(aData.taskId)
	local aRewardPackageConfig = MetaManager.reward_package[aConfigData.achieveReward]
	if BagCalcManager.needToCheck(aRewardPackageConfig.content1Type) and BagCalcManager.isFull() then
		NewPackageFullPanel:show()
		return
	end

	local function onAfterSucceed(requestEvent)
		--更新次数等状态
		aData.gain = true
		self:reFreshTipNum()
		local tableOffset = self.tableView:getContentOffset()
		self.tableView:reloadData()
		self.tableView:setContentOffset(tableOffset, true)
	end
	--print("aData = " .. tostringRich(aData))
	GainDailyAchieveRequest.sendRequestDefalut(aData.taskId, onAfterSucceed)
end

function DailyTargetScene:setTableViewsEnabledInner(isEnable)
  if self.tableView then
      self.tableView:setTouchEnabled(isEnable)
  end
end

function DailyTargetScene:doEnterAnimation()
  self:preEnterAnimation()
  self:startEnterAnimation()
end

function DailyTargetScene:preEnterAnimation()
  BaseUIScene.preEnterAnimation(self)
end

function DailyTargetScene:startEnterAnimation()
  BaseUIScene.startEnterAnimation(self)
  local function enterActionFinished()
    --print("enterActionFinished 1! os.clock() = " .. os.clock())
    self:nodeAnimationFinished()
  end
  
  for _, aChild in pairs(self.mainUI.list) do
    if not (self.ignoreAction and (aChild.name == "btn_tab_activity1" or aChild.name == "btn_tab_activity2" or aChild.name == "btn_tab_activity3")) then
      aChild:setPositionX(aChild:getPositionX() - visibleSize.width)
      local arr = CCArray:create()
      arr:addObject(CCMoveBy:create(0.3, ccp(visibleSize.width, 0)))
      arr:addObject(CCCallFunc:create(enterActionFinished))
      aChild:runAction(CCSequence:create(arr))
    end
  end
  if self.tableView then
    ViewControlUtil.showTableViewAction(self.tableView, visibleSize)
  end
end

function DailyTargetScene:sufEnterAnimation()
	BaseUIScene.sufEnterAnimation(self)
end

function DailyTargetScene:doExitAnimation()
  self:preExitAnimation()
  self:startExitAnimation()
end

function DailyTargetScene:preExitAnimation()
  BaseUIScene.preExitAnimation(self)
end

function DailyTargetScene:startExitAnimation()
	BaseUIScene.startExitAnimation(self)
	local function enterActionFinished()
    --print("enterActionFinished 2! os.clock() = " .. os.clock())
		self:nodeAnimationFinished()
	end
  
	if self.mainUI.list then
    --print("#self.mainUI.list = " .. tostringRich(#self.mainUI.list))
    local funcAdded = false
		for _, aChild in pairs(self.mainUI.list) do
			if not (self.ignoreAction and (aChild.name == "btn_tab_activity1" or aChild.name == "btn_tab_activity2" or aChild.name == "btn_tab_activity3" or aChild.name == "table_view")) then
				local arr = CCArray:create()
        --print("444444444444444444444444")
				arr:addObject(CCMoveBy:create(0.3, ccp(-visibleSize.width, 0)))
        if not funcAdded then
          arr:addObject(CCCallFunc:create(enterActionFinished))
          funcAdded = true
        end
				aChild:runAction(CCSequence:create(arr))
			end
		end
		if self.tableView then
			ViewControlUtil.disappearTableViewAction(self.tableView, visibleSize)
		end
	end
end

function DailyTargetScene:sufExitAnimation()
	BaseUIScene.sufExitAnimation(self)
end

function DailyTargetScene:back()
  self.ignoreAction = false
	self:replaceScene(MainMenuScene)
end

------------------------------------------------------------------------------------------------------------------------------------

function DailyTargetScene.gotoDailyTargetScene()
	local function onAfterSucceed( evt )
		local scene = Director:mgr():run()
		local argv = {enterScene=nil,returnScene=nil, enterType="DailyTargetScene",params={data = evt.data, ignoreAction = true , secretaryTips = g_homeInfo.enableGainDailyActiveRewardNum}}
		scene:replaceScene(DailyTargetScene,argv)
	end
	GetDailyAchieveInfoRequest.sendRequestDefalut(onAfterSucceed)
end

--刷新获得新的角标数
function DailyTargetScene:reFreshTipNum()
	local result = 0
	local targetList = self.argv.params.data.dailyAchieveInfo
	for k, v in ipairs(targetList) do
		local configData = DailyTargetScene.getTargetConfigById(v.taskId)
		if v.num >= configData.achieveNum then
			if not v.gain then
				result = result + 1
			end
		end
	end
	DailyTargetScene.tipNum = result
	--print("update DailyTargetScene.tipNum = " .. DailyTargetScene.tipNum)

    if DailyTargetScene.getTipNum() > 0 then
      self.targetTabDisplay:getChildByName("icn_tixing_kong"):setVisible(true)
      self.targetTabDisplay:getChildByName("txt2"):setVisible(true)
      self.targetTabDisplay:getChildByName("txt2"):setString(tostring(DailyTargetScene.getTipNum()))
    else
      self.targetTabDisplay:getChildByName("icn_tixing_kong"):setVisible(false)
      self.targetTabDisplay:getChildByName("txt2"):setVisible(false)
    end
end

function DailyTargetScene.getTipNum()
	return DailyTargetScene.tipNum
end

--获取配置信息
function DailyTargetScene.getConfigData()
	return DataManager.GameMetaData.dailyAchieveConfig or {}
end

--获取目标列表
-- <bean desc="每日成就配置">
-- 	<property code="achieveId" type="int" desc="每日成就唯一id" />
-- 	<property code="achieveType" type="int" desc="每日成就奖励类型，用于区分成就种类" />
-- 	<property code="achieveNum" type="int" desc="成就计数" />
-- 	<property code="achieveReward" type="int" desc="成就奖励包id" />
-- </bean>
function DailyTargetScene.getTargetList()
	return DailyTargetScene.getConfigData().dailyAchieve or {}
end
function DailyTargetScene.getTargetConfigById(taskId)
	local configList = DailyTargetScene.getTargetList()
	return configList[taskId]
end