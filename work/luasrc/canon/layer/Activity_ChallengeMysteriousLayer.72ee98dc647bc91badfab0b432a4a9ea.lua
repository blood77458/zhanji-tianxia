require "hecore.display.CocosObject"
require "hecore.display.Director"
require "canon.customUI.CanonGoodIcon"
require "canon.models.PackageModel"
require "canon.customUI.CdLabelComponent"
require "canon.data.AccountPlatformLogin"
require "canon.features.mesterious.Mesterious"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

Activity_ChallengeMysteriousLayer = class(Layer)

local function onPassDay(evt)
  local self = evt.context

  self:refreshSelf()
end

function Activity_ChallengeMysteriousLayer:ctor()
  self.container = nil
end

function Activity_ChallengeMysteriousLayer:create( container , extraArgs)
  self.container = container
  self.extraArgs = extraArgs
  local s = Activity_ChallengeMysteriousLayer.new()
  s:initLayer()
  return s
end

function Activity_ChallengeMysteriousLayer:enable(curTimeStamp)

    -- local isEnable = MaintenanceManager.isActivityOpen("activityInvitationCode")
    return true
    -- return true
end 

function Activity_ChallengeMysteriousLayer:panelDismiss()
    self.container.targetInfoPanel = nil
end

function Activity_ChallengeMysteriousLayer:dispose()
	NotificationManager:removeEventListener(PassDayManager.PASS_DAY, onPassDay, self)
	Activity_ChallengeMysteriousLayer.super.dispose(self)
end

function Activity_ChallengeMysteriousLayer:initLayer()
    Activity_ChallengeMysteriousLayer.super.initLayer(self)

    self.builder = LayoutBuilder:createWithContentsOfFile("scene/launch_activity_02.json")
    self.builder.useArtLabelTTF = true
	self.mainUI = self.builder:build("launch_activity_mysteriousTraining")
	self:addChild(self.mainUI)

	-- self.panelUI = self.builder:build("table_activity_mysteriousTraining_list")
	-- self:addChild(self.panelUI)
	-- self.panelUI:setVisible(false)

	self.tableView = self:createTableView(MesteriousManager.getMesteriousData())
	self.mainUI:addChild(self.tableView)


	NotificationManager:addEventListener(PassDayManager.PASS_DAY, onPassDay, self)
end

function Activity_ChallengeMysteriousLayer:createTableView(data)
	local cellTag = 1024
	local buttonTag = {}

	local tableViewRenderer = class(TableViewRenderer)

	local const_Name = {
	"wei",
	"shu",
	"wu",
	"qun",
	"equipment"
}

  	function tableViewRenderer:ctor(width, height, creater)
		self.list = data or {}
		self.creater = creater
	end
	function tableViewRenderer:buildCell(container)
		local builder = LayoutBuilder:createWithContentsOfFile("scene/launch_activity_02.json")
		builder.useArtLabelTTF = true
		local aCell = builder:build("list_mysteriousTraining")
		container:addChild(aCell)
		aCell:setTag(cellTag)

		local aLeaderLevelLabel = aCell:getChildByName("txt_mT_01")
		aLeaderLevelLabel = aLeaderLevelLabel:getChildByName("txt")
		--描边
		aLeaderLevelLabel:setColor(ccc3(0, 0, 0))
		aLeaderLevelLabel:setAroundColor(ccc3(255, 255, 255))

        --扫描cell并自动添加tag
        self:addTags(aCell)
	end

	function tableViewRenderer:setData( rawCocosObj, index )
		local aCell = self:getChildByTag(rawCocosObj, cellTag)
		local aData = self.list[index + 1]

		-- <bean desc="跨服gvg某军团积分信息">
		-- 	<property code="unionId" type="int" desc="军团id" />
		-- 	<property code="unionName" type="String" desc="军团名" />
		-- 	<property code="score" type="int" desc="军团当前积分" />
		-- 	<property code="rank" type="int" desc="当前积分排名" />
		-- </bean>
		--显示文本
		-- self:setTxtByNames(aCell, "txt_guild_pk_19/txt", CrossUnionPkUtils.getRankStr(aData.rank))--排名
		-- self:setTxtByNames(aCell, "txt_1/txt", CrossArenaUtils.getUnionNameStrById(aData.unionName))--[军团名]
		-- self:setTxtByNames(aCell, "txt_2/txt", CrossArenaUtils.getUnionNameStrById(aData.unionName))--[军团名]
		-- self:setTxtByNames(aCell, "txt_guild_pk_20/txt", aData.score)--积分

		-- --选择显示颜色
		-- if aData.rank <= 4 then
		-- 	--前四 晋级 黄色
		-- 	self:getChildByNames(aCell, "txt_1"):setVisible(true)
		-- 	self:getChildByNames(aCell, "txt_2"):setVisible(false)
		-- else
		-- 	--未晋级 白色
		-- 	self:getChildByNames(aCell, "txt_1"):setVisible(false)
		-- 	self:getChildByNames(aCell, "txt_2"):setVisible(true)
		-- end
		for k,v in pairs(const_Name) do
			self:getChildByNames(aCell, "bg_mysteriousTraining_"..const_Name[k]):setVisible(false)
			self:getChildByNames(aCell, "bg_mysteriousTraining_"..const_Name[k].."_g"):setVisible(false)
		end
		for k,v in pairs(const_Name) do
			self:getChildByNames(aCell, "bg_mysteriousTraining_"..const_Name[k]):setVisible(k == (index + 1))
			self:getChildByNames(aCell, "icon_exchangeDaily_"..const_Name[k]):setVisible(k == (index + 1))
		end

		if not aData or tonumber(MesteriousManager.getMysteriousChallengeTimesById( index + 1)) == 0  then
			self:getChildByNames(aCell, "bg_mysteriousTraining_"..const_Name[index + 1]):setVisible(false)
			self:getChildByNames(aCell, "bg_mysteriousTraining_"..const_Name[index + 1].."_g"):setVisible(true)

		else
			self:getChildByNames(aCell, "bg_mysteriousTraining_"..const_Name[index + 1]):setVisible(true)
			self:getChildByNames(aCell, "bg_mysteriousTraining_"..const_Name[index + 1].."_g"):setVisible(false)

			
		end

		-- self:getChildByNames(aCell, "txt_mT_01/txt"):setAroundColor(ccc3(255, 255, 255))
		-- self:getChildByNames(aCell, "txt_mT_01/txt"):setColor(ccc3(0, 0, 0))

		self:setTxtByNames(aCell , "txt_mT_01/txt" , getTextByKey("Mysterious_tips"..(index + 1)))
		self:setTxtByNames(aCell, "txt_mT_02/txt", getTextByKey("stage_times" , {challengeNum = ""}))--积分
		self:setTxtByNames(aCell , "txt_mT_03/txt" , MesteriousManager.getMysteriousChallengeTimesById( index + 1))
		self:setTxtByNames(aCell , "txt_mT_04/txt" , MesteriousManager.getMysteriousChallengeTimesById( index + 1))
		self:setTxtByNames(aCell , "txt_mT_05/txt" , "/" .. MesteriousManager.getMysteriousConfig().eventLimit)

		if not aData then
			self:getChildByNames(aCell, "txt_mT_02/txt"):setVisible(false)
			self:getChildByNames(aCell, "txt_mT_03/txt"):setVisible(false)
			self:getChildByNames(aCell, "txt_mT_04/txt"):setVisible(false)
			self:getChildByNames(aCell, "txt_mT_05/txt"):setVisible(false)
		else
			self:getChildByNames(aCell, "txt_mT_02/txt"):setVisible(true)
			self:getChildByNames(aCell, "txt_mT_03/txt"):setVisible(true)
			self:getChildByNames(aCell, "txt_mT_04/txt"):setVisible(true)
			self:getChildByNames(aCell, "txt_mT_05/txt"):setVisible(true)
			if tonumber(MesteriousManager.getMysteriousChallengeTimesById( index + 1)) == 0 then
				self:getChildByNames(aCell, "txt_mT_03/txt"):setVisible(false)
				self:getChildByNames(aCell, "txt_mT_04/txt"):setVisible(true)
			else
				self:getChildByNames(aCell, "txt_mT_03/txt"):setVisible(true)
				self:getChildByNames(aCell, "txt_mT_04/txt"):setVisible(false)
			end
		end


	end
	local function onListItemTouch( evt )
		local aIndex = evt.data + 1
		local newCell = self.tableView:cellAtIndex(aIndex - 1)
		local aCell = newCell:getChildByTag(cellTag)
		local posInCell = newCell:convertToNodeSpace(evt.globalPosition)
		local aData = data[aIndex]

		MesteriousManager.setChanllengeCountry( aIndex )

		local btnDisplay = self.renderer:getChildByNames(aCell, "bg_mysteriousTraining_wei")
		if aData and not (tonumber(MesteriousManager.getMysteriousChallengeTimesById( aIndex)) == 0) and isHittedDisplay(posInCell, btnDisplay) then
			--点击按钮
			local scene = Director:mgr():run()
			scene.targetInfoPanel = MesteriousChanllengePanel:create(self)
		    PopoutManager:sharedManager():popout(scene.targetInfoPanel, kPopoutDir.kScale, true, false , scene)
		end
	end
	self.mainUI:getChildByName("table_activity_mysteriousTraining_list"):setVisible(false)
	local tableViewSizes = getTableViewSizes(self.mainUI:getChildByName("table_activity_mysteriousTraining_list"))
	tableViewSizes.item_width = tableViewSizes.item_width--因为只有文本框 导出后文字消失导致长度不够 补充最右边文本框宽度
	tableViewSizes.table_width = tableViewSizes.table_width--因为只有文本框 导出后文字消失导致长度不够 补充最右边文本框宽度
	tableViewSizes.table_height = tableViewSizes.table_height--因为只有文本框 导出后文字消失导致高度不够 补充一行高度

	self.renderer = tableViewRenderer.new(tableViewSizes.item_width, tableViewSizes.item_height,self)

	--添加tag
    local builder = LayoutBuilder:createWithContentsOfFile("scene/launch_activity_02.json")
    local aCell = builder:build("list_mysteriousTraining")
    self.renderer:scanTags(aCell)
    -- table.insert(buttonTag, self.renderer:getTagByLayerName("icon_VV"))--按钮

	local aTableView = TableView:create(self.renderer, tableViewSizes.table_width, tableViewSizes.table_height, cellTag, buttonTag, CCScale9Sprite:create("pic/scroll.png"), CCScale9Sprite:create("pic/scroll.png"))
	aTableView:setPosition(ccp(tableViewSizes.table_posX, tableViewSizes.table_posY))
	aTableView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch , self)

	return aTableView
end

function Activity_ChallengeMysteriousLayer:refreshSelf()
	local tableOffset = nil
	if self.tableView then
		tableOffset = self.tableView:getContentOffset()
		self.tableView:removeFromParentAndCleanup(true)
		self.tableView = nil
	end

	self.tableView = self:createTableView(MesteriousManager.getMesteriousData())
	self.mainUI:addChild(self.tableView)

	if tableOffset then
		self.tableView:setContentOffset(tableOffset)
	end
end

function Activity_ChallengeMysteriousLayer:setTableViewsEnabled(v)
	self.tableView:setTouchEnabled(v)
end

function Activity_ChallengeMysteriousLayer.getTipNum()
  if not Activity_ChallengeMysteriousLayer.enable() then
    return 0
  end
  return 0
end


function Activity_ChallengeMysteriousLayer:showNotEnoughEventPointPanel()
  local hasProp, eventPointPropList = BagCalcManager.getEventPointPropList()
  if hasProp then
    self:showUseEventPointProptPanel(eventPointPropList)
  else
    self:showEventPointLimitPanel()
  end
end

function Activity_ChallengeMysteriousLayer:showUseEventPointProptPanel(eventPointPropList)
  local function callback(aEventPointPropId)
    self:recoveryEventPoint(aEventPointPropId)
  end
  local aPanel = EEPSupplyPanel:create(self.container, eventPointPropList, callback)
  self.container:addChild(aPanel)
  aPanel:scaleIn()
end

function Activity_ChallengeMysteriousLayer:recoveryEventPoint(aEventPointPropId)
  local function usePropSucceed(event)
    local aReward = {
      {	itemType = ResourceEnum.PROP, metaId = aEventPointPropId, amount = -1
      },
      {	itemType = ResourceEnum.EVENTPOINT,
        amount = event.data.rewards[1].amount,
      }
    }
    RewardManager:getReward(aReward)
    CanonPlayEffect("music/sfx_engly_lvup.wav")
    SuspensionLabel:showContent(self, getTextByKey("propInfo_eventPointReplenished"))
  end
  
  local function usePropFailed(event)
    if event.data.retCode == 712309 then
      local function closeCanonMessageBox()
      end
      self.targetInfoPanel = CanonMessageBox:Show(getTextByKey("propInfo_eventPointFull"), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
    elseif event.data.retCode == 712301 then
      local function closeCanonMessageBox()
      end
      local aPropMetaConfig = MetaManager.prop_meta[aEventPointPropId]
      self.targetInfoPanel = CanonMessageBox:Show(getTextByKey("popup_noProp", {propname = Localization:getInstance():getText(aPropMetaConfig.name)}), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
    end
  end
  
  local request = UsePropRequest.new( {propId = aEventPointPropId, amount = 1}, rpc.SendingPriority.kHigh )
	request:addEventListener( RequestNotifyEnum.UsePropSucceed, usePropSucceed )
	request:addEventListener( RequestNotifyEnum.UsePropFailed, usePropFailed )
	request:start()
end

function Activity_ChallengeMysteriousLayer:showEventPointLimitPanel()
  local function callback()
  end
  local aPanel = EENPSupplyPanel:create(self.container, {supplyType = EESupplyTypeEnum.EventPoint, callback = callback})
  self.container:addChild(aPanel)
  aPanel:scaleIn()
end
