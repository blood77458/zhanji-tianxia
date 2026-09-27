require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"
require "canon.panel.ReNameInputPanel"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

ReNamePropBuyPanel = class(Layer)

function ReNamePropBuyPanel:ctor()
	self.container = nil
end

function ReNamePropBuyPanel:create( container )
	self.container = container
	local s = ReNamePropBuyPanel.new()
	s:initLayer()
	return s
end

function ReNamePropBuyPanel:initLayer()
	if type(self.container.setTableViewsEnabled) == "function" then
		self.container:setTableViewsEnabled(false)
	end
	ReNamePropBuyPanel.super.initLayer(self)
	
	local builder = LayoutBuilder:createWithContentsOfFile("scene/common_new.json")
	builder.useArtLabelTTF = true
	self.panelUI = builder:build("common_popup_change_name_gold")

	self.panelUI:getChildByName("common_popup_changename_gold_2"):getChildByName("txt"):setString(getTextByKey("rename_noRenameCard1"))
	self.panelUI:getChildByName("common_popup_changename_gold_1"):getChildByName("txt"):setString(getTextByKey("rename_noRenameCard3"))
	self.panelUI:getChildByName("common_popup_changename_gold_3"):getChildByName("txt"):setString(getTextByKey("rename_noRenameCard4"))
	self.panelUI:getChildByName("common_popup_changename_gold_5"):getChildByName("txt"):setString(getTextByKey("rename_noRenameCard2"))
	self.panelUI:getChildByName("common_popup_changename_gold_4"):getChildByName("txt"):setString(MetaManager.game_meta.gameSettingConfig.renameCardGoldCost)
	self.panelUI:getChildByName("common_btn_sellItem_yes"):getChildByName("txt_yes"):setString(getTextByKey("yes"))

	-- 关闭Panel事件
	local function onClosePanel(evt)
		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale)
		if type(self.container.setTableViewsEnabled) == "function" then
			self.container:setTableViewsEnabled(true)
		end
	end

	-- 关闭按钮
	local closeButtonDisplay = self.panelUI:getChildByName("btn_close")
	local closeButton = Button:create(closeButtonDisplay)
	closeButton:addEventListener(Events.kStart, onClosePanel, self)

	local function onConfirm( evt )
		if CalculationManager.calcComplex_getGemsNow() < MetaManager.game_meta.gameSettingConfig.renameCardGoldCost then
			local aPanel = AssistantMessageBoxPanel:create( self.container, AsMessageBoxType.addCoin , nil, {onReplaceSceneFunc = onReplaceScene})
	        self.container:addChild(aPanel)
	        aPanel:scaleIn()
	        return
	    end

	    if BagCalcManager.isFull() then
			NewPackageFullPanel:show()
			return 
	    end

	    local function buyGoodsSucceedResponse(evt)
			SuspensionLabel:showContent(self, getTextByKey("shop_buySuccess"))
			
			RewardManager:getReward(evt.data.reward)
			local costTable = {}
			costTable.amount = -(MetaManager.game_meta.gameSettingConfig.renameCardGoldCost)
			costTable.metaId = 0
			costTable.itemType = 2
			costTable.id = 0
			RewardManager:getReward({costTable})

			local targetInfoPanel = ReNameInputPanel:create(self.container)
        	PopoutManager:sharedManager():popout(targetInfoPanel, kPopoutDir.kScale, true, false, self.container)

        	onClosePanel(nil)
		end
		
		local function buyGoodsFailedResponse(evt)
			if evt.data == 710513 then --gold not enough
				local aPanel = AssistantMessageBoxPanel:create( self, AsMessageBoxType.addCoin )
				self:addChild(aPanel)
				aPanel:scaleIn()
			elseif evt.data == 710516 then --package full
				local aContent = Localization:getInstance():getText("shop_inventoryFull")
				local function closeCanonMessageBox()
				end
				self.targetInfoPanel = NewPackageFullPanel:show()
			else
				CanonMessageBox:showCommUnHandleErrorBox(evt.data)
			end
		end

		local reNamePropId =  MetaManager.game_meta.gameSettingConfig.renamePropId
		local shopReNameProp =  CommonManager.getSubTableByKey(
			MetaManager.shop_meta,
			{name = "metaId" , value = reNamePropId})
		local request = BuyGoodsRequest.new( {goodsId = shopReNameProp.id}, rpc.SendingPriority.kHigh )
		request:addEventListener( RequestNotifyEnum.BuyGoodsSucceed, buyGoodsSucceedResponse )
		request:addEventListener( RequestNotifyEnum.BuyGoodsFailed, buyGoodsFailedResponse )
		request:start()
	end

	local confirmButton = Button:create(self.panelUI:getChildByName("common_btn_sellItem_yes"))
	confirmButton:addEventListener(Events.kStart, onConfirm, self)
	
	self:addChild(self.panelUI)
end
