require "hecore.display.CocosObject"
require "hecore.display.Director"
require "canon.customUI.CanonGoodIcon"
require "canon.manager.BagCalcManager"
require "hecore.ui.TableView"
require "canon.models.PackageModel"
require "canon.request.ExchangeSecretShopRequest"
require "canon.request.RefreshSecretShopRequest"
require "canon.customUI.CdLabelComponent"
require "canon.scene.CardRebirthScene"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

Activity_MysteryShopLayer = class(Layer)

function Activity_MysteryShopLayer:ctor()
  self.container = nil
end

function Activity_MysteryShopLayer:create( container , extraArgs)
  self.container = container
  self.extraArgs = extraArgs
  self.version = self.extraArgs.version
  local s = Activity_MysteryShopLayer.new()
  s:initLayer()
  return s
end

function Activity_MysteryShopLayer:enable(curTimeStamp)

    --local isEnable = MaintenanceManager.isActivityOpen("cowStage")
    --return isEnable
    return true
end 

function Activity_MysteryShopLayer:panelDismiss()
    self.container.targetInfoPanel = nil
end

function Activity_MysteryShopLayer:dispose()

	if self.cdLabelComponent then
		self.cdLabelComponent:dispose()
		self.cdLabelComponent = nil
	end
	Activity_MysteryShopLayer.super.dispose(self)
end

function Activity_MysteryShopLayer:initLayer()
    Activity_MysteryShopLayer.super.initLayer(self)
    -- print("消耗金币"..MetaManager.getGameSettingConfig().secretShopConfig.refreshGoldCost)

    self.builder = LayoutBuilder:createWithContentsOfFile("scene/shopmystery.json")
    self.builder.useArtLabelTTF = true
	self.mainUI = self.builder:build("shopmystery")
	self:addChild(self.mainUI)

	local gameInitData = DataManager.getGameInitData()
    if(gameInitData.sharkUserSecretShop) then
    	gameInitData.sharkUserSecretShop.ifListFresh = false
		DataManager.setGameInitData(gameInitData)
    end

	-- if (HeMemDataHolder:getInteger("Activity_SecretShopTips") == 1) then
		HeMemDataHolder:setInteger("Activity_SecretShopTips" , 0)
		self.container:resetTipInfoForActivity("Activity_SecretShop")
	-- end
	local gameInitData = DataManager.getGameInitData()
	gameInitData.sharkUserSecretShop.freeTimes = self.extraArgs.freeTimes
	DataManager.setGameInitData(gameInitData)

	self.tableView = self:createTableView(self.extraArgs.itemIdList)
	self.mainUI:addChild(self.tableView)

	local function onToPractice()
		if (DataManager.getCurrUser().level < MetaManager.getGameSettingConfig().sacrificeUnlockLevel) then
			SuspensionLabel:showContent(self, Localization:getInstance():getText("module_needLevel", {num = MetaManager.getGameSettingConfig().sacrificeUnlockLevel}))
			return
		end
		
		Director:sharedDirector():replaceScene(CardRebirthScene:create({enterScene = "ActivityPanelScene", returnScene = "ActivityPanelScene"}))
	end
	local toPractice = Button:create(self.mainUI:getChildByName("btn_change_password"))
	toPractice:addEventListener(Events.kStart, onToPractice)
	self.mainUI:getChildByName("btn_change_password"):getChildByName("txt"):setString(getTextByKey("secretShop_sacrificeBtn"))

	local function onReFresh()
		local gameInitData = DataManager.getGameInitData()
		local freeRefreshTimes = gameInitData.sharkUserSecretShop.freeTimes
		if freeRefreshTimes <= 0 and BagCalcManager.getNumById(400163) <= 0 then
			if CalculationManager.calcComplex_getGemsNow() < MetaManager.getGameSettingConfig().secretShopConfig.refreshGoldCost then
	    		local function onReplaceScene()
		          self.container:setTableViewsEnabled(true)
		          self.container.targetInfoPanel = nil
		        end
		        local aPanel = AssistantMessageBoxPanel:create( self.container, AsMessageBoxType.addCoin , nil, {onReplaceSceneFunc = onReplaceScene})
		        self.container:addChild(aPanel)
		        aPanel:scaleIn()
		        return
		    end
		end
		
		local function refreshSucceed( response )
			self.tableView:removeFromParentAndCleanup(true)
			self.tableView = self:createTableView(response.data.itemIdList)
			self.mainUI:addChild(self.tableView)

			local gameInitData = DataManager.getGameInitData()
			local freeRefreshTimes = gameInitData.sharkUserSecretShop.freeTimes
			if freeRefreshTimes > 0 then
				gameInitData.sharkUserSecretShop.freeTimes = freeRefreshTimes - 1
				DataManager.setGameInitData(gameInitData)
      		elseif BagCalcManager.getNumById(400163) > 0 then
      			RewardManager:getReward({{itemType = ResourceEnum.PROP, metaId = 400163, amount = -1}})
  			else
  				RewardManager:gainReward({itemType = ResourceEnum.GEMS, amount = -MetaManager.getGameSettingConfig().secretShopConfig.refreshGoldCost})
      		end
      		self:refreshAstralessence()
		end
		local function refreshFailed()
			
		end
		RefreshSecretShopRequest.sendRequest(nil , refreshSucceed , refreshFailed)
	end

	local toRefresh = Button:create(self.mainUI:getChildByName("btn_refresh"))
	toRefresh:addEventListener(Events.kStart, onReFresh)
	self.mainUI:getChildByName("btn_refresh"):getChildByName("txt"):setString(getTextByKey("secretShop_refreshBtn"))
	local buttonGoldCostStr = Localization:getInstance():getText("secretShop_refreshBtn_gold" , {num = MetaManager.getGameSettingConfig().secretShopConfig.refreshGoldCost})
	self.mainUI:getChildByName("btn_refresh"):getChildByName("txt_1"):setString(buttonGoldCostStr)
	self.mainUI:getChildByName("txt_shopmystery8"):getChildByName("txt"):setString(getTextByKey("secretShop_sacrificeText"))
	self.mainUI:getChildByName("txt_shopmystery4"):getChildByName("txt"):setString(getTextByKey("secretShop_refreshCountdown"))
	-- self.mainUI:getChildByName("txt_shopmystery6"):getChildByName("txt"):setString(getTextByKey("secretShop_propRefresh"))
	
	self:refreshAstralessence()

	self:refreshTime()

end

function Activity_MysteryShopLayer:getGoodList()
	
end

function Activity_MysteryShopLayer:refreshTime( delay )
	delay = delay or 0
	function onTimeTick(remainedSec)
		local formatedTimeStr = TimeUtil.formatTime(remainedSec)
		-- print(formatedTimeStr)
		self.mainUI:getChildByName("txt_shopmystery5"):getChildByName("txt"):setString(formatedTimeStr)--{num1}:{num2}:{num3}后可加入军团
	end
	self.onTimeTick = onTimeTick

	function onTimeComplete()
		local function successCallback(data)
			local function isServerRefresh( )
				local serverTime = TimeUtil.getServerTimeSeconds()
				local h , m , s = TimeUtil.getHourMinSec(serverTime)
				h = math.mod(h + 8 , 24)  -- 时间戳0是从8点开始的
				--服务器4小时定时刷新，如果服务器返回的时间是下面这些时间，说明前端早于服务器刷新，返回false
				if h == 3 or h == 7 or h == 11 or h == 15 or h == 19 or h == 23 then
					return false
				else
					return true
				end
				-- return true
			end
			if(self.version ~= data.data.version) then
				if self.mainUI == nil or self.mainUI.list == nil then--在刷新的一瞬间点去祭恋，消息返回的话操作UI就会有问题
					return
				end
				self.tableView:removeFromParentAndCleanup(true)
				self.tableView = self:createTableView(data.data.itemIdList)
				self.mainUI:addChild(self.tableView)

				local gameInitData = DataManager.getGameInitData()
				if(not gameInitData.sharkUserSecretShop) then
					gameInitData.sharkUserSecretShop = {}
					gameInitData.sharkUserSecretShop.lastRefreshSecond = -1
				end
				gameInitData.sharkUserSecretShop.lastRefreshSecond = TimeUtil.getServerTimeSeconds()
	      		DataManager.setGameInitData(gameInitData)
	      		self:refreshTime()

	      		local serverTime = TimeUtil.getServerTimeSeconds()
				local h , m , s = TimeUtil.getHourMinSec(serverTime)
				h = math.mod(h + 8 , 24)  -- 时间戳0是从8点开始的
				if h == 0 then--跨天了
					--重新请求后端
					local gameInitData = DataManager.getGameInitData()
					gameInitData.sharkUserSecretShop.freeTimes = data.data.freeTimes
					DataManager.setGameInitData(gameInitData)
					self:refreshAstralessence()
				end
			else
				self:refreshTime(3)
			end
	    end

	    local function failureCallback(data)

	    end

	    GetSecretShopListRequest.sendRequest(successCallback , failureCallback)
	end
	self.onTimeComplete = onTimeComplete
	if self.cdLabelComponent then
		self.cdLabelComponent:stop()
	end
	self.cdLabelComponent = CdLabelComponent:create()
	self.cdLabelComponent:setCallback(onTimeTick, onTimeComplete)
	
	local gameInitData = DataManager.getGameInitData()
	  	if(not gameInitData.sharkUserSecretShop) then
	    	self.lastRefleshTime = -1
	  	else
	    	self.lastRefleshTime = gameInitData.sharkUserSecretShop.lastRefreshSecond
	end
	local targetTime = 0
	local newRefreshInterval = string.split(MetaManager.getGameSettingConfig().secretShopConfig.newRefreshInterval, '|')
	local todayTimestamp = TimeUtil.getTodayTimestampBy(0,0,0)
	local currentTime = TimeUtil.getServerTimeSeconds()
	local currentToatalTimestamp = todayTimestamp + newRefreshInterval[1]
	print("todayTimestamp"..todayTimestamp)
	local fourHour = 0
	for i=1,#newRefreshInterval do
		if currentTime < tonumber(currentToatalTimestamp) then
			fourHour = tonumber(newRefreshInterval[i])
			break
		else
			currentToatalTimestamp = currentToatalTimestamp + newRefreshInterval[i + 1]
		end
	end

	-- local fourHour = 14400
	if delay == 0 then
		targetTime = fourHour + self.lastRefleshTime
	else
		targetTime = TimeUtil.getServerTimeSeconds() + delay--如果本地刷新了，但是服务器还没刷新，就继续延长3秒倒计时
	end
	if (TimeUtil.getServerTimeSeconds() > targetTime) then
		local dis = TimeUtil.getServerTimeSeconds() - self.lastRefleshTime
		local freshTimes = math.modf(dis / fourHour)
		gameInitData.sharkUserSecretShop.lastRefreshSecond = self.lastRefleshTime + freshTimes * fourHour
	    self.lastRefleshTime = gameInitData.sharkUserSecretShop.lastRefreshSecond
	    DataManager.setGameInitData(gameInitData)
	    self:refreshTime()
	    return
	end
	-- local targetTime = 60 + self.lastRefleshTime + delay
	self.cdLabelComponent:setTargetTime(targetTime)
	self.cdLabelComponent:start()
end

function Activity_MysteryShopLayer:refreshAstralessence()
	local GameData = DataManager.getGameInitData()
	self.mainUI:getChildByName("txt_shopmyster8"):getChildByName("txt"):setString(GameData.sharkUserExtend.astralEssence)
	local costDetails = nil

	local gameInitData = DataManager.getGameInitData()
	local freeRefreshTimes = gameInitData.sharkUserSecretShop.freeTimes
	if freeRefreshTimes > 0 then
		costDetails = Localization:getInstance():getText("secretShop_freeRefresh" , {num = freeRefreshTimes})
	else
		costDetails = Localization:getInstance():getText("secretShop_propRefresh" , {num = BagCalcManager.getNumById(400163)})
	end
	self.mainUI:getChildByName("txt_shopmystery6"):getChildByName("txt"):setString(costDetails)

	if freeRefreshTimes > 0 or not (BagCalcManager.getNumById(400163) == 0) then
		self.mainUI:getChildByName("btn_refresh"):getChildByName("icon_gold"):setVisible(false)
		self.mainUI:getChildByName("btn_refresh"):getChildByName("txt"):setVisible(true)
		self.mainUI:getChildByName("btn_refresh"):getChildByName("txt_1"):setVisible(false)
	else
		self.mainUI:getChildByName("btn_refresh"):getChildByName("icon_gold"):setVisible(true)
		self.mainUI:getChildByName("btn_refresh"):getChildByName("txt"):setVisible(false)
		self.mainUI:getChildByName("btn_refresh"):getChildByName("txt_1"):setVisible(true)
	end
end

local TABLEVIEW_CELL_TAG = -1001
local TAG_BUTTON_EXCHANGE = 1001
local TAG_ICON_ITEM = 1002
local TAG_TXT_GOODNAME = 1003
local TAG_TXT_GOODCOST = 1004
local TAG_ICON_STARSOUL  = 1005
local TAG_ICON_COIN = 1006
local TAG_TXT_BUYTIMES = 1007
local TAG_ICON_GOODICON = 1008

function Activity_MysteryShopLayer:createTableView( itemList )
	local MysteryShopLayerRenderer = class(TableViewRenderer)
	function MysteryShopLayerRenderer:ctor(width, height)
	    -- body
	    self.list = itemList
	    local builder = LayoutBuilder:createWithContentsOfFile("scene/shopmystery.json")
	    builder.useArtLabelTTF = true
	    self.builder = builder
	end
	function MysteryShopLayerRenderer:buildCell(container)
	    local cell = self.builder:build("list_goods1")
	    cell:setPosition(ccp(0, 0))   
	    cell:setTag(TABLEVIEW_CELL_TAG)
	    container:addChild(cell)

	    local infoLabelFlash1 = cell:getChildByName("txt_tradename"):getChildByName("txt")
		infoLabelFlash1:setColor(ccc3(0,252,255))
		infoLabelFlash1:setAroundColor(ccc3(59, 0, 0))
	    cell:getChildByName("btn_guildoption"):setTag(TAG_BUTTON_EXCHANGE)
	    cell:getChildByName("btn_guildoption"):getChildByName("txt"):setString(getTextByKey("secretShop_exchangeBtn"))
	    cell:getChildByName("btn_guildoption_grey"):getChildByName("txt"):setString(getTextByKey("secretShop_exchangeBtn"))
	    cell:getChildByName("txt_tradename"):setTag(TAG_TXT_GOODNAME)
	    cell:getChildByName("txt_tradename"):getChildByName("txt"):setTag(TAG_TXT_GOODNAME)
	    cell:getChildByName("txt_spirit"):setTag(TAG_TXT_GOODCOST)
	    cell:getChildByName("txt_spirit"):getChildByName("txt"):setTag(TAG_TXT_GOODCOST)
	    cell:getChildByName("txt_shopmystery1"):getChildByName("txt"):setString(getTextByKey("secretShop_exchangeChance"))
	    cell:getChildByName("txt_shopmystery3"):getChildByName("txt"):setString(getTextByKey("secretShop_exchangeChance2"))
	    cell:getChildByName("icon_spirit"):setTag(TAG_ICON_STARSOUL)
	    cell:getChildByName("icon_gold"):setTag(TAG_ICON_COIN)
	    cell:getChildByName("txt_shopmystery2"):setTag(TAG_TXT_BUYTIMES)
	    cell:getChildByName("txt_shopmystery2"):getChildByName("txt"):setTag(TAG_TXT_BUYTIMES)
	    cell:getChildByName("normal_card_small"):setTag(TAG_ICON_GOODICON)

    end
    local function setTextByTag( cell, tag, str)
	    local txt = cell:getChildByTag(tag):getChildByTag(tag)
	    setNodeText(txt, str);
	end

	local function setNodeVisibleByTag(cell, tag, visible)
	    cell:getChildByTag(tag):setVisible(visible)
	end

	function MysteryShopLayerRenderer:setData(rawCocosObj,index)
		local cell = self:getChildByTag(rawCocosObj, TABLEVIEW_CELL_TAG)
		local itemData = self.list[index + 1]
		setNodeVisibleByTag(cell , TAG_BUTTON_EXCHANGE , true)

		if(self.list[index + 1].boughtTime <= 0) then
			setNodeVisibleByTag(cell , TAG_BUTTON_EXCHANGE , false)
		end
		setTextByTag(cell ,TAG_TXT_BUYTIMES ,self.list[index + 1].boughtTime)
		setTextByTag(cell ,TAG_TXT_GOODCOST ,self.list[index + 1].moneyAmount)

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
		local icon = CanonGoodIcon.createGoodIcon(itemData.itemType, itemData.itemId, 1, params)
		cell:addChild(icon.refCocosObj, zOrder)
		if icon then
			icon:setTag(TAG_ICON_ITEM)
			icon:dispose()
		end

		local goodDetails = CanonGoodIcon.getGoodName(itemData.itemType , itemData.itemId , itemData.itemAmount , nil)
		setTextByTag(cell , TAG_TXT_GOODNAME , goodDetails)

    	if(self.list[index + 1].moneyType == ResourceEnum.ASTRALESSENCE) then
    		setNodeVisibleByTag(cell , TAG_ICON_STARSOUL , true)
    		setNodeVisibleByTag(cell , TAG_ICON_COIN , false)
    	elseif (self.list[index + 1].moneyType == ResourceEnum.GEMS ) then
    		setNodeVisibleByTag(cell , TAG_ICON_STARSOUL , false)
    		setNodeVisibleByTag(cell , TAG_ICON_COIN , true)
    	else
    		--nothing
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
	    -- itemList[evt.data + 1].boughtTime = itemList[evt.data + 1].boughtTime - 1
	    -- self.tableView:reloadData()

	    if(selectedCell:getChildByTag(TAG_BUTTON_EXCHANGE):isVisible()) then
		    local posInCell = selectedCell:convertToNodeSpace(evt.globalPosition)
		    local itemPosX, itemPosY = selectedCell:getChildByTag(TAG_BUTTON_EXCHANGE):getPosition()
		    local itemRect = {}
		    itemRect.x = itemPosX
		    itemRect.y = itemPosY - 66
		    itemRect.width = 168
		    itemRect.height = 66
		    if inArea(posInCell.x, posInCell.y, itemRect) then
		    	local function doPlayAfterExchangeSucceed( rewards )
			        -- body
			        local function onGet(  )
			          -- body
			          RewardManager:getReward(rewards)
			          if(itemList[evt.data + 1].moneyType == ResourceEnum.ASTRALESSENCE )then
			          	RewardManager:gainReward({itemType = ResourceEnum.ASTRALESSENCE, amount = -itemList[evt.data + 1].moneyAmount})
			          elseif(itemList[evt.data + 1].moneyType == ResourceEnum.GEMS )then
			          	RewardManager:gainReward({itemType = ResourceEnum.GEMS, amount = -itemList[evt.data + 1].moneyAmount})
			          end
			          itemList[evt.data + 1].boughtTime = itemList[evt.data + 1].boughtTime - 1
			          self:refreshAstralessence()
			          local offset = self.tableView:getContentOffset()
			          self.tableView:reloadData()
			          self.tableView:setContentOffset(offset)
			        end

			        SuspensionLabel:showContent(self, getTextByKey("secretShop_exchangeSuccess"))
			        onGet()

			  --       local RewardPanel = GetRewardInfoPanel:create( self.container, rewards, onGet)
					-- PopoutManager:sharedManager():popout(RewardPanel, kPopoutDir.kScale, true, false ,self.container)

			        -- local aRewardPanel = RewardReviewPanel:create( self.container, {rewardList = rewards, rewardTitle = Localization:getInstance():getText("activity_newyear_rewardTitle"), callback = onGet} )
			        -- self.container:addChild(aRewardPanel)
			        -- aRewardPanel:scaleIn()

			    end
		    	local function exchangeSucceed( response )
		    		doPlayAfterExchangeSucceed(response.data.rewards)
		    	end

		    	local function exchangeFailed( response )
		    		if ( response.data == 716454) then
		    			local function successCallback(data)
							self.tableView:removeFromParentAndCleanup(true)
							self.tableView = self:createTableView(data.data.itemIdList)
							self.mainUI:addChild(self.tableView)

							local gameInitData = DataManager.getGameInitData()
							if(not gameInitData.sharkUserSecretShop) then
								gameInitData.sharkUserSecretShop = {}
								gameInitData.sharkUserSecretShop.lastRefreshSecond = -1
							end
							gameInitData.sharkUserSecretShop.lastRefreshSecond = TimeUtil.getServerTimeSeconds()
				      		DataManager.setGameInitData(gameInitData)
				      		self:refreshTime()
					    end

					    local function failureCallback(data)

					    end

					    GetSecretShopListRequest.sendRequest(successCallback , failureCallback)
		    		end
		    	end
		    	if BagCalcManager.needToCheck(itemList[evt.data + 1].itemType) and BagCalcManager.isFull() then
		    		NewPackageFullPanel:show()
		    		-- CanonMessageBox:Show(getTextByKey("shop_inventoryFull"), ShowMessageType.ShowText, ShowButtonType.ID_OK, 40) 
		    		return
		    	end
		    	local params = {exchangeId = itemList[evt.data + 1].id , exchangeListId = itemList[evt.data + 1].listId}
		    	if(itemList[evt.data + 1].moneyType == ResourceEnum.ASTRALESSENCE and DataManager.getGameInitData().sharkUserExtend.astralEssence < itemList[evt.data + 1].moneyAmount) then
		    		SuspensionLabel:showContent(self, getTextByKey("secretShop_astralEssenceInsufficient"))
		    	elseif (itemList[evt.data + 1].moneyType == ResourceEnum.GEMS and CalculationManager.calcComplex_getGemsNow() < itemList[evt.data + 1].moneyAmount) then
		    		local function onReplaceScene()
			          self.container:setTableViewsEnabled(true)
			          self.container.targetInfoPanel = nil
			        end
			        local aPanel = AssistantMessageBoxPanel:create( self.container, AsMessageBoxType.addCoin , nil, {onReplaceSceneFunc = onReplaceScene})
			        self.container:addChild(aPanel)
			        aPanel:scaleIn()
			        return
			    else
			    	ExchangeSecretShopRequest.sendRequest(params , exchangeSucceed , exchangeFailed)
		    	end
		    end
		end
	end

	local cell_height = 200
	local list_height = 585.85
	local list_posY = 784

	local renderer = MysteryShopLayerRenderer.new(BAGCONFIG.WIDTH, cell_height)
	local tableView = TableView:create(renderer, BAGCONFIG.WIDTH, list_height, TABLEVIEW_CELL_TAG,TAG_BUTTON_EXCHANGE, CCScale9Sprite:create("pic/scroll.png"), CCScale9Sprite:create("pic/scroll.png"))

	tableView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch)
	tableView:setPosition(ccp(10, 198.5))
	return tableView

end

function Activity_MysteryShopLayer:setTouchEnabled(v)
  self.tableView:setTouchEnabled(v)
end


function Activity_MysteryShopLayer.getTipNum()
  if not Activity_MysteryShopLayer.enable() then
    return 0
  end

  return HeMemDataHolder:getInteger("Activity_SecretShopTips")
end