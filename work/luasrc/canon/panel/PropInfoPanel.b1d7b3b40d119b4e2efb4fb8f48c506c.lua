--------------------------------------------------------------------------------
-- PropInfoPanel.lua - 道具详情面板
-- author: fanzhou.long
-- date: 2013-08-27
--------------------------------------------------------------------------------
require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"
require "canon.panel.ItemSellMessageBoxPanel"
require "canon.request.UsePropRequest"
require "canon.scene.PropConfig"
require "canon.panel.GetRewardInfoPanel"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

PropInfoPanel = class(Layer)

function PropInfoPanel:ctor()
	self.container = nil
end

function PropInfoPanel:create( container , isShopScene , index)
	self.container = container
	self.prop = self.container._data
	self.isShopScene = isShopScene
	self.newIndex = index
	local s = PropInfoPanel.new()
	s:initLayer()
	return s
end

function PropInfoPanel:refreshData()
	local aProp =  MetaManager.prop_meta[self.prop.metaId]
	
	--刷新描述标签
	self.panelUI:getChildByName("common_txt_propInfo_title"):getChildByName("txt_propInfo_title"):setString(Localization:getInstance():getText("propInfo_title"))
	
	--刷新动态标签
	self.panelUI:getChildByName("common_popup_propInfo_upper"):getChildByName("txt_propInfo_desc_txt"):getChildByName("txt_propInfo_desc_txt"):setString(Localization:getInstance():getText(aProp.desc))
	self.panelUI:getChildByName("common_popup_propInfo_upper"):getChildByName("txt_equipName"):getChildByName("txt_equipName"):setString(Localization:getInstance():getText(aProp.name))

	local function onClickUseBtn(evt)
		--使用个数(单个使用)
		local openNum = 1
		
		local function onClickMore()
			self.prop.amount = BagCalcManager.getNumById(self.prop.metaId)
			if (self.prop.amount>0) then
				self.panelUI:getChildByName("common_popup_propInfo_upper"):getChildByName("shuliang"):getChildByName("txt"):setString(getTextByKey("propInfo_quantity") .. self.prop.amount)
				self:refreshData()
			else
				self.container:setTableViewsEnabled(true)
				self.container.targetInfoPanel = nil
				PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
			end
		end

		local function usePropResponse( e )
			onGeneralUsePropResponse(e, self.container._data, self.container.dataList, self.container, self.container.dataIndex, openNum, onClickMore)
			self.prop.amount = BagCalcManager.getNumById(self.prop.metaId)
			if (self.prop.amount>0) then
				self.panelUI:getChildByName("common_popup_propInfo_upper"):getChildByName("shuliang"):getChildByName("txt"):setString(getTextByKey("propInfo_quantity") .. self.prop.amount)
				self:refreshData()
			else
				self.container:setTableViewsEnabled(true)
				self.container.targetInfoPanel = nil
				PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
			end
		end
						
		local function usePropFailed(e)
			onGeneralUsePropFailed(e, self.container._data, self.container )
			--self.waitRequest = false;
		end
		
		local function onConfirmClick(e)
		end
		
		local function onGotoShop(e)
			self.container:setTableViewsEnabled(true)
			self.container.targetInfoPanel = nil
			PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
		end
						
		if self.container.waitRequest then
			do return end
		end

		if self.prop.metaId == MetaManager.game_meta.gameSettingConfig.renamePropId then
			local renameNextTime , timeRemain = CalculationManager.calcComplex_getRenameCoolingTime()
		    if timeRemain <= 0 then
		    	self.container.targetInfoPanel = ReNameInputPanel:create( self.container )
				PopoutManager:sharedManager():popout(self.container.targetInfoPanel, kPopoutDir.kScale, true, false ,self.container)
		    else
		    	self.container.targetInfoPanel = ReNameCoolingPanel:create( self.container )
		    	PopoutManager:sharedManager():popout(self.container.targetInfoPanel, kPopoutDir.kScale, true, false ,self.container) 
		    end
		    self.container:setTableViewsEnabled(true)
		    PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
			return
		end
		
		requestUsePropRequest(self.container._data, self.container.dataList, usePropResponse, usePropFailed, self.container, openNum, onGotoShop)

		--self.container.waitRequest = true;
	end

	--批量使用按钮
	local function onClickMultiUseBtn(evt)
		--使用个数
		local openNum = BackpackScene.ItemCanOpenNum(self.container._data.metaId)
		
		local function onClickMore()
			self.prop.amount = BagCalcManager.getNumById(self.prop.metaId)
			if (self.prop.amount>0) then
				self.panelUI:getChildByName("common_popup_propInfo_upper"):getChildByName("shuliang"):getChildByName("txt"):setString(getTextByKey("propInfo_quantity") .. self.prop.amount)
				self:refreshData()
			else
				self.container:setTableViewsEnabled(true)
				self.container.targetInfoPanel = nil
				PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
			end
		end

		local function usePropResponse( e )
			onGeneralUsePropResponse(e, self.container._data, self.container.dataList, self.container, self.container.dataIndex, openNum, onClickMore)
			self.prop.amount = BagCalcManager.getNumById(self.prop.metaId)
			if (self.prop.amount>0) then
				self.panelUI:getChildByName("common_popup_propInfo_upper"):getChildByName("shuliang"):getChildByName("txt"):setString(getTextByKey("propInfo_quantity") .. self.prop.amount)
				self:refreshData()
			else
				self.container:setTableViewsEnabled(true)
				self.container.targetInfoPanel = nil
				PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
			end
		end
						
		local function usePropFailed(e)
			onGeneralUsePropFailed(e, self.container._data, self.container )
			--self.waitRequest = false;
		end
		
		local function onConfirmClick(e)
		end
		
		local function onGotoShop(e)
			self.container:setTableViewsEnabled(true)
			self.container.targetInfoPanel = nil
			PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
		end
						
		if self.container.waitRequest then
			do return end
		end

		requestUsePropRequest(self.container._data, self.container.dataList, usePropResponse, usePropFailed, self.container, openNum, onGotoShop)
		
		--self.container.waitRequest = true;
	end
	
	local function onClickSellBtn(evt)
		local aPanel = ItemSellMessageBoxPanel:create( self.container , {propData={{metaId=self.prop.metaId, amount=self.prop.amount}}}, self , self.newIndex)
		self.container:addChild(aPanel)
		aPanel:scaleIn()
	end
	
	local multiUseBtnDisplay = nil
	local useBtnDisplay = nil
	local sellBtnDisplay = nil
	
	if (aProp.cate == 1) then --可以使用
		if aProp.canSell then --可以卖出
			local openNum = BackpackScene.ItemCanOpenNum(self.prop.metaId)
			if (aProp.effectType == Prop_Effect_Type.BOX or aProp.effectType == Prop_Effect_Type.VIPBOX) and (openNum > 0) then
				--可以批量使用 并且数量不是0
				self.panelUI:getChildByName("btn_l"):setVisible(true)--1
				self.panelUI:getChildByName("common_btn_propInfo_useBtn"):setVisible(false)
				self.panelUI:getChildByName("common_btn_equip_SellBtn"):setVisible(true)--1
				self.panelUI:getChildByName("common_btn_equip_SellBtn_usable"):setVisible(false)
				self.panelUI:getChildByName("btn_r"):setVisible(true)--1


				useBtnDisplay = self.panelUI:getChildByName("btn_l")
				multiUseBtnDisplay = self.panelUI:getChildByName("common_btn_equip_SellBtn")
				sellBtnDisplay = self.panelUI:getChildByName("btn_r")

				if aProp.effectType == Prop_Effect_Type.TREASUREBOX or aProp.effectType == Prop_Effect_Type.BOX then
					useBtnDisplay:getChildByName("txt_propInfo_useBtn"):setString(Localization:getInstance():getText("bag_openBtn"))
				else
					useBtnDisplay:getChildByName("txt_propInfo_useBtn"):setString(Localization:getInstance():getText("propInfo_useBtn"))
				end
				multiUseBtnDisplay:getChildByName("txt_equip_SellBtn"):setString(BackpackScene.getItemUseBtnStr(self.prop.metaId, false))
				sellBtnDisplay:getChildByName("txt_equip_SellBtn"):setString(Localization:getInstance():getText("cardInfo_SellBtn"))
			else
				--不可批量使用
				self.panelUI:getChildByName("btn_l"):setVisible(false)
				self.panelUI:getChildByName("common_btn_propInfo_useBtn"):setVisible(true)--1
				self.panelUI:getChildByName("common_btn_equip_SellBtn"):setVisible(false)
				self.panelUI:getChildByName("common_btn_equip_SellBtn_usable"):setVisible(true)--1
				self.panelUI:getChildByName("btn_r"):setVisible(false)

				useBtnDisplay = self.panelUI:getChildByName("common_btn_propInfo_useBtn")
				sellBtnDisplay = self.panelUI:getChildByName("common_btn_equip_SellBtn_usable")
				sellBtnDisplay:getChildByName("txt_equip_SellBtn"):setString(Localization:getInstance():getText("cardInfo_SellBtn"))

				if aProp.effectType == Prop_Effect_Type.TREASUREBOX or aProp.effectType == Prop_Effect_Type.BOX then
					useBtnDisplay:getChildByName("txt_propInfo_useBtn"):setString(Localization:getInstance():getText("bag_openBtn"))
				else
					useBtnDisplay:getChildByName("txt_propInfo_useBtn"):setString(Localization:getInstance():getText("propInfo_useBtn"))
				end
			end
		else --不可卖出(一定不可批量使用 如果有增加则需修改)
			self.panelUI:getChildByName("btn_l"):setVisible(false)
			self.panelUI:getChildByName("common_btn_propInfo_useBtn"):setVisible(false)
			self.panelUI:getChildByName("common_btn_equip_SellBtn_usable"):setVisible(false)
			self.panelUI:getChildByName("btn_r"):setVisible(false)

			useBtnDisplay = self.panelUI:getChildByName("common_btn_equip_SellBtn")

			if aProp.effectType == Prop_Effect_Type.TREASUREBOX or aProp.effectType == Prop_Effect_Type.BOX then
				useBtnDisplay:getChildByName("txt_equip_SellBtn"):setString(Localization:getInstance():getText("bag_openBtn"))
			else
				useBtnDisplay:getChildByName("txt_equip_SellBtn"):setString(Localization:getInstance():getText("propInfo_useBtn"))
			end
		end
	else --不可使用
		self.panelUI:getChildByName("common_btn_propInfo_useBtn"):setVisible(false)
		self.panelUI:getChildByName("common_btn_equip_SellBtn_usable"):setVisible(false)
		self.panelUI:getChildByName("btn_l"):setVisible(false)
		self.panelUI:getChildByName("btn_r"):setVisible(false)
		if aProp.canSell then --可以卖出
			self.panelUI:getChildByName("common_btn_equip_SellBtn"):setVisible(true)--1

			sellBtnDisplay = self.panelUI:getChildByName("common_btn_equip_SellBtn")
			sellBtnDisplay:getChildByName("txt_equip_SellBtn"):setString(Localization:getInstance():getText("cardInfo_SellBtn"))
		else --不可卖出
			self.panelUI:getChildByName("common_btn_equip_SellBtn"):setVisible(false)
		end
	end
	
	if self.isShopScene then
		if useBtnDisplay then
			useBtnDisplay:setVisible(false)
		end
		if sellBtnDisplay then
			sellBtnDisplay:setVisible(false)
		end
		if multiUseBtnDisplay then
			multiUseBtnDisplay:setVisible(false)
		end
	else
		if useBtnDisplay then
			local upgradeBtn = Button:create(useBtnDisplay)
			upgradeBtn:addEventListener(Events.kStart, onClickUseBtn, self)  
		end
		if sellBtnDisplay then
			local sellBtn = Button:create(sellBtnDisplay)
			sellBtn:addEventListener(Events.kStart, onClickSellBtn, self)  
		end
		if multiUseBtnDisplay then
			local multiUseBtn = Button:create(multiUseBtnDisplay)
			multiUseBtn:addEventListener(Events.kStart, onClickMultiUseBtn, self)  
		end
	end
end

function PropInfoPanel:initLayer()
	self.container:setTableViewsEnabled(false)
	PropInfoPanel.super.initLayer(self)
	
	local builder = LayoutBuilder:createWithContentsOfFile("scene/common_new.json")
	self.panelUI = builder:build("common_popup_propInfo")
	self.panelUI:getChildByName("common_txt_propInfo_title"):getChildByName("txt_propInfo_title"):setString(Localization:getInstance():getText("propInfo_title"))
	
	--设置数量
	if self.prop.amount == -1 then
		--不显示数量(比如军团斗兽场不显示这个数量)
		self.panelUI:getChildByName("common_popup_propInfo_upper"):getChildByName("shuliang"):setVisible(false)
	else
		self.panelUI:getChildByName("common_popup_propInfo_upper"):getChildByName("shuliang"):setVisible(true)
		self.panelUI:getChildByName("common_popup_propInfo_upper"):getChildByName("shuliang"):getChildByName("txt"):setString(getTextByKey("propInfo_quantity") .. self.prop.amount)
	end
	self:refreshData() 
	
	--关闭
	local function onClosePanel(evt)
		self.container:setTableViewsEnabled(true)
		self.container.targetInfoPanel = nil
		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
	end	 
	local bt_panel_close = Button:create(self.panelUI:getChildByName("common_btn_close"))
	bt_panel_close:addEventListener(Events.kStart, onClosePanel)

    self.panelUI:getChildByName("common_popup_propInfo_upper"):getChildByName("normal_card_small"):setVisible(false)
    --物品信息
	local propObject = CanonItem:create()
    propObject:loadByMetaId(self.prop.metaId)
	local position = self.panelUI:getChildByName("common_popup_propInfo_upper"):getChildByName("normal_card_small"):getPosition()
	propObject:setPosition(ccp(position.x,position.y))
	self.panelUI:getChildByName("common_popup_propInfo_upper"):addChild(propObject)  
    --显示品质
    self.propMetaData = MetaManager.prop_meta[tonumber(self.prop.metaId, 10)]   
	self:addChild(self.panelUI)
end

function PropInfoPanel:initData()

end

function PropInfoPanel:updata()

end