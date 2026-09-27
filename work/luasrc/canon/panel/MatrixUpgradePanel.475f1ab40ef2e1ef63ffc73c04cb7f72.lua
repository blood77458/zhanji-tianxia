require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

MatrixUpgradePanel = class(Layer)

function MatrixUpgradePanel:ctor()
	self.container = nil
	self.isMaterialEnough = false
	self.materialTable = {}
end

function MatrixUpgradePanel:create( container, matrixInfo)
	self.container = container
	self.matrixInfo = matrixInfo
	
	local s = MatrixUpgradePanel.new()
	s:initLayer()
	return s
end

function MatrixUpgradePanel:initLayer()
	self.container:setTableViewsEnabled(false)
	MatrixUpgradePanel.super.initLayer(self)
	
	self.builder = LayoutBuilder:createWithContentsOfFile("scene/camp.json")
	self.panelUI = self.builder:build("popup_camp")
	
	self.panelUI:getChildByName("icon_need_item"):setVisible(false)
	
	self.panelUI:getChildByName("btn_lvup_sure"):getChildByName("txt"):setString(getTextByKey("matrix_upgrade_button2"))
	
	local function onClosePanel(evt)
		self.container:setTableViewsEnabled(true)
		self.container.targetInfoPanel = nil
		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
	end	 
	local bt_panel_close = Button:create(self.panelUI:getChildByName("login_btn_close"))
	bt_panel_close:addEventListener(Events.kStart, onClosePanel)
	
	local function onClickUpgrade(evt)	
		local curMatrixLevelMeta = MetaManager.matrix_level[self.matrixInfo.matrixLevelId]
		if curMatrixLevelMeta.userLevelRequire > DataManager.getCurrUser().level then
			SuspensionLabel:showContent(self, Localization:getInstance():getText("matrix_upgrade_userLevel_emind", {num = curMatrixLevelMeta.userLevelRequire}))
			do return end
		end
		
		if not self.isMaterialEnough then
			SuspensionLabel:showContent(self, getTextByKey("matrix_upgrade_material_require"))
			do return end
		end
		
		if self.waitResponse then
			do return end
		end
		
		local function onUpgradeMatrixSucceed(evt)
			self.waitResponse = false
			g_previousBonusTable = nil;

			--显示战斗力更新 FIGHT_CAPACITY_MODIFY by zheng.che @ 2014-12-22
			DataManager.fightCapacityMaybeUpdated()
			
			--setmatrixdata and gameinitdata
			self.matrixInfo.matrixLevel = self.matrixInfo.matrixLevel + 1
			local isLevelMax = true
			for k,data in pairs(MetaManager.matrix_level) do
				if data.matrixObtain == self.matrixInfo.matrixId and data.matrixLevel == self.matrixInfo.matrixLevel then
					self.matrixInfo.matrixLevelId = data.id
					isLevelMax = false;
					if data.nextMatrix == 0 then
						isLevelMax = true;
					end
					break;
				end
			end
			
			self.matrixInfo.hpBonus = nil
			self.matrixInfo.atkBonus = nil
			self.matrixInfo.defBonus = nil
			
			if type(self.container.completeCurSharkMatricesData) == "function" then
				self.container:completeCurSharkMatricesData()
			end
			
			local sharkMatricesData = DataManager.getSharkMatricesData()
			local upgradeMatrixInfo
			for k, v in pairs(sharkMatricesData) do 
				if v.matrixId == self.matrixInfo.matrixId then
					upgradeMatrixInfo = v
					break;
				end
			end
			if upgradeMatrixInfo then
				upgradeMatrixInfo.matrixLevel = upgradeMatrixInfo.matrixLevel + 1
			else
				upgradeMatrixInfo = {matrixId = self.matrixInfo.matrixId, matrixLevel = self.matrixInfo.matrixLevel, sharkMatrixGrids = {}}
				table.insert(sharkMatricesData, upgradeMatrixInfo)
			end
			DataManager.setSharkMatricesData(sharkMatricesData)
			
			local itemData = DataManager.getPropsData()
			
			for k, data in ipairs(self.materialTable) do
				for kk, vv in pairs(itemData) do
					if data.metaId == vv.metaId then
						vv.amount = vv.amount - data.amount
						if vv.amount <= 0 then
							vv.amount = 0
						end
						break;
					end
				end
			end
			DataManager.setPropsData(itemData)
			
			SuspensionLabel:showContent(self.container, Localization:getInstance():getText("matrix_upgrade_finish_remind", {Num = self.matrixInfo.matrixLevel}))
			if isLevelMax then
				--close
				onClosePanel()
			else
				--refresh
				self:refreshUI()
			end
			--refreshMatrixScene
			if type(self.container.refreshMatrixData) == "function" then
				self.container:refreshMatrixData()
			end
		end
		
		local function onUpgradeMatrixFailed(evt)
			self.waitResponse = false
			if evt.data == 713406 then
				local function closeCanonMessageBox()
				end
				self.targetInfoPanel = CanonMessageBox:Show(getTextByKey("matrix_level_max_remind"), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox)
			elseif evt.data == 713407 then
				local function closeCanonMessageBox()
				end
				self.targetInfoPanel = CanonMessageBox:Show(getTextByKey("matrix_upgrade_userLevel_notEnough"), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox)
			elseif evt.data == 712301 then
				SuspensionLabel:showContent(self, getTextByKey("matrix_upgrade_material_require"))
			else
				CanonMessageBox:showCommUnHandleErrorBox(evt.data)
			end
		end
		
		self.waitResponse = true
		local request = UpgradeMatrixRequest.new( {matrixId = self.matrixInfo.matrixId}, rpc.SendingPriority.kHigh )
		request:addEventListener( RequestNotifyEnum.UpgradeMatrixSucceed, onUpgradeMatrixSucceed )
		request:addEventListener( RequestNotifyEnum.UpgradeMatrixFailed, onUpgradeMatrixFailed )
		request:start()
	end
	
	self.bt_upgrade = Button:create(self.panelUI:getChildByName("btn_lvup_sure"))
	self.bt_upgrade:addEventListener(Events.kStart, onClickUpgrade)
	
	self:addChild(self.panelUI)	
	
	self:refreshUI()
end

function MatrixUpgradePanel:refreshUI()
	self.panelUI:getChildByName("txt_popup_camp_title"):getChildByName("txt"):setString(
	getTextByKey(MetaManager.matrix_meta[self.matrixInfo.matrixId].matrixName) .. " LV " .. self.matrixInfo.matrixLevel
	)
	
	local curMatrixLevelMeta = MetaManager.matrix_level[self.matrixInfo.matrixLevelId]
	local nextMatrixLevelMeta = MetaManager.matrix_level[curMatrixLevelMeta.nextMatrix]
	local gridIds = string.split(nextMatrixLevelMeta.gridUnlock, '|')
	local nextLevelUnlockNum = 0
	for k,v in ipairs(gridIds) do 
		if tonumber(v) ~= 0 then
			nextLevelUnlockNum = nextLevelUnlockNum + 1
		end
	end
	
	self.panelUI:getChildByName("txt_camp_3"):getChildByName("txt"):setString(
	Localization:getInstance():getText("matrix_upgrade_remind", {num = nextLevelUnlockNum}) 
	)
	
	self.panelUI:getChildByName("txt_camp_4"):getChildByName("txt"):setString(
	Localization:getInstance():getText("matrix_upgrade_userLevel_emind", {num = curMatrixLevelMeta.userLevelRequire}) 
	)
	
	if curMatrixLevelMeta.userLevelRequire > DataManager.getCurrUser().level then
		self.panelUI:getChildByName("txt_camp_4"):getChildByName("txt"):setColor(ccc3(255, 0, 0))
		self.bt_upgrade:setEnable(false)
		self.bt_upgrade.display:getChildByName("btn_long_blue"):setVisible(false)
	else
		self.panelUI:getChildByName("txt_camp_4"):getChildByName("txt"):setColor(ccc3(0, 255, 0))
		self.bt_upgrade:setEnable(true)
		self.bt_upgrade.display:getChildByName("btn_long_blue"):setVisible(true)
	end
	
	local fakeSprite = self.panelUI:getChildByName("icon_need_item")
	self.isMaterialEnough = true
	self.materialTable = {}
	for i = 1, 4 do
		local previousUI = self.panelUI:getChildByName("materialItem" .. i)
		if previousUI then
			previousUI:removeFromParentAndCleanup(true)
		end
		
		local needAmount = curMatrixLevelMeta["propAmount" .. i]
		if needAmount > 0 then
			local item = self.builder:build("icon_need_item")
			item.name = "materialItem" .. i
			local needPropId = curMatrixLevelMeta["propId" .. i]
			local haveAmount = 0
			for k,v in pairs(DataManager.getPropsData()) do
				if v.metaId == needPropId then
					haveAmount = v.amount
					break;
				end
			end
			table.insert(self.materialTable, {metaId = needPropId, amount = needAmount})
			item:setPositionXY(fakeSprite:getPositionX() + (i - 1) * 150, fakeSprite:getPositionY())
			item:getChildByName("txt_needitem_value"):getChildByName("txt"):setString(tostring(haveAmount) .. "/" .. tostring(needAmount))
			item:getChildByName("txt_needitem_name"):getChildByName("txt"):setString(getTextByKey(MetaManager.prop_meta[needPropId].name))
			if haveAmount < needAmount then
				item:getChildByName("txt_needitem_value"):getChildByName("txt"):setColor(ccc3(255, 0, 0))
				self.isMaterialEnough = false
			end
			
			local itemSprite = getCanonItemByMetaId(needPropId)
			itemSprite:setPositionXY(item:getChildByName("normal_card_small"):getPositionX(), item:getChildByName("normal_card_small"):getPositionY())
			item:addChildAt(itemSprite, item:getChildByName("normal_card_small"):getZOrder() + 1)
			
			item:getChildByName("normal_card_small"):setVisible(false)
			self.panelUI:addChild(item)
		end
	end
	
end