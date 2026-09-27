--------------------------------------------------------------------------------
-- CanonCardScene.lua - 图鉴界面
-- author: litong.sun
-- date: 2014-04-02
--------------------------------------------------------------------------------

require "canon.panel.CardIllustratedShowPanel"
require "canon.panel.EquipIllustratedShowPanel"
require "canon.request.GetCardBookRequest"
require "canon.scene.BaseUIScene"


local visibleSize = CCDirector:sharedDirector():getVisibleSize()

CanonCardScene = class(BaseUIScene)

function CanonCardScene:ctor()
	self.title = getTextByKey("gallery_title")
	self.tabButton = {}
	self.tabPicActive = {}
	self.tabPicInActive = {}
	self.cardTabButton = {}
	self.equipTabButton = {}
	self.icon = {}
	self.cardData = {{ownedCount = 0}, {ownedCount = 0}, {ownedCount = 0}, {ownedCount = 0}}
	self.equipData = {{ownedCount = 0}, {ownedCount = 0}, {ownedCount = 0}}
end

function CanonCardScene:create()
	local scene = CanonCardScene.new()
	scene:initScene()
	return scene
end

function CanonCardScene:onInit()
	BaseUIScene.initBackGround(self)
	--新UI加黑底
    local colorLayer = LayerColor:create()
    colorLayer:setOpacity(kDarkOpacity)
    colorLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
    self:addChild(colorLayer)

	self.uiBuilder = LayoutBuilder:createWithContentsOfFile("scene/illu.json")
	self.uiBuilder.useArtLabelTTF = true
	self.mainUI = self.uiBuilder:build("illustrated_bg")
	self:addChild(self.mainUI)
	
	local head = self.mainUI:getChildByName("btn_illustrated_title")
	local tabButton = {"btn_illustrated_card", "btn_illustrated_equi"}
	local tabTextKey = {"gallery_cardTab", "gallery_equipTab"}
	for i = 1,2 do
		local tab = head:getChildByName(tabButton[i])
		tab:getChildByName("txt_illustrated_card"):setString(getTextByKey(tabTextKey[i]))
		self.tabPicActive[i] = tab:getChildByName("active")
		self.tabPicInActive[i] = tab:getChildByName("inactive")
		self.tabButton[i] = Button:create(tab)
		local function onClick()
			if not self.switchTab then
				self:showTab(i, 1)
			end
		end
		self.tabButton[i]:addEventListener(Events.kStart, onClick)
	end
	local cardHead = self.mainUI:getChildByName("skill_big_cardver")
	local cardTab = {"icon_counter_wei", "icon_counter_shu", "icon_counter_wu", "icon_counter_qun","btn_Achievement"}
	for i = 1,5 do
		self.cardTabButton[i] = Button:create(cardHead:getChildByName(cardTab[i]))
		local function onClick()
			if i == 5 then
				--第五个按钮的跳转
				if i == 5 then
				local argv = {enterScene="CanonCardScene",returnScene="CanonCardScene", params = {ignoreAction = true , secretaryTips = 0,CellNum = 3}}
					Director:sharedDirector():replaceScene(AchievementScene:create(argv))
				end

			else
				self:showTab(1, i)
			end
			
		end
		self.cardTabButton[i]:addEventListener(Events.kStart, onClick)
	end
	local equipHead = self.mainUI:getChildByName("skill_big_itemver")
	local equipTab = {"bg_icon_skill_big_1", "bg_icon_skill_big_2", "bg_icon_skill_big_3"}
	local equipTabIcon = {"skill_wepon", "skill_armor", "skill_horse"}
	for i = 1,3 do
		local tab = equipHead:getChildByName(equipTab[i])
		equipHead:getChildByName(equipTabIcon[i]).touchEnabled = false
		self.equipTabButton[i] = Button:create(tab)
		local function onClick()
			self:showTab(2, i)
		end
		self.equipTabButton[i]:addEventListener(Events.kStart, onClick)
	end

	self.mainUI:getChildByName("txt_illustrated_progress"):getChildByName("txt_illustrated_progress"):setString(getTextByKey("gallery_progress"))
	local icon1 = self.mainUI:getChildByName("icon_illu")
	for i = 0,3 do
		for j = 0,3 do
			local icon = icon1
			if i > 0 or j > 0 then
				icon = self.uiBuilder:build("icon_illu")
				icon:setPosition(ccp(icon1:getPositionX() + j*168, icon1:getPositionY() - i*159))
				self.mainUI:addChild(icon)
			end
			icon:getChildByName("icon_illu_sb"):setAnchorPoint(ccp(0.5,0.5))
			self.icon[i*4+j+1] = icon
			local iconButton = Button:create(icon)
			local function onClickIcon()
				local itemIndex = (self.currentPage-1)*16 + i*4 + j + 1
				if self.currentTab == 1 then
					local card = self.cardData[self.currentSubTab][itemIndex]
					if card and card.owned then
						local aPanel = CardIllustratedShowPanel:create(self, false, card.meta.id)
						PopoutManager:sharedManager():popout(aPanel, kPopoutDir.kScale, true, false, self)
					end
				else
					local equip = self.equipData[self.currentSubTab][itemIndex]
					if equip and equip.owned then
						local aPanel = EquipIllustratedShowPanel:create(self, equip.meta.id)
						PopoutManager:sharedManager():popout(aPanel, kPopoutDir.kScale, true, false, self)
					end
				end
			end
			iconButton:addEventListener(Events.kStart, onClickIcon)
		end
	end
	local pgUp = self.mainUI:getChildByName("btn_pgup")
	pgUp:getChildByName("txt"):setString(getTextByKey("skill_pageUpBtn"))
	self.prevButton = Button:create(pgUp)
	local function onPrevClick()
		self:setPage(self.currentPage-1)
	end
	self.prevButton:addEventListener(Events.kStart, onPrevClick)
	local pgDown = self.mainUI:getChildByName("btn_pgdown")
	pgDown:getChildByName("txt"):setString(getTextByKey("skill_pageDownBtn"))
	self.nextButton = Button:create(pgDown)
	local function onNextClick()
		self:setPage(self.currentPage+1)
	end
	self.nextButton:addEventListener(Events.kStart, onNextClick)

	BaseUIScene.onInit(self)
end

function CanonCardScene:back()
	self:replaceScene(MainMenuScene)
end

function CanonCardScene:doEnterAnimation()
	self:preEnterAnimation()
	self:startEnterAnimation()
end

function CanonCardScene:doExitAnimation()
	self:preExitAnimation()
	self:startExitAnimation()
end

function CanonCardScene:startEnterAnimation()
	BaseUIScene.startEnterAnimation(self)
	local function nodeActionFinished()
		self:nodeAnimationFinished()
	end
	self:showTab(1, 1)
	self.mainUI:setPositionX(self.mainUI:getPositionX() - visibleSize.width)
	local arr = CCArray:create()
	arr:addObject(CCMoveBy:create(0.2, ccp(visibleSize.width, 0)))
	arr:addObject(CCCallFunc:create(nodeActionFinished))
	self.mainUI:runAction(CCSequence:create(arr))
end

function CanonCardScene:sufEnterAnimation()
	BaseUIScene.sufEnterAnimation(self)

	local function onGetCardBookSucceed(e)
		local ownedCard = {}
		if e.data.sharkCardBook and e.data.sharkCardBook.cardMetaIds then
			for k,v in pairs(e.data.sharkCardBook.cardMetaIds) do
				ownedCard[v] = true
			end
		end
		for k,v in pairs(MetaManager.card_meta) do
			--增加过滤条件: 当前区域允许卡牌出现 modified by zheng.che @ 2015-1-12
			if v.haveGallery and SystemManager.isMyLocation(v.areaSwitch) then
				table.insert(self.cardData[v.country], {meta = v, owned = ownedCard[k]})
				if ownedCard[k] then
					self.cardData[v.country].ownedCount = self.cardData[v.country].ownedCount + 1
				end
			end
		end
		local function cardSort(l, r)
			if l.meta.maxEvolvedLevel > 1 and r.meta.maxEvolvedLevel <= 1 then
				return true
			elseif l.meta.maxEvolvedLevel <= 1 and r.meta.maxEvolvedLevel > 1 then
				return false
			end
			if l.meta.evolutionLevel ~= r.meta.evolutionLevel then
				return l.meta.evolutionLevel < r.meta.evolutionLevel
			end
			if l.meta.rare ~= r.meta.rare then
				return l.meta.rare < r.meta.rare
			end
			return l.meta.id < r.meta.id
		end
		for i,v in ipairs(self.cardData) do
			table.sort(v, cardSort)
		end
		local ownedEquip = {}
		if e.data.sharkCardBook and e.data.sharkCardBook.equipMetaIds then
			for k,v in pairs(e.data.sharkCardBook.equipMetaIds) do
				ownedEquip[v] = true
			end
		end
		for k,v in pairs(MetaManager.equip_meta) do
			if v.id ~= 235001 then
		      	if v.evolveLevel == 1 then
		        	table.insert(self.equipData[v.position], {meta = v, owned = ownedEquip[k]})
		        	if ownedEquip[k] then
		          		self.equipData[v.position].ownedCount = self.equipData[v.position].ownedCount + 1
		        	end
		      	end
		    end
		end
		local function equipSort(l, r)
			if l.meta.quality ~= r.meta.quality then
				return l.meta.quality < r.meta.quality
			end
			return l.meta.id < r.meta.id
		end
		for i,v in ipairs(self.equipData) do
			table.sort(v, equipSort)
		end
		self:showTab(1, 1)
	end
	local request = GetCardBookRequest.new(nil, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.GetCardBookSucceed, onGetCardBookSucceed)
	request:start()
end

function CanonCardScene:startExitAnimation()
	BaseUIScene.startExitAnimation(self)
	local function nodeActionFinished()
		self:nodeAnimationFinished()
	end
	local arr = CCArray:create()
	arr:addObject(CCMoveBy:create(0.2, ccp(-visibleSize.width, 0)))
	arr:addObject(CCCallFunc:create(nodeActionFinished))
	self.mainUI:runAction(CCSequence:create(arr))
end

function CanonCardScene:showTab(tab, subTab)
	local cardHead = self.mainUI:getChildByName("skill_big_cardver")
	local equipHead = self.mainUI:getChildByName("skill_big_itemver")
	if tab == 1 and subTab > 0 and subTab <= 4 then
		cardHead:setVisible(true)
		local cardTab = {"icon_counter_wei", "icon_counter_shu", "icon_counter_wu", "icon_counter_qun","btn_Achievement"}
		local activePic = {"bg_icon_wei_selected", "bg_icon_shu_selected", "bg_icon_wu_selected", "bg_icon_qun_selected","disabled"}
		local grayPic = {"bg_icon_wei", "bg_icon_shu", "bg_icon_wu", "bg_icon_qun","normal"}
		local isEnable = AchievementScene.isEnable()
		for i=1,5 do
			if i == 5 and not isEnable then
				local tab = cardHead:getChildByName(cardTab[i])
				tab:getChildByName(activePic[i]):setVisible(isEnable)
				tab:getChildByName(grayPic[i]):setVisible(isEnable)
				self.cardTabButton[i]:setEnable(isEnable)
			else
				local tab = cardHead:getChildByName(cardTab[i])
				tab:getChildByName(activePic[i]):setVisible(i == subTab)
				tab:getChildByName(grayPic[i]):setVisible(i ~= subTab)
				self.cardTabButton[i]:setEnable(i ~= subTab)
			end
		end
		equipHead:setVisible(false)
		if self.cardData[subTab] then
			self.mainUI:getChildByName("txt_illustrated_progress_num"):getChildByName("txt_illustrated_progress_num"):setString(self.cardData[subTab].ownedCount .. "/" .. #self.cardData[subTab])
		else
			self.mainUI:getChildByName("txt_illustrated_progress_num"):getChildByName("txt_illustrated_progress_num"):setString("0/0")
		end
	elseif tab == 2 and subTab > 0 and subTab <= 3 then
		equipHead:setVisible(true)
		local equipTab = {"bg_icon_skill_big_1", "bg_icon_skill_big_2", "bg_icon_skill_big_3"}
		for i=1,3 do
			equipHead:getChildByName(equipTab[i]):getChildByName("bg_icon_skill_big_selected"):setVisible(i == subTab)
			self.equipTabButton[i]:setEnable(i ~= subTab)
		end
		cardHead:setVisible(false)
		if self.equipData[subTab] then
			self.mainUI:getChildByName("txt_illustrated_progress_num"):getChildByName("txt_illustrated_progress_num"):setString(self.equipData[subTab].ownedCount .. "/" .. #self.equipData[subTab])
		else
			self.mainUI:getChildByName("txt_illustrated_progress_num"):getChildByName("txt_illustrated_progress_num"):setString("0/0")
		end
	else
		return
	end
	for i=1,2 do
		self.tabButton[i]:setEnable(i ~= tab)
		self.tabPicActive[i]:setVisible(i == tab)
		self.tabPicInActive[i]:setVisible(i ~= tab)
	end
	self.currentTab = tab
	self.currentSubTab = subTab
	self:setPage(1)
end

function CanonCardScene:setPage(index)
	local maxPage = self:getPageCount()
	index = math.min(maxPage, math.max(1, index))
	for i=0,3 do
		for j=0,3 do
			local itemIndex = (index - 1) * 16 + i * 4 + j + 1
			local iconContainer = self.icon[i*4+j+1]
			local icon = iconContainer.refCocosObj:getChildByTag(190)
			if icon then
				icon:removeFromParentAndCleanup(true)
				icon = nil
			end
			local iconSize = nil
			local name = ""
			if self.currentTab == 1 then
				local card = self.cardData[self.currentSubTab][itemIndex]
				if card then
					if card.owned then
						icon = getHeadIconCanonCardByMetaId(card.meta.id)
						iconSize = icon:getGroupBounds().size
					end
					name = getTextByKey(card.meta.name)
					iconContainer:setVisible(true)
				else
					iconContainer:setVisible(false)
				end
			else
				local equip = self.equipData[self.currentSubTab][itemIndex]
				if equip then
					if equip.owned then
						icon = CanonItem:create()
						icon:loadByMetaId(equip.meta.id)
						iconSize = icon:getGroupBounds().size
					else
						if self.currentSubTab == 1 then
							icon = Sprite:create("Item/Picture/Equip_empty.png")
						elseif self.currentSubTab == 2 then
							icon = Sprite:create("Item/Picture/Equip_empty2.png")
						else
							icon = Sprite:create("Item/Picture/Equip_empty3.png")
						end
						iconSize = icon:getContentSize()
					end
					name = getTextByKey(equip.meta.name)
					iconContainer:setVisible(true)
				else
					iconContainer:setVisible(false)
				end
			end
			if icon then
				icon:setTag(190)
				local bk = iconContainer:getChildByName("icon_illu_sb")
				icon:setPosition(ccp(bk:getPositionX(), bk:getPositionY()))
				icon:setScaleX(bk:getContentSize().width / iconSize.width)
				icon:setScaleY(bk:getContentSize().height / iconSize.height)
				iconContainer:addChildAt(icon, 0)
				bk:setVisible(false)
			else
				iconContainer:getChildByName("icon_illu_sb"):setVisible(true)
			end
			iconContainer:getChildByName("txt_item_name"):getChildByName("txt"):setString(name)
		end
	end
	self.prevButton:setEnable(index > 1)
	self.prevButton.display:getChildByName("btn_d_many"):setVisible(index > 1)
	self.prevButton.display:getChildByName("btn_d_many_disable"):setVisible(index <= 1)
	self.nextButton:setEnable(index < maxPage)
	self.nextButton.display:getChildByName("btn_d_many"):setVisible(index < maxPage)
	self.nextButton.display:getChildByName("btn_d_many_disable"):setVisible(index >= maxPage)
	self.mainUI:getChildByName("txt_page"):getChildByName("txt"):setString(index .. "/" .. maxPage)
	self.currentPage = index
end

function CanonCardScene:getPageCount()
	if self.currentTab == 1 then
		return self.cardData[self.currentSubTab] and math.floor((#self.cardData[self.currentSubTab]+15)/16) or 0
	else
		return self.equipData[self.currentSubTab] and math.floor((#self.equipData[self.currentSubTab]+15)/16) or 0
	end
end
