--------------------------------------------------------------------------------
-- MedalShopScene.lua -- 勋章商店
-- author: l1ghtsaber
-- date: 2015-8-27
--------------------------------------------------------------------------------

require "canon.panel.GetRewardInfoPanel"
require "canon.manager.BagCalcManager"
require "canon.request.GetMedalShopListRequest"
require "canon.request.ExchangeMedalShopRequest"
require "canon.request.RefreshMedalShopRequest"

MedalShopScene = class(BaseUIScene)
local visibleSize = CCDirector:sharedDirector():getVisibleSize();

function MedalShopScene:ctor()
	self.title = getTextByKey("activity_daily_shopicon")
	self.tableUI = nil
	self.mainUI = nil
	self.waitRequest = false
end

function MedalShopScene:create(argv)
    if argv then 
        self.argv = argv 
    else
        self.argv = {enterScene=nil,returnScene=nil,params={}}
    end
    local scene = MedalShopScene.new()
    self.medalList = self.argv.params.medalList
    scene:initScene()
    return scene
end

function MedalShopScene:back()
    if self.argv.returnScene ~= nil then  
    else
		local function getDailyActiveInfoSucceedResponse( evt )
		-- body
		-- print("getDailyActiveInfoSucceedResponse:"..tostringRich(evt.data.dailyActiveInfo))
		DailyTargetScene.tipNum = (g_homeInfo and g_homeInfo.enableGainDailyAchieveRewardNum or 0)
		local argv = {enterScene=nil,returnScene=nil,params={data = evt.data , secretaryTips = (g_homeInfo and g_homeInfo.enableGainDailyActiveRewardNum or 0)}}
		self:replaceScene(SecretaryScene,argv);
		end

		local function getDailyActiveInfoFailedResponse( evt )
			print(table.serialize(evt.data))
			-- body
		end
	    local request = GetDailyActiveInfoRequest.new( {}, rpc.SendingPriority.kHigh )
		request:addEventListener( RequestNotifyEnum.GetDailyActiveInfoSucceed, getDailyActiveInfoSucceedResponse )
		request:addEventListener( RequestNotifyEnum.GetDailyActiveInfoFailed, getDailyActiveInfoFailedResponse )
		request:start()
    end
end

local function getItemServerInfoById(shopId)--获取商品信息
	if not itemServerInfoTable[shopId] then
		local shopData = {}
		shopData.isNew = true;
		shopData.lifeBuyTimes = 0;
		for k , data in pairs(lifeLimitDataTable) do
			if data.goodMetaId == shopId then
				shopData.lifeBuyTimes = data.lifePurchaseTimes
				break;
			end
		end
		shopData.dailyBuyTimes = 0;
		for k , data in pairs(dailyLimitDataTable) do
			if data.goodMetaId == shopId then
				shopData.dailyBuyTimes = data.dailyPurchaseTimes
				break;
			end
		end
		
		itemServerInfoTable[shopId] = shopData
	end
	return itemServerInfoTable[shopId]
end

local TAG_TXT_MEDAL = 1001
local TAG_TXT_TIMES = 1002
local TAG_BUTTON_BUY = 1003
local TAG_ICON_SHOP = 1004
local TAG_TXT_NAME = 1005
local TAG_TXT_DES = 1006
local TAG_PIC_SHOP = 1007

local cellTag = -1001
local cell_height = 200.76

function MedalShopScene:createTableView(data,argv)
	local MedalRenderer = class(TableViewRenderer)
	function MedalRenderer:ctor(width,height)
		self.list = data
		local builder = LayoutBuilder:createWithContentsOfFile("scene/daily_activity.json")
		builder.useArtLabelTTF = true
		self.builder = builder
	end
	
	function MedalRenderer:buildCell(container)
		local cell = self.builder:build("list_goods1") 
		cell:setPosition(ccp(0,0))
		cell:getChildByName("txt_spirit"):setTag(TAG_TXT_MEDAL)
		cell:getChildByName("txt_spirit"):getChildByName("txt"):setTag(TAG_TXT_MEDAL)
		cell:getChildByName("txt_shopmystery2"):setTag(TAG_TXT_TIMES)
		cell:getChildByName("txt_shopmystery2"):getChildByName("txt"):setTag(TAG_TXT_TIMES)
		cell:getChildByName("btn_guildoption"):setTag(TAG_BUTTON_BUY)
		-- cell:getChildByName("normal_card_small"):setVisible(false)
		cell:getChildByName("normal_card_small"):setTag(TAG_ICON_SHOP)
		cell:getChildByName("txt_tradename"):setTag(TAG_TXT_NAME)
		cell:getChildByName("txt_tradename"):getChildByName("txt"):setTag(TAG_TXT_NAME)
		cell:getChildByName("flower_tab_bg2_r"):setTag(TAG_TXT_DES)
		cell:getChildByName("flower_tab_bg2_r"):getChildByName("txt"):setTag(TAG_TXT_DES)
		cell:getChildByName("txt_shopmystery1"):getChildByName("txt"):setString(getTextByKey("activity_daily_shoptext3"))
		cell:getChildByName("txt_shopmystery3"):getChildByName("txt"):setString(getTextByKey("activity_daily_shoptext4"))
		cell:getChildByName("btn_guildoption"):getChildByName("txt"):setString(getTextByKey("activity_daily_shoptext5"))
		cell:getChildByName("btn_guildoption_grey"):getChildByName("txt"):setString(getTextByKey("activity_daily_shoptext6"))
        cell:getChildByName("icon_spirit"):setVisible(false)
		cell:getChildByName("icon_gold"):setVisible(false)
		cell:setTag(cellTag)
		container:addChild(cell)
	end 

	local function setTextByTag(cell, tag, str)
		local txt = cell:getChildByTag(tag):getChildByTag(tag)
		setNodeText(txt, str)
	end
	
	local function setNodeVisibleByTag(cell, tag, visible)
		cell:getChildByTag(tag):setVisible(visible)
	end
		
	function MedalRenderer:setData(rawCocosObj,index)
		local cell = self:getChildByTag(rawCocosObj, cellTag)

		local medalInfo = data[index + 1]

		if cell:getChildByTag(TAG_PIC_SHOP) then
			cell:removeChildByTag(TAG_PIC_SHOP, true)
		end		
        local itemIcon = CanonGoodIcon.createGoodIcon(
        	medalInfo.itemType, medalInfo.itemId, medalInfo.itemAmount, 
        	{sourceDisplay = cell:getChildByTag(TAG_ICON_SHOP) , showInCenter = true}
        )
        itemIcon:setTag(TAG_PIC_SHOP)
        cell:addChild(itemIcon.refCocosObj,cell:getChildByTag(TAG_ICON_SHOP):getZOrder())
        itemIcon:dispose()

        setTextByTag(
        	cell ,
        	TAG_TXT_NAME , 
        	CanonGoodIcon.getGoodName(medalInfo.itemType, medalInfo.itemId, medalInfo.itemAmount, {withoutAmount = false})
        )

        setTextByTag(cell ,TAG_TXT_DES , CanonGoodIcon.getGoodDescribe(medalInfo.itemType, medalInfo.itemId))
		
		setTextByTag(cell ,TAG_TXT_MEDAL , medalInfo.moneyAmount)
		setTextByTag(cell ,TAG_TXT_TIMES , medalInfo.boughtTime)
		setNodeVisibleByTag(cell ,TAG_BUTTON_BUY , medalInfo.boughtTime > 0)
	end 
	
	local function inArea(posX, posY, rect)
		if posX >= rect.x and posX <= rect.x + rect.width and posY >= rect.y and posY <= rect.y + rect.height then
			return true
		end
		return false
	end	

	local function onListItemTouch( evt ) 
		local selectedCell = self.tableUI:cellAtIndex(evt.data):getChildByTag(cellTag)
		local curTabIndex = evt.context
		self._data = data[evt.data + 1]

		local function afterExchangeMedalShop(evt)
			self.waitRequest = false;
			SuspensionLabel:showContent(self, getTextByKey("activity_daily_shoptext10"))

			RewardManager:getReward(evt.data.rewards)

			local gameData = DataManager.getGameInitData()
			local nowMedal = DataManager.getMedalNum()
			local tempMedalNum = nowMedal - self._data.moneyAmount
			self.mainUI:getChildByName("txt_saily_activity"):getChildByName("txt"):setString(getTextByKey("activity_daily_shoptext2")..tempMedalNum)
			DataManager.setMedalNum(nowMedal - self._data.moneyAmount)

			self._data.boughtTime = self._data.boughtTime - 1

			self:refreshTable(true)
		end
		
		local function failedResponse(evt)
			self.waitRequest = false
			if evt.data == 710513 then --gold not enough
				local aPanel = AssistantMessageBoxPanel:create( self, AsMessageBoxType.addCoin )
				self:addChild(aPanel)
				aPanel:scaleIn()
			elseif evt.data == 713001 then --daily purchase limit
				local aContent = Localization:getInstance():getText("shop_limitReached")
				local function closeCanonMessageBox()
				end
				self.targetInfoPanel = CanonMessageBox:Show(aContent, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
			elseif evt.data == 713002 then --life purchase limit
				local aContent = Localization:getInstance():getText("shop_limitReached")
				local function closeCanonMessageBox()
				end
				self.targetInfoPanel = CanonMessageBox:Show(aContent, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
			elseif evt.data == 712906 then --vip level not enough
				local aContent = Localization:getInstance():getText("shop_vipLevelInsufficient")
				local function closeCanonMessageBox()
				end
				self.targetInfoPanel = CanonMessageBox:Show(aContent, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
			elseif evt.data == 710516 then --package full
				local aContent = Localization:getInstance():getText("shop_inventoryFull")
				local function closeCanonMessageBox()
				end
				self.targetInfoPanel = NewPackageFullPanel:show()
			else
				CanonMessageBox:showCommUnHandleErrorBox(evt.data)
			end
		end
		
		local function sendBuyGoodsReuqest()
			if DataManager.getMedalNum() < self._data.moneyAmount then
				SuspensionLabel:showContent(self, getTextByKey("activity_daily_shoptext9"))
				do return end
			end
							
			local usedGridNum = BagCalcManager.calcUsedGridNum()
			local totalGridNum = BagCalcManager.calcTotalGridNum()
			if BagCalcManager.isFull() then
				local aContent = Localization:getInstance():getText("shop_inventoryFull")
				local function closeCanonMessageBox()
				end
				self.targetInfoPanel = NewPackageFullPanel:show()
				do return end
			end
						
			if self.waitRequest then
				do return end
			end
							
			self.waitRequest = true
			ExchangeMedalShopRequest.sendRequestDefalut(self._data.id, self._data.listId, afterExchangeMedalShop, failedResponse)
		end

		local posInCell = selectedCell:convertToNodeSpace(evt.globalPosition)
		local itemPosX, itemPosY = selectedCell:getChildByTag(TAG_BUTTON_BUY):getPosition()
		local itemRect = {}
		itemRect.x = itemPosX
		itemRect.y = itemPosY - 66
		itemRect.width = 168
		itemRect.height = 66
		if inArea(posInCell.x, posInCell.y, itemRect) then
			if selectedCell:getChildByTag(TAG_BUTTON_BUY) then
				if selectedCell:getChildByTag(TAG_BUTTON_BUY):isVisible() then
					sendBuyGoodsReuqest()
				end
			end
			do return end
		end
	end
	
	local buttonTag = {}
	table.insert(buttonTag, TAG_BUTTON_BUY)
	local result = {
		item_width = 690.29,
		table_width = 690.29,
		table_height = 636.99,
		table_posX = 14.30,
		table_posY = 203.75
	}
  	local renderer = MedalRenderer.new(result.item_width, cell_height)
  	local list = TableView:create(renderer, result.table_width, result.table_height, cellTag, buttonTag)

    list:addEventListener(DisplayEvents.kTouchItem, onListItemTouch )
  	list:setPosition(ccp(result.table_posX, result.table_posY))

    return list
end 

function MedalShopScene:refreshTable(keepOffset)--刷新商品或者充值的列表
	if keepOffset then
		local tableOffset = self.tableUI:getContentOffset()
		self.tableUI:reloadData()
		local minOffset = self.tableUI:getViewSize().height - cell_height * table.getn(self.medalList)
		if tableOffset.y > 0 then
			tableOffset.y = 0
		end
		if tableOffset.y < minOffset then
			tableOffset.y = minOffset
		end
		self.tableUI:setContentOffset(tableOffset, true)
	else
		self.tableUI:reloadData()
	end
end

function MedalShopScene:refreshShopAuto()
	local function afterGetMedalShopList(evt)
		self.waitRequest = false
        if (type(self) == "table") and self.MedalShopSceneExit then
			return
        end
        if type(evt.data.itemIdList) == "table" then 
	        local maxLen = #self.medalList > #evt.data.itemIdList and #self.medalList or #evt.data.itemIdList
	        for i = 1,maxLen do
	        	self.medalList[i] = evt.data.itemIdList[i]
	        end
	        self:refreshTable()
	    end 
	end
	local function afterFailed()
		self.waitRequest = false
	end
	self.waitRequest = true
	GetMedalShopListRequest.sendRequestDefalut(afterGetMedalShopList,afterFailed)
end 

function MedalShopScene:refreshUpdateTime()
	local nowTime = TimeUtil.getServerTimeSeconds() - 6--todo 改时间
	local newRefreshInterval = string.split(MetaManager.getGameSettingConfig().dailyShopConfig.newRefreshInterval, '|')
	local todayTimestamp = TimeUtil.getTodayTimestampBy(0,0,0)
	local currentToatalTimestamp = todayTimestamp + newRefreshInterval[1]
	local fourHour = 0
	for i=1,#newRefreshInterval do
		if nowTime < tonumber(currentToatalTimestamp) then
			fourHour = tonumber(newRefreshInterval[i])
			break
		else
			currentToatalTimestamp = currentToatalTimestamp + newRefreshInterval[i + 1]
		end
	end
	local leftTime = currentToatalTimestamp - nowTime
	leftTime = leftTime % 43200
	if leftTime >= 0 then 
		local timeString = string.format("%02d:%02d:%02d", math.floor(leftTime/3600), math.floor(leftTime/60)%60, leftTime%60)
		self.mainUI:getChildByName("txt_shopmystery5"):getChildByName("txt"):setString(timeString)
	end
	if (leftTime == 0) then 
		self:refreshShopAuto()
	end
end

function MedalShopScene:setEnableUserTouch(isEnable)
    self:setTableViewsEnabled( isEnable )
    self.mainUI:setTouchEnabled(isEnable)
end 

function MedalShopScene:panelDismiss()
    self:setEnableUserTouch(true)
    self.targetInfoPanel = nil
end

function MedalShopScene:onInit()
	BaseUIScene.initBackGround(self)
	
	self.builder = LayoutBuilder:createWithContentsOfFile("scene/daily_activity.json")
	self.mainUI = self.builder:build("shopMedal")
    self:addChild(self.mainUI)

	self.mainUI:getChildByName("txt_daily_activity3"):getChildByName("txt"):setString(getTextByKey("activity_daily_shoptext1"))
	self.mainUI:getChildByName("txt_shopmystery4"):getChildByName("txt"):setString(getTextByKey("activity_daily_shoptext7"))
	self.mainUI:getChildByName("txt_saily_activity"):getChildByName("txt"):setString(getTextByKey("activity_daily_shoptext2")..DataManager.getMedalNum())
	
	local function onClickUpdate()
		if self.waitRequest then
			return 
		end
		local nowCoin = CalculationManager.calcComplex_getGemsNow()
		local cost = MetaManager.getGameSettingConfig().dailyShopConfig.refreshGoldCost
		if nowCoin < cost then 
			local aPanel = AssistantMessageBoxPanel:create( self, AsMessageBoxType.addCoin )
			self:addChild(aPanel)
			aPanel:scaleIn()
			return
		end
		local function afterRefreshMedal(evt)
			self.waitRequest = false
	        if (type(self) == "table") and self.MedalShopSceneExit then
				return
	        end

	 		local requisite = {
				amount = tostring(-cost),
				metaId = 0,
				itemType = 2,
				id = 0
			}
			RewardManager:getReward({requisite})

	        --self.medalList = evt.data.itemIdList
	        local maxLen = #self.medalList > #evt.data.itemIdList and #self.medalList or #evt.data.itemIdList
	        for i = 1,maxLen do
	        	self.medalList[i] = evt.data.itemIdList[i]
	        end

	        self:refreshTable()
		end
		local function afterFailed()
			self.waitRequest = false
		end

		self.waitRequest = true
		RefreshMedalShopRequest.sendRequestDefalut(afterRefreshMedal,afterFailed)
	end
	self.mainUI:getChildByName("btn_refresh"):getChildByName("txt_1"):setString(MetaManager.getGameSettingConfig().dailyShopConfig.refreshGoldCost..getTextByKey("activity_daily_shoptext8"))
	local updateBtn = Button:create(self.mainUI:getChildByName("btn_refresh"))
	updateBtn:addEventListener( Events.kStart, onClickUpdate, self )  

	self.mainUI:getChildByName("txt_saily_activity8"):setVisible(false)
	local zOrder = self.mainUI:getChildByName("txt_saily_activity8"):getZOrder()

	self:refreshUpdateTime()
	self.tableUI = self:createTableView(self.medalList)
    self.mainUI:addChildAt(self.tableUI , zOrder)
    self:addChild(self.mainUI)

	BaseUIScene.onInit(self)
end

function MedalShopScene:doEnterAnimation()
  self:preEnterAnimation()
  self:startEnterAnimation()
end

function MedalShopScene:preEnterAnimation()
  BaseUIScene.preEnterAnimation(self)
end

function MedalShopScene:startEnterAnimation()
  BaseUIScene.startEnterAnimation(self)
  local function enterMov()
        self:nodeAnimationFinished()
        self:setEnableUserTouch(true)
        self.targetInfoPanel = nil
    end 
    local array = CCArray:create()
    self.mainUI:setPositionX(-visibleSize.width)

	array:addObject(CCMoveBy:create(0.3, ccp(visibleSize.width, 0)))
	array:addObject(CCDelayTime:create(0.3))
	array:addObject(CCCallFunc:create(enterMov))
	self:setEnableUserTouch(false)
	self.mainUI:runAction(CCSequence:create(array)) 

	local function refresh()
		self:refreshUpdateTime()
	end
	self.scheduledRefreshHandle = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(refresh, 1, false)
end

function MedalShopScene:sufEnterAnimation()
  BaseUIScene.sufEnterAnimation(self)
end

function MedalShopScene:doExitAnimation()
  self:preExitAnimation()
  self:startExitAnimation()
end

function MedalShopScene:preExitAnimation()
  BaseUIScene.preExitAnimation(self)
  self.MedalShopSceneExit = true
end

function MedalShopScene:startExitAnimation()
    BaseUIScene.startExitAnimation(self)
    self:setEnableUserTouch(false)
    local function exitActionFinished()
        self:nodeAnimationFinished()
    end
    local array = CCArray:create()
	if #self.medalList > 0 then
		array:addObject(CCDelayTime:create(0.3))
	end
	array:addObject(CCMoveBy:create(0.3, ccp(-visibleSize.width-50, 0)))
	array:addObject(CCCallFunc:create(exitActionFinished))
	self.mainUI:runAction(CCSequence:create(array))
	--self.tableUI:runAction(CCMoveBy:create(0.5, ccp(-visibleSize.width, 0)))
	local aDuration
	if #self.medalList == 1 then
	    aDuration = 0.3 
	else
	    aDuration = 0.3  / (#self.medalList - 1)
	end
    for i = 1, #self.medalList do
        local aCell = self.tableUI:cellAtIndex(i - 1)
        if aCell ~= nil then
            local arr = CCArray:create()
            arr:addObject(CCDelayTime:create(aDuration * (i - 1)))
            arr:addObject(CCMoveBy:create(0.2, ccp(-visibleSize.width-50, 0)))
            aCell:runAction(CCSequence:create(arr))
        end 
    end

	if self.scheduledRefreshHandle then
		CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.scheduledRefreshHandle)
		self.scheduledRefreshHandle = nil
	end
end

function MedalShopScene:sufExitAnimation()
  BaseUIScene.sufExitAnimation(self)
end

function MedalShopScene:dispose()
	if self.scheduledRefreshHandle then
		CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.scheduledRefreshHandle)
		self.scheduledRefreshHandle = nil
	end
	MedalShopScene.super.dispose(self)
end


function MedalShopScene:setTableViewsEnabled( v )
	if not self.touchDisableSetTimes then
		self.touchDisableSetTimes = 0
	end
	if (v) then
		self.touchDisableSetTimes = self.touchDisableSetTimes - 1
		if (self.touchDisableSetTimes <= 0) then
			self.touchDisableSetTimes = 0
			if self.tableUI then
				self.tableUI:setTouchEnabled(v)
			end
		end
	else
		self.touchDisableSetTimes = self.touchDisableSetTimes + 1
		if self.tableUI then
			self.tableUI:setTouchEnabled(v)
		end
	end 
end 
