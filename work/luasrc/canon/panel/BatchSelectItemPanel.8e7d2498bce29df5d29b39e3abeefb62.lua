-- BatchSelectItemPanel.lua
-- 2014-11-11
-- zheng.che
-- 批量选择物品弹窗

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

--焦点变化事件
local function onFocusChanged(evt)
	evt.context:setTableViewsEnabled(evt.data == evt.context)
end

--清除场景事件
local function onSceneClear(evt)
	local self = evt.context
	PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
end

--点击关闭
local function onClose(evt)
	local self = evt.context
	self:close()
end

--点击确定
local function onConfirmClick(evt)
	local self = evt.context

	local currentSelectNum = #self.selectDataList
	if currentSelectNum < self.selectMaxNum then
		if self.selectType == BatchSelectItemPanel.SELECT_TYPE_CARD_EXCHANGE then
			--卡牌以旧换新
			local scene = Director:mgr():run()
			SuspensionLabel:showContent(scene, Localization:getInstance():getText("cardExchange_error_txt3", {num1 = self.selectMaxNum}))--需要选择x名材料武将！
			return
		end
	end

	if self.selectCB then
		self.selectCB(self.selectDataList)
	end

	self:close()
end

------------------------------------------------------------------------------------------------------

BatchSelectItemPanel = class(Layer)

--批量选择的物品类型
BatchSelectItemPanel.SELECT_TYPE_CARD_EXCHANGE = "SELECT_TYPE_CARD_EXCHANGE" --卡牌以旧换新

function BatchSelectItemPanel:ctor()
	self.container = nil
	self.content = nil
end

function BatchSelectItemPanel:create(dataList, selectType, selectMaxNum, selectCB)
	local s = BatchSelectItemPanel.new()
	s:initLayer(dataList, selectType, selectMaxNum, selectCB)
	return s
end

function BatchSelectItemPanel:initLayer(dataList, selectType, selectMaxNum, selectCB)
	BatchSelectItemPanel.super.initLayer(self)

	self.dataList = dataList
	self.selectType = selectType
	self.selectMaxNum = selectMaxNum
	self.selectCB = selectCB

	--已经选择的物品数据列表
	self.selectDataList = {}

	local builder = LayoutBuilder:createWithContentsOfFile("scene/oldChangeNew.json")
	builder.useArtLabelTTF = true
	self.panelUI = builder:build("popup_oldChangeNew_01")

	self:addChild(self.panelUI)

	--刷新自身
	--keepOffset 保持位置不变
	function refreshSelf()
	end
	self.refreshSelf = refreshSelf

	--显示小格
	function onCellDataSet(cell)
		if cell.display and cell.data then
			if self.selectType == BatchSelectItemPanel.SELECT_TYPE_CARD_EXCHANGE then
				--卡牌以旧换新
				--显示卡牌图标
				if cell.display.cardIcon then
					cell.display.cardIcon:removeFromParentAndCleanup(true)
				end
				local aCardDisplay = cell.display:getChildByName("normal_card_small")
				aCardDisplay:setVisible(false)
				local params = {}
				params.sourceDisplay = aCardDisplay
				params.showInCenter = true
				cell.display.cardIcon = CanonGoodIcon.createGoodIcon(ResourceEnum.CARD, CommonManager:changeAvatarByCardInfo(cell.data), 0, params)
				cell.display:addChildAt(cell.display.cardIcon, aCardDisplay:getZOrder())

				--显示卡牌名称
				local cardName = CanonGoodIcon.getGoodName(ResourceEnum.CARD, cell.data.metaId, 0, {withoutAmount = true})
				cell.display:getChildByName("txt"):getChildByName("txt"):setString(cardName)

				--显示对勾
				if table.indexOf(self.selectDataList, cell.data) ~= nil then
					cell.display:getChildByName("icon_selected_green"):setVisible(true)
				else
					cell.display:getChildByName("icon_selected_green"):setVisible(false)
				end

				if cell.data.oldTONew_isFateCard then
					--同名卡牌(缘分卡)
					if not cell.display.rewardParticle then
						--显示粒子效果
						cell.display.rewardParticle = ParticleManager.geneParticle(ParticlePathConstants.FxStarline, ccp(cell.display:getChildByName("normal_card_small"):getPositionX(), cell.display:getChildByName("normal_card_small"):getPositionY()), 1, 1000, cell.display)
						cell.display.rewardParticle.refCocosObj:setPositionType(kCCPositionTypeRelative);
						local contentSize = cell.display:getChildByName("normal_card_small"):getContentSize()
						local width = cell.display:getChildByName("normal_card_small"):getScaleX() * contentSize.width
						local height = cell.display:getChildByName("normal_card_small"):getScaleY() * contentSize.height
						ParticleManager.moveParticle(cell.display.rewardParticle, 1, {ccp(width, 0), ccp(0, -height), ccp(-width, 0), ccp(0, height)})
					end
				else
					--删除粒子效果
					if cell.display.rewardParticle then --删除粒子效果
						cell.display.rewardParticle:removeFromParentAndCleanup(true)
						cell.display.rewardParticle = nil
					end
				end
			end
		end
	end

	--点击小格
	function onCellClick(evt)
		local cell = evt.context
		if cell.data then
			--print("cell.data = " .. tostringRich(cell.data))

			local dataIndex = table.indexOf(self.selectDataList, cell.data)
			if dataIndex ~= nil then
				table.remove(self.selectDataList, dataIndex)
			else
				if self.selectMaxNum > 1 then
					--可多选
					local currentSelectNum = #self.selectDataList
					if currentSelectNum >= self.selectMaxNum then
						--达到可选上限
						if self.selectType == BatchSelectItemPanel.SELECT_TYPE_CARD_EXCHANGE then
							--卡牌以旧换新
							local scene = Director:mgr():run()
							SuspensionLabel:showContent(scene, Localization:getInstance():getText("cardExchange_error_txt4", {num1 = self.selectMaxNum}))--只能选取x名材料武将！
							return
						end
					end
				else
					--单选 清空之前选择
					self.selectDataList = {}
				end
				table.insert(self.selectDataList, cell.data)
			end

			--刷新小格显示
			--onCellDataSet(cell)
			self.pageListView:refreshCurrentPage()--改为全刷新

			--更新已选择数量
			if self.selectType == BatchSelectItemPanel.SELECT_TYPE_CARD_EXCHANGE then
				--卡牌以旧换新
				self.panelUI:getChildByName("page_list"):getChildByName("txt_1"):getChildByName("txt"):setString(getTextByKey("cardExchange_choice_notice1", {num1 = self.selectMaxNum, num2 = #self.selectDataList}))--需要选取{num1}位武将，已选取{num2}位
			end
		end
	end

	--固定文字
	if self.selectType == BatchSelectItemPanel.SELECT_TYPE_CARD_EXCHANGE then
		--卡牌以旧换新
		self.panelUI:getChildByName("txt_distribution"):getChildByName("txt"):setString(getTextByKey("cardExchange_choice_title"))--请选择材料武将
	end

	--按钮
	local closeButton = Button:create(self.panelUI:getChildByName("login_btn_close"))
	closeButton:addEventListener(Events.kStart,onClose, self)

	local confirmButton = Button:create(self.panelUI:getChildByName("common_btn_propInfo_useBtn"))
	self.panelUI:getChildByName("common_btn_propInfo_useBtn"):getChildByName("txt_propInfo_useBtn"):setString(getTextByKey("yes"))--确认
	confirmButton:addEventListener(Events.kStart,onConfirmClick, self)

	--列表组件
	self.listView = ListView:create(onCellDataSet, nil, onCellClick, nil)
	self.listView:setDisplay(self.panelUI:getChildByName("page_list"):getChildByName("page_oldChangeNew_distribution"), "list_")
	self.pageListView = PageListView:create(self.listView)
	self.pageListView:setDisplay(self.panelUI:getChildByName("page_list"), {prevBtnName = "skillup_btn_pgup", nextBtnName = "skillup_btn_pgdown", pageTextName = "txt_3", pageTextInfoName = "txt_oldChangeNew_17"})

	UiStackManager_EventDispatcher:addEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged, self)
	BaseUINotify:addEventListener(UI_NOTIFY_EVENT_ENUM.SCENE_CLEAR, onSceneClear, self)

	--显示列表
	self.pageListView:setDataList(self.dataList)

	self.refreshSelf()
end

function BatchSelectItemPanel:dispose()
	UiStackManager_EventDispatcher:removeEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged)
	BaseUINotify:removeEventListener(UI_NOTIFY_EVENT_ENUM.SCENE_CLEAR, onSceneClear)

	if self.pageListView then
		self.pageListView:dispose()
	end

	self.dataList = nil
	self.selectType = nil
	self.selectMaxNum = nil
	self.selectCB = nil

	BatchSelectItemPanel.super.dispose(self)
end

function BatchSelectItemPanel:setTableViewsEnabled(v)
end

--关闭对话框
function BatchSelectItemPanel:close()
	PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
end

--------------------------------------------------------------------------------------------------------------------------------------static