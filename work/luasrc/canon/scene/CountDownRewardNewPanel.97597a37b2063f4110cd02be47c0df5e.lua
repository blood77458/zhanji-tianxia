require "hecore.display.CocosObject"
require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "canon.data.MetaManager"
require "canon.utils.ViewControlUtil"

CountDownRewardNewPanel = class(Layer)
local visibleSize = CCDirector:sharedDirector():getVisibleSize();

function CountDownRewardNewPanel:ctor()
  self.container = nil
end

function CountDownRewardNewPanel:create(container, timeCoolDown, rewardId, finish, panelType, closeCallBackFunc)
  self.container = container
  self.timeCoolDown = timeCoolDown
  self.rewardId = rewardId
  -- self.finish = finish
  -- self.panelType = panelType
  self.closeCallBackFunc = closeCallBackFunc
  self.updateStop =false
  self.MoveToCeter = true
  
  local panel = CountDownRewardNewPanel.new()
  panel:initLayer()
  
  return panel
end

function CountDownRewardNewPanel:initLayer()
  CountDownRewardNewPanel.super.initLayer(self)
  self.container:setTableViewsEnabled(false)
  -- 设置Layer
  local winSize = CCDirector:sharedDirector():getWinSize()
  self:setContentSize(CCSizeMake(winSize.width, winSize.height))
  
  -- 获取公告UI
  local builder = LayoutBuilder:createWithContentsOfFile("scene/common_new.json")
  self.ui = builder:build("common_countdown_reward_upbox_new")
  self:addChild(self.ui)

  -- 设置页面标题
  local titleLabel = self.ui:getChildByName("common_txt_reward_title"):getChildByName("txt_reward_title")
  titleLabel:setString(getTextByKey("countdownReward_title"))

  -- 关闭Panel事件
  local function onClosePanel(evt)
    PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale)
    self.container:setTableViewsEnabled(true)
    self.container.targetInfoPanel = nil
    if self.container.btnGetReward then
      self.container.btnGetReward:setEnable(true)
    end
    if self.colseCallBackFunc and type(self.colseCallBackFunc) == "function" then
      self.colseCallBackFunc()
    end
    if (self.onUpdateRewardUIFunc) then
	    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.onUpdateRewardUIFunc)
	    self.onUpdateRewardUIFunc = nil
	  end
  end

  -- 关闭按钮
  local closeButtonDisplay = self.ui:getChildByName("common_btn_close")
  local closeButton = Button:create(closeButtonDisplay)
  closeButton:addEventListener(Events.kStart, onClosePanel, self)

  self.ui:getChildByName("txt_countdown_reward_info"):getChildByName("txt"):setString(getTextByKey("countdownRewardNew_text1"))

  -- local allRewardsList = DataManager.GameMetaData.countdownRewardConfig

  -- -- 奖励信息
  -- self.tableView = self:createTableView(allRewardsList.rewards) 
  -- self:addChild(self.tableView)
  self:showTableView()
end

local TABLEVIEW_CELL_TAG = -1001
local TAG_TAG_START = 900
local TAG_TXT_REWARDID = 1000
local TAG_TXT_TIMECOOLDOWN = 1001
local TAG_BUTTON_ABLE = 1002
local TAG_BUTTON_DISABLE = 1003
local TAG_REWARD_NAME = 1004
local TAG_NORMAL_CARD_SMALL = 1005
local TAG_ICON_BG = 1006
local TAG_ICON_BG2 = 1007


local cell_height = 198

function CountDownRewardNewPanel:afterReward()
	self.rewardId = self.rewardId + 1
	self.updateStop = false
	local allRewardsList = DataManager.GameMetaData.countdownRewardConfig
	if self.rewardId == #(allRewardsList.rewards) + 1 then
		print("全都领完了")
		if (self.onUpdateRewardUIFunc) then
		    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.onUpdateRewardUIFunc)
		    self.onUpdateRewardUIFunc = nil
		    self.updateStop = true
		  end
		  self:showTableView(true)
	else
		self.timeCoolDown = allRewardsList.rewards[self.rewardId].countdownTime
		if (self.onUpdateRewardUIFunc) then
		    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.onUpdateRewardUIFunc)
		    self.onUpdateRewardUIFunc = nil
		  end
		  self:showTableView(true)
	end
end

function CountDownRewardNewPanel:afterRewardCoolDown(  )
	-- body
	if (self.onUpdateRewardUIFunc) then
		    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.onUpdateRewardUIFunc)
		    self.onUpdateRewardUIFunc = nil
		  end
	self:showTableView(true)
end

function CountDownRewardNewPanel:showTableView( reload )
	-- body
	print(1)
	local oldTableViewOffset = nil
	if reload then
		if self.tableView then
			oldTableViewOffset = self.tableView:getContentOffset()
			self.ui:removeChild(self.tableView ,true)
			self.tableView = nil
		end
	end	
	if self.tableView == nil then
		print(2)
	  local allRewardsList = DataManager.GameMetaData.countdownRewardConfig

  -- 奖励信息
	  	self.tableView = self:createTableView(allRewardsList.rewards) 
	  	self.ui:addChild(self.tableView)

	  	if self.MoveToCeter then
	  		local tableOffset = self.tableView:getContentOffset()
			print(self.tableView:getViewSize().height.."%%%%%%%%%%%"..self.rewardId)
			if self.rewardId > 2 then
				local maxOffsetY = #(allRewardsList.rewards) * cell_height - self.tableView:getViewSize().height

				if (self.rewardId - 2) * cell_height > maxOffsetY then
					tableOffset.y = tableOffset.y + maxOffsetY
				else
					tableOffset.y = tableOffset.y + (self.rewardId - 2) * cell_height
				end
			end

		  	self.tableView:setContentOffset(tableOffset, true)
		  	self.MoveToCeter =false
		  else
		  	if oldTableViewOffset then
			  	self.tableView:setContentOffset(oldTableViewOffset, true)
			  end
	  	end

	  	local function onUpdateRewardUI(ee)
	      if self.timeCoolDown <= 0 then
	      	self.updateStop = true
	      	self:afterRewardCoolDown()
	        return
	      else
	        self.timeCoolDown = self.timeCoolDown - 1
	      end

	      	for i=1,#(allRewardsList.rewards) do
	      		local txtHour, txtMin, txtSec = TimeUtil.getHourMinSec(self.timeCoolDown)
			    local timeCoolDownTxt = Localization:getInstance():getText("countdownRewardNew_text3" , {hour = txtHour , min = txtMin , sec = txtSec})
			    if self.tableView:cellAtIndex(i-1) then
			    	setNodeText(self.tableView:cellAtIndex(i-1):getChildByTag(TABLEVIEW_CELL_TAG):getChildByTag(TAG_TXT_TIMECOOLDOWN):getChildByTag(TAG_TXT_TIMECOOLDOWN) , timeCoolDownTxt)
		      		-- self.tableView:cellAtIndex(i-1):getChildByTag(TABLEVIEW_CELL_TAG):getChildByTag(TAG_TXT_TIMECOOLDOWN):getChildByTag(TAG_TXT_TIMECOOLDOWN):setString(timeCoolDownTxt)
		      	end
	      	end

    end

	  	if not self.onUpdateRewardUIFunc and not self.updateStop then --计时器不存在时创建
              self.onUpdateRewardUIFunc = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(onUpdateRewardUI, 1, false)
            end

	end
end

function CountDownRewardNewPanel:createTableView( allRewardsList )
	-- body
	local RewardCellRenderer = class(TableViewRenderer)
	local fatherContainer = self
	function RewardCellRenderer:ctor(width, height)
		self.list = allRewardsList
	    local builder = LayoutBuilder:createWithContentsOfFile("scene/common_new.json")
	    builder.useArtLabelTTF = true
	    self.builder = builder
	end

	function RewardCellRenderer:buildCell(container)
		local cell = self.builder:build("list_reward_tab")
	    cell:setPosition(ccp(0, 0))   
	    cell:setTag(TABLEVIEW_CELL_TAG)
	    container:addChild(cell)

	    cell:getChildByName("txt_reward_rank"):setTag(TAG_TXT_REWARDID)
	    cell:getChildByName("txt_reward_rank"):getChildByName("txt"):setTag(TAG_TXT_REWARDID)
	    cell:getChildByName("txt_reward_rank"):getChildByName("txt"):setString(getTextByKey("countdownRewardNew_text1"))
	    cell:getChildByName("txt_reward_rank2"):setTag(TAG_TXT_TIMECOOLDOWN)
	    cell:getChildByName("txt_reward_rank2"):getChildByName("txt"):setTag(TAG_TXT_TIMECOOLDOWN)
	    cell:getChildByName("btn_getcdreward"):setTag(TAG_BUTTON_ABLE)
	    cell:getChildByName("btn_getcdreward"):getChildByName("txt"):setTag(TAG_BUTTON_ABLE)
	    cell:getChildByName("btn_getcdreward_inactive"):setTag(TAG_BUTTON_DISABLE)
	    cell:getChildByName("btn_getcdreward_inactive"):getChildByName("txt"):setTag(TAG_BUTTON_DISABLE)
	    cell:getChildByName("reward_item"):setVisible(false)
	    local txtHour, txtMin, txtSec = TimeUtil.getHourMinSec(fatherContainer.timeCoolDown)
	    local timeCoolDownTxt = Localization:getInstance():getText("countdownRewardNew_text3" , {hour = txtHour , min = txtMin , sec = txtSec})
	    cell:getChildByName("txt_reward_rank2"):getChildByName("txt"):setString(timeCoolDownTxt)

	    -- local builder = LayoutBuilder:createWithContentsOfFile("scene/reward_new.json")
	    --   local layer = builder:build("reward_item")
	      cell:getChildByName("reward_item"):setTag(TAG_ICON_BG)
	      cell:getChildByName("reward_item"):getChildByName("normal_card_small"):setTag(TAG_NORMAL_CARD_SMALL)
	      cell:getChildByName("reward_item"):getChildByName("normal_card_small"):setVisible(false)
	      cell:getChildByName("reward_item"):getChildByName("txt_item_name"):setTag(TAG_REWARD_NAME)
	      cell:getChildByName("reward_item"):getChildByName("txt_item_name"):getChildByName("txt_item_name"):setTag(TAG_REWARD_NAME)

	      cell:getChildByName("reward_item2"):setTag(TAG_ICON_BG2)
	      cell:getChildByName("reward_item2"):getChildByName("normal_card_small"):setTag(TAG_NORMAL_CARD_SMALL)
	      cell:getChildByName("reward_item2"):getChildByName("normal_card_small"):setVisible(false)
	      cell:getChildByName("reward_item2"):getChildByName("txt_item_name"):setTag(TAG_REWARD_NAME)
	      cell:getChildByName("reward_item2"):getChildByName("txt_item_name"):getChildByName("txt_item_name"):setTag(TAG_REWARD_NAME)

	end

	local function setTextByTag( cell, tag, str)
	    local txt = cell:getChildByTag(tag):getChildByTag(tag)
	    setNodeText(txt, str);
	  end

	  local function setNodeVisibleByTag(cell, tag, visible)
	    cell:getChildByTag(tag):setVisible(visible)
	  end

	function RewardCellRenderer:setData(rawCocosObj, index)
		-- body
		local cell = self:getChildByTag(rawCocosObj, TABLEVIEW_CELL_TAG)
		local COLS_NUM = 2

		local function setIcon( cellLayer ,rewardID)
			-- body
			local picPosX, picPosY = cellLayer:getChildByTag(TAG_NORMAL_CARD_SMALL):getPosition()
		    -- local picZOrder = cellLayer:getChildByTag(TAG_PIC_REWARD_BG):getZOrder()
		    cellLayer:setVisible(true)
		    local rewardInfo = allRewardsList[index+1].rewardPackage
		    local rewardInfoTable = MetaManager.getRewardInfoByID(rewardInfo)

		    local params = {sourceSizes = {90,90}}

			local icon = CanonGoodIcon.createGoodIcon(rewardInfoTable[rewardID].itemType , rewardInfoTable[rewardID].metaId , 0 , params)
			local iconName = CanonGoodIcon.getGoodName(rewardInfoTable[rewardID].itemType , rewardInfoTable[rewardID].metaId ,rewardInfoTable[rewardID].amount)
			setNodeText(cellLayer:getChildByTag(TAG_REWARD_NAME):getChildByTag(TAG_REWARD_NAME) , iconName)
			-- cellLayer:getChildByTag(TAG_REWARD_NAME):getChildByTag(TAG_REWARD_NAME):setString(iconName)
			cellLayer:addChild(icon.refCocosObj)
		end

		setIcon(cell:getChildByTag(TAG_ICON_BG) , 2)
		setIcon(cell:getChildByTag(TAG_ICON_BG2) , 1)

		setNodeVisibleByTag(cell,TAG_TXT_TIMECOOLDOWN,false)

		local txtRewardID = Localization:getInstance():getText("countdownRewardNew_text2" , {num = index + 1})
		setTextByTag(cell,TAG_TXT_REWARDID , txtRewardID)
		setNodeVisibleByTag(cell , TAG_TXT_TIMECOOLDOWN , false)
		
		if index + 1 < fatherContainer.rewardId or fatherContainer.rewardId > #allRewardsList then
			setNodeVisibleByTag(cell , TAG_BUTTON_ABLE , false)
			setNodeVisibleByTag(cell , TAG_BUTTON_DISABLE , true)
			setTextByTag(cell , TAG_BUTTON_DISABLE , getTextByKey("activity_daily_receive"))
		elseif index + 1 == fatherContainer.rewardId then
			if fatherContainer.timeCoolDown <= 0 then
				setNodeVisibleByTag(cell , TAG_BUTTON_ABLE , true)
				setNodeVisibleByTag(cell , TAG_BUTTON_DISABLE , false)
				setTextByTag(cell , TAG_BUTTON_ABLE , getTextByKey("activity_daily_get"))
			else
				setNodeVisibleByTag(cell , TAG_TXT_TIMECOOLDOWN , true)
				setNodeVisibleByTag(cell , TAG_BUTTON_ABLE , false)
				setNodeVisibleByTag(cell , TAG_BUTTON_DISABLE , true)
				setTextByTag(cell , TAG_BUTTON_DISABLE , getTextByKey("activity_daily_get"))
				setNodeVisibleByTag(cell,TAG_TXT_TIMECOOLDOWN,true)
			end
		else
			setNodeVisibleByTag(cell , TAG_BUTTON_ABLE , false)
			setNodeVisibleByTag(cell , TAG_BUTTON_DISABLE , true)
			setTextByTag(cell , TAG_BUTTON_DISABLE , getTextByKey("activity_daily_get"))
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

	    if(selectedCell:getChildByTag(TAG_BUTTON_DISABLE):isVisible()) then
		      do return end
	    end
	    if(selectedCell:getChildByTag(TAG_BUTTON_ABLE):isVisible()) then
	      local posInCell = selectedCell:convertToNodeSpace(evt.globalPosition)
	      local itemPosX, itemPosY = selectedCell:getChildByTag(TAG_BUTTON_ABLE):getPosition()
	      local itemRect = {}
	      itemRect.x = itemPosX
	      itemRect.y = itemPosY - 66
	      itemRect.width = 168
	      itemRect.height = 66
	      if inArea(posInCell.x, posInCell.y, itemRect) then

	        local function getCountdownRewardFinish(responseData)
		          -- btnGetReward:setEnable(true)
		          -- local gainRewardId = countdownRewardInfo.inProcessRewardId
		          
		          countdownRewardInfo = {
		            latestRewardTimestamp = responseData.data.latestRewardTimestamp,
		            inProcessRewardId = responseData.data.inProcessRewardId,
		            finished = responseData.data.finished,
		          }
		          --更新新手礼包信息并领奖
		          DataManager.setCountdownRewardInfo(countdownRewardInfo)
		          -- RewardManager:getReward(responseData.data.rewards)
		          fatherContainer:afterReward()
		          fatherContainer:closeCallBackFunc()

		          local function onGet(  )
			          -- body
			          RewardManager:getReward(responseData.data.rewards)
			        end
			        
			        local aRewardPanel = RewardReviewPanel:create( fatherContainer, {rewardList = responseData.data.rewards, rewardTitle = Localization:getInstance():getText("activity_newyear_rewardTitle"), callback = onGet} )
			        fatherContainer:addChild(aRewardPanel)
			        aRewardPanel:scaleIn()
		      end

	        local function getCountdownRewardFailed(evt)
	          local errorCode = tonumber(evt.data)
	          if(CommErrorCodes.COUNTDOWN_REWARD_META_NOT_CONFIGED.code == errorCode) then
	            CanonMessageBox:showCommErrorBox(CommErrorCodes.COUNTDOWN_REWARD_META_NOT_CONFIGED, nil, nil, nil)
	          elseif(CommErrorCodes.COUNTDOWN_REWARD_NOT_REACH_TIME.code == errorCode) then
	            CanonMessageBox:showCommErrorBox(CommErrorCodes.COUNTDOWN_REWARD_NOT_REACH_TIME, nil, nil, nil)
	          end
	        end

	        local params = {}
	        local request = GetCountdownRewardRequest.new( params, rpc.SendingPriority.kHigh )
	        request:addEventListener( RequestNotifyEnum.GetCountdownRewardSucceed, getCountdownRewardFinish )
	        request:addEventListener( RequestNotifyEnum.GetCountdownRewardFailed, getCountdownRewardFailed )
	        request:start()
	      end
	  end

    end

	
	  local list_height = 622.95

	  local renderer = RewardCellRenderer.new(636.3, cell_height)
	  local list = TableView:create(renderer, 646.75, list_height, TABLEVIEW_CELL_TAG,TAG_BUTTON_ABLE, CCScale9Sprite:create("pic/scroll.png"), CCScale9Sprite:create("pic/scroll.png"))

	  list:addEventListener(DisplayEvents.kTouchItem, onListItemTouch)
	  list:setPosition(ccp(42, 246.05))
	  return list

end

