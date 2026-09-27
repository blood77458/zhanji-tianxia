--
-- FragmentScene
-- Author: czh
-- Date: 2014-02-12 18:13:31
--
require "hecore.display.CocosObject"
require "hecore.display.Director"
require "hecore.ui.Button"
require "hecore.display.Sprite"
require "hecore.ui.LayoutBuilder"
require "canon.scene.BaseUIScene"
require "canon.panel.FragmentEquipListPanel"
require "canon.customUI.TabPanelChangeComponent"
require "canon.panel.FragmentCardListPanel"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

FragmentTagEnum = {
  CARD = 1,
  EQUIP = 2,
}

local enter_animation_duration = 0.3

-------------------------------------------------------------------------------
-- 可用函数
-------------------------------------------------------------------------------


local function cardTabButtonSelected(evt)
  evt.context.tabChangeComponent:changeToPanelByIndex(FragmentTagEnum.CARD)
end

local function cquipTabButtonSelected(evt)
  evt.context.tabChangeComponent:changeToPanelByIndex(FragmentTagEnum.EQUIP)
end

-------------------------------------------------------------------------------
-- 初始化处理
-------------------------------------------------------------------------------

FragmentScene = class(BaseUIScene)

function FragmentScene:ctor()
end

local globalReturnScene

function FragmentScene:create(argv)
  local s = FragmentScene.new()
  if argv then 
      self.argv = argv 
  else
      self.argv = {enterScene=nil,returnScene=nil,params={}}
  end

  --当前选择的panel
  self.selectedPanel = nil
  -- self.bossInfo = self.argv.params.data
  -- if self.argv.returnScene == "FragmentScene" then
  --   globalReturnScene = "FragmentScene"
  -- elseif self.argv.returnScene == "ChapterMapScene" then
  --   globalReturnScene = "ChapterMapScene"
  -- end
  s:initScene()
  return s
end

function FragmentScene:onInit()

	--用于生成新panle
	local function onCreatePanel(aIndex)
		if aIndex == FragmentTagEnum.CARD then
			return FragmentCardListPanel:create(self)
		elseif aIndex == FragmentTagEnum.EQUIP then
			return FragmentEquipListPanel:create(self)
		end
		print("无效的panle编号! aIndex = " .. aIndex)
	end

	BaseUIScene.initBackGround(self)

	self.title = Localization:getInstance():getText("home_fragmentBtn")

	local builder = LayoutBuilder:createWithContentsOfFile("scene/soulcombine.json")
	builder.useArtLabelTTF = true
	local ui = builder:build("soulcombine")
	self:addChild(ui)
	self.ui = ui

	--静态文本
	self.noneText = ui:getChildByName("txt_soulcombine_info")
	self.noneText:setVisible(false)

	self.tabChangeComponent = TabPanelChangeComponent.new(self, onCreatePanel, nil, nil, nil)

	--显示tab
	self.uiGroup1 = ui:getChildByName("btn_tab_cardsoul")
	self.uiGroup1:getChildByName("txt"):setString(Localization:getInstance():getText("fragment_cardTab"))
	self.cardTabButton = Button:create(self.uiGroup1)
	self.cardTabButton:addEventListener(Events.kStart, cardTabButtonSelected, self)
	self.tabChangeComponent:addTab(self.cardTabButton)

	self.uiGroup2 = ui:getChildByName("btn_tab_itemsoul")
	self.uiGroup2:getChildByName("txt"):setString(Localization:getInstance():getText("fragment_equipTab"))
	self.euuipTabButton = Button:create(self.uiGroup2)
	self.euuipTabButton:addEventListener(Events.kStart, cquipTabButtonSelected, self)
	self.tabChangeComponent:addTab(self.euuipTabButton)

	--设定初始显示的页面为第一页
	self.tabChangeComponent:changeToPanelByIndex(FragmentTagEnum.CARD)
	
	--新加跳转炼魂按钮
	local gotoCardRebirthBtn = Button:create(self.ui:getChildByName("icon_therefined"))
	self.ui:getChildByName("icon_therefined"):setPosition(ccp(610,1047))
	self.ui:getChildByName("icon_therefined"):setZOrder(66)
	local function onGotoCardRebirthBtnClick(e)
		if DataManager.getCurrUser().level < MetaManager.getGameSettingConfig().cardResolveUnlockLevel then
			SuspensionLabel:showContent(self, Localization:getInstance():getText("cardSplit_prompt", {num = MetaManager.getGameSettingConfig().cardResolveUnlockLevel}))
		-- if (DataManager.getCurrUser().level < MetaManager.getGameSettingConfig().sacrificeUnlockLevel) then
		-- 	SuspensionLabel:showContent(self, Localization:getInstance():getText("module_needLevel", {num = MetaManager.getGameSettingConfig().sacrificeUnlockLevel}))
		else
			Director:sharedDirector():replaceScene(CardRebirthScene:create({params = {showPanelIndex = 3}}))
		end
	end
	gotoCardRebirthBtn:addEventListener(Events.kStart, onGotoCardRebirthBtnClick)
  
	local function refreshSelf()
	end
	self.refreshSelf = refreshSelf
  
	refreshSelf()

	BaseUIScene.onInit(self)
end
-----------------------------------------------外部接口------------------------------------------------------------

--改用ui堆栈来处理滚动启用状态 这里不需要了
-- function FragmentScene:setTableViewsEnabled(enabled)
-- 	if self.tabChangeComponent and self.tabChangeComponent.currentSelectedPanel then
-- 		self.tabChangeComponent.currentSelectedPanel:setTableViewTouched(enabled)
-- 	end
-- end

-----------------------------------------------进出场景动画------------------------------------------------------------
function FragmentScene:doEnterAnimation()
	self:preEnterAnimation()
	self:startEnterAnimation()
end

function FragmentScene:preEnterAnimation()
	BaseUIScene.preEnterAnimation(self)
	--
	CanonPlayBackgroundMusic("music/background.mp3", true)
end

function FragmentScene:startEnterAnimation()
	BaseUIScene.startEnterAnimation(self)
	local function enterActionFinished()
		self:nodeAnimationFinished()
	end

	self.ui:setPositionX(self.ui:getPositionX() - visibleSize.width)
	local arr = CCArray:create()
	arr:addObject(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
	arr:addObject(CCCallFunc:create(enterActionFinished))
	self.ui:runAction(CCSequence:create(arr))
end

function FragmentScene:sufEnterAnimation()
	BaseUIScene.sufEnterAnimation(self)
	--
end

function FragmentScene:doExitAnimation()
	self:preExitAnimation()
	self:startExitAnimation()
end

function FragmentScene:preExitAnimation()
	BaseUIScene.preExitAnimation(self)
end

function FragmentScene:startExitAnimation()
	BaseUIScene.startExitAnimation(self)
	local function enterActionFinished()
		self:nodeAnimationFinished()
	end

	local arr = CCArray:create()
	arr:addObject(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
	arr:addObject(CCCallFunc:create(enterActionFinished))
	self.ui:runAction(CCSequence:create(arr))

	--同时当前选择页也退出动画 并行进行
	self.tabChangeComponent:startPanelExit(nil)
end

function FragmentScene:sufExitAnimation()
	BaseUIScene.sufExitAnimation(self)
end
-----------------------------------------------进出场景动画------------------------------------------------------------

-- 退出到外层
function FragmentScene:back()
	self:replaceScene(MainMenuScene)
end

function FragmentScene:dispose()
	self.tabChangeComponent:dispose()
	self.tabChangeComponent = nil

	FragmentScene.super.dispose(self)
end

-----------------------------------------------静态函数------------------------------------------------------------
function FragmentScene.Get_Card_Whole_Information( This_Card_Id )
	local function getSubTableByKey(sourceTable, key)
		local subTable = nil
			local keyNo = -1
			for aKey, aValue in pairs(sourceTable) do
			if (tostring(sourceTable[aKey][key.name])==tostring(key.value)) then
				subTable = sourceTable[aKey]
				keyNo = aKey
				break;
			end
		end
		return subTable,keyNo
	end
	local All_Cards = DataManager.getCardsData()
	local Results = getSubTableByKey( All_Cards, {name="cardId", value=This_Card_Id} )
	return Results
end

function FragmentScene.Get_Equip_Whole_Information( This_Equip_Id )
	local function getSubTableByKey(sourceTable, key)
		local subTable = nil
			local keyNo = -1
			for aKey, aValue in pairs(sourceTable) do
			if (tostring(sourceTable[aKey][key.name])==tostring(key.value)) then
				subTable = sourceTable[aKey]
				keyNo = aKey
				break;
			end
		end
		return subTable,keyNo
	end
	local All_Equips = DataManager.getEquipsData()
	local Results = getSubTableByKey( All_Equips, {name="equipId", value=This_Equip_Id} )
	return Results
end
