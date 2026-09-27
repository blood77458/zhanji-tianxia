-- ENCHANT_MODIFY 装备增加附灵信息 同时属性扩充为3个 modified by zheng.che @ 2014-12-18

require "hecore.display.Director"

require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.ui.TableView"
require "hecore.ui.PopoutManager"

require "canon.data.MetaManager"

require "canon.models.PackageModel"
require "canon.models.CommonManager"

require "canon.panel.EquipInfoPanel"
require "canon.features.equipment.panel.EquipInfoNewPanel"
require "canon.panel.PropInfoPanel"
require "canon.panel.CardInfoNewPanel"
require "canon.panel.ItemSellMessageBoxPanel"
require "canon.panel.MessageBoxPanel"
require "canon.panel.GetRewardInfoPanel"
require "canon.panel.VipWarningPanel"

require "canon.request.GetEquipsRequest"
require "canon.request.GetPropsRequest"
require "canon.request.ReplaceCardRequest"
require "canon.request.SetupEquipRequest"
require "canon.request.BuyGridRequest"
require "canon.request.UsePropRequest"

require "canon.manager.BagCalcManager"

require "canon.scene.BaseUIScene"

require "canon.customUI.CanonItem"
require "canon.customUI.SuspensionLabel"
require "canon.scene.PropConfig"

require "canon.request.ReplaceMatrixGridRequest"

require "canon.panel.BackPackSortPanel"
require "canon.panel.SpiritBackPackSortPanel"
require "canon.panel.ReNameCoolingPanel"

require "canon.features.multilineup.manager.BitOperManager"

TOTALENTERDURATION = 0.3
CELLENTERDURATION = 0.15


MAXRARE = 7

MAX_OPEN_CHEST_NUM = 10

local SELF

local card_tableview = nil;
local equip_tableview = nil;
local item_tableview = nil;

local selfTableInfo = {}

local SORT_TYPE = table.const{
	RARE_ASC = 1,
	RARE_DESC = 2,
	LV_ASC = 3,
	LV_DESC = 4,
	ATK_ASC = 5,
	ATK_DESC = 6,
	DEF_ASC = 7,
	DEF_DESC = 8,
	HP_ASC = 9,
	HP_DESC = 10,
}

local function runChangeBtnSellAction(backpackStatus, curTab)
	if not backpackStatus then
		backpackStatus = BACKPACK_STATUS.CHECKBOX
	end
	if not curTab then
		curTab = SELF.currentTab
	end
	
	local previousBtnEnable = SELF.btnSell.enable
			SELF.btnSell:setEnable(false)
			local function changeButtonText()
				if backpackStatus == BACKPACK_STATUS.NORMAL then
					SELF.mainUI:getChildByName("btn_inventory_R"):getChildByName("txt_bag_SellBtn"):setString(getTextByKey("cancel"))
				else
					SELF.mainUI:getChildByName("btn_inventory_R"):getChildByName("txt_bag_SellBtn"):setString(getTextByKey("bag_SellBtn"))
				end
			end
				
			local function onButtonClickFinish()
				SELF.btnSell:setEnable(previousBtnEnable)
			end
				
			local actionArray = CCArray:create() 
			actionArray:addObject(CCMoveBy:create(0.2, ccp(200, 0)))
			actionArray:addObject(CCCallFuncN:create(changeButtonText))
			actionArray:addObject(CCMoveBy:create(0.2, ccp(-200, 0)))
			actionArray:addObject(CCCallFuncN:create(onButtonClickFinish))
			SELF.mainUI:getChildByName("btn_inventory_R"):runAction(CCSequence:create(actionArray))
			
			
			SELF.btnBuyGrid:setEnable(false)
			SELF:setTableViewsEnabled(false)
			local function changeTitleInfo()
				SELF:setSellMenuVisible(false)
				SELF:setTableViewsEnabled(true)
				SELF.sellPrice = 0
				if backpackStatus == BACKPACK_STATUS.NORMAL then
					SELF.mainUI:getChildByName("inventory_title"):getChildByName("txt_tochose"):setVisible(true)
					SELF.mainUI:getChildByName("inventory_title"):getChildByName("bg_inventory_title_bg"):setVisible(false)
					if curTab ==  BAGCATEGORY.card then
						SELF.mainUI:getChildByName("inventory_title"):getChildByName("txt_tochose"):getChildByName("txt"):setString(getTextByKey("sellItem_selectCard"))
					elseif curTab ==  BAGCATEGORY.item then
						SELF.mainUI:getChildByName("inventory_title"):getChildByName("txt_tochose"):getChildByName("txt"):setString(getTextByKey("sellItem_selectProp"))
					elseif curTab ==  BAGCATEGORY.equip then
						SELF.mainUI:getChildByName("inventory_title"):getChildByName("txt_tochose"):getChildByName("txt"):setString(getTextByKey("sellItem_selectEquip"))
					end
					SELF.mainUI:getChildByName("inventory_title"):getChildByName("txt_inventory_num"):setVisible(false)
					SELF.mainUI:getChildByName("inventory_title"):getChildByName("txt_inventory"):setVisible(false)
					SELF.mainUI:getChildByName("inventory_title"):getChildByName("btn_inventory_switch"):setVisible(false)
				else
					SELF.mainUI:getChildByName("inventory_title"):getChildByName("txt_tochose"):setVisible(false)
					SELF.mainUI:getChildByName("inventory_title"):getChildByName("bg_inventory_title_bg"):setVisible(true)
					SELF.mainUI:getChildByName("inventory_title"):getChildByName("txt_tochose"):getChildByName("txt"):setString("")
					SELF.mainUI:getChildByName("inventory_title"):getChildByName("txt_inventory_num"):setVisible(true)
					SELF.mainUI:getChildByName("inventory_title"):getChildByName("txt_inventory"):setVisible(true)
					SELF.mainUI:getChildByName("inventory_title"):getChildByName("btn_inventory_switch"):setVisible(true)
				end
			end
				
			local function onTitleMoveFinish()
				SELF.btnBuyGrid:setEnable(true)
			end
				
			local actionArray = CCArray:create() 
			actionArray:addObject(CCMoveBy:create(0.2, ccp(0, 400)))
			actionArray:addObject(CCCallFuncN:create(changeTitleInfo))
			actionArray:addObject(CCMoveBy:create(0.2, ccp(0, -400)))
			actionArray:addObject(CCCallFuncN:create(onTitleMoveFinish))			
			SELF.mainUI:getChildByName("inventory_title"):runAction(CCSequence:create(actionArray))
			
end

local function setCocosObjectColor(obj, color)
	for k,v in pairs(obj.list)
	do
		if type(v.setColor) == "function" then
			v:setColor(color)
		end
		if type(v.list) == "table" then
			setCocosObjectColor(v, color)
		end
	end
end

local function releaseAll(param)
	if type(param.dispose) == "function" then
		param:dispose()
	else
		for k,v in pairs(param)
		do
			releaseAll(v)
		end
	end
end

local visibleSize = CCDirector:sharedDirector():getVisibleSize()
local item_position = {card={},item={},equip={}}
local user_select = { tab=nil,row=nil,col=nil }
local selectCard  = {}
local nowSelected = 0
local matterCardSelected = nil --选中的素材卡
BACKPACK_STATUS = table.const{
    NORMAL = 1,   --正常，显示卡牌信息
    OPTION = 2,   --单选
    CHECKBOX = 3, --复选
}

SORT_ORDER = table.const{
    ASC  = 0, --升序
    DESC = 1, --降序
}

local BackpackUIStatus = BACKPACK_STATUS.NORMAL

local queueData = {}--出战&上阵卡牌
local queueCardList = {}--卡牌阵容信息（0~7八种状态） by l1ghtsaber
local queueEquipList = {}--装备阵容信息（0~7八种状态） by l1ghtsaber

local function isCardInBattle(card)
	if card.isInBattle == nil or card.isLeaderCard == nil or card.isInMatrix then
		local isLeaderCard = false;
		card.isInBattle = false;
		card.isLeaderCard = false
		card.isInMatrix = false
		if queueData[card.cardId] then
			if queueData[card.cardId] == 1 then
				card.isLeaderCard = true;
				card.isInBattle = true;
			elseif queueData[card.cardId] > 100 then--isInMatrix
				card.isInMatrix = true
			else
				card.isInBattle = true;
			end
		end
	end
	return card.isInBattle,card.isLeaderCard, card.isInMatrix
end

local idsToSell = {}

BackpackScene  = class(BaseUIScene)
function BackpackScene:ctor()
	SELF = self
    SELF.tableUI = nil
    SELF.targetInfoPanel = nil
    SELF.title = getTextByKey("bag_Title")
    SELF.mainUI = nil
    SELF.card_view  = nil   
    SELF.item_view  = nil
    SELF.equip_view = nil 
    SELF.sortButton = {}
    SELF.sortButtonTxt = {}
    SELF.currentTab = nil
	BackpackUIStatus = BACKPACK_STATUS.NORMAL
    SELF.BackpackFilter = BACKPACK_FILTER.ALL
    SELF.sortOrder = nil
    SELF.coverLayer = nil
    SELF.preTableUI = nil
    SELF.slotNum = {card=nil,item=nil,equip=nil}
	SELF.enablePanelChange = true;
	SELF.limitSelectNum = 999
	SELF.notShowTitle = true
	SELF.sellPrice = 0
	--SELF.useCoroutine = true
  self.curSceneEnum = SceneEnum.BackpackScene
end

local previousIsCardTrain = false

function BackpackScene:create( argv, isBaseUIReplace )
    if argv then 
        self.argv = argv 
    else
        self.argv = {enterScene=nil,returnScene=nil,params={}}
    end
		
		if self.argv.params.isCardTrain ~= nil then
			previousIsCardTrain = self.argv.params.isCardTrain
		else
			self.argv.params.isCardTrain = previousIsCardTrain
		end
		
	
	self.isBaseUIReplace = isBaseUIReplace
    
    local scene = BackpackScene.new()
    scene:initScene()
    return scene
end

local priotyTable = {}
function BackpackScene:cardGeneralSort()
	priotyTable = {}
	for k,v in pairs(SELF.card_data)
	do
		priotyTable[v.cardId] = k
	end
	
	local function cardGeneralSortFun(a, b)
		local isAInBattle, isALeaderCard, isAInMatirx = isCardInBattle(a)
		local isBInBattle, isBLeaderCard, isBInMatirx = isCardInBattle(b)
		if isALeaderCard and not isBLeaderCard then
			return true
		elseif isAInBattle and not isBInBattle then
			return true
		elseif isAInMatirx and not isBInMatirx then
			return true
		elseif isALeaderCard == isBLeaderCard and isAInBattle == isBInBattle then
			return priotyTable[a.cardId] < priotyTable[b.cardId]
		else
			return false
		end
	end
	
	table.sort(SELF.card_data, cardGeneralSortFun)
end


function BackpackScene:equipGeneralSort()
	priotyTable = {}
	for k,v in pairs(SELF.equip_data)
	do
		priotyTable[v.equipId] = k
	end
	
	local function equipGeneralSortFun(a, b)
		local isAEquiped = (a.cardId > 0)
		local isBEquiped = (b.cardId > 0)
		if isAEquiped and not isBEquiped then
			return true
		elseif isAEquiped == isBEquiped then
			return priotyTable[a.equipId] < priotyTable[b.equipId]
		else
			return false
		end
	end
	
	table.sort(SELF.equip_data, equipGeneralSortFun)
end

function BackpackScene:refreshTable(keepOffset, insertData, deleteData , index)
	if keepOffset then
		local tableOffset = SELF.tableUI:getContentOffset()
		SELF.tableUI:reloadData()
		
		-- if insertData then
		-- 	tableOffset.y = tableOffset.y - 185
		-- end
		
		if deleteData then
			-- tableOffset.y = tableOffset.y + 185
			-- tableOffset.y = -(SELF.tableUI.tableViewRenderer:numberOfCells() * 185 - (BAGCONFIG.HEIGHT - 30))
			if index < 6 then
				tableOffset.y = tableOffset.y + 206  --（原为185）
			-- else

			end

		end	
		local minOffsetY
		local maxOffsetY
		local numberOfCells = SELF.tableUI.tableViewRenderer:numberOfCells()
	    local cellSize = SELF.tableUI.tableViewRenderer:getContentSize()
	    local viewSize = SELF.tableUI:getViewSize()
	    if (cellSize.height * numberOfCells) > viewSize.height then
	    	minOffsetY = viewSize.height - (cellSize.height * numberOfCells)
	    	maxOffsetY = 0
	    	if tableOffset.y < minOffsetY then
	    		tableOffset.y = minOffsetY
	    	end
	    	if tableOffset.y > maxOffsetY then
	    		tableOffset.y = maxOffsetY
	    	end
	   	else
	   		tableOffset.y = viewSize.height - (cellSize.height * numberOfCells)
	   	end
		SELF.tableUI:setContentOffset(tableOffset, true)
	else
		SELF.tableUI:reloadData()
	end
end

function BackpackScene:refreshTableAfterUserProp( propMetaId )
	local itemData = DataManager.getPropsData()
	local usePropIndex = 0
	local PropExistAfterUse = false
	local newItemTable = {}
	for k,v in pairs(itemData) do
		if v.amount > 0 or v.metaId == propMetaId then
			table.insert(newItemTable , v)
		end
	end
	--道具
    for i,item in pairs(newItemTable) do 
        newItemTable[i].quality = MetaManager.prop_meta[item.metaId].quality
    end

	local function sortFunc(a , b)
		if a.quality == b.quality then
			return a.metaId < b.metaId
		else
			return a.quality > b.quality
		end
    end

    table.sort(newItemTable,sortFunc)

    for k,v in pairs(newItemTable) do
    	if v.metaId == propMetaId then
			usePropIndex = k
			if v.amount > 0 then
				PropExistAfterUse = true
			end
		end
    end

	local tableOffset = SELF.tableUI:getContentOffset()
	SELF.tableUI:reloadData()
	local minOffsetY
	local maxOffsetY
	local numberOfCells = SELF.tableUI.tableViewRenderer:numberOfCells()
    local cellSize = SELF.tableUI.tableViewRenderer:getContentSize()
    local viewSize = SELF.tableUI:getViewSize()
	local offsetY
	if PropExistAfterUse then
		offsetY = (usePropIndex - #newItemTable + 2) * cellSize.height
	else
		offsetY = (usePropIndex - (#newItemTable -1) + 2) * cellSize.height
	end

	tableOffset.y = offsetY
	
    if (cellSize.height * numberOfCells) > viewSize.height then
    	minOffsetY = viewSize.height - (cellSize.height * numberOfCells)
    	maxOffsetY = 0
    	if tableOffset.y < minOffsetY then
    		tableOffset.y = minOffsetY
    	end
    	if tableOffset.y > maxOffsetY then
    		tableOffset.y = maxOffsetY
    	end
   	else
   		tableOffset.y = viewSize.height - (cellSize.height * numberOfCells)
   	end
	SELF.tableUI:setContentOffset(tableOffset, true)
end

local function getCardInfoFromInitData(cardId)
  local gameInitData = DataManager.getGameInitData()
  local aCard = {}    
  for _, temp in ipairs(gameInitData.sharkCards.sharkCards) do
    if cardId == temp.cardId then
      aCard = temp
      break
      end
  end
  return aCard
end

function BackpackScene:refreshUIForPanelInfo(aCardId, extraParams)
	local relocate = true
	if not extraParams or not extraParams.slaveIds then
		relocate = false
	end
	if relocate then
		for _,value in pairs(extraParams.slaveIds) do
			for k, v in pairs(SELF.card_data)
			do
				if v.cardId == value then
					table.remove(SELF.card_data, k)
					break;
				end
			end
		end
	end

	local aIndex
	for k, aCardData in ipairs(SELF.card_data) do
		if aCardData.cardId == aCardId then
			SELF.card_data[k] = getCardInfoFromInitData(aCardId)
			SELF.card_data[k].rare = MetaManager.card_meta[SELF.card_data[k].metaId].rare
			isCardInBattle(SELF.card_data[k])
			if g_cardInfoCache[aCardData.cardId] then
				g_cardInfoCache[aCardData.cardId].needUpdate = true
			end
			aIndex = k
			break
		end
	end
	if true then
		ViewControlUtil.refreshAndLocateTableView(SELF.tableUI, aIndex)
	else
		ViewControlUtil.refreshTableView(SELF.tableUI, true)
	end

	self:recalcBagInfo()
end

function BackpackScene:getPanelInfoData(aCardId)
	for k, aCardData in ipairs(SELF.card_data) do
		if aCardData.cardId == aCardId then
			return aCardData
		end
	end
end

function BackpackScene:recalcBagInfo()
	SELF.usedSpace = BagCalcManager.calcUsedGridNum()
	SELF.totalSpace = BagCalcManager.calcTotalGridNum()
	SELF.mainUI:getChildByName("inventory_title"):getChildByName("txt_inventory_num"):getChildByName("font"):setString(tostring(SELF.usedSpace).."/" .. SELF.totalSpace)
end

function BackpackScene:onSellFinish()	
	--BackpackUIStatus = BACKPACK_STATUS.NORMAL
	--idsToSell = {}
	
	SELF.usedSpace = BagCalcManager.calcUsedGridNum()
	SELF.totalSpace = BagCalcManager.calcTotalGridNum()
	SELF.mainUI:getChildByName("inventory_title"):getChildByName("txt_inventory_num"):getChildByName("font"):setString(tostring(SELF.usedSpace).."/" .. SELF.totalSpace)
	--SELF.mainUI:getChildByName("btn_inventory_R"):getChildByName("txt_bag_SellBtn"):setString(getTextByKey("bag_SellBtn"))
	--SELF:setSellMenuVisible(false)
	
	if  SELF.currentTab == BAGCATEGORY.card then
		if #SELF.card_data == 0 and not tosetvisible then
			setCocosObjectColor(SELF.btnSell.display, ccc3(80, 80, 80))
			SELF.btnSell:setEnable(false)
		end
		SuspensionLabel:showContent(SELF, getTextByKey("sellItem_cardSuccess"))
	elseif SELF.currentTab == BAGCATEGORY.item then 
		if #SELF.item_data == 0 and not tosetvisible then
			setCocosObjectColor(SELF.btnSell.display, ccc3(80, 80, 80))
			SELF.btnSell:setEnable(false)
		end
		SuspensionLabel:showContent(SELF, getTextByKey("sellItem_propSuccess"))
	elseif SELF.currentTab == BAGCATEGORY.equip then
		if #SELF.equip_data == 0 and not tosetvisible then
			setCocosObjectColor(SELF.btnSell.display, ccc3(80, 80, 80))
			SELF.btnSell:setEnable(false)
		end
		SuspensionLabel:showContent(SELF, getTextByKey("sellItem_equipSuccess"))
	end
	
	runChangeBtnSellAction()
	BackpackUIStatus = BACKPACK_STATUS.NORMAL
	idsToSell = {}
end

local function sortCardFunc( evt )
	local function sortFunc(a , b)
		local isAInBattle, isALeaderCard, isAInMatirx = isCardInBattle(a)
		local isBInBattle, isBLeaderCard, isBInMatirx = isCardInBattle(b)
		local isACanEvolve = false
		local isBCanEvolve = false
		if (SELF.argv.enterScene == "CardEvolutionScene" and type(SELF.argv.params) == "table" and SELF.argv.params.cardType == "master") then
			isACanEvolve = a.hasMaterial and a.levelEnough
			isBCanEvolve = b.hasMaterial and b.levelEnough
		end
		if isACanEvolve ~= isBCanEvolve then
			return isACanEvolve
		elseif isALeaderCard ~= isBLeaderCard then
			return isALeaderCard
		elseif isAInBattle ~= isBInBattle then
			return isAInBattle
		elseif isAInMatirx ~= isBInMatirx then
			return isAInMatirx
		else
			if evt.context == SORT_TYPE.RARE_ASC then
				if a.rare == b.rare then
					return a.metaId < b.metaId
				else
					return a.rare < b.rare
				end
			elseif evt.context == SORT_TYPE.RARE_DESC then
				if a.rare == b.rare then
					return a.metaId < b.metaId
				else
					return a.rare > b.rare
				end
			elseif evt.context == SORT_TYPE.LV_ASC then
				if a.level == b.level then
					return a.metaId < b.metaId
				else
					return a.level < b.level
				end
			elseif evt.context == SORT_TYPE.LV_DESC then
				if a.level == b.level then
					return a.metaId < b.metaId
				else
					return a.level > b.level
				end
			elseif evt.context == SORT_TYPE.ATK_ASC then
				local cardStatusA = CommonManager:getBackpackCardPropertiesWithSharkCard( a )
				local cardStatusB = CommonManager:getBackpackCardPropertiesWithSharkCard( b )
				if cardStatusA.att == cardStatusB.att then
					return a.metaId < b.metaId
				else
					return cardStatusA.att < cardStatusB.att
				end
			elseif evt.context == SORT_TYPE.ATK_DESC then
				local cardStatusA = CommonManager:getBackpackCardPropertiesWithSharkCard( a )
				local cardStatusB = CommonManager:getBackpackCardPropertiesWithSharkCard( b )
				if cardStatusA.att == cardStatusB.att then
					return a.metaId < b.metaId
				else
					return cardStatusA.att > cardStatusB.att
				end
			elseif evt.context == SORT_TYPE.DEF_ASC then
				local cardStatusA = CommonManager:getBackpackCardPropertiesWithSharkCard( a )
				local cardStatusB = CommonManager:getBackpackCardPropertiesWithSharkCard( b )
				if cardStatusA.def == cardStatusB.def then
					return a.metaId < b.metaId
				else
					return cardStatusA.def < cardStatusB.def
				end
			elseif evt.context == SORT_TYPE.DEF_DESC then
				local cardStatusA = CommonManager:getBackpackCardPropertiesWithSharkCard( a )
				local cardStatusB = CommonManager:getBackpackCardPropertiesWithSharkCard( b )
				if cardStatusA.def == cardStatusB.def then
					return a.metaId < b.metaId
				else
					return cardStatusA.def > cardStatusB.def
				end
			elseif evt.context == SORT_TYPE.HP_ASC then
				local cardStatusA = CommonManager:getBackpackCardPropertiesWithSharkCard( a )
				local cardStatusB = CommonManager:getBackpackCardPropertiesWithSharkCard( b )
				if cardStatusA.hp == cardStatusB.hp then
					return a.metaId < b.metaId
				else
					return cardStatusA.hp < cardStatusB.hp
				end
			elseif evt.context == SORT_TYPE.HP_DESC then
				local cardStatusA = CommonManager:getBackpackCardPropertiesWithSharkCard( a )
				local cardStatusB = CommonManager:getBackpackCardPropertiesWithSharkCard( b )
				if cardStatusA.hp == cardStatusB.hp then
					return a.metaId < b.metaId
				else
					return cardStatusA.hp > cardStatusB.hp
				end
			end
		end
    end
    table.sort(SELF.card_data,sortFunc)
    HeMemDataHolder:setString("savedSortOrder_card", tostring(evt.context))
end

local function sortEquipFunc( evt )
    local function sortFunc(a , b)
		local isAEquiped = (a.cardId > 0)
		local isBEquiped = (b.cardId > 0)
		if isAEquiped and not isBEquiped then
			return true
		elseif isAEquiped == isBEquiped then
			if evt.context == SORT_TYPE.RARE_ASC then 
				if a.quality == b.quality then
					return a.metaId < b.metaId
				else
					return a.quality < b.quality
				end
			elseif evt.context == SORT_TYPE.RARE_DESC then
				if a.quality == b.quality then
					return a.metaId < b.metaId
				else
					return a.quality > b.quality
				end
			elseif evt.context == SORT_TYPE.LV_ASC then 
				if a.level == b.level then
					return a.metaId < b.metaId
				else
					return a.level < b.level
				end
			elseif evt.context == SORT_TYPE.LV_DESC then
				if a.level == b.level then
					return a.metaId < b.metaId
				else
					return a.level > b.level
				end
			end
		else
			return false
		end
    end
    table.sort(SELF.equip_data,sortFunc)
    HeMemDataHolder:setString("savedSortOrder_equip", tostring(evt.context))
end

local function sortItemFunc()
	local function sortFunc(a , b)
        -- if SELF.sortOrder == SORT_ORDER.ASC then 
			if a.quality == b.quality then
				return a.metaId < b.metaId
			else
				return a.quality > b.quality
			end
   --      else
			-- if a.quality == b.quality then
			-- 	return a.metaId < b.metaId
			-- else
			-- 	return a.quality > b.quality
			-- end
   --      end
    end
    table.sort(SELF.item_data,sortFunc)
end

local function onClickSort(e)
		-- local tosetvisible = not SELF.mainUI:getChildByName("btn_bagSort_QualityDownBtn"):isVisible()
		-- if e.forceSet then
		-- 	tosetvisible = e.forceVisible
		-- end
		-- SELF.mainUI:getChildByName("btn_bagSort_QualityDownBtn"):setVisible(tosetvisible)
		-- SELF.mainUI:getChildByName("btn_bagSort_LevelUpBtn"):setVisible(tosetvisible)
		-- SELF.mainUI:getChildByName("btn_bagSort_LevelDownBtn"):setVisible(tosetvisible)
		-- SELF.mainUI:getChildByName("btn_bagSort_QualityUpBtn"):setVisible(tosetvisible)
		-- SELF.coverLayer:setVisible(tosetvisible)
		-- local tosetColor;
		-- if tosetvisible then
		-- 	tosetColor = ccc3(80, 80, 80)
		-- else
		-- 	tosetColor = ccc3(255, 255, 255)
		-- end
		
		
		-- setCocosObjectColor(SELF.btnSell.display, tosetColor)
		-- setCocosObjectColor(SELF.btnBuyGrid.display, tosetColor)
		-- setCocosObjectColor(SELF.mainUI:getChildByName("inventory_title"), tosetColor)
		
		-- SELF.btnSell:setEnable(not tosetvisible)
		-- SELF.btnBuyGrid:setEnable(not tosetvisible)
		-- SELF.tableUI:setTouchEnabled(not tosetvisible)		
		
		if SELF.currentTab == BAGCATEGORY.card then
			local argv = {queueData = queueData , sortFunc = sortCardFunc}
			SELF.targetInfoPanel = BackPackSortPanel:create( SELF , argv)
			PopoutManager:sharedManager():popout(SELF.targetInfoPanel, kPopoutDir.kScale, true, false ,SELF) 
		elseif SELF.currentTab == BAGCATEGORY.item and not SELF.argv.enterScene then
			
		elseif SELF.currentTab == BAGCATEGORY.equip then
			local argv = {sortFunc = sortEquipFunc , enterType = "BackPackScene"}
			SELF.targetInfoPanel = SpiritBackPackSortPanel:create( SELF , argv)
			PopoutManager:sharedManager():popout(SELF.targetInfoPanel, kPopoutDir.kScale, true, false ,SELF) 
		end

		
		
end

function BackpackScene:back()
	-- onClickSort({forceSet = true, forceVisible = false})
	if BackpackUIStatus == BACKPACK_STATUS.CHECKBOX and SELF.argv.params.cardType ~= "mainCard" and SELF.argv.params.cardType ~= "matterCard" then
		runChangeBtnSellAction()
		--SELF.mainUI:getChildByName("btn_inventory_R"):getChildByName("txt_bag_SellBtn"):setString(getTextByKey("bag_SellBtn"))
		BackpackUIStatus = BACKPACK_STATUS.NORMAL
		idsToSell = {}
		SELF:refreshTable(true)
		self.isChangeingScene = false
		do return end
	end

	
  if SELF.argv.returnScene == "MatrixScene" then
		SELF:replaceScene(MatrixScene)
	elseif SELF.argv.returnScene == "CardEvolutionScene" then 
		local nextReturnScene = nil;
		if SELF.argv.params then
			nextReturnScene = SELF.argv.params.preReturnScene
		end
		local argv = {enterScene="BackpackScene",returnScene=nextReturnScene,params={}}
        SELF:replaceScene(CardEvolutionScene, argv)
	elseif SELF.argv.returnScene == "ActivityPanelScene" then 
		local nextReturnScene = nil;
		if SELF.argv.params then
			nextReturnScene = SELF.argv.params.preReturnScene
		end
		local argv = {selectPanelName = "Activity_Pray"}
        SELF:replaceScene(ActivityPanelScene, argv)
    elseif SELF.argv.returnScene == "CardComposeScene" then
		local nextReturnScene = nil;
		if SELF.argv.params then
			nextReturnScene = SELF.argv.params.preReturnScene
		end
		local argv = {enterScene="BackpackScene",returnScene=nextReturnScene,params={}}
        argv.params.state = SELF.argv.params.state
        SELF:replaceScene(CardComposeScene, argv)
	elseif SELF.argv.returnScene == "CardQueueScene" then
		if SELF.argv.params.argvs then
			SELF.argv.returnScene = "CardQueueScene"
			SELF.argv.enterScene = "CardQueueScene" 
			SELF:replaceScene(EquipQuickUpgradeScene,SELF.argv.params.argvs)
		else
			SELF:replaceScene(CardQueueScene, {enterScene="BackpackScene", returnScene= (SELF.argv.params and SELF.argv.params.preReturnScene)})
		end
	elseif SELF.argv.returnScene == "BackpackScene" and SELF.argv.params.filter == BACKPACK_FILTER.EQUIP then
		local argv = {params={isCardTrain = false, tabIndex = BAGCATEGORY.equip}}
		SELF:replaceScene( BackpackScene , argv)
	elseif SELF.argv.returnScene == "CardRebirthScene" then
		SELF:replaceScene(CardRebirthScene)
	
    else
        SELF:replaceScene(MainMenuScene)
    end
end

function BackpackScene:onSetButtonState( btName , noAction)
  if(SELF.currentTab and SELF.currentTab == btName) then
    return nil
  end
    SELF:generateAnimatedCells();
	SELF:setSellMenuVisible(false)
    if SELF.argv.params.filter ~=nil then
        SELF.BackpackFilter = SELF.argv.params.filter
    end
    SELF.headpanelUI:getChildByName("btn_inventor_active_card"):setVisible(false)
    SELF.headpanelUI:getChildByName("btn_inventory_inactive_quip"):setVisible(false)
    SELF.headpanelUI:getChildByName("btn_inventory_inactive_prov"):setVisible(false)
	
    if SELF.BackpackFilter~=nil and next(SELF.BackpackFilter) ~= nil then
        for k,v in pairs(SELF.BackpackFilter) do
            SELF.headpanelUI:getChildByName(v):setVisible(true)
        end
    end
	
	local curTitleIndex = 1
	local titlePirortyTable = {"btn_inventor_active_card", "btn_inventory_inactive_quip", "btn_inventory_inactive_prov"}
	
	for i = 1, 3
	do
		if SELF.headpanelUI:getChildByName(titlePirortyTable[i]):isVisible() then
			SELF.headpanelUI:getChildByName(titlePirortyTable[i]):setPositionXY(SELF.titlePosTable[curTitleIndex].x, SELF.titlePosTable[curTitleIndex].y)
			curTitleIndex = curTitleIndex + 1
		end
	end
	SELF.mainUI:getChildByName("inventory_title"):getChildByName("txt_tochose_2"):getChildByName("txt"):setString("")
	if SELF.argv.enterScene and SELF.BackpackFilter ~= BACKPACK_FILTER.ALL then
		if  SELF.headpanelUI:getChildByName("btn_inventor_active_card"):isVisible() then
			--选择对象是卡牌
			if SELF.argv.enterScene == "ActivityPanelScene" then
				SELF.mainUI:getChildByName("inventory_title"):getChildByName("txt_tochose"):getChildByName("txt"):setString(getTextByKey("activity_pray_chooseCardTips"))
			else
				--默认情况
				SELF.mainUI:getChildByName("inventory_title"):getChildByName("txt_tochose"):getChildByName("txt"):setString(getTextByKey("bag_selectCard"))
			end
			if SELF.argv.enterScene == "MatrixScene" then
				local typeText = ""
				if SELF.argv.params.matrixGridType == 1 then
					typeText = getTextByKey("attr_Attack")
				elseif SELF.argv.params.matrixGridType == 2 then
					typeText = getTextByKey("attr_Defense")
				else
					typeText = getTextByKey("attr_HP")
				end
				local text = Localization:getInstance():getText("grid_card_on_remind", {type1 = typeText, type2 = typeText}) 
				SELF.mainUI:getChildByName("inventory_title"):getChildByName("txt_tochose"):getChildByName("txt"):setString("")
				SELF.mainUI:getChildByName("inventory_title"):getChildByName("txt_tochose_2"):getChildByName("txt"):setString(text)
			end
		elseif SELF.headpanelUI:getChildByName("btn_inventory_inactive_quip"):isVisible() then
			SELF.mainUI:getChildByName("inventory_title"):getChildByName("txt_tochose"):getChildByName("txt"):setString(getTextByKey("bag_selectEquip"))			
		else
			SELF.mainUI:getChildByName("inventory_title"):getChildByName("txt_tochose"):getChildByName("txt"):setString("")
		end
	else
		SELF.mainUI:getChildByName("inventory_title"):getChildByName("txt_inventory_num"):setVisible(true)
		SELF.mainUI:getChildByName("inventory_title"):getChildByName("txt_inventory"):setVisible(true)
		SELF.mainUI:getChildByName("inventory_title"):getChildByName("btn_inventory_switch"):setVisible(true)
		SELF.mainUI:getChildByName("inventory_title"):getChildByName("txt_tochose"):setVisible(false)
		SELF.mainUI:getChildByName("inventory_title"):getChildByName("bg_inventory_title_bg"):setVisible(true)
	end
	
    SELF.currentTab = btName
    SELF.card_view:setPositionX(-visibleSize.width)
    SELF.item_view:setPositionX(-visibleSize.width)
    SELF.equip_view:setPositionX(-visibleSize.width)    
    
    SELF.mainUI:getChildByName("btn_inventory_R"):getChildByName("txt_bag_SellBtn"):setString(getTextByKey("bag_SellBtn"))    
    SELF.headpanelUI:getChildByName("btn_inventor_active_card"):getChildByName("btn"):setVisible(false)      
    SELF.headpanelUI:getChildByName("btn_inventor_active_card"):getChildByName("normal"):setVisible(false)               
    SELF.headpanelUI:getChildByName("btn_inventory_inactive_prov"):getChildByName("btn"):setVisible(false)      
    SELF.headpanelUI:getChildByName("btn_inventory_inactive_prov"):getChildByName("normal"):setVisible(false)
    SELF.headpanelUI:getChildByName("btn_inventory_inactive_quip"):getChildByName("btn"):setVisible(false)             
    SELF.headpanelUI:getChildByName("btn_inventory_inactive_quip"):getChildByName("normal"):setVisible(false)  
	-- SELF.headpanelUI:getChildByName("btn_inventor_active_card"):getChildByName("icon_inventory_arrow_down"):setVisible(false)
	-- SELF.headpanelUI:getChildByName("btn_inventory_inactive_prov"):getChildByName("icon_inventory_arrow_down"):setVisible(false)
	-- SELF.headpanelUI:getChildByName("btn_inventory_inactive_quip"):getChildByName("icon_inventory_arrow_down"):setVisible(false)
    if SELF.tableUI==nil then 
        if btName == BAGCATEGORY.card then
            SELF.preTableUI = SELF.card_view
        elseif btName == BAGCATEGORY.item then
            SELF.preTableUI = SELF.item_view
        elseif btName == BAGCATEGORY.equip then 
            SELF.preTableUI = SELF.equip_view
        end
    else
        SELF.preTableUI = SELF.tableUI
    end
	SELF.card_view:setTouchEnabled(false)
	SELF.item_view:setTouchEnabled(false)
	SELF.equip_view:setTouchEnabled(false)
	
	local toRefresh = false;
	
	if SELF.nocardButton then
		SELF.nocardButton:setEnable(false)
		SELF.nocardButton:setVisible(false)
	end
	
    if btName == BAGCATEGORY.card then 
        SELF.tableUI = SELF.card_view
		if SELF.isOldCardView then
			toRefresh = true;
		end
        SELF.headpanelUI:getChildByName("btn_inventor_active_card"):getChildByName("btn"):setVisible(true)      
        SELF.headpanelUI:getChildByName("btn_inventory_inactive_prov"):getChildByName("normal"):setVisible(true)
        SELF.headpanelUI:getChildByName("btn_inventory_inactive_quip"):getChildByName("normal"):setVisible(true)
		-- SELF.headpanelUI:getChildByName("btn_inventor_active_card"):getChildByName("icon_inventory_arrow_down"):setVisible(true)
		SELF.noCardText:setVisible(#SELF.card_data == 0)
		if SELF.nocardButton and #SELF.card_data == 0 then
			SELF.nocardButton:setEnable(true)
			SELF.nocardButton:setVisible(true)
		end
		SELF.noItemText:setVisible(false)
		SELF.noEquipText:setVisible(false)
	elseif btName == BAGCATEGORY.item  then 
        SELF.tableUI = SELF.item_view     
		if SELF.isOldItemView then
			toRefresh = true;
		end
        SELF.headpanelUI:getChildByName("btn_inventory_inactive_prov"):getChildByName("btn"):setVisible(true)             
        SELF.headpanelUI:getChildByName("btn_inventor_active_card"):getChildByName("normal"):setVisible(true)   
        SELF.headpanelUI:getChildByName("btn_inventory_inactive_quip"):getChildByName("normal"):setVisible(true)
		-- SELF.headpanelUI:getChildByName("btn_inventory_inactive_prov"):getChildByName("icon_inventory_arrow_down"):setVisible(true)
		SELF.noCardText:setVisible(false)
		SELF.noItemText:setVisible(#SELF.item_data == 0)
		SELF.noEquipText:setVisible(false)
	elseif btName == BAGCATEGORY.equip then 
        SELF.tableUI = SELF.equip_view
		if SELF.isOldEquipView then
			toRefresh = true;
		end
        SELF.headpanelUI:getChildByName("btn_inventory_inactive_quip"):getChildByName("btn"):setVisible(true)   
        SELF.headpanelUI:getChildByName("btn_inventor_active_card"):getChildByName("normal"):setVisible(true)  
        SELF.headpanelUI:getChildByName("btn_inventory_inactive_prov"):getChildByName("normal"):setVisible(true)
		-- SELF.headpanelUI:getChildByName("btn_inventory_inactive_quip"):getChildByName("icon_inventory_arrow_down"):setVisible(true)
		SELF.noCardText:setVisible(false)
		SELF.noItemText:setVisible(false)
		SELF.noEquipText:setVisible(#SELF.equip_data == 0)
	end
	SELF.tableUI:setTouchEnabled(true)
	SELF.tableUI:setVisible(true)
	
    
	SELF.usedSpace = BagCalcManager.calcUsedGridNum()
	SELF.totalSpace = BagCalcManager.calcTotalGridNum()
	SELF.mainUI:getChildByName("inventory_title"):getChildByName("txt_inventory_num"):getChildByName("font"):setString(tostring(SELF.usedSpace).."/" .. SELF.totalSpace)
	
    --SELF.mainUI:getChildByName("inventory_title"):getChildByName("txt_inventory_num"):getChildByName("font"):setString(tostring(SELF.usedSpace).."/" .. SELF.totalSpace)
    
    BackpackUIStatus = BACKPACK_STATUS.NORMAL  
    selectCard = {}
	if noAction then
		if toRefresh then
			SELF.tableUI:reloadData()
		end
		do return end
	end
	SELF.tableUI:reloadData()
    --进入动画
    local function enterMov()
        SELF.tableUI:setPositionX(0)
        local arr = CCArray:create()
        --arr:addObject(CCMoveBy:create(0.2, ccp(visibleSize.width, 0)))
        arr:addObject(CCDelayTime:create(0.4))
        
        local function enterMovFinished()
          SELF.mainUI:setTouchEnabled(true) --add by spark.bai
          SELF.mainUI:setTouchEnabled(true)
		  SELF.preTableUI:setVisible(false)
        end
        arr:addObject(CCCallFunc:create(enterMovFinished))
        
        SELF.tableUI:runAction(CCSequence:create(arr))
		SELF:generateAnimatedCells();
		local aDuration
		  if #SELF.animatedCells == 1 then
			aDuration = TOTALENTERDURATION - CELLENTERDURATION
		  else
			aDuration = (TOTALENTERDURATION - CELLENTERDURATION) / (#SELF.animatedCells - 1)
		  end
		  for aIndex, aCell in ipairs(SELF.animatedCells) do
			aCell:setPositionX(aCell:getPositionX() - visibleSize.width)
			local arr = CCArray:create()
			arr:addObject(CCDelayTime:create(aDuration * (aIndex - 1)))
			arr:addObject(CCMoveBy:create(CELLENTERDURATION, ccp(visibleSize.width, 0)))
			aCell:runAction(CCSequence:create(arr))
		  end
    end
    --出去动画
    local array = CCArray:create()
    SELF.preTableUI:setPositionX(0)
    --array:addObject(CCMoveBy:create(0.2, ccp(-visibleSize.width, 0)))
    array:addObject(CCDelayTime:create(0.4))
    array:addObject(CCCallFunc:create(enterMov))
    SELF.mainUI:setTouchEnabled(false) --add by spark.bai
    SELF.mainUI:setTouchEnabled(false)
    SELF.preTableUI:runAction(CCSequence:create(array))       
  local aDuration
  if #SELF.animatedCells == 1 then
    aDuration = TOTALENTERDURATION - CELLENTERDURATION
  else
    aDuration = (TOTALENTERDURATION - CELLENTERDURATION) / (#SELF.animatedCells - 1)
  end
  for aIndex, aCell in ipairs(SELF.animatedCells) do
    local arr = CCArray:create()
    arr:addObject(CCDelayTime:create(aDuration * (aIndex - 1)))
    arr:addObject(CCMoveBy:create(CELLENTERDURATION, ccp(-visibleSize.width, 0)))
    aCell:runAction(CCSequence:create(arr))
  end
end

function BackpackScene:buyGridRequest(buy)
	SELF:setTableViewsEnabled(true)
	if not buy then
		do return end
	end
	
	if CalculationManager.calcComplex_getGemsNow() < SELF.goldCost then
		local aPanel = AssistantMessageBoxPanel:create( SELF, AsMessageBoxType.addCoin )
		SELF:addChild(aPanel)
		aPanel:scaleIn()
		do return end
	end
	
	local function buyGridFailed(e)
		if e.data == 710513 then
			local aPanel = AssistantMessageBoxPanel:create( SELF, AsMessageBoxType.addCoin )
			SELF:addChild(aPanel)
			aPanel:scaleIn()
		elseif e.data == 713301 then
			local gameInitData = DataManager.getGameInitData()
			gameInitData.sharkUserExtend.boughtGridTimes = MetaManager.game_meta.gameSettingConfig.inventoryMaxExpandTimes
			DataManager.setGameInitData(gameInitData)
			SELF:setTableViewsEnabled(false)
			SELF.targetInfoPanel = MessageBoxPanel:create(SELF, MessageBoxType.kEnsureBuyGridWarning, {setTargetInfoPanelNil = true})
			SELF:addChild(SELF.targetInfoPanel)
			SELF.targetInfoPanel:scaleIn()
		else
			CanonMessageBox:showCommUnHandleErrorBox(e.data)
		end
	end

	local function buyGridResponse( e )
		SuspensionLabel:showContent(SELF, getTextByKey("bag_expandSuccess"))
		
		local gameInitData = DataManager.getGameInitData()
		gameInitData.sharkUserExtend.boughtGridTimes = gameInitData.sharkUserExtend.boughtGridTimes + 1
		DataManager.setGameInitData(gameInitData)
		RewardManager:getReward(e.data.rewards)
		e.data.requisite.amount = tostring(-tonumber(e.data.requisite.amount))
		RewardManager:getReward({e.data.requisite})
		SELF.totalSpace = SELF.totalSpace + tonumber(e.data.rewards[1].amount)
		SELF.mainUI:getChildByName("inventory_title"):getChildByName("txt_inventory_num"):getChildByName("font"):setString(tostring(SELF.usedSpace).."/" .. SELF.totalSpace)
	end
		
	local request = BuyGridRequest.new( nil, rpc.SendingPriority.kHigh )
	request:addEventListener( RequestNotifyEnum.BuyGridSucceed, buyGridResponse )
	request:addEventListener( RequestNotifyEnum.BuyGridFailed, buyGridFailed )
	request:start()
end

function BackpackScene:onInit()
	--[[if not self.isBaseUIReplace then
		local co = coroutine.create(self.onInitCoroutine)
		while coroutine.status(co) ~= "dead"
		do
			coroutine.resume(co)
		end
	end--]]
	if not self.isBaseUIReplace then
		self:onInitCoroutine()
	end

	Set_ShareData( "Guide_Lineup3", 0);
end

function BackpackScene:onInitCoroutine(callback)
    --print(table.tostring(SELF.argv))
	idsToSell = {}
	table.removeAll(queueData)
	local tQueueData = CommonManager.getQueueData( )
	for k,v in ipairs(tQueueData)
	do
		queueData[v] = k
	end
	CommonManager:setCardNeedUpdate(tQueueData)

	--deal with matrix card
	
	local matrixCardData = CommonManager:getMatrixCardData()
	for k,v in ipairs(matrixCardData) do 
		if not queueData[v] then
			queueData[v] = k + 100
		end
	end
	CommonManager:setCardNeedUpdate(matrixCardData)

	--初始化阵容卡牌和装备状态信息（BitOperManager.data[BattleArrayId]表示2的BattleArrayId-1次方）
	table.removeAll(queueCardList)
	table.removeAll(queueEquipList)
	local gameData = DataManager.getGameInitData()
	for BattleArrayId = 1,3 do
		local quedata = gameData.sharkUserBattleArray[BattleArrayId] and gameData.sharkUserBattleArray[BattleArrayId].sharkUserQueue or {}
		local matdata = gameData.sharkUserBattleArray[BattleArrayId] and gameData.sharkUserBattleArray[BattleArrayId].sharkMatrices and 
						gameData.sharkUserBattleArray[BattleArrayId].sharkMatrices.sharkMatrices or {} 
		for k,v in pairs(quedata) do
			if v.cardId then 
				if not queueCardList[v.cardId] then
					queueCardList[v.cardId] = BitOperManager.data[BattleArrayId]
				else
					queueCardList[v.cardId] = queueCardList[v.cardId] + BitOperManager.data[BattleArrayId]
				end
			end

			if (not v.equips) then v.equips = {} end
			for _,value in pairs(v.equips) do
				if not queueEquipList[value] then
					queueEquipList[value] = BitOperManager.data[BattleArrayId] 
				else
					queueEquipList[value] = queueEquipList[value] + BitOperManager.data[BattleArrayId]
				end
			end	
		end
		for k,v in pairs(matdata) do
			if not v.sharkMatrixGrids then v.sharkMatrixGrids = {} end
			for _,value in pairs(v.sharkMatrixGrids) do
				if value.cardId then 
					if not queueCardList[value.cardId] then
						queueCardList[value.cardId] = BitOperManager.data[BattleArrayId]
					else
						queueCardList[value.cardId] = queueCardList[value.cardId] + BitOperManager.data[BattleArrayId]
					end
				end
			end		
		end			
	end
	--end by l1ghtsaber
	
    BaseUIScene.initBackGround(SELF)
    SELF.tableView = { card={},equip={},item={} }    
	SELF.backbuilder = LayoutBuilder:createWithContentsOfFile("scene/package_new.json")
	SELF.backbuilder.useArtLabelTTF = true
	
	
    SELF.mainUI = SELF.backbuilder:build("package_inventory") --背包  
	SELF.headpanelUI = SELF.backbuilder:build("package_btn_inventory_title")
	
	SELF.group1 = {}
	table.insert(SELF.group1, SELF.mainUI:getChildByName("btn_inventory_L"))
	table.insert(SELF.group1, SELF.mainUI:getChildByName("bg_inventory_red"))
	
	SELF.group2 = {}
	table.insert(SELF.group2, SELF.mainUI:getChildByName("btn_inventory_R"))
	
	SELF.group3 = {}	
	table.insert(SELF.group3, SELF.mainUI:getChildByName("inventory_title"))
	
	SELF.group4 = {}
	table.insert(SELF.group4, SELF.headpanelUI)
	
	SELF.titlePosTable = {}
	local titleNameTable = {"btn_inventor_active_card", "btn_inventory_inactive_prov", "btn_inventory_inactive_quip"}
	for i = 1, 3
	do
		SELF.titlePosTable[i] = {}
		local titlePos = SELF.headpanelUI:getChildByName(titleNameTable[i]):getPosition()
		SELF.titlePosTable[i].x, SELF.titlePosTable[i].y = titlePos.x, titlePos.y
	end
	
	SELF.headpanelUI:getChildByName("btn_inventor_active_card"):getChildByName("normal"):getChildByName("btn_tab_inactive_R").refCocosObj:getTexture():setAliasTexParameters();
	
    --TAB按钮
  local function onClickCard()
		if SELF.enablePanelChange then
			SELF:onSetButtonState( BAGCATEGORY.card )
			-- onClickSort({forceSet = true, forceVisible = false})
			if #SELF.card_data == 0 then
				setCocosObjectColor(SELF.btnSell.display, ccc3(80, 80, 80))
				SELF.btnSell:setEnable(false)
			else
				setCocosObjectColor(SELF.btnSell.display, ccc3(255, 255, 255))
				SELF.btnSell:setEnable(true)
			end

			setCocosObjectColor(SELF.btnSort.display, ccc3(255, 255, 255))
			SELF.btnSort:setEnable(true)
		end
  end
	
  local function onClickItem()
		if SELF.enablePanelChange then
			SELF:onSetButtonState( BAGCATEGORY.item )
			-- onClickSort({forceSet = true, forceVisible = false})
			if #SELF.item_data == 0 then
				setCocosObjectColor(SELF.btnSell.display, ccc3(80, 80, 80))
				SELF.btnSell:setEnable(false)
			else
				setCocosObjectColor(SELF.btnSell.display, ccc3(255, 255, 255))
				SELF.btnSell:setEnable(true)
			end

			setCocosObjectColor(SELF.btnSort.display, ccc3(80, 80, 80))
			SELF.btnSort:setEnable(false)
		end
  end
  
  local function onClickEquip()
		if SELF.enablePanelChange then
			SELF:onSetButtonState( BAGCATEGORY.equip )
			-- onClickSort({forceSet = true, forceVisible = false})
			if #SELF.equip_data == 0 then
				setCocosObjectColor(SELF.btnSell.display, ccc3(80, 80, 80))
				SELF.btnSell:setEnable(false)
			else
				setCocosObjectColor(SELF.btnSell.display, ccc3(255, 255, 255))
				SELF.btnSell:setEnable(true)
			end

			setCocosObjectColor(SELF.btnSort.display, ccc3(255, 255, 255))
			SELF.btnSort:setEnable(true)
		end
  end
    --界面初始化
  SELF.headpanelUI:getChildByName("btn_inventor_active_card"):getChildByName("txt_bag_CardTag"):setString(getTextByKey("bag_CardTag"))
  SELF.headpanelUI:getChildByName("btn_inventory_inactive_prov"):getChildByName("txt_bag_ItemTag"):setString(getTextByKey("bag_ItemTag"))
  SELF.headpanelUI:getChildByName("btn_inventory_inactive_quip"):getChildByName("txt_bag_ItemTag"):setString(getTextByKey("bag_EquipmentTag"))
  SELF.mainUI:getChildByName("btn_inventory_L"):getChildByName("txt_bag_ArrangeBtn"):setString(getTextByKey("bag_ArrangeBtn"))
  SELF.mainUI:getChildByName("btn_inventory_R"):getChildByName("txt_bag_SellBtn"):setString(getTextByKey("bag_SellBtn"))
    
  SELF.mainUI:getChildByName("inventory_title"):getChildByName("txt_inventory"):getChildByName("txt_inventory"):setString(getTextByKey("bag_Slot"))
  SELF.mainUI:getChildByName("inventory_title"):getChildByName("txt_inventory_num"):getChildByName("font"):setString("99/99")
  SELF.mainUI:getChildByName("inventory_title"):getChildByName("btn_inventory_switch"):getChildByName("txt_btn_inventory_switch"):getChildByName("txt_btn_inventory_switch"):setString(getTextByKey("bag_ExpandBtn"))
	
	local function changeRotatedR(bgR)
		bgR.refCocosObj:setAnchorPoint(ccp(0.5, 0.5))
		local contentSize = bgR.refCocosObj:getContentSize()
		local curPosX,curPosY = bgR.refCocosObj:getPosition()
		bgR:setPosition(ccp(curPosX - contentSize.width / 2 , curPosY - contentSize.height / 2))
	end
	--changeRotatedR(SELF.mainUI:getChildByName("inventory_title"):getChildByName("btn_inventory_switch"):getChildByName("btn_inventory_switch_R"))
	changeRotatedR(SELF.headpanelUI:getChildByName("btn_inventor_active_card"):getChildByName("normal"):getChildByName("btn_tab_inactive_R"))
	changeRotatedR(SELF.headpanelUI:getChildByName("btn_inventor_active_card"):getChildByName("btn"):getChildByName("btn_tab_active_R"))
	changeRotatedR(SELF.headpanelUI:getChildByName("btn_inventory_inactive_prov"):getChildByName("normal"):getChildByName("btn_tab_inactive_R"))
	changeRotatedR(SELF.headpanelUI:getChildByName("btn_inventory_inactive_prov"):getChildByName("btn"):getChildByName("btn_tab_active_R"))
	changeRotatedR(SELF.headpanelUI:getChildByName("btn_inventory_inactive_quip"):getChildByName("normal"):getChildByName("btn_tab_inactive_R"))
	changeRotatedR(SELF.headpanelUI:getChildByName("btn_inventory_inactive_quip"):getChildByName("btn"):getChildByName("btn_tab_active_R"))
	
	--[[local expandBtnBgR = SELF.mainUI:getChildByName("inventory_title"):getChildByName("btn_inventory_switch"):getChildByName("btn_inventory_switch_R")
	expandBtnBgR.refCocosObj:setAnchorPoint(ccp(0.5, 0.5))
	local contentSize = expandBtnBgR.refCocosObj:getContentSize()
	local curPosX,curPosY = expandBtnBgR.refCocosObj:getPosition()
	expandBtnBgR:setPosition(ccp(curPosX - contentSize.width / 2 , curPosY - contentSize.height / 2))--]]
	
	SELF.mainUI:getChildByName("inventory_prov"):setVisible(false)
	SELF.mainUI:getChildByName("inventory_equip"):setVisible(false)
	SELF.mainUI:getChildByName("inventory_card"):setVisible(false)
	SELF.mainUI:getChildByName("package_inventory_baowu"):setVisible(false)
	SELF.mainUI:getChildByName("btn"):setVisible(false)
	
	-- SELF.mainUI:getChildByName("btn_inventory_L"):getChildByName("icon_inventory_arrow"):setVisible(false);
	
	-- SELF.mainUI:getChildByName("btn_bagSort_QualityDownBtn"):setVisible(false)
	-- SELF.mainUI:getChildByName("btn_bagSort_LevelUpBtn"):setVisible(false)
	-- SELF.mainUI:getChildByName("btn_bagSort_LevelDownBtn"):setVisible(false)
	-- SELF.mainUI:getChildByName("btn_bagSort_QualityUpBtn"):setVisible(false)
	
	-- SELF.mainUI:getChildByName("btn_bagSort_QualityDownBtn"):getChildByName("txt_bagSort_QualityDownBtn"):setString(getTextByKey("bagSort_QualityDownBtn"))
	-- SELF.mainUI:getChildByName("btn_bagSort_LevelUpBtn"):getChildByName("txt_bagSort_LevelUpBtn"):setString(getTextByKey("bagSort_LevelUpBtn"))
	-- SELF.mainUI:getChildByName("btn_bagSort_LevelDownBtn"):getChildByName("txt_bagSort_LevelDownBtn"):setString(getTextByKey("bagSort_LevelDownBtn"))
	-- SELF.mainUI:getChildByName("btn_bagSort_QualityUpBtn"):getChildByName("txt_bagSort_QualityUpBtn"):setString(getTextByKey("bagSort_QualityUpBtn"))

    SELF.sortOrder = SORT_ORDER.ASC
    for index,bt in ipairs(SELF.sortButton) do
        bt:setVisible(false)
        bt:setZOrder(101)
    end    
    SELF.mainUI:getChildByName("inventory_card"):setVisible(false)
    SELF.mainUI:getChildByName("inventory_prov"):setVisible(false)
    SELF.mainUI:getChildByName("inventory_title"):setZOrder(9)
    SELF.headpanelUI:setZOrder(10)
    local btCard  = Button:create(SELF.headpanelUI:getChildByName("btn_inventor_active_card"))
    local btItem  = Button:create(SELF.headpanelUI:getChildByName("btn_inventory_inactive_prov"))
    local btEquip = Button:create(SELF.headpanelUI:getChildByName("btn_inventory_inactive_quip"))    
    
    btCard:addEventListener( Events.kStart, onClickCard )
    btItem:addEventListener( Events.kStart, onClickItem )
    btEquip:addEventListener( Events.kStart, onClickEquip )
    --切换按钮
    local function onClickSwitch(e)
		SELF:setTableViewsEnabled(false)
		SELF.targetInfoPanel = MessageBoxPanel:create(SELF, MessageBoxType.kEnsureBuyGridWarning, {setTargetInfoPanelNil = true})
		SELF:addChild(SELF.targetInfoPanel)
		SELF.targetInfoPanel:scaleIn()
		
    end
    local btnSwitch = Button:create(SELF.mainUI:getChildByName("inventory_title"):getChildByName("btn_inventory_switch"))
    btnSwitch:addEventListener(Events.kStart, onClickSwitch)  
	SELF.btnBuyGrid = btnSwitch
	if not SELF.argv.enterScene then
		SELF.mainUI:getChildByName("inventory_title"):getChildByName("txt_tochose"):setVisible(false)
		SELF.mainUI:getChildByName("inventory_title"):getChildByName("bg_inventory_title_bg"):setVisible(true)
	else
		
		SELF.mainUI:getChildByName("inventory_title"):getChildByName("btn_inventory_switch"):setVisible(false)
		SELF.mainUI:getChildByName("inventory_title"):getChildByName("txt_inventory_num"):setVisible(false)
		SELF.mainUI:getChildByName("inventory_title"):getChildByName("txt_inventory"):setVisible(false)
	end
    --卖出按钮
    local function onClickBtSell(e)
		if SELF.coverLayer:isVisible() then
			do return end
		end
		
		if SELF.currentTab == BAGCATEGORY.card then
			if BackpackUIStatus == BACKPACK_STATUS.NORMAL then
				local function filterCardFunc( cardList )
					local result = {}
					local queueList = {}
					for k,v in pairs(CommonManager.getQueueData()) do
						queueList[v] = true
					end
					for k,v in pairs(CommonManager:getMatrixCardData()) do
						queueList[v] = true
					end
					for k,v in pairs(cardList) do
						if not queueList[v.cardId] then
							table.insert(result, v)
						end
					end
					return result
				end     
				local argv = {enterScene="BackpackScene",returnScene="BackpackScene",params={preReturnScene = SELF.argv.returnScene, filterFunc = filterCardFunc}}
				SELF:replaceScene(CardStrenthenSelectScene, argv)
				return
			else
				if SELF.argv.enterScene == "CardComposeScene" and SELF.argv.params.cardType=="matterCard" then--select matter card
					local userCardData = DataManager.getCardsData()
					local matterCard = {}
					for _,v in ipairs(idsToSell) do 
						for __,vv in pairs(userCardData) do 
							if v == vv.cardId then 
								--print(table.tostring(vv))
								table.insert(matterCard,{cardId=vv.cardId,metaId=vv.metaId})
							end
						end 
					end
					local params = {}
					local nextReturnScene = nil;
					if SELF.argv.params then
						nextReturnScene = SELF.argv.params.preReturnScene
					end
					local argv = {enterScene="BackpackScene",returnScene=nextReturnScene,params={matterCard=matterCard,cardType="matterCard"}}
					SELF:replaceScene(CardComposeScene , argv)
					do return end
				else--sellselectedCard
					runChangeBtnSellAction(BackpackUIStatus, SELF.currentTab)
					BackpackUIStatus = BACKPACK_STATUS.NORMAL
					idsToSell = {}					
				end				
			end
		elseif SELF.currentTab == BAGCATEGORY.item then
			if BackpackUIStatus == BACKPACK_STATUS.NORMAL then
				runChangeBtnSellAction(BackpackUIStatus, SELF.currentTab)
				BackpackUIStatus = BACKPACK_STATUS.CHECKBOX
				idsToSell = {}
			else
				runChangeBtnSellAction(BackpackUIStatus, SELF.currentTab)
				BackpackUIStatus = BACKPACK_STATUS.NORMAL
				idsToSell = {}
			end
		elseif SELF.currentTab == BAGCATEGORY.equip then
			local argv = {enterScene="BackpackScene",returnScene="BackpackScene",params={preReturnScene = SELF.argv.returnScene, sellType = ResourceEnum.EQUIP}}
			SELF:replaceScene(BatchSellScene, argv)

			-- if BackpackUIStatus == BACKPACK_STATUS.NORMAL then
			-- 	runChangeBtnSellAction(BackpackUIStatus, SELF.currentTab)
			-- 	BackpackUIStatus = BACKPACK_STATUS.CHECKBOX
			-- 	idsToSell = {}
			-- else
			-- 	runChangeBtnSellAction(BackpackUIStatus, SELF.currentTab)
			-- 	BackpackUIStatus = BACKPACK_STATUS.NORMAL
			-- 	idsToSell = {}
			-- end
		end
		
		SELF:refreshTable(true)
  end
  local bt_sell = Button:create(SELF.mainUI:getChildByName("btn_inventory_R"))
  bt_sell:addEventListener(Events.kStart, onClickBtSell)
	
	SELF.btnSell = bt_sell
    --排序按钮        
  local btSortUI = SELF.mainUI:getChildByName("btn_inventory_L")
  local btSort = Button:create(btSortUI)    
 
  btSort:addEventListener(Events.kStart, onClickSort , SELF )

  SELF.btnSort = btSort
	
    --点击排序执行
    local function onClickSortImpl(e)
        local index = tonumber(e.context.index)
		SELF.sortOrder = e.context.sortOrder
        if index == 1 then  --排序按钮        
            for _i,_value in pairs(SELF.sortButton) do 
                local key = SELF.sortButtonTxt[_i].key
                if SELF.sortOrder == SORT_ORDER.ASC then 
                    _value:getChildByName(key):setString(SELF.sortButtonTxt[_i].up) 
                else
                    _value:getChildByName(key):setString(SELF.sortButtonTxt[_i].down) 
                end            
            end  
            SELF.sortOrder = (1+SELF.sortOrder)%2
        elseif index == 2 --[[and SELF.currentTab==BAGCATEGORY.card--]] then  --卡牌排序（稀有度）
            local function sortFunc(a, b)
				local isAInBattle, isALeaderCard, isAInMatirx = isCardInBattle(a)
				local isBInBattle, isBLeaderCard, isBInMatirx = isCardInBattle(b)
				local isACanEvolve = false
				local isBCanEvolve = false
				if (SELF.argv.enterScene == "CardEvolutionScene" and type(SELF.argv.params) == "table" and SELF.argv.params.cardType == "master") then
					isACanEvolve = a.hasMaterial and a.levelEnough
					isBCanEvolve = b.hasMaterial and b.levelEnough
				end
				if isACanEvolve ~= isBCanEvolve then
					return isACanEvolve
				elseif isALeaderCard ~= isBLeaderCard then
					return isALeaderCard
				elseif isAInBattle ~= isBInBattle then
					return isAInBattle
				elseif isAInMatirx ~= isBInMatirx then
					return isAInMatirx
				else
					if SELF.sortOrder == SORT_ORDER.ASC then 
						if a.rare == b.rare then
							return a.metaId < b.metaId
						else
							return a.rare < b.rare
						end
					else
						if a.rare == b.rare then
							return a.metaId < b.metaId
						else
							return a.rare > b.rare
						end
					end
				end
            end
			
			
            table.sort(SELF.card_data,sortFunc)     
			--SELF:cardGeneralSort()
        elseif index == 3 --[[and SELF.currentTab==BAGCATEGORY.card--]] then --卡牌排序（等级）
            local function sortFunc(a , b)
				local isAInBattle, isALeaderCard, isAInMatirx = isCardInBattle(a)
				local isBInBattle, isBLeaderCard, isBInMatirx = isCardInBattle(b)
				local isACanEvolve = false
				local isBCanEvolve = false
				if (SELF.argv.enterScene == "CardEvolutionScene" and type(SELF.argv.params) == "table" and SELF.argv.params.cardType == "master") then
					isACanEvolve = a.hasMaterial and a.levelEnough
					isBCanEvolve = b.hasMaterial and b.levelEnough
				end
				if isACanEvolve ~= isBCanEvolve then
					return isACanEvolve
				elseif isALeaderCard ~= isBLeaderCard then
					return isALeaderCard
				elseif isAInBattle ~= isBInBattle then
					return isAInBattle
				elseif isAInMatirx ~= isBInMatirx then
					return isAInMatirx
				else
					if SELF.sortOrder == SORT_ORDER.ASC then 
						if a.level == b.level then
							return a.metaId < b.metaId
						else
							return a.level < b.level
						end
					else
						if a.level == b.level then
							return a.metaId < b.metaId
						else
							return a.level > b.level
						end
					end
				end
            end
            table.sort(SELF.card_data,sortFunc)
			--SELF:cardGeneralSort()
       --[[ elseif index == 4 and SELF.currentTab==BAGCATEGORY.card then --卡牌排序（攻击力）
            local function sortFunc(a , b)
                if SELF.sortOrder == SORT_ORDER.ASC then 
                    return a.attack < b.attack
                elseif SELF.sortOrder == SORT_ORDER.DESC then 
                    return a.attack > b.attack
                end
            end
            table.sort(SELF.card_data,sortFunc)
			SELF:cardGeneralSort()
        elseif index == 5 and SELF.currentTab==BAGCATEGORY.card then --卡牌排序（防御力）
            local function sortFunc(a , b)
                if SELF.sortOrder == SORT_ORDER.ASC then 
                    return a.defense < b.defense
                elseif SELF.sortOrder == SORT_ORDER.DESC then 
                    return a.defense > b.defense
                end
            end
            table.sort(SELF.card_data,sortFunc)
			SELF:cardGeneralSort()
        elseif index ==6 and SELF.currentTab==BAGCATEGORY.card then --卡牌排序（血量）
            local function sortFunc(a , b)
                if SELF.sortOrder == SORT_ORDER.ASC then 
                    return a.hp < b.hp
                elseif SELF.sortOrder == SORT_ORDER.DESC then 
                    return a.hp > b.hp
                end
            end
            table.sort(SELF.card_data,sortFunc)
			SELF:cardGeneralSort()--]]
		end
        if (index ==2 or index == 3) --[[and SELF.currentTab==BAGCATEGORY.item--]] then --物品排序（稀有度）
            local function sortFunc(a , b)
                if SELF.sortOrder == SORT_ORDER.ASC then 
					if a.quality == b.quality then
						return a.metaId < b.metaId
					else
						return a.quality < b.quality
					end
                else
					if a.quality == b.quality then
						return a.metaId < b.metaId
					else
						return a.quality > b.quality
					end
                end
            end
            table.sort(SELF.item_data,sortFunc)
		end
        if index ==2 --[[and SELF.currentTab==BAGCATEGORY.equip--]] then --装备排序（稀有度）
            local function sortFunc(a , b)
				local isAEquiped = (a.cardId > 0)
				local isBEquiped = (b.cardId > 0)
				if isAEquiped and not isBEquiped then
					return true
				elseif isAEquiped == isBEquiped then
					if SELF.sortOrder == SORT_ORDER.ASC then 
						if a.quality == b.quality then
							return a.metaId < b.metaId
						else
							return a.quality < b.quality
						end
					else
						if a.quality == b.quality then
							return a.metaId < b.metaId
						else
							return a.quality > b.quality
						end
					end
				else
					return false
				end
                
            end
            table.sort(SELF.equip_data,sortFunc)
            --SELF:equipGeneralSort()
        elseif index ==3 --[[and SELF.currentTab==BAGCATEGORY.equip--]] then --物品排序（等级）
            local function sortFunc(a , b)
				local isAEquiped = (a.cardId > 0)
				local isBEquiped = (b.cardId > 0)
				if isAEquiped and not isBEquiped then
					return true
				elseif isAEquiped == isBEquiped then
					if SELF.sortOrder == SORT_ORDER.ASC then 
						if a.level == b.level then
							return a.metaId < b.metaId
						else
							return a.level < b.level
						end
					else
						if a.level == b.level then
							return a.metaId < b.metaId
						else
							return a.level > b.level
						end
					end
				else
					return false
				end
                
            end
            table.sort(SELF.equip_data,sortFunc)
			--SELF:equipGeneralSort()
        end
		if not e.onlySort then
			onClickSort({forceSet = true, forceVisible = false})
			SELF.tableUI:reloadData()
		end
		HeMemDataHolder:setString("savedSortOrder", tostring(SELF.sortOrder))
		HeMemDataHolder:setString("savedSortFun", tostring(index))
    end
	
	--local enterTime = os.time()
	
    --创建TableView   
    SELF.card_data = DataManager.getCardsData()
    if HeMemDataHolder:getString("notShowInBattleCards") == "true" then
    	local tempTable = {}
		for k,v in pairs(SELF.card_data) do
			local isAInBattle, isALeaderCard, isAInMatirx = isCardInBattle(v)
			if isAInBattle == false and isAInMatirx == false then
				table.insert(tempTable , v)
			end
		end
		for i = #SELF.card_data, 1, -1 do
			table.remove(SELF.card_data, i)
		end
		for k,v in pairs(tempTable) do
			table.insert(SELF.card_data , v)
		end
    end

    --显示x国武将状态
    if HeMemDataHolder:getInteger("notShowCountryCards") ~= 0 then
    	local notShowCountryCards = HeMemDataHolder:getInteger("notShowCountryCards")
    	for i = #SELF.card_data, 1, -1 do 
    		local isAInBattle, isALeaderCard, isAInMatirx = isCardInBattle(SELF.card_data[i])
    		if not isAInBattle then
	    		local countryId = MetaManager.card_meta[SELF.card_data[i].metaId].country
	    		if BitOperManager:_and(BitOperManager:_shl(1,countryId-1,4),notShowCountryCards,4) ~= 0 then
	    			table.remove(SELF.card_data , i)
	    		end
    		end
    	end
    end

    if tonumber(Get_ShareData( "Sacrifice_Guide_Running")) == 1 then
    	SELF.equip_data = {{equipId = 0, metaId = 212111, level = 1, cardId = 0, enchantLevel = 0, enchantNum = 0}}
    	EnchantData.setEnchantPoint(EnchantData.getEnchantPoint() + EnchantData.guideEnchantNum)
    else
	    SELF.equip_data = DataManager.getEquipsData()
	    if HeMemDataHolder:getString("notShowEquipedItems") == "true" then
	    	local tempTable = {}
			for k,v in pairs(SELF.equip_data) do
				if v.cardId == 0 then
					table.insert(tempTable , v)
				end
			end
			for i = #SELF.equip_data, 1, -1 do
				table.remove(SELF.equip_data, i)
			end
			for k,v in pairs(tempTable) do
				table.insert(SELF.equip_data , v)
			end
	    end
	end
    SELF.item_data = {}
	
	--print("get .. " .. os.difftime(os.time(), enterTime))
	--enterTime = os.time()
	
	for k,item in pairs(DataManager.getPropsData()) do
        if tonumber(item.amount) > 0 then 
            table.insert(SELF.item_data,item)
        end
    end
	
    SELF.slotNum.card  = #SELF.card_data
    SELF.slotNum.item  = #SELF.item_data
    SELF.slotNum.equip = #SELF.equip_data

    --过滤规则
    if SELF.argv.params.filterFunc ~= nil then
        --卡牌
        if SELF.argv.params.filter ~=nil and SELF.argv.params.filter==BACKPACK_FILTER.CARD then
        	--卡牌和阵法里的卡牌
            local id_list = SELF.argv.params.filterFunc(SELF.card_data)
            SELF.card_data = id_list
        end
        --装备
        if SELF.argv.params.filter ~=nil and SELF.argv.params.filter==BACKPACK_FILTER.EQUIP then 
            local id_list = SELF.argv.params.filterFunc(SELF.equip_data)
            SELF.equip_data = id_list
        end
        --ITEM
        if SELF.argv.params.filter ~=nil and SELF.argv.params.filter==BACKPACK_FILTER.ITEM then 
            local id_list = SELF.argv.params.filterFunc(SELF.item_data)
            SELF.item_data = id_list
        end        
    end    
	--coroutine.yield() 
	--卡牌
    for i,card in pairs(SELF.card_data) do 
        --计算卡牌攻，防，血
        --稀有度
        if SystemManager.debug then
        	DebugManager.assert(MetaManager.card_meta[card.metaId] ~= nil, "无法打开背包! card.metaId = " .. tostringRich(card.metaId))
        end
        SELF.card_data[i].rare = MetaManager.card_meta[card.metaId].rare
		isCardInBattle(SELF.card_data[i])
		if tonumber(i) % 5 == 0 then
			--coroutine.yield() 
		end
    end 
    --道具
    for i,item in pairs(SELF.item_data) do 
        SELF.item_data[i].quality = MetaManager.prop_meta[item.metaId].quality
		SELF.item_data[i].price =  MetaManager.prop_meta[SELF.item_data[i].metaId].sellPrice 
		SELF.item_data[i].canSell =  MetaManager.prop_meta[SELF.item_data[i].metaId].canSell 
		if tonumber(i) % 5 == 0 then
			--coroutine.yield() 
		end
    end
    --装备
    for i,equip in pairs(SELF.equip_data) do
        SELF.equip_data[i].quality  = MetaManager.equip_meta[equip.metaId].quality
		SELF.equip_data[i].price = MetaManager.equip_meta[SELF.equip_data[i].metaId].sellPriceCoe * MetaManager.equip_level[SELF.equip_data[i].level].sellPriceBase
		if tonumber(i) % 5 == 0 then
			--coroutine.yield() 
		end
    end
	
	--print("calc .. " .. os.difftime(os.time(), enterTime))
	--enterTime = os.time()
	
	local function setSellButtonDisableWhenNoItem()
		if not SELF.argv.enterScene then
			if SELF.currentTab == BAGCATEGORY.card then
				if #SELF.card_data == 0 then
					setCocosObjectColor(SELF.btnSell.display, ccc3(80, 80, 80))
					SELF.btnSell:setEnable(false)
				end
			elseif SELF.currentTab == BAGCATEGORY.item then
				if #SELF.item_data == 0 then
					setCocosObjectColor(SELF.btnSell.display, ccc3(80, 80, 80))
					SELF.btnSell:setEnable(false)
				end
			elseif SELF.currentTab == BAGCATEGORY.equip then
				if #SELF.equip_data == 0 then
					setCocosObjectColor(SELF.btnSell.display, ccc3(80, 80, 80))
					SELF.btnSell:setEnable(false)
				end
			end
		end
	end
	
	local savedSortOrder = HeMemDataHolder:getString("savedSortOrder")
	local savedSortFun = HeMemDataHolder:getString("savedSortFun")
	local curTab = SELF.argv.params.tabIndex 
	if not curTab then
		curTab = BAGCATEGORY.card
	end

	self.sortCardFunc = sortCardFunc
	self.sortEquipFunc = sortEquipFunc
	self.sortItemFunc = sortItemFunc

	if HeMemDataHolder:getString("savedSortOrder_card") == "" then
		sortCardFunc({context = SORT_TYPE.RARE_DESC})
	else
		sortCardFunc({context = tonumber(HeMemDataHolder:getString("savedSortOrder_card"))})
	end

	if HeMemDataHolder:getString("savedSortOrder_equip") == "" then
		sortEquipFunc({context = SORT_TYPE.RARE_DESC})
	else
		sortEquipFunc({context = tonumber(HeMemDataHolder:getString("savedSortOrder_equip"))})
	end

	sortItemFunc()

	--SELF:cardGeneralSort()   
	
	SELF.toreleaseCardTable = {}
	SELF.toreleaseEquipTable = {}
	SELF.toreleaseItemTable = {}
	
	local function replaceTable(tableName)
		if not selfTableInfo[tableName] then
			selfTableInfo[tableName] = {}
		else
			table.removeAll(selfTableInfo[tableName])
		end
		
		for k,v in ipairs(SELF[tableName])
		do
			table.insert(selfTableInfo[tableName], v)
		end
		SELF[tableName] = selfTableInfo[tableName]
	end
	
	replaceTable("toreleaseCardTable")
	replaceTable("toreleaseItemTable")
	replaceTable("toreleaseEquipTable")
	replaceTable("card_data")
	replaceTable("equip_data")
	replaceTable("item_data")
	
	--coroutine.yield()
	
	if card_tableview then
		SELF.card_view = card_tableview
		SELF.isOldCardView = true
	else
		SELF.card_view  = SELF:createTableView( BAGCATEGORY.card, "card_data" , "argv", "toreleaseCardTable") 
		if g_enableTableViewCache then
			card_tableview = SELF.card_view
			card_tableview:retain();
		end
	end
	
	--coroutine.yield()
	
	if equip_tableview then
		SELF.equip_view = equip_tableview
		SELF.isOldEquipView = true
	else
		SELF.equip_view  = SELF:createTableView( BAGCATEGORY.equip,"equip_data","argv", "toreleaseEquipTable")  
		if g_enableTableViewCache then
			equip_tableview = SELF.equip_view
			equip_tableview:retain();
		end
	end
	
	--coroutine.yield()
	
	if item_tableview then
		SELF.item_view = item_tableview
		SELF.isOldItemView = true
	else
		SELF.item_view  = SELF:createTableView( BAGCATEGORY.item,"item_data","argv", "toreleaseItemTable" )  
		if g_enableTableViewCache then
			item_tableview = SELF.item_view
			item_tableview:retain();
		end
	end
	
	--coroutine.yield()
	
	--print("createtable" .. os.difftime(os.time(), enterTime))
	--enterTime = os.time()
    
	local defaultNoCardText = getTextByKey("bag_NoCard")
	if SELF.argv.enterScene == "CardEvolutionScene" then
		if SELF.argv.params and SELF.argv.params.cardType=="slave" then
			defaultNoCardText = getTextByKey("cardEvolve_NoSubCardTxt")
		else
			defaultNoCardText = getTextByKey("cardEvolve_NoCardTxt")
		end
	elseif SELF.argv.enterScene == "CardComposeScene" then
		defaultNoCardText = getTextByKey("cardEnhance_NoCardTxt")
	end
	SELF.noCardText = TextField:create(defaultNoCardText, "Arial", 30)
	local winSize = CCDirector:sharedDirector():getWinSize()
	SELF.noCardText:setPosition(ccp(winSize.width / 2, winSize.height / 2))
	SELF.noCardText:setVisible(false)
	
	local defaultNoCardText = getTextByKey("bag_NoProp")
	SELF.noItemText = TextField:create(defaultNoCardText, "Arial", 30)
	local winSize = CCDirector:sharedDirector():getWinSize()
	SELF.noItemText:setPosition(ccp(winSize.width / 2, winSize.height / 2))
	SELF.noItemText:setVisible(false)
	
	local defaultNoCardText = getTextByKey("bag_NoEquip")
	SELF.noEquipText = TextField:create(defaultNoCardText, "Arial", 30)
	local winSize = CCDirector:sharedDirector():getWinSize()
	SELF.noEquipText:setPosition(ccp(winSize.width / 2, winSize.height / 2))
	SELF.noEquipText:setVisible(false)
    
	SELF.card_view:setVisible(false)
	SELF.equip_view:setVisible(false)
	SELF.item_view:setVisible(false)
	
	local function onClick(e)
		SELF:moveToMap()
	end
	
	local buttonLayer
	if SELF.argv.enterScene == "CardComposeScene" and SELF.argv.params.cardType == "matterCard" then
		buttonLayer = SELF.backbuilder:build("package_btn_gostage")
		buttonLayer:getChildByName("txt_gostage"):setString(getTextByKey("cardEnhance_NoCardBtn"))
		buttonLayer:setPosition(ccp(360 - 126, 550 + 77 / 2))
		local button = Button:create(buttonLayer)
		button:addEventListener(Events.kStart, onClick)
		SELF.nocardButton = button;
		
		table.insert(SELF.group1, buttonLayer)
	end
	
	--coroutine.yield()
	
    --默认选择卡牌按钮
    if SELF.argv.params.tabIndex ~= nil then
        SELF:onSetButtonState( SELF.argv.params.tabIndex, true)
    else
        SELF:onSetButtonState( BAGCATEGORY.card, true)
    end
	--SELF.bg:setPosition(ccp(0, 1040))
	--SELF:addChild(SELF.bg)
	
	if SELF.argv.params.tabIndex == BAGCATEGORY.equip and SELF.argv.params.equipId then
		for key ,data in ipairs(SELF.equip_data) do
			if data.equipId == SELF.argv.params.equipId then
				if key >= 5 then
					local tableOffset = SELF.tableUI:getContentOffset()
					tableOffset.y = - 206 * (#SELF.equip_data - key)  --（原版185）
					SELF.tableUI:setContentOffset(tableOffset, true)
				end
				break;
			end
		end
	end
	--coroutine.yield()
    
	local zOrder = SELF.mainUI:getChildByName("bg_inventory_red"):getZOrder() + 1
	SELF.coverLayer = LayerColor:create()
	SELF.coverLayer:setColor(ccc3( 0, 0, 0 ))
	SELF.coverLayer.refCocosObj:setOpacity( 170 )
	SELF.coverLayer:setContentSize(CCSizeMake( visibleSize.width, 932 ))
	SELF.coverLayer:setPosition(ccp( 0, 118 ))
	SELF.coverLayer:setVisible(false)
	SELF.mainUI:addChildAt(SELF.coverLayer, zOrder)  
	SELF.mainUI:addChildAt(SELF.card_view, zOrder)    
	SELF.mainUI:addChildAt(SELF.equip_view, zOrder)  
	SELF.mainUI:addChildAt(SELF.item_view, zOrder)   
	
	SELF.mainUI:addChild(SELF.noCardText)
	SELF.mainUI:addChild(SELF.noItemText)
	SELF.mainUI:addChild(SELF.noEquipText)
	
	table.insert(SELF.group1, SELF.noCardText)
	table.insert(SELF.group1, SELF.noItemText)
	table.insert(SELF.group1, SELF.noEquipText)
	if buttonLayer then
		SELF.mainUI:addChild(buttonLayer)
	end
	
	
	
    --title不显示
    
    if	SELF.argv.enterScene == "CardEvolutionScene" or
        SELF.argv.enterScene == "EquipUpgradeEmptyScene" or
        SELF.argv.enterScene == "EquipEvolveEmptyScene" or
		SELF.argv.enterScene == "MatrixScene" or
        SELF.argv.enterScene == "CardQueueScene" or  
        SELF.argv.enterScene == "ActivityPanelScene" or
		SELF.argv.enterScene == "CardRebirthScene" then  
        BackpackUIStatus = BACKPACK_STATUS.OPTION
    end
    matterCardSelected = ""
    if SELF.argv.enterScene == "CardComposeScene" then        
        if SELF.argv.params.cardType=="mainCard" then
            BackpackUIStatus = BACKPACK_STATUS.OPTION
			SELF.enablePanelChange = false
			if #idsToSell > 0 then
				SELF.mainUI:getChildByName("btn_inventory_R"):getChildByName("txt_bag_SellBtn"):setString(getTextByKey("yes"))
			else
				SELF.mainUI:getChildByName("btn_inventory_R"):getChildByName("txt_bag_SellBtn"):setString(getTextByKey("cancel"))
			end
			SELF.tableUI:reloadData()
        elseif SELF.argv.params.cardType=="matterCard" then
			SELF.enablePanelChange = false;
            local matterCardString = HeMemDataHolder:getString("matterCard")
            if matterCardString=="" then 
                matterCardString = {}
            else
                matterCardSelected = table.deserialize(matterCardString)
				for k, v in pairs(matterCardSelected)
				do
					table.insert(idsToSell, v.cardId)
				end
            end
			
			if #idsToSell > 0 then
				SELF.mainUI:getChildByName("btn_inventory_R"):getChildByName("txt_bag_SellBtn"):setString(getTextByKey("yes"))
			else
				SELF.mainUI:getChildByName("btn_inventory_R"):getChildByName("txt_bag_SellBtn"):setString(getTextByKey("cancel"))
			end
				
            BackpackUIStatus = BACKPACK_STATUS.CHECKBOX
            SELF.tableUI:reloadData()
        end        
    end
	if SELF.argv.params.limitSelectNum then
		SELF.limitSelectNum = tonumber(SELF.argv.params.limitSelectNum)
	end
	if (BackpackUIStatus == BACKPACK_STATUS.OPTION) then
		SELF.mainUI:getChildByName("btn_inventory_R"):setVisible(false)
		SELF.tableUI:reloadData()
	end
	SELF:addChild(SELF.mainUI)
	BaseUIScene.onInit(SELF)
    SELF:addChild(SELF.headpanelUI)
	SELF.btn_home_menu_title:setVisible(false)
	
	--print("else" .. os.difftime(os.time(), enterTime))
	--enterTime = os.time()

	--显示战斗力更新 FIGHT_CAPACITY_MODIFY by zheng.che @ 2014-12-22
	DataManager.fightCapacityMaybeUpdated()
	
	if isUCAndroid()  then
        if getIsUCSdkInit() then
            showUCFloatButton(50,50,true)
        end
    elseif is91Android() then
        if getIs91SdkInit() then
            show91FloatButton(true)
        end
    elseif isDKAndroid() then
    	showDKFloatButton(true)
    end 
	if callback then
		callback()
	end
	--
	if self.argv.params.cardId and self.argv.params.infoPanelTabType then
		local function showCardInfoNewPanel()
			for k, v in pairs(SELF.card_data) do
				if v.cardId == self.argv.params.cardId then
					SELF._data = v
					SELF.dataIndex = k
					break
				end
			end
			SELF.dataList = SELF.card_data
			user_select.tab = BAGCATEGORY.card
			SELF.targetInfoPanel = CardInfoNewPanel:create( SELF , true , SELF.dataIndex, {tabType = self.argv.params.infoPanelTabType})
			PopoutManager:sharedManager():popout(SELF.targetInfoPanel, kPopoutDir.kScale, true, false ,SELF) 
			ViewControlUtil.refreshAndLocateTableView(SELF.card_view, SELF.dataIndex)
		end
		
		local delayHandlerEntry
		local function delayHandler()
			if delayHandlerEntry ~= nil then
				CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(delayHandlerEntry)
				delayHandlerEntry = nil;
			end
			showCardInfoNewPanel()
		end
		delayHandlerEntry = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(delayHandler,0.01,false);
	end
end

function BackpackScene:sendReplaceCardRequest(cardData)
	if SELF.waitRequest then
		do return end
	end
	
	local function replaceMatrixGridSucceed(evt)
		g_shouldCalc = true;
		SELF.waitRequest = false;
		g_previousBonusTable = nil;
		--setgameinitdata
		local sharkMatricesData = DataManager.getSharkMatricesData()
		local tosetMatrix
		for k, data in pairs(sharkMatricesData) do
			if data.matrixId == SELF.argv.params.matrixId then
				tosetMatrix = data
				break;
			end
		end
		if tosetMatrix then
			if not tosetMatrix.sharkMatrixGrids then
				tosetMatrix.sharkMatrixGrids = {}
			end
			local tosetGrid
			local toChangeGrid--更换已经在阵法里的武将
			for k, data in pairs(tosetMatrix.sharkMatrixGrids) do
				if data.posId == SELF.argv.params.posId then
					tosetGrid = data
				end
				if data.cardId == cardData.cardId then
					toChangeGrid = data
				end
			end
			if tosetGrid then
				if toChangeGrid then
					toChangeGrid.cardId = tosetGrid.cardId
				end
				tosetGrid.cardId = cardData.cardId
			else
				table.insert(tosetMatrix.sharkMatrixGrids, {posId = SELF.argv.params.posId, cardId = cardData.cardId})
			end
		else
			tosetMatrix = {matrixId = SELF.argv.params.matrixId, matrixLevel = 0, sharkMatrixGrids = {}}
			table.insert(tosetMatrix.sharkMatrixGrids, {posId = SELF.argv.params.posId, cardId = cardData.cardId})
			table.insert(sharkMatricesData, tosetMatrix)
		end
		DataManager.setSharkMatricesData(sharkMatricesData)

		--当前阵容（换阵法武将）
		if DataManager.getGameInitData().sharkUser.level >= (MetaManager.game_meta.gameSettingConfig.lineupUnlockLevel or 43) then 
			local gameData = DataManager.getGameInitData()
			local BattleArrayId = gameData.sharkUserExtendMore.battleArrayId
			gameData.sharkUserBattleArray[BattleArrayId].sharkMatrices.sharkMatrices = sharkMatricesData
			DataManager.setGameInitData(gameData)
		end
		--end by l1ghtsaber
		
		if SELF.argv.params.previousCardId then
			CommonManager:setCardNeedUpdate({SELF.argv.params.previousCardId})
		end
		CommonManager:updateEffectQueueStatus()

		g_cardCountryNumCache.needUpdate = true

		if evt.data.type == 1 then
			local srcCardId = cardData.cardId
			local cardQueue = table.clone(CommonManager.getQueueData(), true)
			local cardIds = {}
			for aKey, aCardId  in pairs(cardQueue) do
				cardIds[aCardId] = aKey
			end

			local srcPos = 0
			if (srcCardId==0) then
				HeMemDataHolder:setInteger("CardQueue_RollTo",#cardQueue+1)
				srcPos = #cardQueue+1
			else
				HeMemDataHolder:setInteger("CardQueue_RollTo",cardIds[srcCardId])
				srcPos = cardIds[srcCardId]
			end
			local queueIds = {}
			for key, value in pairs(cardQueue) do
				queueIds[key] = value
			end

			local cardsData = DataManager.getCardsData()
			local originalCard = nil
			local originalCardKey = 0
			local targetCard,targetCardKey = CommonManager.getSubTableByKey(
				cardsData,
				{name = "cardId", value = SELF.argv.params.previousCardId}
			)

			if queueIds[srcPos] then
			    originalCard,originalCardKey = CommonManager.getSubTableByKey(
					cardsData,
					{name = "cardId", value = cardData.cardId}
				)
			else
				print("Bug ~")
				return
			end

			queueIds[srcPos] = nil
			queueIds[srcPos] = SELF.argv.params.previousCardId

			--build the new formation table
			local mainCardId = queueIds[1]
			local additionalCardIds = {}
			local additionalCardIdStr = ""

			for key,value in pairs(queueIds) do
				if (key~=1) then
					table.insert(additionalCardIds, value)
					additionalCardIdStr = additionalCardIdStr .. "," .. value
				end
			end
			--build the new formation string and params
			additionalCardIdStr = string.sub(additionalCardIdStr, 2, -1)
			local params = {mainCardId = mainCardId, additionalCardIds = additionalCardIds}

			local gameData = DataManager.getGameInitData()

			gameData["sharkUser"]["mainCardId"] = params.mainCardId
			gameData["sharkUser"]["additionalCardIds"] = additionalCardIdStr

			local equipsData = DataManager.getEquipsData()
			if (originalCard) then
				if (originalCard.equipIds) then
					local equipIds = originalCard.equipIds
					cardsData[originalCardKey].equipIds = nil
					cardsData[targetCardKey].equipIds = equipIds
					for _, aEquipId in pairs(equipIds) do
						local _,aEquipKey = CommonManager.getSubTableByKey(
							equipsData,
							{name = "equipId", value = aEquipId}
						)
						equipsData[aEquipKey].cardId = targetCard.cardId
					end
				end
			end
			local spiritsData = DataManager.getSpiritsData()
			if (originalCard) then
				if (originalCard.cardSpirits) then
					local cardSpirits = originalCard.cardSpirits
					cardsData[originalCardKey].cardSpirits = nil
					cardsData[targetCardKey].cardSpirits = cardSpirits
					for _, aEquipId in pairs(cardSpirits) do
						local _,aEquipKey = CommonManager.getSubTableByKey(
							spiritsData,
							{name = "spiritId", value = aEquipId.spiritId}
						)
						spiritsData[aEquipKey].cardId = targetCard.cardId
					end
				end
			end

			local treasureData = DataManager.getTreasuresData()
			if (originalCard) then
				if (originalCard.treasureId ~= 0) then
					local cardTreasureId = originalCard.treasureId
					cardsData[originalCardKey].treasureId = 0
					cardsData[targetCardKey].treasureId = cardTreasureId
					for k,v in pairs(treasureData) do
						if v.treasureId == cardTreasureId then
							v.cardId = targetCard.cardId
							break
						end
					end
				end
			end


			--当前阵容（换阵法武将换到队伍的）
			if (originalCard) and (gameData.sharkUser.level >= (MetaManager.game_meta.gameSettingConfig.lineupUnlockLevel or 43))
			then
				local BattleArrayId = gameData.sharkUserExtendMore.battleArrayId
				for k,v in pairs(gameData.sharkUserBattleArray[BattleArrayId].sharkUserQueue) do
					if (originalCard.cardId == v.cardId) then 
						v.cardId = targetCard.cardId
					elseif (targetCard.cardId == v.cardId) then
						v.cardId = originalCard.cardId 
					end
				end
			end
			--end by l1ghtsaber

			gameData.sharkCards.sharkCards = cardsData
			gameData.sharkEquips.sharkEquips = equipsData
			gameData.sharkSpirits.sharkSpirits = spiritsData
			gameData.sharkTreasures.sharkTreasures = treasureData

			DataManager.setGameInitData(gameData)
		end

		--replacescene
		SELF:replaceScene(MatrixScene, {enterScene = "BackpackScene", params = {}})
	end
	
	local function replaceMatrixGridFailed(evt)
		SELF.waitRequest = false
		if evt.data == 713405 then
			local function closeCanonMessageBox()
			end
			self.targetInfoPanel = CanonMessageBox:Show(getTextByKey("grid_lock_remind"), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox)
		elseif evt.data == 710203 then
		    local aContent = Localization:getInstance():getText("formation_leadershipInsufficient")
			SuspensionLabel:showContent(SELF, aContent)
		else
			CanonMessageBox:showCommUnHandleErrorBox(evt.data)
		end
	end
	
	SELF.waitRequest = true
	local request = ReplaceMatrixGridRequest.new( {matrixId = SELF.argv.params.matrixId, posId = SELF.argv.params.posId, cardId = cardData.cardId}, rpc.SendingPriority.kHigh )
	request:addEventListener( RequestNotifyEnum.ReplaceMatrixGridSucceed, replaceMatrixGridSucceed )
	request:addEventListener( RequestNotifyEnum.ReplaceMatrixGridFailed, replaceMatrixGridFailed )
	request:start()
end

local TAG_TXT_CARD_NAME = 1001
local TAG_TXT_CHALLENGE = 1002
local TAG_TXT_LEADERSHIP_NUM = 1003
local TAG_TXT_ATK_NUM = 1004
local TAG_TXT_DEF_NUM = 1005
local TAG_TXT_HP_NUM = 1006
local TAG_ICON_CHALLENGE = 1007
local TAG_TXT_LV_NUM = 1008
local TAG_ICON_CHECKBOX = 1009
local TAG_ICON_EVOLVE = 1010
local TAG_ICON_CHECKBOX_BG = 1011
local TAG_ICON_USEITEM = 1012
local TAG_TXT_ITEM_AMOUNT = 1013
local TAG_TXT_ITEM_DESC = 1014
local TAG_TXT_ITEM_NAME = 1015
local TAG_PIC = 1016
local TAG_ICON_STRENGTHEN = 1017
local TAG_TXT_EQUIPNAME = 1018
--ENCHANT_MODIFY 去掉原装备属性数值
--local TAG_TXT_EQUIPINFO = 1019
local TAG_TXT_EQUIPLV = 1020
local TAG_TXT_EQUIPED = 1021
--ENCHANT_MODIFY 去掉原装备属性数值
--local TAG_ICON_EQUIPINFO = 1022
local TAG_ICON_WHITE = 1023
local TAG_ICON_GREEN = 1024
local TAG_ICON_BLUE = 1025
local TAG_ICON_PURPLE = 1026
local TAG_ICON_ORANGE = 1027
local TAG_ICON_RED = 1028
local TAG_ICON_GOLD = 1029
local TAG_ICON_SELECTED = 1030
local TAG_ICON_SELLCOIN = 1031
local TAG_TXT_SELLCOIN = 1032
local TAG_TXT_EXP = 1033
local TAG_TXT_LEADERSHIPTXT = 1034
local TAG_TXT_LEADERSHIPTXT2 = 1035
local TAG_TXT_LEADERSHIP_NUM2 = 1036
local TAG_TXT_ENABLEEVOLUTION = 1037
local TAG_TXT_POTENTIALPOINT = 1038
local TAG_BTN_TRAIN = 1039
local TAG_TXT_CANNOTSELL = 1040
local TAG_TXT_PERFECT = 1041
--ENCHANT_MODIFY
local TAG_TXT_ENCHANT_STR = 1042
local TAG_TXT_ENCHANT_NUM = 1043
local TAG_TXT_ATTR1 = 1044
local TAG_TXT_ATTR2 = 1045
local TAG_TXT_ATTR3 = 1046


local TAG_FIRST_STAR = 10001
local TAG_CARD_HEAD = 10100
local TAG_EQUP_ATTRI = 10101

local TAG_FLAG_FIR = 1047
local TAG_FLAG_SEC = 1048
local TAG_FLAG_THD = 1049  --add by l1ghtsaber

function BackpackScene:createTableView( tableViewType ,data , argv, releaseTable )
	local BackPackRenderer = class(TableViewRenderer)
	function BackPackRenderer:ctor(width, height)
		self.list = SELF[data]
		self.releaseTable = SELF[releaseTable]
		local builder = LayoutBuilder:createWithContentsOfFile("scene/package_new.json")
		builder.useArtLabelTTF = true
		self.builder = builder
	end
	
	local firstStarPosX,firstStarPosY, starPixielX
	
	function BackPackRenderer:buildCell(container)
		if tableViewType == BAGCATEGORY.card then
			local cell = self.builder:build("package_inventory_card") 
			cell:setPosition(ccp(0, self.height))
			cell:getChildByName("normal_card_big"):setVisible(false);
			cell:getChildByName("normal_card_big"):setTag(TAG_PIC)
			cell:getChildByName("txt_inventory_card_name"):setTag(TAG_TXT_CARD_NAME)
			cell:getChildByName("txt_inventory_card_name"):getChildByName("txt_inventory_card_name"):setTag(TAG_TXT_CARD_NAME)
			cell:getChildByName("txt_icon_stageList_challenge"):setTag(TAG_TXT_CHALLENGE)
			cell:getChildByName("txt_icon_stageList_challenge"):getChildByName("txt_icon_stageList_challenge"):setTag(TAG_TXT_CHALLENGE)
			cell:getChildByName("txt_icon_stageList_challenge"):getChildByName("txt_icon_stageList_challenge"):setString(getTextByKey("bag_CardInBattle"))
			cell:getChildByName("txt_cardInfo_Leadership_num"):setTag(TAG_TXT_LEADERSHIP_NUM)
			cell:getChildByName("txt_cardInfo_Leadership_num"):getChildByName("font"):setTag(TAG_TXT_LEADERSHIP_NUM)
			cell:getChildByName("txt_cardInfo_Leadership_num_2"):setTag(TAG_TXT_LEADERSHIP_NUM2)
			cell:getChildByName("txt_cardInfo_Leadership_num_2"):getChildByName("font"):setTag(TAG_TXT_LEADERSHIP_NUM2)
			cell:getChildByName("txt_wecandoanything"):setTag(TAG_TXT_ENABLEEVOLUTION)
			cell:getChildByName("txt_wecandoanything"):getChildByName("txt"):setTag(TAG_TXT_ENABLEEVOLUTION)
			cell:getChildByName("txt_atk_num"):setTag(TAG_TXT_ATK_NUM)
			cell:getChildByName("txt_atk_num"):getChildByName("font"):setTag(TAG_TXT_ATK_NUM)
			cell:getChildByName("txt_def_num"):setTag(TAG_TXT_DEF_NUM)
			cell:getChildByName("txt_def_num"):getChildByName("font"):setTag(TAG_TXT_DEF_NUM)
			cell:getChildByName("txt_hp_num"):setTag(TAG_TXT_HP_NUM)
			cell:getChildByName("txt_hp_num"):getChildByName("font"):setTag(TAG_TXT_HP_NUM)
			cell:getChildByName("icon_stageList_challenge"):setTag(TAG_ICON_CHALLENGE)
			cell:getChildByName("icon_star_1"):setVisible(false)
			if not firstStarPosX and not firstStarPosY then
				firstStarPosX, firstStarPosY = cell:getChildByName("icon_star_1").refCocosObj:getPosition()
			end
			cell:getChildByName("txt_lv_num"):setTag(TAG_TXT_LV_NUM)
			cell:getChildByName("txt_lv_num"):getChildByName("txt_lv_num"):setTag(TAG_TXT_LV_NUM)
			cell:getChildByName("icon_star_2"):setVisible(false)
			if not starPixielX then
				local posX, posY = cell:getChildByName("icon_star_2").refCocosObj:getPosition()
				starPixielX = firstStarPosX - posX
			end
			
			for i = 1, 7
			do
				local star = Sprite:create(UI_RES_PATH.."/package_new/package_icon_star_sb.png")
				star:setAnchorPoint(ccp(0, 1))
				star:setPosition(ccp(firstStarPosX - starPixielX * (i - 1), firstStarPosY))
				star.refCocosObj:setTag( TAG_FIRST_STAR - 1 + i)
				cell:addChild(star)
			end

			cell:getChildByName("icon_checkbox"):setTag(TAG_ICON_CHECKBOX)
			cell:getChildByName("bg_checkbox"):setTag(TAG_ICON_CHECKBOX_BG)
			cell:getChildByName("txt_cardInfo_Leadership"):getChildByName("txt_cardInfo_Leadership"):setString(getTextByKey("formation_leadership"))
			cell:getChildByName("txt_cardInfo_Leadership"):setTag(TAG_TXT_LEADERSHIPTXT)
			cell:getChildByName("txt_cardInfo_Leadership_2"):getChildByName("txt_cardInfo_Leadership"):setString(getTextByKey("formation_leadership"))
			cell:getChildByName("txt_cardInfo_Leadership_2"):setTag(TAG_TXT_LEADERSHIPTXT2)
			cell:getChildByName("q_white9_panel"):setTag(TAG_ICON_WHITE)
			cell:getChildByName("q_green9_panel"):setTag(TAG_ICON_GREEN)
			cell:getChildByName("q_blue9_panel"):setTag(TAG_ICON_BLUE)
			cell:getChildByName("q_purple9_panel"):setTag(TAG_ICON_PURPLE)
			cell:getChildByName("q_orange9_panel"):setTag(TAG_ICON_ORANGE)
			cell:getChildByName("q_red9_panel"):setTag(TAG_ICON_RED)
			cell:getChildByName("q_yellow9_panel"):setTag(TAG_ICON_GOLD)
			cell:getChildByName("q_white9_panel"):setVisible(false)
			cell:getChildByName("q_green9_panel"):setVisible(false)
			cell:getChildByName("q_blue9_panel"):setVisible(false)
			cell:getChildByName("q_purple9_panel"):setVisible(false)
			cell:getChildByName("q_orange9_panel"):setVisible(false)
			cell:getChildByName("q_red9_panel"):setVisible(false)
			cell:getChildByName("q_yellow9_panel"):setVisible(false)
			cell:getChildByName("frame_card"):setVisible(false)
			cell:getChildByName("txt_inventory_equip_selled"):setVisible(false)
			cell:getChildByName("flash_light9_panel"):setTag(TAG_ICON_SELECTED)
			cell:getChildByName("txt_sellv_font"):setTag(TAG_TXT_SELLCOIN)
			cell:getChildByName("txt_sellv_font"):getChildByName("txt"):setTag(TAG_TXT_SELLCOIN)
			cell:getChildByName("txt_cardInfo_expv"):setVisible(false)
			cell:getChildByName("txt_sellv"):setTag(TAG_TXT_EXP)
			cell:getChildByName("txt_sellv"):getChildByName("txt"):setString(getTextByKey("cardInfo_exp"))
			cell:getChildByName("icon_slivercoin"):setTag(TAG_ICON_SELLCOIN)
			cell:getChildByName("btn_train"):setTag(TAG_BTN_TRAIN)
			cell:getChildByName("btn_train"):getChildByName("txt"):setString(getTextByKey("cardTrain_levellow"))
			cell:getChildByName("txt_cardInfo_point_2"):setTag(TAG_TXT_POTENTIALPOINT)
			cell:getChildByName("txt_cardInfo_point_2"):getChildByName("txt"):setString(getTextByKey("cardTrain_capacity"))

			cell:getChildByName("icon_squad_1"):setTag(TAG_FLAG_FIR)
			cell:getChildByName("icon_squad_2"):setTag(TAG_FLAG_SEC)
			cell:getChildByName("icon_squad_3"):setTag(TAG_FLAG_THD)
			cell:getChildByName("icon_squad_1"):getChildByName("icon_squad1"):setTag(TAG_FLAG_FIR)
			cell:getChildByName("icon_squad_2"):getChildByName("icon_squad2"):setTag(TAG_FLAG_SEC)
			cell:getChildByName("icon_squad_3"):getChildByName("icon_squad3"):setTag(TAG_FLAG_THD)

			local perfectTxt = cell:getChildByName("txt_perfect"):getChildByName("txt")
		    perfectTxt:setColor(ccc3(255,0,0))
		    perfectTxt:setAroundColor(ccc3(255, 255, 255))
			cell:getChildByName("txt_perfect"):setTag(TAG_TXT_PERFECT)
			cell:getChildByName("txt_perfect"):getChildByName("txt"):setTag(TAG_TXT_PERFECT)
			
			cell:setTag(-1001)
			container:addChild(cell)
		elseif tableViewType == BAGCATEGORY.item then
			local cell = self.builder:build("package_inventory_prov") 
			cell:getChildByName("normal_card_small"):setAnchorPoint(ccp(0.5, 0.5))
			cell:getChildByName("normal_card_small"):setTag(TAG_PIC)
			cell:getChildByName("icon_checkbox"):setTag(TAG_ICON_CHECKBOX)
			cell:getChildByName("bg_checkbox"):setTag(TAG_ICON_CHECKBOX_BG)
			cell:getChildByName("btn_inventory_prov_use"):setTag(TAG_ICON_USEITEM)
			cell:getChildByName("btn_inventory_prov_use"):getChildByName("txt_inventory_prov_use"):setTag(TAG_ICON_USEITEM)
			cell:getChildByName("txt_inventory_prov_name_num"):setTag(TAG_TXT_ITEM_AMOUNT)
			cell:getChildByName("txt_inventory_prov_name_num"):getChildByName("txt_inventory_prov_name_num"):setTag(TAG_TXT_ITEM_AMOUNT)
			cell:getChildByName("txt_inventory_prov_desc"):setTag(TAG_TXT_ITEM_DESC)
			cell:getChildByName("txt_inventory_prov_desc"):getChildByName("txt_inventory_prov_desc"):setTag(TAG_TXT_ITEM_DESC)
			cell:getChildByName("txt_inventory_prov_name"):setTag(TAG_TXT_ITEM_NAME)
			cell:getChildByName("txt_inventory_prov_name"):getChildByName("txt_inventory_prov_name"):setTag(TAG_TXT_ITEM_NAME)			
			cell:getChildByName("txt_inventory_prov_name"):getChildByName("txt_inventory_prov_name"):setDimensions(CCSizeMake(0, 0))
			cell:getChildByName("q_white9_panel"):setTag(TAG_ICON_WHITE)
			cell:getChildByName("q_green9_panel"):setTag(TAG_ICON_GREEN)
			cell:getChildByName("q_blue9_panel"):setTag(TAG_ICON_BLUE)
			cell:getChildByName("q_purple9_panel"):setTag(TAG_ICON_PURPLE)
			cell:getChildByName("q_orange9_panel"):setTag(TAG_ICON_ORANGE)
			cell:getChildByName("q_red9_panel"):setTag(TAG_ICON_RED)
			cell:getChildByName("q_yellow9_panel"):setTag(TAG_ICON_GOLD)
			cell:getChildByName("q_white9_panel"):setVisible(false)
			cell:getChildByName("q_green9_panel"):setVisible(false)
			cell:getChildByName("q_blue9_panel"):setVisible(false)
			cell:getChildByName("q_purple9_panel"):setVisible(false)
			cell:getChildByName("q_orange9_panel"):setVisible(false)
			cell:getChildByName("q_red9_panel"):setVisible(false)
			cell:getChildByName("q_yellow9_panel"):setVisible(false)
			cell:getChildByName("frame_card"):setVisible(false)
			cell:getChildByName("txt_inventory_equip_selled"):setVisible(false)
			cell:getChildByName("txt_sellv"):setVisible(false)
			cell:getChildByName("flash_light9_panel"):setTag(TAG_ICON_SELECTED)
			cell:getChildByName("icon_slivercoin"):setTag(TAG_ICON_SELLCOIN)
			cell:getChildByName("txt_sellv_font"):setTag(TAG_TXT_SELLCOIN)
			cell:getChildByName("txt_sellv_font"):getChildByName("txt"):setTag(TAG_TXT_SELLCOIN)
			cell:getChildByName("txt_inventory_cantsell"):setTag(TAG_TXT_CANNOTSELL)
			cell:getChildByName("txt_inventory_cantsell"):getChildByName("txt"):setString(getTextByKey("inventory_cannotSell"))
			cell:setPosition(ccp(0, self.height))
			cell:setTag(-1001)
			container:addChild(cell)
		elseif tableViewType == BAGCATEGORY.equip then
			local cell = self.builder:build("package_inventory_equip")
			cell:getChildByName("normal_card_small"):setAnchorPoint(ccp(0.5, 0.5))
			cell:getChildByName("normal_card_small"):setTag(TAG_PIC)
			cell:getChildByName("icon_checkbox"):setTag(TAG_ICON_CHECKBOX)
			cell:getChildByName("bg_checkbox"):setTag(TAG_ICON_CHECKBOX_BG)
			cell:getChildByName("btn_equip_Evolve"):setTag(TAG_ICON_EVOLVE)
			cell:getChildByName("btn_equip_Evolve"):getChildByName("txt_-equip_Evolve"):setString(getTextByKey("equip_Evolve"))
			cell:getChildByName("btn_equipEnhance_Title"):setTag(TAG_ICON_STRENGTHEN)
			cell:getChildByName("btn_equipEnhance_Title"):getChildByName("txt_equipEnhance_Title"):setString(getTextByKey("equip_Enhance"))
			cell:getChildByName("txt_inventory_card_name"):setTag(TAG_TXT_EQUIPNAME)
			cell:getChildByName("txt_inventory_card_name"):getChildByName("txt_inventory_card_name"):setTag(TAG_TXT_EQUIPNAME)
			--ENCHANT_MODIFY 去掉原装备属性数值
			--cell:getChildByName("txt_frameS_parameter"):setTag(TAG_TXT_EQUIPINFO)
			--cell:getChildByName("txt_frameS_parameter"):getChildByName("font"):setTag(TAG_TXT_EQUIPINFO)
			cell:getChildByName("txt_lv_num"):setTag(TAG_TXT_EQUIPLV)
			cell:getChildByName("txt_lv_num"):getChildByName("txt_lv_num"):setTag(TAG_TXT_EQUIPLV)
			cell:getChildByName("txt_inventory_equip_selled"):setTag(TAG_TXT_EQUIPED)
			cell:getChildByName("txt_inventory_equip_selled"):getChildByName("txt_inventory_equip_selled"):setTag(TAG_TXT_EQUIPED)
			--ENCHANT_MODIFY 去掉原装备属性数值
			-- cell:getChildByName("icon_atk_sb"):setTag(TAG_ICON_EQUIPINFO)
			-- cell:getChildByName("icon_atk_sb"):setVisible(false)
			cell:getChildByName("q_white9_panel"):setTag(TAG_ICON_WHITE)
			cell:getChildByName("q_green9_panel"):setTag(TAG_ICON_GREEN)
			cell:getChildByName("q_blue9_panel"):setTag(TAG_ICON_BLUE)
			cell:getChildByName("q_purple9_panel"):setTag(TAG_ICON_PURPLE)
			cell:getChildByName("q_orange9_panel"):setTag(TAG_ICON_ORANGE)
			cell:getChildByName("q_red9_panel"):setTag(TAG_ICON_RED)
			cell:getChildByName("q_yellow9_panel"):setTag(TAG_ICON_GOLD)
			cell:getChildByName("flash_light9_panel"):setTag(TAG_ICON_SELECTED)
			cell:getChildByName("frame_card"):setVisible(false)
			cell:getChildByName("txt_sellv"):setVisible(false)
			cell:getChildByName("icon_slivercoin"):setTag(TAG_ICON_SELLCOIN)
			cell:getChildByName("txt_sellv_font"):setTag(TAG_TXT_SELLCOIN)
			cell:getChildByName("txt_sellv_font"):getChildByName("txt"):setTag(TAG_TXT_SELLCOIN)
			cell:getChildByName("txt_icon_inverntory_equiped"):setTag(TAG_TXT_CHALLENGE)
			cell:getChildByName("txt_icon_inverntory_equiped"):getChildByName("txt_icon_stageList_challenge"):setString(getTextByKey("equip_equipped"))
			cell:getChildByName("icon_stageList_challenge"):setTag(TAG_ICON_CHALLENGE)
			cell:getChildByName("icon_star_1"):setVisible(false)
			cell:getChildByName("icon_star_2"):setVisible(false)
			--ENCHANT_MODIFY
			cell:getChildByName("txt_1"):setTag(TAG_TXT_ENCHANT_STR)
			cell:getChildByName("txt_1"):getChildByName("txt"):setString(getTextByKey("enchant_1"))--附灵
			cell:getChildByName("txt_3"):setTag(TAG_TXT_ENCHANT_NUM)
			cell:getChildByName("txt_3"):getChildByName("txt"):setTag(-11)

			cell:getChildByName("attribute_01"):setTag(TAG_TXT_ATTR1)
			cell:getChildByName("attribute_01"):getChildByName("icon_atk"):setTag(-11)
			cell:getChildByName("attribute_01"):getChildByName("icon_hp"):setTag(-12)
			cell:getChildByName("attribute_01"):getChildByName("icon_def"):setTag(-13)
			cell:getChildByName("attribute_01"):getChildByName("txt_03"):setTag(-14)
			cell:getChildByName("attribute_01"):getChildByName("txt_03"):getChildByName("txt"):setTag(-11)
			cell:getChildByName("attribute_01"):getChildByName("txt_02"):setTag(-15)
			cell:getChildByName("attribute_01"):getChildByName("txt_02"):getChildByName("txt"):setTag(-11)

			cell:getChildByName("attribute_02"):setTag(TAG_TXT_ATTR2)
			cell:getChildByName("attribute_02"):getChildByName("icon_atk"):setTag(-11)
			cell:getChildByName("attribute_02"):getChildByName("icon_hp"):setTag(-12)
			cell:getChildByName("attribute_02"):getChildByName("icon_def"):setTag(-13)
			cell:getChildByName("attribute_02"):getChildByName("txt_03"):setTag(-14)
			cell:getChildByName("attribute_02"):getChildByName("txt_03"):getChildByName("txt"):setTag(-11)
			cell:getChildByName("attribute_02"):getChildByName("txt_02"):setTag(-15)
			cell:getChildByName("attribute_02"):getChildByName("txt_02"):getChildByName("txt"):setTag(-11)

			cell:getChildByName("attribute_03"):setTag(TAG_TXT_ATTR3)
			cell:getChildByName("attribute_03"):getChildByName("icon_atk"):setTag(-11)
			cell:getChildByName("attribute_03"):getChildByName("icon_hp"):setTag(-12)
			cell:getChildByName("attribute_03"):getChildByName("icon_def"):setTag(-13)
			cell:getChildByName("attribute_03"):getChildByName("txt_03"):setTag(-14)
			cell:getChildByName("attribute_03"):getChildByName("txt_03"):getChildByName("txt"):setTag(-11)
			cell:getChildByName("attribute_03"):getChildByName("txt_02"):setTag(-15)
			cell:getChildByName("attribute_03"):getChildByName("txt_02"):getChildByName("txt"):setTag(-11)

			if not firstStarPosX and not firstStarPosY then
				firstStarPosX, firstStarPosY = cell:getChildByName("icon_star_1").refCocosObj:getPosition()
			end
			if not starPixielX then
				local posX, posY = cell:getChildByName("icon_star_2").refCocosObj:getPosition()
				starPixielX = firstStarPosX - posX
			end
			
			for i = 1, 7
			do
				local star = Sprite:create(UI_RES_PATH.."/package_new/package_icon_star_sb.png")
				star:setAnchorPoint(ccp(0, 1))
				star:setPosition(ccp(firstStarPosX - starPixielX * (i - 1), firstStarPosY))  
				star.refCocosObj:setTag( TAG_FIRST_STAR - 1 + i)
				cell:addChild(star)
			end

			cell:getChildByName("icon_squad_1"):setTag(TAG_FLAG_FIR)
			cell:getChildByName("icon_squad_2"):setTag(TAG_FLAG_SEC)
			cell:getChildByName("icon_squad_3"):setTag(TAG_FLAG_THD)
			cell:getChildByName("icon_squad_1"):getChildByName("icon_squad1"):setTag(TAG_FLAG_FIR)
			cell:getChildByName("icon_squad_2"):getChildByName("icon_squad2"):setTag(TAG_FLAG_SEC)
			cell:getChildByName("icon_squad_3"):getChildByName("icon_squad3"):setTag(TAG_FLAG_THD)

			cell:setPosition(ccp(0, self.height))
			cell:setTag(-1001)
			container:addChild(cell)
		end
	end
	
	local function setTextByTag( cell, tag, str , isArtLabel)
		local txt = cell:getChildByTag(tag):getChildByTag(tag)
		setNodeText(txt, str);
	end
	
	local function setNodeVisibleByTag(cell, tag, visible)
		cell:getChildByTag(tag):setVisible(visible)
	end
	
	function BackPackRenderer:setData( rawCocosObj, index )
		local cell = self:getChildByTag(rawCocosObj, -1001)
		if tableViewType == BAGCATEGORY.card then
			if SELF[data][index + 1] then
				local cardInfo = SELF[data][index + 1]
				-- print("index" .. tostringRich(index))
				-- print("cardInfo" .. tostringRich(cardInfo))
				if not cardInfo.attack then
					local cardStatus = CommonManager:getBackpackCardPropertiesWithSharkCard( cardInfo )
					--print("cardStatus" .. tostringRich(cardStatus))
					cardInfo.attack  = cardStatus.att
					cardInfo.defense = cardStatus.def
					cardInfo.hp      = cardStatus.hp
					cardInfo.price   = cardStatus.price
					cardInfo.resultExp   = math.floor(cardStatus.resultExp)
					cardInfo.potential = cardStatus.totalPotential - cardInfo.usedPotential
				end
				
				local cardMeta = MetaManager.card_meta[cardInfo.metaId]
				
				if cell:getChildByTag(TAG_CARD_HEAD) then
					cell:removeChildByTag(TAG_CARD_HEAD, true)
				end
				
				local itemPosX, itemPosY = cell:getChildByTag(TAG_PIC):getPosition()
				local zOrder = cell:getChildByTag(TAG_PIC):getZOrder()
				if not self.releaseTable.canonCard then
					self.releaseTable.canonCard = {}
				end
				if self.releaseTable.canonCard[index] then
					releaseAll(self.releaseTable.canonCard[index])
				end
				self.releaseTable.canonCard[index] = nil;

				setNodeVisibleByTag(cell, TAG_TXT_PERFECT , false)
				local perfectType = 0
				if CommonManager:checkIsCardPerfect(cardInfo) then
					if cardMeta.evolutionLevel == cardMeta.maxEvolvedLevel then
						perfectType = CardPerfectEnum.goldRight
						setTextByTag(cell, TAG_TXT_PERFECT, getTextByKey("option_perfect"))
						setNodeVisibleByTag(cell, TAG_TXT_PERFECT , true)
					else
						perfectType = CardPerfectEnum.silverRight
						setNodeVisibleByTag(cell, TAG_TXT_PERFECT , false)
					end
				end
				self.releaseTable.canonCard[index] = getBackpackHeadIconCanonCardByMetaId(CommonManager:changeAvatarByCardInfo( cardInfo ), cardInfo.lock , perfectType)
				--local headCard = CocosObject.new(CCSprite:createWithSpriteFrame(getIconCardSpriteFrame(cardInfo.metaId)))
				self.releaseTable.canonCard[index]:setPosition(ccp(itemPosX, itemPosY))
				self.releaseTable.canonCard[index]:setTag(TAG_CARD_HEAD)
				cell:addChild(self.releaseTable.canonCard[index].refCocosObj, zOrder)
				
				setTextByTag(cell, TAG_TXT_CARD_NAME, getTextByKey(cardMeta.name), true)
				setTextByTag(cell, TAG_TXT_LEADERSHIP_NUM, "" .. math.floor(cardMeta.leadPoint))
				setTextByTag(cell, TAG_TXT_LEADERSHIP_NUM2, "" .. math.floor(cardMeta.leadPoint))
				setTextByTag(cell, TAG_TXT_ATK_NUM, "" .. math.floor(cardInfo.attack))
				setTextByTag(cell, TAG_TXT_DEF_NUM, "" .. math.floor(cardInfo.defense))
				setTextByTag(cell, TAG_TXT_HP_NUM, "" .. math.floor(cardInfo.hp))
				setTextByTag(cell, TAG_TXT_LV_NUM, "" .. cardInfo.level .. "/" .. MetaManager.card_evolve[cardMeta.evolutionLevel].maxCardLevel)
				
				--[[for i = 1, MAXRARE
				do
					if cell:getChildByTag(TAG_FIRST_STAR + i - 1) then
						cell:removeChildByTag(TAG_FIRST_STAR+i - 1, true)
					end
				end
				
				if not self.releaseTable.starSprite then
					self.releaseTable.starSprite = {}
				end
				if self.releaseTable.starSprite[index] then
					releaseAll(self.releaseTable.starSprite[index])
				end
				self.releaseTable.starSprite[index] = {}
				for i = 1, cardMeta.rare
				do
					self.releaseTable.starSprite[index][i] = Sprite:create(UI_RES_PATH.."/package_new/package_icon_star_sb.png")
					self.releaseTable.starSprite[index][i]:setAnchorPoint(ccp(0, 1))
					self.releaseTable.starSprite[index][i]:setPosition(ccp(firstStarPosX - starPixielX * (i - 1), firstStarPosY))
					cell:addChild(self.releaseTable.starSprite[index][i].refCocosObj, 1000, TAG_FIRST_STAR - 1 + i)
				end--]]
				
				for i = 1, 7
				do
					setNodeVisibleByTag(cell, TAG_FIRST_STAR - 1 + i, i <= cardMeta.rare)
				end --数星星
				
				if BackpackUIStatus == BACKPACK_STATUS.CHECKBOX then
					setNodeVisibleByTag(cell, TAG_TXT_LEADERSHIPTXT, false)
					setNodeVisibleByTag(cell, TAG_TXT_LEADERSHIPTXT2, false)
					setNodeVisibleByTag(cell, TAG_TXT_LEADERSHIP_NUM, false)
					setNodeVisibleByTag(cell, TAG_TXT_LEADERSHIP_NUM2, false)
					setNodeVisibleByTag(cell, TAG_TXT_ENABLEEVOLUTION, false)
					if SELF.argv.enterScene then
						setNodeVisibleByTag(cell, TAG_ICON_SELLCOIN, false)
						if SELF.argv.enterScene == "CardComposeScene" and SELF.argv.params.cardType=="matterCard" then
							setNodeVisibleByTag(cell, TAG_TXT_EXP, true)
							setNodeVisibleByTag(cell, TAG_TXT_SELLCOIN, true)
							setTextByTag(cell, TAG_TXT_SELLCOIN, tostring(cardInfo.resultExp))
						else
							setNodeVisibleByTag(cell, TAG_TXT_LEADERSHIPTXT, true)
							setNodeVisibleByTag(cell, TAG_TXT_LEADERSHIP_NUM, true)
							setNodeVisibleByTag(cell, TAG_TXT_EXP, false)
							setNodeVisibleByTag(cell, TAG_TXT_SELLCOIN, false)
						end
					else
						setNodeVisibleByTag(cell, TAG_ICON_SELLCOIN, true)
						setNodeVisibleByTag(cell, TAG_TXT_SELLCOIN, true)
						setTextByTag(cell, TAG_TXT_SELLCOIN, cardInfo.price)
						setNodeVisibleByTag(cell, TAG_TXT_EXP, false)
					end
					setNodeVisibleByTag(cell, TAG_ICON_CHECKBOX_BG, true)
					
					local selected = false;
					for k,v in pairs(idsToSell)
					do
						if v == cardInfo.cardId then
							selected = true;
							break;
						end
					end
					setNodeVisibleByTag(cell, TAG_ICON_CHECKBOX, selected)
					setNodeVisibleByTag(cell, TAG_ICON_SELECTED, selected)
				else					
					setNodeVisibleByTag(cell, TAG_ICON_SELLCOIN, false)
					setNodeVisibleByTag(cell, TAG_TXT_SELLCOIN, false)
					setNodeVisibleByTag(cell, TAG_TXT_EXP, false)
					setNodeVisibleByTag(cell, TAG_ICON_CHECKBOX_BG, false)
					setNodeVisibleByTag(cell, TAG_ICON_CHECKBOX, false)
					setNodeVisibleByTag(cell, TAG_ICON_SELECTED, false)
					if (SELF.argv.enterScene == "CardEvolutionScene" and type(SELF.argv.params) == "table" and SELF.argv.params.cardType == "master") then
						if not cardInfo.levelEnough then
							setTextByTag(cell, TAG_TXT_ENABLEEVOLUTION, getTextByKey("cardEvolveTip_Level"))
							local txt = cell:getChildByTag(TAG_TXT_ENABLEEVOLUTION):getChildByTag(TAG_TXT_ENABLEEVOLUTION)
							setNodeColor(txt, ccc3(255, 0, 0));
						elseif not cardInfo.hasMaterial then--material not enough
							setTextByTag(cell, TAG_TXT_ENABLEEVOLUTION, getTextByKey("cardEvolveTip_Material"))
							local txt = cell:getChildByTag(TAG_TXT_ENABLEEVOLUTION):getChildByTag(TAG_TXT_ENABLEEVOLUTION)
							setNodeColor(txt, ccc3(255, 0, 0));
						else
							setTextByTag(cell, TAG_TXT_ENABLEEVOLUTION, getTextByKey("cardEvolveRemind"))
							local txt = cell:getChildByTag(TAG_TXT_ENABLEEVOLUTION):getChildByTag(TAG_TXT_ENABLEEVOLUTION)
							setNodeColor(txt, ccc3(0, 255, 0));
						end
						setNodeVisibleByTag(cell, TAG_TXT_LEADERSHIPTXT, false)
						setNodeVisibleByTag(cell, TAG_TXT_LEADERSHIP_NUM, false)
						setNodeVisibleByTag(cell, TAG_TXT_LEADERSHIPTXT2, true)
						setNodeVisibleByTag(cell, TAG_TXT_LEADERSHIP_NUM2, true)
						setNodeVisibleByTag(cell, TAG_TXT_ENABLEEVOLUTION, true)
					else
						setNodeVisibleByTag(cell, TAG_TXT_LEADERSHIPTXT, true)
						setNodeVisibleByTag(cell, TAG_TXT_LEADERSHIP_NUM, true)
						setNodeVisibleByTag(cell, TAG_TXT_LEADERSHIPTXT2, false)
						setNodeVisibleByTag(cell, TAG_TXT_LEADERSHIP_NUM2, false)
						setNodeVisibleByTag(cell, TAG_TXT_ENABLEEVOLUTION, false)
					end
				end

				--显示多阵容卡牌状态
				if DataManager.getGameInitData().sharkUser.level < (MetaManager.game_meta.gameSettingConfig.lineupUnlockLevel or 43) then
					cell:getChildByTag(TAG_FLAG_FIR):setVisible(false)
					cell:getChildByTag(TAG_FLAG_SEC):setVisible(false)
					cell:getChildByTag(TAG_FLAG_THD):setVisible(false)
				else
					cell:getChildByTag(TAG_FLAG_FIR):getChildByTag(TAG_FLAG_FIR):setVisible(true)
					cell:getChildByTag(TAG_FLAG_SEC):getChildByTag(TAG_FLAG_SEC):setVisible(true)
					cell:getChildByTag(TAG_FLAG_THD):getChildByTag(TAG_FLAG_THD):setVisible(true)
					if not queueCardList[cardInfo.cardId] then
						cell:getChildByTag(TAG_FLAG_FIR):getChildByTag(TAG_FLAG_FIR):setVisible(false)
						cell:getChildByTag(TAG_FLAG_SEC):getChildByTag(TAG_FLAG_SEC):setVisible(false)
						cell:getChildByTag(TAG_FLAG_THD):getChildByTag(TAG_FLAG_THD):setVisible(false)
					else
						if BitOperManager:_and(queueCardList[cardInfo.cardId],1,3) == 0 then 
							cell:getChildByTag(TAG_FLAG_FIR):getChildByTag(TAG_FLAG_FIR):setVisible(false)
						end
						if BitOperManager:_and(queueCardList[cardInfo.cardId],2,3) == 0 then 
							cell:getChildByTag(TAG_FLAG_SEC):getChildByTag(TAG_FLAG_SEC):setVisible(false)
						end
						if BitOperManager:_and(queueCardList[cardInfo.cardId],4,3) == 0 then 
							cell:getChildByTag(TAG_FLAG_THD):getChildByTag(TAG_FLAG_THD):setVisible(false)
						end
					end
				end
				--end by l1ghtsaber

				if cardInfo.isInBattle or cardInfo.isInMatrix then  --显示装备和上阵 
					setNodeVisibleByTag(cell, TAG_TXT_CHALLENGE, true)
					setNodeVisibleByTag(cell, TAG_ICON_CHALLENGE, true)
					setNodeVisibleByTag(cell, TAG_ICON_CHECKBOX_BG, false)
					if cardInfo.isInBattle then
						setTextByTag(cell, TAG_TXT_CHALLENGE, getTextByKey("bag_CardInBattle"))
					else
						setTextByTag(cell, TAG_TXT_CHALLENGE, getTextByKey("matrix_cardOnMatrix_remind"))
					end
				else
					setNodeVisibleByTag(cell, TAG_TXT_CHALLENGE, false)
					setNodeVisibleByTag(cell, TAG_ICON_CHALLENGE, false)
				end
				
				for quality = 1, 7
				do
					setNodeVisibleByTag(cell, TAG_ICON_WHITE + quality - 1, quality == cardInfo.rare)
				end
				
				setNodeVisibleByTag(cell, TAG_BTN_TRAIN, false)
				setNodeVisibleByTag(cell, TAG_TXT_POTENTIALPOINT, false)
				if BackpackUIStatus == BACKPACK_STATUS.NORMAL and SELF.argv and SELF.argv.params and SELF.argv.params.isCardTrain then
					setNodeVisibleByTag(cell, TAG_BTN_TRAIN, true)
					setNodeVisibleByTag(cell, TAG_TXT_POTENTIALPOINT, true)
					setNodeVisibleByTag(cell, TAG_TXT_LEADERSHIP_NUM2, true)
					setTextByTag(cell, TAG_TXT_LEADERSHIP_NUM2, tostring(cardInfo.potential))
					setNodeVisibleByTag(cell, TAG_TXT_LEADERSHIPTXT, false)
					setNodeVisibleByTag(cell, TAG_TXT_LEADERSHIP_NUM, false)
				end
			end
		elseif tableViewType == BAGCATEGORY.item then
			if SELF[data][index + 1] then
				
				local itemInfo = SELF[data][index + 1]
				local itemMeta = MetaManager.prop_meta[itemInfo.metaId]
				setNodeVisibleByTag(cell, TAG_TXT_CANNOTSELL, false)

				--设置使用按钮上的文字 by zheng.che
				setTextByTag(cell, TAG_ICON_USEITEM, BackpackScene.getItemUseBtnStr(itemInfo.metaId, false))

				setNodeVisibleByTag(cell, TAG_ICON_USEITEM, false)
				if BackpackUIStatus == BACKPACK_STATUS.CHECKBOX then
					setNodeVisibleByTag(cell, TAG_ICON_CHECKBOX_BG, true)
					setNodeVisibleByTag(cell, TAG_ICON_SELLCOIN, true)
					setNodeVisibleByTag(cell, TAG_TXT_SELLCOIN, true)
					setNodeVisibleByTag(cell, TAG_TXT_CANNOTSELL, true)
					setTextByTag(cell, TAG_TXT_SELLCOIN, itemInfo.price * itemInfo.amount)
					local selected = false;
					for k,v in pairs(idsToSell)
					do
						if v.metaId == itemInfo.metaId then
							selected = true;
							break;
						end
					end
					setNodeVisibleByTag(cell, TAG_ICON_CHECKBOX, selected)
					setNodeVisibleByTag(cell, TAG_ICON_SELECTED, selected)
				else
					setNodeVisibleByTag(cell, TAG_ICON_SELLCOIN, false)
					setNodeVisibleByTag(cell, TAG_TXT_SELLCOIN, false)
					setNodeVisibleByTag(cell, TAG_ICON_CHECKBOX_BG, false)
					setNodeVisibleByTag(cell, TAG_ICON_SELECTED, false)
					setNodeVisibleByTag(cell, TAG_ICON_CHECKBOX, false)
					if BackpackUIStatus == BACKPACK_STATUS.NORMAL and itemMeta.cate == 1 then
						setNodeVisibleByTag(cell, TAG_ICON_USEITEM, true)
					end
				end
				local itemPosX, itemPosY = cell:getChildByTag(TAG_PIC):getPosition()
				local zOrder = cell:getChildByTag(TAG_PIC):getZOrder()
				if cell:getChildByTag(TAG_CARD_HEAD) then
					cell:removeChildByTag(TAG_CARD_HEAD, true)
				end
				
				if not self.releaseTable.canonItem then
					self.releaseTable.canonItem = {}
				end
				if self.releaseTable.canonItem[index] then
					releaseAll(self.releaseTable.canonItem[index])
				end
				self.releaseTable.canonItem[index] = nil;
				
				self.releaseTable.canonItem[index] = CanonItem:create()
                self.releaseTable.canonItem[index]:loadByMetaId(itemInfo.metaId)
				self.releaseTable.canonItem[index]:setPosition(ccp(itemPosX, itemPosY))
				self.releaseTable.canonItem[index]:setTag(TAG_CARD_HEAD)
				self.releaseTable.canonItem[index]:setScale(0.9) --add by l1ghtsaber
				cell:addChild(self.releaseTable.canonItem[index].refCocosObj, zOrder)
				setTextByTag(cell, TAG_TXT_ITEM_AMOUNT, "x" .. itemInfo.amount)
				setTextByTag(cell, TAG_TXT_ITEM_DESC, getTextByKey(itemMeta.desc))
				setTextByTag(cell, TAG_TXT_ITEM_NAME, getTextByKey(itemMeta.name))
				local textNode = cell:getChildByTag(TAG_TXT_ITEM_NAME):getChildByTag(TAG_TXT_ITEM_NAME)
				
				local width = 76
				if type(textNode.getContentSize) == "function" then
					width = textNode:getContentSize().width - width
				end
				
				local textNumNode = cell:getChildByTag(TAG_TXT_ITEM_AMOUNT):getChildByTag(TAG_TXT_ITEM_AMOUNT)
				
				local posX, posY = textNode:getPosition()
				textNumNode:setPosition(ccp(posX + width, posY))
				
				if not itemInfo.canSell then
					setNodeVisibleByTag(cell, TAG_ICON_CHECKBOX_BG, false)
					setNodeVisibleByTag(cell, TAG_ICON_SELLCOIN, false)
					setNodeVisibleByTag(cell, TAG_TXT_SELLCOIN, false)
				else
					setNodeVisibleByTag(cell, TAG_TXT_CANNOTSELL, false)
				end
				
				for quality = 1, 7
				do
					setNodeVisibleByTag(cell, TAG_ICON_WHITE + quality - 1, quality == itemInfo.quality)
				end
			end
		elseif tableViewType == BAGCATEGORY.equip then
			if SELF[data][index + 1] then
				local itemInfo = SELF[data][index + 1]
				local itemMeta = MetaManager.equip_meta[itemInfo.metaId]
				local maxEquipLevel = 1
				for k,v in pairs(MetaManager.equip_evolve_level)
				do
					if itemMeta.evolveLevel == v.evolveLevel then
						maxEquipLevel = v.levelMax
						break;
					end
				end
				local maxEvolveLevel = itemMeta.maxEvolveLevel

				--ENCHANT_MODIFY
				--显示附灵等级
				--显示附灵等级
				if itemInfo.enchantLevel > 0 then
					--有附灵等级
					cell:getChildByTag(TAG_TXT_ENCHANT_STR):setVisible(true)
					cell:getChildByTag(TAG_TXT_ENCHANT_NUM):setVisible(true)
					setNodeText(cell:getChildByTag(TAG_TXT_ENCHANT_NUM):getChildByTag(-11), EnchantUtils.getEnchantLevelStr(itemInfo.enchantLevel))--+[附灵等级]
				else
					cell:getChildByTag(TAG_TXT_ENCHANT_STR):setVisible(false)
					cell:getChildByTag(TAG_TXT_ENCHANT_NUM):setVisible(false)
				end
				--显示属性加成
				local attrInfos = EquipUtils.findFirstAttrs(itemInfo.metaId, itemInfo.level, itemInfo.enchantLevel)
				for i = 1, (ConstManager.HEAD_ATTR_COUNT) do
					local enchantDisplay = cell:getChildByTag(TAG_TXT_ATTR1 + (i-1))
					if enchantDisplay then
						local attrInfo = attrInfos[i]
						if attrInfo then
							--有附加属性
							enchantDisplay:setVisible(true)
							if i == 1 then
								--普通属性
								EnchantUtils.setAttrShowAsTag(enchantDisplay, attrInfo.id, math.floor(attrInfo.num), 1)
							else
								EnchantUtils.setAttrShowAsTag(enchantDisplay, attrInfo.id, math.floor(attrInfo.num), 2)
							end
						else
							--无附加属性
							enchantDisplay:setVisible(false)
						end
					end
				end

				setNodeVisibleByTag(cell, TAG_ICON_STRENGTHEN, false)
				setNodeVisibleByTag(cell, TAG_ICON_EVOLVE, false)
				setNodeVisibleByTag(cell, TAG_TXT_EQUIPED, tonumber(itemInfo.cardId) > 0)
				if BackpackUIStatus == BACKPACK_STATUS.CHECKBOX then
					setNodeVisibleByTag(cell, TAG_ICON_CHECKBOX_BG, true)
					setNodeVisibleByTag(cell, TAG_ICON_SELLCOIN, true)
					setNodeVisibleByTag(cell, TAG_TXT_SELLCOIN, true)
					setNodeVisibleByTag(cell, TAG_TXT_EQUIPED, false)
					setTextByTag(cell, TAG_TXT_SELLCOIN, math.floor(itemInfo.price))
					local selected = false;
					for k,v in pairs(idsToSell)
					do
						if v == itemInfo.equipId then
							selected = true;
							break;
						end
					end
					setNodeVisibleByTag(cell, TAG_ICON_CHECKBOX, selected)
					setNodeVisibleByTag(cell, TAG_ICON_SELECTED, selected)
				else
					setNodeVisibleByTag(cell, TAG_ICON_CHECKBOX_BG, false)
					setNodeVisibleByTag(cell, TAG_ICON_SELLCOIN, false)
					setNodeVisibleByTag(cell, TAG_TXT_SELLCOIN, false)
					setNodeVisibleByTag(cell, TAG_ICON_CHECKBOX, false)
					setNodeVisibleByTag(cell, TAG_ICON_SELECTED, false)
					if BackpackUIStatus == BACKPACK_STATUS.NORMAL then
						if itemInfo.level < maxEquipLevel then
							setNodeVisibleByTag(cell, TAG_ICON_STRENGTHEN, true)
						elseif itemMeta.evolveLevel < maxEvolveLevel then
							setNodeVisibleByTag(cell, TAG_ICON_EVOLVE, true)
						end
					end
				end
				local itemPosX, itemPosY = cell:getChildByTag(TAG_PIC):getPosition()
				local zOrder = cell:getChildByTag(TAG_PIC):getZOrder()
				if cell:getChildByTag(TAG_CARD_HEAD) then
					cell:removeChildByTag(TAG_CARD_HEAD, true)
				end
				if not self.releaseTable.canonItem then
					self.releaseTable.canonItem = {}
				end
				if self.releaseTable.canonItem[index] then
					releaseAll(self.releaseTable.canonItem[index])
				end
				self.releaseTable.canonItem[index] = nil;
				
				self.releaseTable.canonItem[index] = CanonItem:create()
                self.releaseTable.canonItem[index]:loadByMetaId(itemInfo.metaId)
				self.releaseTable.canonItem[index]:setPosition(ccp(itemPosX, itemPosY))
				self.releaseTable.canonItem[index]:setTag(TAG_CARD_HEAD)
				self.releaseTable.canonItem[index] = CanonItem:create()
                self.releaseTable.canonItem[index]:loadByMetaId(itemInfo.metaId)
				self.releaseTable.canonItem[index]:setPosition(ccp(itemPosX, itemPosY))
				self.releaseTable.canonItem[index]:setTag(TAG_CARD_HEAD)
				self.releaseTable.canonItem[index]:setScale(0.9)
				cell:addChild(self.releaseTable.canonItem[index].refCocosObj, zOrder)
				setTextByTag(cell, TAG_TXT_EQUIPNAME, getTextByKey(itemMeta.name), true)
				--ENCHANT_MODIFY 去掉原装备属性数值
				-- local equipType
				-- local spriteName
				-- local attriNum
				-- if itemMeta.position == 1  then
				-- 	equipType = "Atk"
				-- 	spriteName = "#package_new/package_icon_atk_sb0000"
				-- 	attriNum = itemMeta.basicAtk + itemMeta.atkSCoe * MetaManager.equip_level[itemInfo.level].atk
				-- elseif itemMeta.position == 2 then
				-- 	equipType = "Defense"
				-- 	spriteName = "#package_new/package_icon_def_sb0000"
				-- 	attriNum = itemMeta.basicDefence + itemMeta.defSCoe * MetaManager.equip_level[itemInfo.level].def
				-- else
				-- 	equipType = "Hp"
				-- 	spriteName = "#package_new/package_icon_hp_sb0000"
				-- 	attriNum = itemMeta.basicHp + itemMeta.hpSCoe * MetaManager.equip_level[itemInfo.level].hp
				-- end
				-- setTextByTag(cell, TAG_TXT_EQUIPINFO, "" .. math.floor(attriNum))
				setTextByTag(cell, TAG_TXT_EQUIPLV, "" .. itemInfo.level .. "/" .. maxEquipLevel)
				
				setNodeVisibleByTag(cell, TAG_TXT_CHALLENGE, tonumber(itemInfo.cardId) > 0)
				setNodeVisibleByTag(cell, TAG_ICON_CHALLENGE, tonumber(itemInfo.cardId) > 0)
				
				if cell:getChildByTag(TAG_EQUP_ATTRI) then
					cell:removeChildByTag(TAG_EQUP_ATTRI, true)
				end
				--ENCHANT_MODIFY 去掉原装备属性数值
				-- local attriPosX,attriPosY = cell:getChildByTag(TAG_ICON_EQUIPINFO):getPosition()
				-- local zOrder = cell:getChildByTag(TAG_ICON_EQUIPINFO):getZOrder()
				
				-- if not self.releaseTable.attriSprite then
				-- 	self.releaseTable.attriSprite = {}
				-- end
				-- if self.releaseTable.attriSprite[index] then
				-- 	releaseAll(self.releaseTable.attriSprite[index])
				-- end
				-- self.releaseTable.attriSprite[index] = nil;
				
				-- self.releaseTable.attriSprite[index] = Sprite:create(spriteName)
				-- self.releaseTable.attriSprite[index]:setPosition(ccp(attriPosX, attriPosY))
				-- self.releaseTable.attriSprite[index].refCocosObj:setAnchorPoint(ccp(0, 1))
				-- self.releaseTable.attriSprite[index]:setTag(TAG_EQUP_ATTRI)
				-- cell:addChild(self.releaseTable.attriSprite[index].refCocosObj, zOrder);
				
				local cardName
				if itemInfo.cardId > 0 then
					for k,v in pairs(DataManager.getCardsData())
					do
						if v.cardId == itemInfo.cardId then
							cardName = getTextByKey(MetaManager.card_meta[v.metaId].name)
							break;
						end
					end
				end
				
				if cardName then
					setTextByTag(cell, TAG_TXT_EQUIPED, Localization:getInstance():getText("bag_EquippedText", {cardname = cardName}), true)
					setNodeVisibleByTag(cell, TAG_ICON_CHECKBOX, false)
					setNodeVisibleByTag(cell, TAG_ICON_CHECKBOX_BG, false)
					setNodeVisibleByTag(cell, TAG_ICON_SELECTED, false)
				end
				
				--[[for i = 1, MAXRARE
				do
					if cell:getChildByTag(TAG_FIRST_STAR + i - 1) then
						cell:removeChildByTag(TAG_FIRST_STAR+i - 1, true)
					end
				end
				
				if not self.releaseTable.starSprite then
					self.releaseTable.starSprite = {}
				end
				if self.releaseTable.starSprite[index] then
					releaseAll(self.releaseTable.starSprite[index])
				end
				self.releaseTable.starSprite[index] = {}
				for i = 1, itemInfo.quality
				do
					self.releaseTable.starSprite[index][i] = Sprite:create(UI_RES_PATH.."/package_new/package_icon_star_sb.png")
					self.releaseTable.starSprite[index][i]:setAnchorPoint(ccp(0, 1))
					self.releaseTable.starSprite[index][i]:setPosition(ccp(firstStarPosX - starPixielX * (i - 1), firstStarPosY))
					cell:addChild(self.releaseTable.starSprite[index][i].refCocosObj, 1000, TAG_FIRST_STAR - 1 + i)
				end--]]

				--显示多阵容装备状态
				if DataManager.getGameInitData().sharkUser.level < (MetaManager.game_meta.gameSettingConfig.lineupUnlockLevel or 43) then
					cell:getChildByTag(TAG_FLAG_FIR):setVisible(false)
					cell:getChildByTag(TAG_FLAG_SEC):setVisible(false)
					cell:getChildByTag(TAG_FLAG_THD):setVisible(false)
				else
				cell:getChildByTag(TAG_FLAG_FIR):getChildByTag(TAG_FLAG_FIR):setVisible(true)
				cell:getChildByTag(TAG_FLAG_SEC):getChildByTag(TAG_FLAG_SEC):setVisible(true)
				cell:getChildByTag(TAG_FLAG_THD):getChildByTag(TAG_FLAG_THD):setVisible(true)
					if not queueEquipList[itemInfo.equipId] then
						cell:getChildByTag(TAG_FLAG_FIR):getChildByTag(TAG_FLAG_FIR):setVisible(false)
						cell:getChildByTag(TAG_FLAG_SEC):getChildByTag(TAG_FLAG_SEC):setVisible(false)
						cell:getChildByTag(TAG_FLAG_THD):getChildByTag(TAG_FLAG_THD):setVisible(false)
					else
						if BitOperManager:_and(queueEquipList[itemInfo.equipId],1) == 0 then 
							cell:getChildByTag(TAG_FLAG_FIR):getChildByTag(TAG_FLAG_FIR):setVisible(false)
						end
						if BitOperManager:_and(queueEquipList[itemInfo.equipId],2) == 0 then 
							cell:getChildByTag(TAG_FLAG_SEC):getChildByTag(TAG_FLAG_SEC):setVisible(false)
						end
						if BitOperManager:_and(queueEquipList[itemInfo.equipId],4) == 0 then 
							cell:getChildByTag(TAG_FLAG_THD):getChildByTag(TAG_FLAG_THD):setVisible(false)
						end
					end
				end
				--end by l1ghtsaber
				
				for i = 1, 7
				do
					setNodeVisibleByTag(cell, TAG_FIRST_STAR - 1 + i, i <= itemInfo.quality)
				end
				
				for quality = 1, 7
				do
					setNodeVisibleByTag(cell, TAG_ICON_WHITE + quality - 1, quality == itemInfo.quality)
				end
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
		if SELF.sellMenu and SELF.sellMenu:isVisible() and evt.globalPosition.y < 212 then
			do return end
		end
		local selectedCell = SELF.tableUI:cellAtIndex(evt.data):getChildByTag(-1001)
		SELF._data = SELF[data][evt.data + 1]
		SELF.dataIndex = evt.data + 1
		SELF.dataList = SELF[data]
		user_select.tab = evt.context
		if BackpackUIStatus == BACKPACK_STATUS.CHECKBOX then
			if evt.context == BAGCATEGORY.card then
				if not SELF._data.isInBattle and not SELF._data.isInMatrix then
					local selected = false;
					for k,v in pairs(idsToSell)
					do
						if v == SELF._data.cardId then
							selected = true;
							table.remove(idsToSell, k)
							SELF.sellPrice = SELF.sellPrice - SELF._data.price
							break;
						end
					end
					if not selected then
						if #idsToSell >= SELF.limitSelectNum then
							SuspensionLabel:showContent(SELF, getTextByKey("cardEnhance_CannotSelectMore"))
							return
						end
						table.insert(idsToSell, SELF._data.cardId)
						SELF.sellPrice = SELF.sellPrice + SELF._data.price
					end
					setNodeVisibleByTag(selectedCell, TAG_ICON_CHECKBOX, not selected)
					setNodeVisibleByTag(selectedCell, TAG_ICON_SELECTED, not selected)
					
					if SELF.argv.enterScene then
						if #idsToSell > 0 then
							SELF.mainUI:getChildByName("btn_inventory_R"):getChildByName("txt_bag_SellBtn"):setString(getTextByKey("yes"))
						else
							SELF.mainUI:getChildByName("btn_inventory_R"):getChildByName("txt_bag_SellBtn"):setString(getTextByKey("cancel"))
						end
					else
						SELF:setSellMenuVisible(#idsToSell > 0)
					end
				end
			elseif evt.context == BAGCATEGORY.item then
				if SELF._data.canSell then
					local selected = false
					for k,v in pairs(idsToSell)
					do
						if v.metaId == SELF._data.metaId then
							selected = true;
							table.remove(idsToSell, k)
							SELF.sellPrice = SELF.sellPrice - SELF._data.price * SELF._data.amount
							break;
						end
					end
					if not selected then
						table.insert(idsToSell, {metaId = SELF._data.metaId, amount = SELF._data.amount})
						SELF.sellPrice = SELF.sellPrice + SELF._data.price * SELF._data.amount
					end
					setNodeVisibleByTag(selectedCell, TAG_ICON_CHECKBOX, not selected)
					setNodeVisibleByTag(selectedCell, TAG_ICON_SELECTED, not selected)
					
					SELF:setSellMenuVisible(#idsToSell > 0)
				end
			else
				if SELF._data.cardId <= 0 then
					local selected = false
					for k,v in pairs(idsToSell)
					do
						if v == SELF._data.equipId then
							selected = true;
							table.remove(idsToSell, k)
							SELF.sellPrice = SELF.sellPrice - SELF._data.price
							break;
						end
					end
					if not selected then
						table.insert(idsToSell, SELF._data.equipId)
						SELF.sellPrice = SELF.sellPrice + SELF._data.price
					end
					setNodeVisibleByTag(selectedCell, TAG_ICON_CHECKBOX, not selected)		
					setNodeVisibleByTag(selectedCell, TAG_ICON_SELECTED, not selected)
					
					SELF:setSellMenuVisible(#idsToSell > 0)
				end
			end
		elseif BackpackUIStatus == BACKPACK_STATUS.OPTION then
			if SELF[argv].enterScene == "MatrixScene" then
				SELF:sendReplaceCardRequest(SELF._data)
			elseif SELF[argv].enterScene == "CardEvolutionScene" then
				if type(SELF.argv.params) == "table" and SELF.argv.params.cardType == "master" and not SELF._data.levelEnough then
					SuspensionLabel:showContent(SELF, Localization:getInstance():getText("cardEvolve_levelTip", {lv = tostring(SELF._data.needLevel)}))
				else
					local params=SELF._data
					local nextReturnScene = nil;
					if SELF.argv.params then
						nextReturnScene = SELF.argv.params.preReturnScene
					end
					local argv = {enterScene="BackpackScene",returnScene=nextReturnScene,params=params}
					argv.params.cardType = SELF.argv.params.cardType
					SELF:replaceScene( CardEvolutionScene , argv)
				end
            end

            if SELF[argv].enterScene == "CardComposeScene"  then
                local params=SELF._data
				local nextReturnScene = nil;
				if SELF.argv.params then
					nextReturnScene = SELF.argv.params.preReturnScene
				end
                local argv = {enterScene="BackpackScene",returnScene=nextReturnScene,params=params}
                argv.params.cardType = SELF.argv.params.cardType
                argv.params.state = SELF.argv.params.state
                SELF:replaceScene(CardComposeScene , argv)
            end

			if SELF[argv].enterScene == "CardRebirthScene"  then
				if SELF.argv.params.selectedTab == 1 and SELF._data.lock then
					SuspensionLabel:showContent(SELF, Localization:getInstance():getText("card_lockedTips_sacrifice"))
				else
					local argv = {enterScene="BackpackScene", params=SELF._data}
                	SELF:replaceScene(CardRebirthScene , argv)
				end
			end

            if SELF[argv].enterScene == "ActivityPanelScene"  then
               	--选择武将返回活动页面
				local nextReturnScene = nil;
				if SELF.argv.params then
					nextReturnScene = SELF.argv.params.preReturnScene
				end
                local argv = {selectPanelName = "Activity_Pray", oriented = true, orientedParams = {cardId = SELF._data.cardId}}
                SELF:replaceScene(ActivityPanelScene , argv)
            end

            if SELF[argv].enterScene == "EquipUpgradeEmptyScene"  then
                local argv = {enterScene="BackpackScene",returnScene="BackpackScene",params=SELF._data}
                SELF:replaceScene( EquipUpgradeScene , argv)
            elseif SELF[argv].enterScene == "EquipEvolveEmptyScene"  then
                local argv = {enterScene="BackpackScene",returnScene="BackpackScene",params=SELF._data}
                SELF:replaceScene( EquipEvolveScene , argv)
            end

			if SELF[argv].enterScene == "CardQueueScene"  then
				if SELF.argv.params.filter==BACKPACK_FILTER.EQUIP then
				--获取要修改的内存数据
					local GameData = DataManager.getGameInitData()
					local cards = DataManager.getCardsData()
					local equips = DataManager.getEquipsData()
						
					local originalCardId = 0
					for _, aEquip in pairs(equips) do
						if (aEquip.equipId == SELF._data.equipId) then
							if (aEquip.cardId ~= 0) then
								originalCardId = aEquip.cardId
							end
							break
						end
					end
						
					local function afterSetupEquip(e)
						SELF.waitRequest = false;
						g_shouldCalc = true;
						local targetCardId = HeMemDataHolder:getInteger("EquipChange_nowCardId")
							
						for _, aEquip in pairs(equips) do
							if (aEquip.equipId == SELF._data.equipId) then
								aEquip.cardId = targetCardId
							end
							if (aEquip.equipId == HeMemDataHolder:getInteger("EquipChange_NowEquipId")) then
								aEquip.cardId = 0
							end
						end

						local aCard,cardKey = CommonManager.getSubTableByKey(
							cards,
							{name = "cardId", value = SELF.argv.params.cardId}
						)
						local originalCard,originalCardKey = CommonManager.getSubTableByKey(
							cards,
							{name = "cardId", value = originalCardId}
						)
							
						local dirtyCardIds = {}
						if originalCard then
							table.insert(dirtyCardIds, originalCard.cardId)
						end
						if aCard then
							table.insert(dirtyCardIds, aCard.cardId)
						end
						CommonManager:setCardNeedUpdate(dirtyCardIds)
													
						--给卡牌穿上装备
						local nowEquipId = HeMemDataHolder:getInteger("EquipChange_NowEquipId")
						local equipKey = 0
						if (nowEquipId ~= 0) and (aCard.equipIds ~= nil) then--[and (aCard.equipIds ~= nil)] 解决小概率因找不到aCard.equipIds而崩溃问题 modified by zheng.che @ 2015-1-4
							if type(aCard.equipIds) == "table" then
								for key, value in pairs(aCard.equipIds) do
									if (value == nowEquipId) then
										equipKey = key
										break
									end
								end
							end
							aCard.equipIds[equipKey] = SELF._data.equipId
						else
							if (not aCard.equipIds) then
								aCard.equipIds = {}
							end
							table.insert(aCard.equipIds, SELF._data.equipId)
						end
													
						GameData.sharkCards.sharkCards[cardKey] = aCard
													
						--需求变动：原卡牌上的装备对应替换，不是直接脱下new
						if (originalCard) then
							for aKey, aEquipId in pairs(originalCard.equipIds) do
								if (aEquipId == SELF._data.equipId) then
									if nowEquipId ~= 0 then
										--换上aCard对应装备
										originalCard.equipIds[aKey] = nowEquipId
									else
										--aCard上原来没有装备，直接脱掉originalCard上对应装备
										table.remove(originalCard.equipIds, aKey)
									end
									break
								end
							end
						end
						GameData.sharkCards.sharkCards[originalCardKey] = originalCard
						
							
						for _, aEquip in pairs(equips) do
							if (aEquip.equipId == SELF._data.equipId) then
								aEquip["cardId"] = aCard.cardId
        --                         if self.argv.params.argvs then
							 --       SELF.argv.params.argvs.params.container.queue[SELF.argv.params.argvs.params.cardPos].equips[SELF.argv.params.argvs.params.EquipPos] = aEquip
							 --       SELF.argv.params.argvs.params.equip = aEquip
								-- end
							end
							if nowEquipId ~= 0 and originalCard and (aEquip.equipId == nowEquipId) then
								aEquip["cardId"] = originalCard.cardId
							end
						end

						--当前阵容（换/上装备）
						if GameData.sharkUser.level >= (MetaManager.game_meta.gameSettingConfig.lineupUnlockLevel or 43) then 
							local BattleArrayId = GameData.sharkUserExtendMore.battleArrayId
							for k,v in pairs(GameData.sharkUserBattleArray[BattleArrayId].sharkUserQueue) do
								if (originalCard) then
									if (originalCard.cardId == v.cardId) then v.equips = originalCard.equipIds end
								end
								if (aCard.cardId == v.cardId) then v.equips = aCard.equipIds end
							end
						end
						--end by l1ghtsaber
                        
						DataManager.setGameInitData(GameData)
						DataManager.setEquipsData(equips)

						
							
						if SELF.argv.returnScene == "CardQueueScene" then
                            if self.argv.params.argvs then
								SELF.argv.params.argvs.enterScene = "CardQueueScene"
							    SELF.argv.params.argvs.returnScene = "CardQueueScene"
							    self:replaceScene( EquipQuickUpgradeScene , self.argv.params.argvs)
						    else
								local argv = {enterScene="BackpackScene",returnScene=(SELF.argv.params and SELF.argv.params.preReturnScene),params=nil}
								SELF:replaceScene( CardQueueScene , argv)
							end
					    else
							local argv = {showStrength = true ,params={isCardTrain = false, tabIndex = BAGCATEGORY.equip}}
							SELF:replaceScene( BackpackScene , argv)
						end
					end
						 
					local function afterSetupEquipFailed(e)
						SELF.waitRequest = false;
						CanonMessageBox:showCommUnHandleErrorBox(e.data)
					end
						
					local function sendRequest()
						if SELF.waitRequest then
							do return end
						end
						g_previousBattleCount = CommonManager:getLocalPlayerStrength()
						local params = {cardId = SELF.argv.params.cardId, equipId = SELF._data.equipId}
						--send request
						local request = SetupEquipRequest.new( params, rpc.SendingPriority.kHigh )
						request:addEventListener( RequestNotifyEnum.SetupEquipSucceed, afterSetupEquip )
						request:addEventListener( RequestNotifyEnum.SetupEquipFailed, afterSetupEquipFailed )
						request:start()
						SELF:setTableViewsEnabled(true)
						SELF.waitRequest = true;
					end
						
					local function cancelChangeRequest()
						SELF:setTableViewsEnabled(true)
					end
						
					if (originalCardId ~= 0) then
						local originalCard = CommonManager.getSubTableByKey(
							cards,
							{name = "cardId", value = originalCardId}
						)
						local equipName = MetaManager.equip_meta[SELF._data.metaId].name
						local cardName = MetaManager.card_meta[originalCard.metaId].name
						SELF:setTableViewsEnabled(false)
						CanonMessageBox:Show(
							Localization:getInstance():getText("equip_EquippedTips", {equipname = getTextByKey(equipName), cardname = getTextByKey(cardName)}),
							ShowMessageType.ShowText,
							ShowButtonType.ID_OK_CANCEL,
							40,
							sendRequest,
							cancelChangeRequest
						)
					else
						sendRequest()
					end
				elseif SELF.argv.params.filter==BACKPACK_FILTER.CARD then
					local cardsData = DataManager.getCardsData()
					local originalCard = nil
					local originalCardKey = 0
					local targetCard,targetCardKey = CommonManager.getSubTableByKey(
						cardsData,
						{name = "cardId", value = SELF._data.cardId}
					)
					if (SELF.argv.params.cardQueue[SELF.argv.params.cardPos]) then
						originalCard,originalCardKey = CommonManager.getSubTableByKey(
							cardsData,
							{name = "cardId", value = SELF.argv.params.cardQueue[SELF.argv.params.cardPos]}
						)
					end
						
					--新武将互换规则
					local originalCardNewPos = 0
					for k,v in pairs(SELF.argv.params.cardQueue) do
						if v == SELF._data.cardId then
							--该武将原来就在阵容中
							originalCardNewPos = k
							break
						end
					end
					
					local nowLeadP,totalLeadP = CalculationManager.calcComplex_getQueueLeaderPoints()
					local tarLP = MetaManager.card_meta[targetCard.metaId].leadPoint
					local orgLP = (originalCard) and MetaManager.card_meta[originalCard.metaId].leadPoint or 0
					if originalCardNewPos ~= 0 and originalCard then
						--两个卡都在队伍中 不用重新计算统御力
					else
						if (nowLeadP-orgLP+tarLP > totalLeadP) then
							local aContent = Localization:getInstance():getText("formation_leadershipInsufficient")
							SuspensionLabel:showContent(SELF, aContent)
							return
						end
					end
					--
					SELF.argv.params.cardQueue[SELF.argv.params.cardPos] = nil
					SELF.argv.params.cardQueue[SELF.argv.params.cardPos] = SELF._data.cardId
					
					if originalCardNewPos ~= 0 and originalCard then
						SELF.argv.params.cardQueue[originalCardNewPos] = originalCard.cardId
					end
					
					--build the new formation table
					local mainCardId = SELF.argv.params.cardQueue[1]
					local additionalCardIds = {}
					local additionalCardIdStr = ""
					
					for key,value in pairs(SELF.argv.params.cardQueue) do
						if (key~=1) then
							table.insert(additionalCardIds, value)
							additionalCardIdStr = additionalCardIdStr .. "," .. value
						end
					end
					--build the new formation string and params
					additionalCardIdStr = string.sub(additionalCardIdStr, 2, -1)
					local params = {mainCardId = mainCardId, additionalCardIds = additionalCardIds}

					local function afterReplaceCard(e)
						g_shouldCalc = true
						SELF.waitRequest = false;
						--refresh game data
						local gameData = DataManager.getGameInitData()

						gameData["sharkUser"]["mainCardId"] = params.mainCardId
						gameData["sharkUser"]["additionalCardIds"] = additionalCardIdStr
						
						--refresh equip data
						--替换为上阵武将
						local equipsData = DataManager.getEquipsData()
						if (originalCard) and originalCardNewPos == 0 then
							if (originalCard.equipIds) then
								local equipIds = originalCard.equipIds
								cardsData[originalCardKey].equipIds = nil
								cardsData[targetCardKey].equipIds = equipIds
								for _, aEquipId in pairs(equipIds) do
									local _,aEquipKey = CommonManager.getSubTableByKey(
										equipsData,
										{name = "equipId", value = aEquipId}
									)
									equipsData[aEquipKey].cardId = targetCard.cardId
								end
							end
						end

						local spiritsData = DataManager.getSpiritsData()
						if (originalCard) and originalCardNewPos == 0 then
							if (originalCard.cardSpirits) then
								local cardSpirits = originalCard.cardSpirits
								cardsData[originalCardKey].cardSpirits = nil
								cardsData[targetCardKey].cardSpirits = cardSpirits
								for _, aEquipId in pairs(cardSpirits) do
									local _,aEquipKey = CommonManager.getSubTableByKey(
										spiritsData,
										{name = "spiritId", value = aEquipId.spiritId}
									)
									spiritsData[aEquipKey].cardId = targetCard.cardId
								end
							end
						end

						local treasureData = DataManager.getTreasuresData()
						if (originalCard) and originalCardNewPos == 0 then
							if (originalCard.treasureId ~= 0) then
								local cardTreasureId = originalCard.treasureId
								cardsData[originalCardKey].treasureId = 0
								cardsData[targetCardKey].treasureId = cardTreasureId
								for k,v in pairs(treasureData) do
									if v.treasureId == cardTreasureId then
										v.cardId = targetCard.cardId
										break
									end
								end
							end
						end

						--当前阵容（换/上阵容武将）
						if gameData.sharkUser.level >= (MetaManager.game_meta.gameSettingConfig.lineupUnlockLevel or 43) then 
							local BattleArrayId = gameData.sharkUserExtendMore.battleArrayId
							if (originalCard) then
								for k,v in pairs(gameData.sharkUserBattleArray[BattleArrayId].sharkUserQueue) do
									if (originalCard.cardId == v.cardId) then 
										v.cardId = targetCard.cardId 
										v.equips = targetCard.equipIds -- 装备跟武将走
										v.spirits = targetCard.cardSpirits -- 元神跟武将走
										v.treasureId = targetCard.treasureId -- 
									elseif (targetCard.cardId == v.cardId) then 
										v.cardId = originalCard.cardId 
										v.equips = originalCard.equipIds -- 装备跟武将走
										v.spirits = originalCard.cardSpirits -- 元神跟武将走
										v.treasureId = originalCard.treasureId
									end
								end
							else --上武将的情况
								local params = {cardId = targetCard.cardId,equips = {},spirits = {},treasureId = 0}
								table.insert(gameData.sharkUserBattleArray[BattleArrayId].sharkUserQueue,params)
							end
						end
						--end by l1ghtsaber
						
						

						gameData.sharkCards.sharkCards = cardsData
						gameData.sharkEquips.sharkEquips = equipsData
						gameData.sharkSpirits.sharkSpirits = spiritsData
						gameData.sharkTreasures.sharkTreasures = treasureData
						DataManager.setGameInitData(gameData)
							
						local dirtyCardIds = {}
						if originalCard then
							table.insert(dirtyCardIds, originalCard.cardId)
						end
						CommonManager:setCardNeedUpdate(dirtyCardIds)
						CommonManager:updateEffectQueueStatus()

						--换卡牌的时候重新算队伍中的国家数量
						g_cardCountryNumCache.needUpdate = true
						
						--在阵型中交换
						if e.data.type == 1 then
						    local sharkMatricesData = DataManager.getSharkMatricesData()
						    local tosetMatrix
							for k, data in pairs(sharkMatricesData) do
								--zhehua
								if data.matrixId == 10 then
									tosetMatrix = data
									break;
								end
							end
							if tosetMatrix then
							    local tosetGrid
							    for k, data in pairs(tosetMatrix.sharkMatrixGrids) do
							    	if data.cardId == targetCard.cardId then
							    		tosetGrid = data
							    		break;
							    	end
							    end
							    if tosetGrid then
							    	tosetGrid.cardId = originalCard.cardId
							    	DataManager.setSharkMatricesData(sharkMatricesData)
									--当前阵容（换阵容武将时换到阵法里的）
									if DataManager.getGameInitData().sharkUser.level >= (MetaManager.game_meta.gameSettingConfig.lineupUnlockLevel or 43) then 
										local gameData = DataManager.getGameInitData()
										local BattleArrayId = gameData.sharkUserExtendMore.battleArrayId									
										gameData.sharkUserBattleArray[BattleArrayId].sharkMatrices.sharkMatrices = sharkMatricesData
										DataManager.setGameInitData(gameData)
									end
									--end by l1ghtsaber
							    end
							end
						end
						--zhehua

						local argv = {enterScene="BackpackScene",returnScene=(SELF.argv.params and SELF.argv.params.preReturnScene),params={insertCardId = SELF._data.cardId}}
						SELF:replaceScene( CardQueueScene , argv)
					end
					
					local function ReplaceCardFailed(e)
						SELF.waitRequest = false;
						if e.data == 710203 then
						    local aContent = Localization:getInstance():getText("formation_leadershipInsufficient")
							SuspensionLabel:showContent(SELF, aContent)
						else
							CanonMessageBox:showCommUnHandleErrorBox(e.data)
						end
						--CCMessageBox("That card is already in the team!","Warning!")
						--local argv = {enterScene="BackpackScene",returnScene=(SELF.argv.params and SELF.argv.params.preReturnScene),params={insertCardId = SELF._data.cardId}}
						--SELF:replaceScene( CardQueueScene , argv)
					end
						
					if SELF.waitRequest then
						do return end
					end
					--send request
					local request = ReplaceCardRequest.new( params, rpc.SendingPriority.kHigh )
					request:addEventListener( RequestNotifyEnum.ReplaceCardSucceed, afterReplaceCard )
					request:addEventListener( RequestNotifyEnum.ReplaceCardFailed, ReplaceCardFailed )
					request:start()
					SELF.waitRequest = true
				end
			end
		elseif BackpackUIStatus==BACKPACK_STATUS.NORMAL then
			local showUnsavedPanel
			if evt.context == BAGCATEGORY.card then
				local posInCell = selectedCell:convertToNodeSpace(evt.globalPosition)
				local itemPosX, itemPosY = selectedCell:getChildByTag(TAG_BTN_TRAIN):getPosition()
				local itemRect = {}
				itemRect.x = itemPosX
				itemRect.y = itemPosY - 66
				itemRect.width = 168
				itemRect.height = 66
				if inArea(posInCell.x, posInCell.y, itemRect) and SELF.argv and SELF.argv.params and SELF.argv.params.isCardTrain then
					CommonManager:setCardNeedUpdate({SELF._data.cardId})
					SELF:replaceScene(CardTrainingScene, {params={card=SELF._data}})
					do return end
				else
					local unsavedCardId = CardTrainingScene.getUnsavedCardId()
					local aPanel
					if unsavedCardId then
						for k, v in pairs(SELF[data]) do
							if v.cardId == unsavedCardId then
								SELF._data = v
								SELF.dataIndex = k
								break
							end
						end
						aPanel = CardInfoNewPanel:create( self, true , evt.data + 1, {tabType = tabTypeEnum.cultivate, forceClose = true})
						showUnsavedPanel = function()
							local aScene = Director.sharedDirector():getRunningScene()
							local aPanel = AssistantMessageBoxPanel:create( aScene, AsMessageBoxType.notFinished )
						    aScene:addChild(aPanel)
						    aPanel:scaleIn()
						end
					else
						aPanel = CardInfoNewPanel:create( SELF , true , evt.data + 1)
					end

					SELF.targetInfoPanel = aPanel
				end
      		elseif evt.context == BAGCATEGORY.equip then
				local posInCell = selectedCell:convertToNodeSpace(evt.globalPosition)
				local itemPosX, itemPosY = selectedCell:getChildByTag(TAG_ICON_STRENGTHEN):getPosition()
				local itemRect = {}
				itemRect.x = itemPosX
				itemRect.y = itemPosY - 66
				itemRect.width = 168
				itemRect.height = 66
				if inArea(posInCell.x, posInCell.y, itemRect) then
					if selectedCell:getChildByTag(TAG_ICON_EVOLVE) and selectedCell:getChildByTag(TAG_ICON_EVOLVE):isVisible() then
						local argv = {
								enterScene = "BackpackScene",
								returnScene = "BackpackScene",
								params = SELF._data
						}
						SELF:replaceScene( EquipEvolveScene, argv ) 
						do return end
					elseif selectedCell:getChildByTag(TAG_ICON_STRENGTHEN) and selectedCell:getChildByTag(TAG_ICON_STRENGTHEN):isVisible() then
						local argv = {
								enterScene = "BackpackScene",
								returnScene = "BackpackScene",
								params = SELF._data
						}
						
						if SELF._data.level >= DataManager.getCurrUser().level then
							SuspensionLabel:showContent(SELF, getTextByKey("equip_LevelMaxText"))
						else
							SELF:replaceScene( EquipUpgradeScene, argv ) 
						end
						do return end
					end
				end
				-- ENCHANT_MODIFY
				-- 改用新的装备详情界面 modified by zheng.che @ 2014-12-5
                --SELF.targetInfoPanel = EquipInfoPanel:create( SELF , "BackpackScene" , evt.data + 1)
                SELF.targetInfoPanel = EquipInfoNewPanel:create( SELF._data , {enterScene="BackpackScene",returnScene="BackpackScene" , params = {index = evt.data + 1}})
            elseif evt.context == BAGCATEGORY.item then
				local posInCell = selectedCell:convertToNodeSpace(evt.globalPosition)
				local itemPosX, itemPosY = selectedCell:getChildByTag(TAG_ICON_USEITEM):getPosition()
				local itemRect = {}
				itemRect.x = itemPosX
				itemRect.y = itemPosY - 66
				itemRect.width = 168
				itemRect.height = 66
				if inArea(posInCell.x, posInCell.y, itemRect) then
					if selectedCell:getChildByTag(TAG_ICON_USEITEM) and selectedCell:getChildByTag(TAG_ICON_USEITEM):isVisible() then
						if SELF.waitRequest then
							do return end
						end

						if SELF._data.metaId == MetaManager.game_meta.gameSettingConfig.renamePropId then
							local renameNextTime , timeRemain = CalculationManager.calcComplex_getRenameCoolingTime()
						    if timeRemain <= 0 then
						    	SELF.targetInfoPanel = ReNameInputPanel:create( SELF )
						    	PopoutManager:sharedManager():popout(SELF.targetInfoPanel, kPopoutDir.kScale, true, false ,SELF) 
						    else
						    	SELF.targetInfoPanel = ReNameCoolingPanel:create( SELF )
						    	PopoutManager:sharedManager():popout(SELF.targetInfoPanel, kPopoutDir.kScale, true, false ,SELF) 
						    end
							return
						end

						--使用个数
						local openNum = BackpackScene.ItemCanOpenNum(SELF._data.metaId)
						local function usePropResponse( e )
							onGeneralUsePropResponse(e, SELF._data, SELF[data], SELF, SELF.dataIndex, openNum, nil)

						end
						
						local function usePropFailed(e)
							onGeneralUsePropFailed(e, SELF._data, SELF)

						end
						
						requestUsePropRequest(SELF._data, SELF[data], usePropResponse, usePropFailed, SELF, openNum, nil)
						--SELF.waitRequest = true;
						do return end
					end
				end
                SELF.targetInfoPanel = PropInfoPanel:create( SELF ,nil , evt.data + 1)
            end 
			PopoutManager:sharedManager():popout(SELF.targetInfoPanel, kPopoutDir.kScale, true, false ,SELF, nil, showUnsavedPanel) 
		end
	end
	
	local cellTag = -1001
    local buttonTag = {}
	if tableViewType == BAGCATEGORY.item then
		table.insert(buttonTag, TAG_ICON_USEITEM)
	elseif tableViewType == BAGCATEGORY.equip then
		table.insert(buttonTag, TAG_ICON_EVOLVE)
		table.insert(buttonTag, TAG_ICON_STRENGTHEN)
	else
		table.insert(buttonTag, TAG_BTN_TRAIN)
	end
	
	local cell_height = 206  --（原版185)
    local renderer = BackPackRenderer.new(BAGCONFIG.WIDTH, cell_height)
	local addY = 50
    local list = TableView:create(renderer, BAGCONFIG.WIDTH, BAGCONFIG.HEIGHT - 80 + addY, cellTag, buttonTag, CCScale9Sprite:create( CCRectMake(0,0,0,0), "pic/scroll.png"), CCScale9Sprite:create( CCRectMake(0,0,0,0), "pic/scroll.png"), SELF[data])

    list:addEventListener(DisplayEvents.kTouchItem, onListItemTouch , tableViewType)
    list:setPosition(ccp(0, (1280-BAGCONFIG.HEIGHT)/2-35 - addY))
    return list
end

function BackpackScene:setTableViewsEnabled( v )
	if (v) then
		SELF.touchDisableSetTimes = SELF.touchDisableSetTimes - 1
		if (SELF.touchDisableSetTimes <= 0) then
			SELF.tableUI:setTouchEnabled(v)
			SELF.mainUI:setTouchEnabled(v)
		end
	else
		SELF.touchDisableSetTimes = SELF.touchDisableSetTimes + 1
		SELF.tableUI:setTouchEnabled(v)
		SELF.mainUI:setTouchEnabled(v)
	end
end

function BackpackScene:doEnterAnimation()
  self:preEnterAnimation()
  self:startEnterAnimation()
end

function BackpackScene:preEnterAnimation()
  BaseUIScene.preEnterAnimation(self)
end

function BackpackScene:startEnterAnimation()
  BaseUIScene.startEnterAnimation(self)
  self:generateAnimatedCells();
  local function enterActionFinished()
    self:nodeAnimationFinished()
  end
  
  local aDuration
  if #self.animatedCells == 1 then
    aDuration = TOTALENTERDURATION - CELLENTERDURATION
  else
    aDuration = (TOTALENTERDURATION - CELLENTERDURATION) / (#self.animatedCells - 1)
  end
  for aIndex, aCell in ipairs(self.animatedCells) do
    aCell:setPositionX( - visibleSize.width)
    local arr = CCArray:create()
    arr:addObject(CCDelayTime:create(CELLENTERDURATION + aDuration * (aIndex - 1)))
    arr:addObject(CCMoveBy:create(CELLENTERDURATION, ccp(visibleSize.width, 0)))
    aCell:runAction(CCSequence:create(arr))
  end
  
  
  local arr = CCArray:create()
  arr:addObject(CCDelayTime:create(TOTALENTERDURATION))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.mainUI:runAction(CCSequence:create(arr))
  
  self.tableUI:setPositionX(0)
  
  for k,v in pairs(self.group1)
  do
	v:setPositionX(v:getPositionX() - visibleSize.width)
	v:runAction(CCMoveBy:create(TOTALENTERDURATION, ccp(visibleSize.width, 0)))
  end
  
  for k,v in pairs(self.group2)
  do
	v:setPositionX(v:getPositionX() + visibleSize.width / 2)
	local arr = CCArray:create()
	arr:addObject(CCDelayTime:create(TOTALENTERDURATION / 2))
	arr:addObject(CCMoveBy:create(TOTALENTERDURATION / 2, ccp(-visibleSize.width / 2, 0)))
	v:runAction(CCSequence:create(arr))
  end
  
  for k,v in pairs(self.group3)
  do
	v:setPositionY(v:getPositionY() + visibleSize.height / 4)
	local arr = CCArray:create()
	arr:addObject(CCDelayTime:create(TOTALENTERDURATION * 3/ 4))
	arr:addObject(CCMoveBy:create(TOTALENTERDURATION / 4, ccp(0, -visibleSize.height / 4)))
	v:runAction(CCSequence:create(arr))
  end
  
  for k,v in pairs(self.group4)
  do
	v:setPositionX(v:getPositionX() + visibleSize.width)
	local arr = CCArray:create()
	arr:addObject(CCDelayTime:create(0.2))
	arr:addObject(CCMoveBy:create(0.1, ccp(-visibleSize.width, 0)))
	v:runAction(CCSequence:create(arr))
  end

	if self.argv.params.showSellFinish then
		print("self.argv.params.tabIndex = " .. tostringRich(self.argv.params.tabIndex))
		if self.argv.params.tabIndex == BAGCATEGORY.equip then
			SuspensionLabel:showContent(self, getTextByKey("sellItem_equipSuccess"))
		else
			SuspensionLabel:showContent(self, getTextByKey("sellItem_cardSuccess"))
		end
	end
end

function BackpackScene:sufEnterAnimation()
  BaseUIScene.sufEnterAnimation(self)
  local dragable = Get_ShareData("New_User_Guide_Running") ~= 1
  SELF.card_view:setDragEnabled(dragable)
  SELF.item_view:setDragEnabled(dragable)
  SELF.equip_view:setDragEnabled(dragable)
  --facebook share card/equip info
  if tonumber(Get_ShareData( "Sacrifice_Guide_Running")) ~= 1 and FacebookShareManager.isOpenFacebookShareFunc() then
	local star5card = false
	local star6card = false
	local star5equip = false
	local star6equip = false
	  for k,v in pairs(SELF.card_data) do
		if star5card and star6card then
			break
		end
		if v.rare == 5 and not star5card then
			if FacebookShareManager.judgeShouldShareFacebook(FacebookCardEquipShareID.STAR5CARD) then
				FacebookShareManager.facebookShareCardEquip(FacebookCardEquipShareID.STAR5CARD)
				return
			else
				star5card = true
			end
		end
		if v.rare == 6 and not star6card then
			if  FacebookShareManager.judgeShouldShareFacebook(FacebookCardEquipShareID.STAR6CARD) then
				FacebookShareManager.facebookShareCardEquip(FacebookCardEquipShareID.STAR6CARD)
				return
			else
				star6card = true
			end
		end
	  end
	  
	  for k,v in pairs(SELF.equip_data) do
		if star5equip and star6equip then
			break
		end
		if v.quality == 5 and not star5equip then
			if FacebookShareManager.judgeShouldShareFacebook(FacebookCardEquipShareID.STAR5EQUIP) then
				FacebookShareManager.facebookShareCardEquip(FacebookCardEquipShareID.STAR5EQUIP) 
				return
			else
				star5equip = true
			end
		end
		if v.quality == 6 and not star6equip then
			if FacebookShareManager.judgeShouldShareFacebook(FacebookCardEquipShareID.STAR6EQUIP) then
				FacebookShareManager.facebookShareCardEquip(FacebookCardEquipShareID.STAR6EQUIP) 
				return
			else
				star6equip = true
			end
		end
	  end
  end
  --testhhhh()--just crash

  if Get_ShareData("Guide_MultiLineup") == 1 then  --阵容切换引导回调
    local originalGuideCallback = getGuideFinishCallback()
    local function guideFinished()
		Director:sharedDirector():replaceScene(CardQueueScene:create())	
        RegisterOnGuideFinishCallback(originalGuideCallback)
    end

    RegisterOnGuideFinishCallback(guideFinished)
  end
  Set_ShareData( "Guide_Lineup3", 1);
end

function BackpackScene:doExitAnimation()
  self:preExitAnimation()
  self:startExitAnimation()
  --self.tableUI:runAction(CCMoveBy:create(0.5, ccp(-visibleSize.width, 0))) 
end

function BackpackScene:preExitAnimation()
  BaseUIScene.preExitAnimation(self)
end

function BackpackScene:dispose()
	releaseAll(self.toreleaseCardTable)
	releaseAll(self.toreleaseEquipTable)
	releaseAll(self.toreleaseItemTable)
	BackpackScene.super.dispose(self)
end

function BackpackScene:startExitAnimation()
  BaseUIScene.startExitAnimation(self)
  self:generateAnimatedCells();
  local function enterActionFinished()
	self.mainUI:removeChild(self.card_view, true)    
	self.mainUI:removeChild(self.equip_view, true)  
	self.mainUI:removeChild(self.item_view, true)   
    self:nodeAnimationFinished()
  end
  
  local aDuration
  if #self.animatedCells == 1 then
    aDuration = TOTALENTERDURATION - CELLENTERDURATION
  else
    aDuration = (TOTALENTERDURATION - CELLENTERDURATION) / (#self.animatedCells - 1)
  end
  for aIndex, aCell in ipairs(self.animatedCells) do
    local arr = CCArray:create()
    arr:addObject(CCDelayTime:create(aDuration * (aIndex - 1)))
    arr:addObject(CCMoveBy:create(CELLENTERDURATION, ccp(-visibleSize.width, 0)))
    aCell:runAction(CCSequence:create(arr))
  end
  
  local arr = CCArray:create()
  arr:addObject(CCDelayTime:create(TOTALENTERDURATION))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.mainUI:runAction(CCSequence:create(arr))
  
  
  for k,v in pairs(self.group1)
  do
	local arr = CCArray:create()
	arr:addObject(CCDelayTime:create(CELLENTERDURATION))
	arr:addObject(CCMoveBy:create(TOTALENTERDURATION - CELLENTERDURATION, ccp(-visibleSize.width, 0)))
	v:runAction(CCSequence:create(arr))
  end
  
  for k,v in pairs(self.group2)
  do
	local arr = CCArray:create()
	arr:addObject(CCDelayTime:create(TOTALENTERDURATION / 4))
	arr:addObject(CCMoveBy:create(TOTALENTERDURATION / 2, ccp(visibleSize.width / 2, 0)))
	v:runAction(CCSequence:create(arr))
  end
  
  for k,v in pairs(self.group3)
  do
	local arr = CCArray:create()
	arr:addObject(CCMoveBy:create(TOTALENTERDURATION / 4, ccp(0, visibleSize.height / 4)))
	v:runAction(CCSequence:create(arr))
  end
  
  for k,v in pairs(self.group4)
  do
	local arr = CCArray:create()
	arr:addObject(CCMoveBy:create(0.1, ccp(visibleSize.width, 0)))
	v:runAction(CCSequence:create(arr))
  end

end

function BackpackScene:sufExitAnimation()
  BaseUIScene.sufExitAnimation(self)
end

local MAXCELLAMOUNT = 6
function BackpackScene:generateAnimatedCells()
	local function getStartIndexAndEndIndex(tableview)
		if tableview.refCocosObj==nil then
			do return 9999 end
		end
		local offsetY = tableview:getContentOffset().y
		local container = tableview.refCocosObj:getContainer()
		local minOffsetY = tableview:getViewSize().height - container:getContentSize().height * container:getScaleY()
		return math.floor((offsetY - minOffsetY) / 206)  --（原版185）
	end
	
	self.animatedCells = {}
	if self.currentTab == BAGCATEGORY.card then
		for i = getStartIndexAndEndIndex(self.card_view), #self.card_data - 1
		do
			local cell = self.card_view:cellAtIndex(i)
			if cell then
				table.insert(self.animatedCells, cell)
				if table.getn(self.animatedCells) >= MAXCELLAMOUNT then
					break;
				end
			end
		end
	elseif self.currentTab == BAGCATEGORY.equip then
		for i = getStartIndexAndEndIndex(self.equip_view), #self.equip_data - 1
		do
			local cell = self.equip_view:cellAtIndex(i)
			if cell then
				table.insert(self.animatedCells, cell)
				if table.getn(self.animatedCells) >= MAXCELLAMOUNT then
					break;
				end
			end
		end
	elseif self.currentTab == BAGCATEGORY.item then
		for i = getStartIndexAndEndIndex(self.item_view), #self.item_data - 1
		do
			local cell = self.item_view:cellAtIndex(i)
			if cell then
				table.insert(self.animatedCells, cell)
				if table.getn(self.animatedCells) >= MAXCELLAMOUNT then
					break;
				end
			end
		end
	end
end

function BackpackScene:setSellMenuVisible(visible)
	local function setSellMenuText()
		local text = ""
		if  SELF.currentTab == BAGCATEGORY.card then
			text = getTextByKey("sellItem_cardNum")
		elseif SELF.currentTab == BAGCATEGORY.item then
			text = getTextByKey("sellItem_propNum")
		elseif SELF.currentTab == BAGCATEGORY.equip then
			text = getTextByKey("sellItem_equipNum")
		end
		SELF.selectCardTxt = SELF.sellMenu:getChildByName("txt_cardselect"):getChildByName("txt"):setString(text .. tostring(#idsToSell))
		SELF.sellPriceTxt = SELF.sellMenu:getChildByName("txt_sell"):getChildByName("txt"):setString(getTextByKey("sellItem_price").. tostring(math.floor(SELF.sellPrice)))
	end
	if not SELF.sellMenu then
		if visible then
			SELF.sellMenu = SELF.backbuilder:build("package_package_bottom")
			SELF.mainUI:addChild(SELF.sellMenu)
			SELF.sellMenu:setVisible(visible)
			setSellMenuText()
			SELF.sellMenu:getChildByName("btn_yellow_sure"):getChildByName("txt"):setString(getTextByKey("yes"))
			local sellButton = Button:create(SELF.sellMenu:getChildByName("btn_yellow_sure"))
			local function onCliokSell()
				if  SELF.currentTab == BAGCATEGORY.card then
					SELF.targetInfoPanel = ItemSellMessageBoxPanel:create( SELF , {cardData= idsToSell }) 
					SELF:addChild(SELF.targetInfoPanel)
					SELF.targetInfoPanel:scaleIn()   
				elseif SELF.currentTab == BAGCATEGORY.item then
					SELF.targetInfoPanel = ItemSellMessageBoxPanel:create( SELF , {propData= idsToSell })
					SELF:addChild(SELF.targetInfoPanel)
					SELF.targetInfoPanel:scaleIn()    
				elseif SELF.currentTab == BAGCATEGORY.equip then
					SELF.targetInfoPanel = ItemSellMessageBoxPanel:create( SELF , {equipData= idsToSell }) --Sell equips
					SELF:addChild(SELF.targetInfoPanel)
					SELF.targetInfoPanel:scaleIn()   
				end
			end
			sellButton:addEventListener(Events.kStart, onCliokSell)
			SELF.sellMenu:setPosition(ccp(0, -300))
			SELF.sellMenu:runAction(CCMoveTo:create(0.15, ccp(0, 0)))
		end
	else
		local function onMoveEnd()
			SELF.sellMenu:setVisible(visible)
		end
		if visible then
			setSellMenuText()
			if visible ~= SELF.sellMenu:isVisible() then
				SELF.sellMenu:setPosition(ccp(0, -300))
				SELF.sellMenu:setVisible(visible)
				local actionArray = CCArray:create()
				actionArray:addObject(CCMoveTo:create(0.15, ccp(0, 0)))
				SELF.sellMenu:runAction(CCSequence:create(actionArray))
			end
		else
			if visible ~= SELF.sellMenu:isVisible() then
				local actionArray = CCArray:create()
				actionArray:addObject(CCMoveTo:create(0.15, ccp(0, -300)))
				actionArray:addObject(CCCallFuncN:create(onMoveEnd))
				SELF.sellMenu:runAction(CCSequence:create(actionArray))
			end
		end
	end
	
end

---------------------------------------------------------------------
--静态函数
---------------------------------------------------------------------

function BackpackScene.ItemCanOpenNum(itemMetaId)
	local itemMeta = MetaManager.prop_meta[itemMetaId]

	if itemMeta.effectType == Prop_Effect_Type.BOX then
		local itemNum = BagCalcManager.getNumById(itemMetaId)
		local relateItem = BackpackScene.findRelationItemInBag(itemMetaId)
		if not relateItem then
			--没有关联道具
			print("warning 该道具没有关联的道具! itemMetaId = " .. itemMetaId)
			return 0
		end
		local relateItemNum = BagCalcManager.getNumById(relateItem.relatedPropId)
		-- print("itemNum = " .. itemNum)
		-- print("relateItemNum = " .. relateItemNum)
		result = math.min(itemNum, relateItemNum)
		if result > MAX_OPEN_CHEST_NUM then
			return MAX_OPEN_CHEST_NUM
		end
		return result
	elseif itemMeta.effectType == Prop_Effect_Type.VIPBOX then
		--vip宝箱类 与当前总数有关
		local itemNum = BagCalcManager.getNumById(itemMetaId)
		if itemNum > MAX_OPEN_CHEST_NUM then
			return MAX_OPEN_CHEST_NUM
		end
		return itemNum
	elseif itemMeta.effectType == Prop_Effect_Type.RED_PACKET_RECIVED then
		--红包类 与当前总数有关
		local itemNum = BagCalcManager.getNumById(itemMetaId)
		if itemNum > MAX_OPEN_CHEST_NUM then
			return MAX_OPEN_CHEST_NUM
		end
		return itemNum
	end

	--其余道具
	return 1
end

function BackpackScene.findRelationItemInBag(itemMetaId)
	for k,v in pairs(MetaManager.prop_relation)
	do
		if tonumber(v.id) == tonumber(itemMetaId) then
			return v
		end
	end

	return nil
end

--isMore: 是否再次开启
function BackpackScene.getItemUseBtnStr(itemMetaId, isMore)
	local itemMeta = MetaManager.prop_meta[itemMetaId]
	if itemMeta.effectType == Prop_Effect_Type.TREASUREBOX then
		return getTextByKey("bag_openBtn")
	elseif itemMeta.effectType == Prop_Effect_Type.BOX then
		local openNum = BackpackScene.ItemCanOpenNum(itemMetaId)
		if openNum == 0 then
			--没有次数 显示"开启"
			return getTextByKey("bag_openBtn")
		end
		if isMore then
			--再次开启x个
			return getTextByKey("propInfo_openChest_open1", {num1 = openNum})
		end
		--开启x个
		return getTextByKey("propInfo_openChest_open", {num1 = openNum})
	elseif itemMeta.effectType == Prop_Effect_Type.VIPBOX or itemMeta.effectType == Prop_Effect_Type.RED_PACKET_RECIVED then
		local openNum = BackpackScene.ItemCanOpenNum(itemMetaId)
		if openNum == 0 then
			--没有次数 显示"使用"
			return getTextByKey("propInfo_useBtn")
		end
		if isMore then
			--再次使用x个
			return getTextByKey("propInfo_openChest_open3", {num1 = openNum})
		end
		--使用x个
		return getTextByKey("propInfo_openChest_open2", {num1 = openNum})
	end
	return getTextByKey("propInfo_useBtn")
end

function BackpackScene.useMoreProp(amount, moreClickCallback)
	local function usePropResponse( e )
		onGeneralUsePropResponse(e, SELF._data, SELF["item_data"], SELF, SELF.dataIndex, amount, moreClickCallback)
		if moreClickCallback then
			moreClickCallback()
		end
	end
	
	local function usePropFailed(e)
		onGeneralUsePropFailed(e, SELF._data, SELF)

	end
	
	requestUsePropRequest(SELF._data, SELF["item_data"], usePropResponse, usePropFailed, SELF, amount, nil)
end