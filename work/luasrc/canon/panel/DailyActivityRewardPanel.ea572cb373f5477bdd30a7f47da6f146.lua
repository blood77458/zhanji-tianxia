require "hecore.display.CocosObject"
require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "canon.data.MetaManager"
require "canon.utils.ViewControlUtil"

DailyActivityRewardPanel = class(Layer)
local visibleSize = CCDirector:sharedDirector():getVisibleSize();

function DailyActivityRewardPanel:ctor()
  self.container = nil
end

function DailyActivityRewardPanel:create(container, rewardList, gainedReward, totalActiveGet)
  self.container = container
  self.rewardList = rewardList
  self.gainedReward = gainedReward
  self.totalActiveGet = totalActiveGet
  -- self.finish = finish
  -- self.panelType = panelType
  -- self.closeCallBackFunc = closeCallBackFunc
  
  local panel = DailyActivityRewardPanel.new()
  panel:initLayer()
  
  return panel
end

  --焦点变化事件
local function onFocusChanged(evt)
	evt.context:setTableViewsEnabled(evt.data == evt.context)
end

function DailyActivityRewardPanel:setTableViewsEnabled( flag )
	-- body
	self.tableView:setTouchEnabled(flag)
end

function DailyActivityRewardPanel:initLayer()
  DailyActivityRewardPanel.super.initLayer(self)
  self.container:setTableViewsEnabled(false)
  -- 设置Layer
  local winSize = CCDirector:sharedDirector():getWinSize()
  self:setContentSize(CCSizeMake(winSize.width, winSize.height))
  
  -- 获取公告UI
  local builder = LayoutBuilder:createWithContentsOfFile("scene/daily_activity.json")
  self.ui = builder:build("popup_activity_reward")
  self:addChild(self.ui)

  -- 设置页面标题
  -- local titleLabel = self.ui:getChildByName("common_txt_reward_title"):getChildByName("txt_reward_title")
  -- titleLabel:setString(getTextByKey("countdownReward_title"))

  -- 关闭Panel事件
  local function onClosePanel(evt)
    PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale)
    self.container:setTableViewsEnabled(true)
    self.container.targetInfoPanel = nil
  end

  -- 关闭按钮
  local closeButtonDisplay = self.ui:getChildByName("Popup_window_daily_activity1_new"):getChildByName("btn_close")
  local closeButton = Button:create(closeButtonDisplay)
  closeButton:addEventListener(Events.kStart, onClosePanel, self)

  -- self.ui:getChildByName("txt_countdown_reward_info"):getChildByName("txt"):setString(getTextByKey("countdownRewardNew_text1"))

  -- local allRewardsList = DataManager.GameMetaData.countdownRewardConfig

  -- -- 奖励信息
  -- self.tableView = self:createTableView(allRewardsList.rewards) 
  -- self:addChild(self.tableView)
  self:showTableView()

  UiStackManager_EventDispatcher:addEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged, self)
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
local TAG_ICON_GOODICON = 1008
local TAG_ICON_ITEM = 1009
local TAG_TXT_DETAIL = 1010
local TAG_BG_YELLOW_PANEL = 1011
local TAG_TXT_REWARDED = 1012
local TAG_ICON_GOODICON2 = 1013
local TAG_REWARD_NAME2 = 1014
local TAG_ICON_ITEM2 = 1015


local cell_height = 198

function DailyActivityRewardPanel:showTableView( reload )
	self.tableView = self:createTableView(self.rewardList , self.gainedReward , self.totalActiveGet)
	self.ui:addChild(self.tableView)
end

function DailyActivityRewardPanel:createTableView( data , gainedRewards , activeValueGet )
	-- body
	local RewardCellRenderer = class(TableViewRenderer)
	local fatherContainer = self
	function RewardCellRenderer:ctor(width, height)
		self.list = data
	    local builder = LayoutBuilder:createWithContentsOfFile("scene/daily_activity.json")
	    builder.useArtLabelTTF = true
	    self.builder = builder
	end

	function RewardCellRenderer:buildCell(container)
		local cell = self.builder:build("list_activity_reward_2")
	    cell:setPosition(ccp(0, 0))   
	    cell:setTag(TABLEVIEW_CELL_TAG)
	    container:addChild(cell)

	    cell:getChildByName("yellow9_panel"):setTag(TAG_BG_YELLOW_PANEL)
	    cell:getChildByName("btn_getcdreward"):setTag(TAG_BUTTON_ABLE)
	    cell:getChildByName("btn_getcdreward"):getChildByName("txt"):setTag(TAG_BUTTON_ABLE)
	    cell:getChildByName("btn_getcdreward"):getChildByName("txt"):setString(getTextByKey("activity_daily_get"))
	    cell:getChildByName("btn_getcdreward_inactive"):setTag(TAG_BUTTON_DISABLE)
	    cell:getChildByName("btn_getcdreward_inactive"):getChildByName("txt"):setTag(TAG_BUTTON_DISABLE)
	    cell:getChildByName("btn_getcdreward_inactive"):getChildByName("txt"):setString(getTextByKey("activity_daily_get"))
        cell:getChildByName("txt_saily_activity5"):setTag(TAG_TXT_REWARDED)
	    cell:getChildByName("txt_saily_activity5"):getChildByName("txt"):setTag(TAG_TXT_REWARDED)
	    cell:getChildByName("txt_saily_activity5"):getChildByName("txt"):setString(getTextByKey("activity_daily_receive"))
	    cell:getChildByName("txt_saily_activity7"):setTag(TAG_REWARD_NAME)
	    cell:getChildByName("txt_saily_activity7"):getChildByName("txt"):setTag(TAG_REWARD_NAME)
	    cell:getChildByName("txt_saily_activity7_2"):setTag(TAG_REWARD_NAME2)
	    cell:getChildByName("txt_saily_activity7_2"):getChildByName("txt"):setTag(TAG_REWARD_NAME2)

	    cell:getChildByName("normal_card_small"):setTag(TAG_ICON_GOODICON)
	    cell:getChildByName("normal_card_small"):setVisible(false)

	    cell:getChildByName("normal_card_small2"):setTag(TAG_ICON_GOODICON2)
	    cell:getChildByName("normal_card_small2"):setVisible(false)

	    cell:getChildByName("txt_reward_rank"):setTag(TAG_TXT_DETAIL)
	    cell:getChildByName("txt_reward_rank"):getChildByName("txt"):setTag(TAG_TXT_DETAIL)


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
		
		local itemData = self.list[index + 1]

	    local itemPosX, itemPosY = cell:getChildByTag(TAG_ICON_GOODICON):getPosition()
    	local itemSize = cell:getChildByTag(TAG_ICON_GOODICON):getContentSize()
    	local zOrder = cell:getChildByTag(TAG_ICON_GOODICON):getZOrder()
    	-- replaceItemIcon(cell , self.list[index + 1] , itemPosX  ,itemPosY)

    	local aCardDisplay = cell:getChildByTag(TAG_ICON_GOODICON)

		local oldIcon = cell:getChildByTag(TAG_ICON_ITEM)
		if oldIcon then
			oldIcon:removeFromParentAndCleanup(true)
		end
		local params = {}
		params.sourceDisplay = aCardDisplay
		params.showInCenter = true
		local icon = CanonGoodIcon.createFirstGoodIconByPackageReward(itemData.rewardPackageId , params)
		cell:addChild(icon.refCocosObj, zOrder)
		if icon then
			icon:setTag(TAG_ICON_ITEM)
			icon:dispose()
		end
		local name = CanonGoodIcon.getFirstGoodNameByPackageReward(itemData.rewardPackageId, params)
		setTextByTag(cell , TAG_REWARD_NAME , name)

		local rewardList = MetaManager.getRewardInfoByID(itemData.rewardPackageId)

		local oldIcon2 = cell:getChildByTag(TAG_ICON_ITEM2)
		if oldIcon2 then
			oldIcon2:removeFromParentAndCleanup(true)
		end
		setTextByTag(cell , TAG_REWARD_NAME2 , "")
		if rewardList[2] then 
			local params = {}
			params.sourceDisplay = cell:getChildByTag(TAG_ICON_GOODICON2)
			params.showInCenter = true
			local icon = CanonGoodIcon.createGoodIcon(rewardList[2].itemType, rewardList[2].metaId, rewardList[2].amount, params)
			cell:addChild(icon.refCocosObj, zOrder)
			if icon then
				icon:setTag(TAG_ICON_ITEM2)
				icon:dispose()
			end
			local name = CanonGoodIcon.getGoodName(rewardList[2].itemType, rewardList[2].metaId, rewardList[2].amount, {})
			setTextByTag(cell , TAG_REWARD_NAME2 , name)
		end

		setTextByTag(cell , TAG_TXT_DETAIL , getTextByKey("activity_daily_value") .. itemData.activeValue)

		local isGained = false
	    for k,v in pairs(gainedRewards) do
	      if(itemData.id == v) then
	        --cell:setVisible(false)
	        -- cell:getChildByTag(TAG_BG_HUA_WEN):setColor(ccc3(127, 127, 127))
	        -- cell:getChildByTag(TAG_BG_WHITE_PANEL):setColor(ccc3(127, 127, 127))
	        -- cell:getChildByTag(TAG_BG_YELLOW_PANEL):setColor(ccc3(127, 127, 127))

	        setNodeVisibleByTag(cell , TAG_BG_YELLOW_PANEL , false)
	        setNodeVisibleByTag(cell , TAG_TXT_REWARDED , true)
	        setNodeVisibleByTag(cell , TAG_BUTTON_ABLE , false)
	        cell:getChildByTag(TAG_BUTTON_DISABLE):setVisible(false)
	        isGained = true
	      
	      end
	    end
	    if(not isGained) then
	      setNodeVisibleByTag(cell , TAG_BG_YELLOW_PANEL , true)
	      if(activeValueGet < itemData.activeValue) then
	          setNodeVisibleByTag(cell , TAG_TXT_REWARDED , false)
	          setNodeVisibleByTag(cell , TAG_BUTTON_ABLE , true)
	          cell:getChildByTag(TAG_BUTTON_DISABLE):setVisible(true)
	          cell:getChildByTag(TAG_BUTTON_ABLE):setVisible(false)
	      else
	          setNodeVisibleByTag(cell , TAG_TXT_REWARDED , false)
	          setNodeVisibleByTag(cell , TAG_BUTTON_ABLE , true)
	          cell:getChildByTag(TAG_BUTTON_DISABLE):setVisible(false)
	          cell:getChildByTag(TAG_BUTTON_ABLE):setVisible(true)
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
		    self.touchItemIndex = evt.data + 1

	      local function doPlayAfterRewardSucceed( evt )
	        -- body
	        local function onGet(  )
	          -- body
	          RewardManager:getReward(evt)
	          table.insert(gainedRewards , self.touchItemIndex)
	          local tableOffset = self.tableView:getContentOffset()
	          self.tableView:reloadData()
	          self.tableView:setContentOffset(tableOffset)
	          -- self.container:afterRewardSuccessed(self.touchItemIndex)
	          self.container:RefreshActiveUI()
	          self.container.secretaryTips = self.container.secretaryTips - 1
	          g_homeInfo.enableGainDailyActiveRewardNum = g_homeInfo.enableGainDailyActiveRewardNum - 1--add by zheng.che @ 2014-10-29 解决问题SK-3792
	          self.container:resetTipUI()
	        end
	        
	        local aRewardPanel = RewardReviewPanel:create( self, {rewardList = evt, rewardTitle = Localization:getInstance():getText("activity_newyear_rewardTitle"), callback = onGet} )
	        self:addChild(aRewardPanel)
	        aRewardPanel:scaleIn()

	      end

	      local function activeRewardSucceedResponse( evt )
	        -- body 获取奖励成功，更新数据
	        print(self.touchItemIndex.."activeRewardSucceedResponse:"..table.serialize(evt.data))
	        -- fatherContainer:afterRewardSuccessed(self.touchItemIndex)
	        doPlayAfterRewardSucceed(evt.data.rewards)
	      end

	      local function activeRewardFailedResponse( evt )
	        --fatherContainer:afterRewardSuccessed(self.touchItemIndex)
	        -- body
	        if ( evt.data.retCode == 710516) then
	        	NewPackageFullPanel:show()
	          -- CanonMessageBox:Show( getTextByKey("shop_inventoryFull"), ShowMessageType.ShowText, ShowButtonType.ID_OK, 40 ) --"您的背包已满，请清理背包。"
	        elseif (evt.data.retCode == 716254) then
	          self.container:refreshWhenAcrossTheDay()
	          if (TimeUtil.whetherSwitchDay(self.currentTime)) then
	            self.currentTime = TimeUtil.getServerTimeSeconds()
	          end
	          PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale)
		      self.container:setTableViewsEnabled(true)
		      self.container.targetInfoPanel = nil
	        end
	      end

	      if inArea(posInCell.x, posInCell.y, itemRect) then
	        if( self.container.isAcrossDay == true) then
	          self.container:refreshWhenAcrossTheDay()
	          PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale)
    		  self.container:setTableViewsEnabled(true)
    		  self.container.targetInfoPanel = nil
	          do return end
	        end
	        if BagCalcManager.isFull() then
		      NewPackageFullPanel:show()
		      return 
		    end
	        local params = {activeRewardId = evt.data + 1}
	        local request = ActiveRewardRequest.new( params, rpc.SendingPriority.kHigh )
	        request:addEventListener( RequestNotifyEnum.ActiveRewardSucceed, activeRewardSucceedResponse )
	        request:addEventListener( RequestNotifyEnum.ActiveRewardFailed, activeRewardFailedResponse )
	        request:start()
	      end
	  end

    end

	
	  local list_height = 662.66  

	  local renderer = RewardCellRenderer.new(636.3, cell_height)
	  local list = TableView:create(renderer, 646.75, list_height, TABLEVIEW_CELL_TAG,TAG_BUTTON_ABLE, CCScale9Sprite:create("pic/scroll.png"), CCScale9Sprite:create("pic/scroll.png"))

	  list:addEventListener(DisplayEvents.kTouchItem, onListItemTouch)
	  list:setPosition(ccp(45, 284))
	  return list

end

function DailyActivityRewardPanel:dispose()
	UiStackManager_EventDispatcher:removeEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged)
  	DailyActivityRewardPanel.super.dispose(self)
end