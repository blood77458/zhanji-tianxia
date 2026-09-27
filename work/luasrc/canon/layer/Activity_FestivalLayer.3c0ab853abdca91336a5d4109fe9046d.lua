require "hecore.display.CocosObject"
require "hecore.display.Director"
require "canon.customUI.CanonGoodIcon"
require "canon.models.PackageModel"
require "canon.customUI.CdLabelComponent"
require "canon.request.GainDailyTaskRewardRequest"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

Activity_FestivalLayer = class(Layer)

--焦点变化事件
local function onFocusChanged(evt)
	evt.context:setTableViewsEnabled(evt.data == nil)
end


local lstTask = {}

local function sortTaskList(list)
	local dailyTaskInfo = DataManager.GameMetaData.dailyTaskConfig.activeTaskList
	local function isFinished( task )
		for k,v in pairs(dailyTaskInfo) do
	    	if v.id == taskId then
	    		if task.progress >= v.conditionNum then
	    			return true
	    		else
	    			return false
	    		end
	    	end
	    end
	end
	local finishNotRewardTable = {}
	local notFinishedTable = {}
	local finishAndRewardTable = {}
	local levelLimitTable = {}
	for k,v in pairs(list) do
		local taskTotalFinishNum = 0
	    local taskLVLimit = 0
	    for m,n in pairs(dailyTaskInfo) do
	    	if n.id == v.taskId then
	    		taskTotalFinishNum = n.conditionNum 
	    		taskLVLimit = n.limit
	    		break
	    	end
	    end
	    if DataManager.getCurrUser().level < taskLVLimit then
	    	table.insert(levelLimitTable , v)
	    else
	    	if v.progress ~= -1 then
	    		if v.progress >= taskTotalFinishNum then
	    			table.insert(finishNotRewardTable , v)
	    		else
	    			table.insert(notFinishedTable , v)
	    		end
	    	else
	    		table.insert(finishAndRewardTable , v)
	    	end
	    end
	end
	local function sortFunc( a , b )
		return a.taskId < b.taskId
	end
	table.sort( finishNotRewardTable,sortFunc )
	table.sort( notFinishedTable,sortFunc )
	table.sort( finishAndRewardTable,sortFunc )
	table.sort( levelLimitTable,sortFunc )
	for k,v in pairs(finishNotRewardTable) do
		table.insert(lstTask , v)
	end
	for k,v in pairs(notFinishedTable) do
		table.insert(lstTask , v)
	end
	for k,v in pairs(finishAndRewardTable) do
		table.insert(lstTask , v)
	end
	for k,v in pairs(levelLimitTable) do
		table.insert(lstTask , v)
	end
end

function Activity_FestivalLayer:ctor()
  self.container = nil
end

function Activity_FestivalLayer:create( container , extraArgs)
  self.container = container
  self.extraArgs = extraArgs
  lstTask = {}
  sortTaskList(self.extraArgs.dailyTaskInfos)
  local s = Activity_FestivalLayer.new()
  s:initLayer()
  return s
end

function Activity_FestivalLayer:enable()

    local isEnable = MaintenanceManager.isActivityOpen("activityChallenge")
    return isEnable
    -- return true
end 

function Activity_FestivalLayer:panelDismiss()
    self.container.targetInfoPanel = nil
end

function Activity_FestivalLayer:dispose()
	UiStackManager_EventDispatcher:removeEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged)
	if (self.onCrossDayUpdateFunc) then
	    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.onCrossDayUpdateFunc)
	end
	Activity_FestivalLayer.super.dispose(self)
end

function Activity_FestivalLayer:setTableViewsEnabled( enable )
	self.tableView:setTouchEnabled(enable)
end

function Activity_FestivalLayer:initLayer()
    Activity_FestivalLayer.super.initLayer(self)
    -- print("消耗金币"..MetaManager.getGameSettingConfig().secretShopConfig.refreshGoldCost)

    self.builder = LayoutBuilder:createWithContentsOfFile("scene/task_activity.json")
    self.builder.useArtLabelTTF = true
	self.mainUI = self.builder:build("task_activity")
	self:addChild(self.mainUI)

	self.tableView = self:createTableView()
	self.mainUI:addChild(self.tableView)

	local endTime = MaintenanceManager:getStartAndEndTime("activityChallenge")
	local month = endTime[2].month
	local day = endTime[2].day

	local endTimeStr = Localization:getInstance():getText("activetask_txt" , {month1 = month , day2 = day})

	self.mainUI:getChildByName("txt_daily_activity3"):getChildByName("txt"):setString(endTimeStr .. "\n\n")

		--定期更新时间
	local function timeTick(ee)
	    --print("定期更新时间: " .. self.currentTime)
	     -- print("定期更新时间2: " .. TimeUtil.getServerTimeSeconds())
	    -- print("标准时间:"..TimeUtil.formatTime(TimeUtil.getServerTimeSeconds()))
	    local b = TimeUtil.whetherSwitchDay(self.currentTime)
	    -- self.isAcrossDay = true
	    --print(b)
	    --print(type(b))
	    if b then
	      --跨天了

	      	self:refreshTableList()
	      --重新记录当前时间
	      	self.currentTime = TimeUtil.getServerTimeSeconds()
	    end
	end

	self.currentTime = TimeUtil.getServerTimeSeconds()
  	self.onCrossDayUpdateFunc = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(timeTick,15,false);

  	UiStackManager_EventDispatcher:addEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged, self)
end

function Activity_FestivalLayer:refreshTableList()
	local function successCallback(data)
  		for i = #lstTask, 1, -1 do
	      table.remove(lstTask, i)
	    end
	    
	    -- local myList = data.data.dailyTaskInfos
	    sortTaskList(data.data.dailyTaskInfos)
	    
	    -- for _, item in ipairs(myList) do
	    --   table.insert(lstTask, item)
	    -- end
	    self.tableView:reloadData()
	end

	local function failureCallback(data)

	end

	GetTaskInfoRequest.sendRequest(successCallback , failureCallback)
end

local TABLEVIEW_CELL_TAG = -1001

local TAG_TXT_DETAIL_GREEN = 1001
local TAG_TXT_DETAIL = 1002
local TAG_TXT_ACTIVE_GET = 1003
local TAG_ALREADY_FINISHED = 1004
local TAG_TXT_NOT_OPEN = 1005
local TAG_BUTTON_REWARD = 1006
local TAG_TXT_REWARD = 1007
local TAG_BUTTON_ABLE = 1008
local TAG_BUTTON_DISABLE = 1009
local TAG_BG_YELLOW_PANEL = 1010
local TAG_BG_HUA_WEN = 1011
local TAG_BG_WHITE_PANEL = 1012
local TAG_REAWRD_ITEM = 1013
local TAG_ICON_SUN = 1014
local TAG_ICON_ITEM = 1015
local TAG_PIC_REWARD = 1016
local TAG_NORMAL_CARD_SMALL = 1017

function Activity_FestivalLayer:createTableView()
  -- body
  local Activity_FestivalLayerRenderer = class(TableViewRenderer)
  local dailyTaskInfo = DataManager.GameMetaData.dailyTaskConfig.activeTaskList
  local function findTaskType( taskId )
		for k,v in pairs(dailyTaskInfo) do
			if v.id == taskId then
				return v.type
			end
		end
	end
  function Activity_FestivalLayerRenderer:ctor(width, height)
    -- body
    self.list = lstTask
    local builder = LayoutBuilder:createWithContentsOfFile("scene/task_activity.json")
    builder.useArtLabelTTF = true
    self.builder = builder
  end

  function Activity_FestivalLayerRenderer:buildCell(container)
    local cell = self.builder:build("list_task_goals")
    cell:setPosition(ccp(333, 0))
    cell:setTag(TABLEVIEW_CELL_TAG)
    container:addChild(cell)

    cell:getChildByName("yellow9_panel"):setTag(TAG_BG_YELLOW_PANEL)
    cell:getChildByName("ibl_completed"):setTag(TAG_ALREADY_FINISHED)
    cell:getChildByName("ibl_completed"):setVisible(false)
    cell:getChildByName("txt_saily_activity4"):setTag(TAG_TXT_NOT_OPEN)
    cell:getChildByName("txt_saily_activity4"):getChildByName("txt"):setTag(TAG_TXT_NOT_OPEN)
    cell:getChildByName("txt_saily_activity4"):setVisible(false)
    cell:getChildByName("txt_saily_activity4"):getChildByName("txt"):setString(getTextByKey("activity_daily_level"))
    cell:getChildByName("btn_getcdreward"):setTag(TAG_BUTTON_REWARD)
    cell:getChildByName("btn_getcdreward"):getChildByName("txt"):setTag(TAG_BUTTON_REWARD)
    cell:getChildByName("btn_getcdreward"):getChildByName("txt"):setString(getTextByKey("achieve_task_get"))
    cell:getChildByName("txt_03"):setTag(TAG_TXT_DETAIL)
    cell:getChildByName("txt_03"):getChildByName("txt"):setTag(TAG_TXT_DETAIL)
    cell:getChildByName("txt_02"):setTag(TAG_TXT_DETAIL_GREEN)
    cell:getChildByName("txt_02"):getChildByName("txt"):setTag(TAG_TXT_DETAIL_GREEN)
    cell:getChildByName("txt_01"):setTag(TAG_TXT_REWARD)
    cell:getChildByName("txt_01"):getChildByName("txt"):setTag(TAG_TXT_REWARD)
    cell:getChildByName("normal_card_small"):setTag(TAG_NORMAL_CARD_SMALL)
    cell:getChildByName("normal_card_small"):setVisible(false)

  end

  local function setTextByTag( cell, tag, str)
    local txt = cell:getChildByTag(tag):getChildByTag(tag)
    setNodeText(txt, str);
  end

  local function setNodeVisibleByTag(cell, tag, visible)
    cell:getChildByTag(tag):setVisible(visible)
  end

  function Activity_FestivalLayerRenderer:setData(rawCocosObj,index)
    local cell = self:getChildByTag(rawCocosObj, TABLEVIEW_CELL_TAG)

    local taskId = lstTask[index + 1].taskId
    local rewardInfo = nil
    local taskTotalFinishNum = 0
    local titleKey
    local taskLVLimit = 0
    for k,v in pairs(dailyTaskInfo) do
    	if v.id == taskId then
    		taskTotalFinishNum = v.conditionNum 
    		rewardInfo = v.reward
    		titleKey = v.titleKey
    		taskLVLimit = v.limit
    		break
    	end
    end

    local taskType = findTaskType(taskId)
    local taskDetail
    if taskType == 4 then
    	taskDetail = Localization:getInstance():getText(titleKey , {num = taskTotalFinishNum})
    else
    	if lstTask[index + 1].progress == -1 then
    		taskDetail = Localization:getInstance():getText(titleKey , {num1 = taskTotalFinishNum , num2 = taskTotalFinishNum})
    	else
    		taskDetail = Localization:getInstance():getText(titleKey , {num1 = math.min(lstTask[index + 1].progress, taskTotalFinishNum) , num2 = taskTotalFinishNum})
    	end
    	
    end
    
    
    local rewardTxt = CanonGoodIcon.getGoodNameByPackageRewardInfo(rewardInfo, nil)

    local picPosX, picPosY = cell:getChildByTag(TAG_NORMAL_CARD_SMALL):getPosition()
	cell:setVisible(true)
	cell:removeChildByTag(TAG_PIC_REWARD, true)

	local params = {}
    params.sourceDisplay = cell:getChildByTag(TAG_NORMAL_CARD_SMALL)
    params.showInCenter = true
  	local headCard = CanonGoodIcon.createGoodIconByPackageRewardInfo(rewardInfo, params)
  	headCard:setPosition(ccp(picPosX, picPosY))
  	headCard:setTag(TAG_PIC_REWARD)
  	cell:addChild(headCard.refCocosObj, 1000)
  	headCard:dispose()

    setTextByTag(cell , TAG_TXT_DETAIL , taskDetail)
    setTextByTag(cell , TAG_TXT_DETAIL_GREEN , taskDetail)
    setTextByTag(cell , TAG_TXT_REWARD , rewardTxt)
    lstTask[index + 1].btnIsGo = true

    if DataManager.getCurrUser().level < taskLVLimit then
    	setNodeVisibleByTag(cell , TAG_ALREADY_FINISHED , false)
    	setNodeVisibleByTag(cell , TAG_BUTTON_REWARD , false)
    	setNodeVisibleByTag(cell , TAG_TXT_NOT_OPEN , true)
    	setNodeVisibleByTag(cell , TAG_TXT_DETAIL , true)
    	setNodeVisibleByTag(cell , TAG_TXT_DETAIL_GREEN , false)
    else
    	if lstTask[index + 1].progress == -1 then
	    	setNodeVisibleByTag(cell , TAG_ALREADY_FINISHED , true)
	    	setNodeVisibleByTag(cell , TAG_BUTTON_REWARD , false)
	    	setNodeVisibleByTag(cell , TAG_TXT_NOT_OPEN , false)
	    	setNodeVisibleByTag(cell , TAG_TXT_DETAIL , true)
	    	setNodeVisibleByTag(cell , TAG_TXT_DETAIL_GREEN , false)
		elseif lstTask[index + 1].progress >= taskTotalFinishNum then
			setNodeVisibleByTag(cell , TAG_ALREADY_FINISHED , false)
	    	setNodeVisibleByTag(cell , TAG_BUTTON_REWARD , true)
	    	lstTask[index + 1].btnIsGo = false
	    	setTextByTag(cell , TAG_BUTTON_REWARD , getTextByKey("activity_daily_get"))
	    	setNodeVisibleByTag(cell , TAG_TXT_NOT_OPEN , false)
	    	setNodeVisibleByTag(cell , TAG_TXT_DETAIL , false)
	    	setNodeVisibleByTag(cell , TAG_TXT_DETAIL_GREEN , true)
	    else
	    	setNodeVisibleByTag(cell , TAG_ALREADY_FINISHED , false)
	    	setNodeVisibleByTag(cell , TAG_BUTTON_REWARD , true)
	    	setTextByTag(cell , TAG_BUTTON_REWARD , getTextByKey("activity_daily_go"))
	    	setNodeVisibleByTag(cell , TAG_TXT_NOT_OPEN , false)
	    	setNodeVisibleByTag(cell , TAG_TXT_DETAIL , true)
	    	setNodeVisibleByTag(cell , TAG_TXT_DETAIL_GREEN , false)
	    end
    end

  end

  local function inArea(posX, posY, rect)
    if posX >= rect.x and posX <= rect.x + rect.width and posY >= rect.y and posY <= rect.y + rect.height then
      return true
    end
    return false
  end 

  local function onListItemTouch( evt ) 
    local selectedCell = self.tableView:cellAtIndex(evt.data):getChildByTag(TABLEVIEW_CELL_TAG)
    
    local posInCell = selectedCell:convertToNodeSpace(evt.globalPosition)
      	local itemPosX, itemPosY = selectedCell:getChildByTag(TAG_BUTTON_REWARD):getPosition()
      	local itemRect = {}
      	itemRect.x = itemPosX
     	itemRect.y = itemPosY - 66
     	itemRect.width = 168
     	itemRect.height = 66
     	local function doPlayAfterRewardSucceed( evt )
	        -- body
	        local function onGet(  )
	          -- body
	        	RewardManager:getReward(evt)
	        end
	        
	        local aRewardPanel = RewardReviewPanel:create( self.container, {rewardList = evt, rewardTitle = Localization:getInstance():getText("activity_newyear_rewardTitle"), callback = onGet} )
	        self.container:addChild(aRewardPanel)
	        aRewardPanel:scaleIn()
	    end

	      	local function activeRewardSucceedResponse( e )
	        	doPlayAfterRewardSucceed(e.data.rewards)
	        	lstTask[evt.data + 1].progress = -1
	        	local tempTable = table.clone(lstTask, true)
	        	for i = #lstTask, 1, -1 do
			      table.remove(lstTask, i)
			    end
			    
			    sortTaskList(tempTable)
	        	ViewControlUtil.refreshTableView(self.tableView, true)
	        	g_homeInfo.dailyTaskRewardNum = g_homeInfo.dailyTaskRewardNum - 1
	        	self.container:resetTipInfoForActivity("Activity_Challenge")
	      	end

	      	local function activeRewardFailedResponse( evt )
		        if ( evt.data == 710516) then
		          	NewPackageFullPanel:show()
		        elseif (evt.data == 714673) then
		          	self:refreshTableList()
		          	if (TimeUtil.whetherSwitchDay(self.currentTime)) then
		            	self.currentTime = TimeUtil.getServerTimeSeconds()
		          	end
		          elseif  evt.data == 714670 then  --activity closed
		          local function closeCanonMessageBox()
		          	self.container:replaceScene(MainMenuScene)
		          end
		          local text = Localization:getInstance():getText("activity_error_expired")
		          self.container.targetInfoPanel = CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
		        end
		    end	
     	if inArea(posInCell.x, posInCell.y, itemRect) then
     		if BagCalcManager.isFull() then
		        local aContent = Localization:getInstance():getText("rewardPopup_inventoryFullTxt")
		        NewPackageFullPanel:show()
		        return
		    end
     		if selectedCell:getChildByTag(TAG_BUTTON_REWARD):isVisible() then
     			
     			if lstTask[evt.data + 1].btnIsGo then
     				local taskType = findTaskType(lstTask[evt.data + 1].taskId)
     				print("前往"..taskType)
     				if taskType == 1 then
     					self.container:replaceScene(ChapterMapScene)
		              -- Director:sharedDirector():replaceScene(CardQueueScene,{enterScene=nil,returnScene=nil,params={}})
		            elseif taskType == 2 then
		            	self.container:replaceScene(ChallengeEntersScene)
		              --self.container:replaceScene(CardComposeScene,{enterScene=nil,returnScene=nil,params={}})
		              -- self.container:replaceScene(CardQueueScene)
		            elseif taskType == 3 then
		            	self.container:callFuncBeforeSceneChange(
		                function()
		                  local function doPrerationSucceed(fragmentsInfo)
		                    local argv = {enterScene="MainMenuScene",returnScene="MainMenuScene",params={fragmentsInfo=fragmentsInfo}}
		                    self.container:replaceScene(BeastScene, argv)
		                  end
		        
		                  local function doPrerationFailed()
		                    self.isChangeingScene = false
		                  end
		        
		                  BeastScene.doPreparationBeforeReplaceToBeastScene(doPrerationSucceed, doPrerationFailed)
		                end
		                )
		              -- self.container:replaceScene(BackpackScene,{params = {isCardTrain = false, tabIndex = BAGCATEGORY.equip}})
		            elseif taskType == 4 then
		            	self.container:replaceScene(ChallengeEntersScene, {params = {showPanelName = "skytower"}})
		              --self.container:replaceScene(BackpackScene,{params = {isCardTrain = true}})
		              -- self.container:replaceScene(CardQueueScene)
		            elseif taskType == 5 or taskType == 6 then
		            	self.container:replaceScene(BackpackScene,{params = {isCardTrain = false, tabIndex = BAGCATEGORY.card}})
		              -- self.container:replaceScene(FriendScene)
		            elseif taskType == 7 then
		              self.container:replaceScene(BackpackScene,{params = {isCardTrain = false, tabIndex = BAGCATEGORY.equip}})
		            elseif taskType == 8 then
		              self.container:replaceToArena()
		              --self.container:replaceScene(BeastScene)--bug
		            elseif taskType == 9 or taskType == 10  then
		            	self.container:replaceScene(FriendScene)
		              -- self.container:replaceScene(ChapterMapScene)
		            elseif taskType == 11 or taskType == 23 or taskType == 24 then
		              	self.container:replaceScene(CardQueueScene)
		            elseif taskType == 12 or taskType == 13 then
		            	self.container:replaceScene(GachaScene)
		            elseif taskType == 14 or taskType == 15 then
		            	self.container.targetInfoPanel = MainActorPanel:create( self.container )
		              	PopoutManager:sharedManager():popout(self.container.targetInfoPanel, kPopoutDir.kScale, true, false ,self.container) 
		              -- self.container:replaceScene(ChallengeEntersScene, {params = {showPanelName = "skytower"}})
		            elseif taskType == 16 then
		            	self.container:replaceScene(SpiritBackPackScene)
		              -- self.container:replaceScene(ActivityPanelScene, {selectPanelName = "Activity_EatPeach"})
		            elseif taskType == 17 then
		            	self.container:replaceScene(ChallengeEntersScene, {params = {showPanelName = "destiny"}})
		              -- self.container:replaceScene(ActivityPanelScene, {selectPanelName = "Activity_WorldBoss"})
		            elseif taskType == 18 then
		            	self.container:replaceScene(ActivityPanelScene, {selectPanelName = "Activity_Wanted"})
		              -- Director:sharedDirector():replaceScene(BackpackScene,{params = {tabIndex = BAGCATEGORY.item}})
		            elseif taskType == 19 or taskType == 20 or taskType == 21 or taskType == 22 then
		            	self.container:replaceScene(BackpackScene, {params = {tabIndex = BAGCATEGORY.item}})
		          	end
		 
     			else
     				print("领取")
     				local params = {taskId = lstTask[evt.data + 1].taskId}
		     		GainDailyTaskRewardRequest.sendRequest(params ,activeRewardSucceedResponse , activeRewardFailedResponse)
     			end
     		end
     	end
  end

  local cell_height = 150
  local list_height = 543.25
  local list_posY = 1280-1164

  local renderer = Activity_FestivalLayerRenderer.new(680, cell_height)
  local list = TableView:create(renderer, BAGCONFIG.WIDTH, list_height, TABLEVIEW_CELL_TAG,TAG_BUTTON_REWARD)

  list:addEventListener(DisplayEvents.kTouchItem, onListItemTouch)
  list:setPosition(ccp(34, list_posY))
  return list
end

function Activity_FestivalLayer.getTipNum()
  if not Activity_FestivalLayer.enable() then
    return 0
  end
  if g_homeInfo then
  	if g_homeInfo.dailyTaskRewardNum and g_homeInfo.dailyTaskRewardNum > 0 then 
  		return 1
  	else
  		return 0 
  	end
   else
     return 0
   end
end