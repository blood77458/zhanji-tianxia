--------------------------------------------------------------------------------
-- TreasureBackpackScene.lua -- 宝物背包
-- author: l1ghtsaber
-- date: 2015-7-28
--------------------------------------------------------------------------------

require "hecore.display.CocosObject"
require "hecore.display.Director"
require "hecore.display.Scene"
require "hecore.ui.LayoutBuilder"
require "canon.scene.BaseUIScene"
require "canon.manager.SpiritManager"
require "canon.request.BuySpiritPoolRequest"
require "canon.panel.SpiritComposePanel"
require "canon.features.multilineup.manager.BitOperManager"

TOTALENTERDURATION = 0.3
CELLENTERDURATION = 0.15

TreasureBackpackScene = class(BaseUIScene)
local visibleSize = CCDirector:sharedDirector():getVisibleSize()

local SELF


BACKPACK_STATUS = table.const{
    NORMAL = 1,   --正常，显示卡牌信息
    OPTION = 2,   --单选
    CHECKBOX = 3, --复选
}

SORT_ORDER = table.const{
    ASC  = 0, --升序
    DESC = 1, --降序
}

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

local BackpackUIStatus = BACKPACK_STATUS.NORMAL

local idsToSell = {}

local queueTreasureList = {} --宝物的多阵容状态（0~7八种）

function TreasureBackpackScene:ctor()
	SELF = self
	SELF.sellPrice = 0
	SELF.sortButton = {}
    SELF.sortButtonTxt = {}
    SELF.tableVeiwEnableStatus = true
    SELF.title = getTextByKey("Treasure_titel_4")
    BackpackUIStatus = BACKPACK_STATUS.NORMAL  
end

function TreasureBackpackScene:create( argv )
    if argv then 
        self.argv = argv 
    else
        self.argv = {enterScene=nil,returnScene=nil,params={}}
    end
    
    local scene = TreasureBackpackScene.new()
    scene:initScene()
    return scene
end

function TreasureBackpackScene:refreshTable(keepOffset, insertData, deleteData , index)
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
				tableOffset.y = tableOffset.y + 206  --原版185
			-- else

			end

		end	
		
		SELF.tableUI:setContentOffset(tableOffset, true)
	else
		SELF.tableUI:reloadData()
	end
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

local function sortTreasureFunc( evt )
	local function sortFunc(a , b)
		local isAEquiped = (a.cardId > 0)
		local isBEquiped = (b.cardId > 0)
		local rarityA = TreasureManager.getTreasureRare( a )
		local rarityB = TreasureManager.getTreasureRare( b )
		if SELF.argv.params and SELF.argv.params.equipedDown then
			if not isAEquiped and isBEquiped then
				return true
			elseif isAEquiped == isBEquiped then
				if evt.context == SORT_TYPE.RARE_ASC then 
					if rarityA == rarityB then
						return a.metaId < b.metaId
					else
						return rarityA < rarityB
					end
				elseif evt.context == SORT_TYPE.RARE_DESC then
					if rarityA == rarityB then
						return a.metaId < b.metaId
					else
						return rarityA > rarityB
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
		else
			if isAEquiped and not isBEquiped then
				return true
			elseif isAEquiped == isBEquiped then
				if evt.context == SORT_TYPE.RARE_ASC then 
					if rarityA == rarityB then
						return a.metaId < b.metaId
					else
						return rarityA < rarityB
					end
				elseif evt.context == SORT_TYPE.RARE_DESC then
					if rarityA == rarityB then
						return a.metaId < b.metaId
					else
						return rarityA > rarityB
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
		
    end
    table.sort(SELF.treasure_data,sortFunc)
    HeMemDataHolder:setString("savedSortOrder_treasure", tostring(evt.context))
end

local function onClickSort(e) -- todo 排序弹窗
	local argv = {sortFunc = sortTreasureFunc , enterType = "TreasureBackPackScene"}
	SELF.targetInfoPanel = SpiritBackPackSortPanel:create( SELF , argv)
	PopoutManager:sharedManager():popout(SELF.targetInfoPanel, kPopoutDir.kScale, true, false ,SELF) 
end

local function runChangeBtnSellAction(backpackStatus)
	if not backpackStatus then
		backpackStatus = BACKPACK_STATUS.CHECKBOX
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
			-- if curTab ==  BAGCATEGORY.card then
				SELF.mainUI:getChildByName("inventory_title"):getChildByName("txt_tochose"):getChildByName("txt"):setString(getTextByKey("Treasure_text_31"))

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

function TreasureBackpackScene:onInit()
	self.backbuilder = LayoutBuilder:createWithContentsOfFile("scene/package_new.json")
	self.backbuilder.useArtLabelTTF = true
	self.mainUI = self.backbuilder:build("package_inventory")
	-- self:addChild(self.mainUI)
	-- BaseUIScene.onInit(self)
	BaseUIScene.initBackGround(SELF)

	self.mainUI:getChildByName("inventory_equip"):setVisible(false)
	self.mainUI:getChildByName("inventory_prov"):setVisible(false)
	self.mainUI:getChildByName("package_inventory_baowu"):setVisible(false)
	self.mainUI:getChildByName("inventory_card"):setVisible(false)

	if	SELF.argv.enterScene == "CardQueueScene" or SELF.argv.enterScene == "CardRebirthScene" then
		BackpackUIStatus = BACKPACK_STATUS.OPTION
	-- elseif SELF.argv.enterScene == "KingTempleScene" then
 --        BackpackUIStatus = BACKPACK_STATUS.NORMAL
    end

	SELF.group1 = {}
	table.insert(SELF.group1, SELF.mainUI:getChildByName("btn_inventory_L"))
	
	SELF.group2 = {}
	table.insert(SELF.group2, SELF.mainUI:getChildByName("btn_inventory_R"))
	
	SELF.group3 = {}	
	table.insert(SELF.group3, SELF.mainUI:getChildByName("inventory_title"))

	SELF.group4 = {}
	table.insert(SELF.group4, SELF.mainUI:getChildByName("bg_inventory_red"))

	local zOrder = SELF.mainUI:getChildByName("bg_inventory_red"):getZOrder() + 1
	SELF.coverLayer = LayerColor:create()
	SELF.coverLayer:setColor(ccc3( 0, 0, 0 ))
	SELF.coverLayer.refCocosObj:setOpacity( 170 )
	SELF.coverLayer:setContentSize(CCSizeMake( visibleSize.width, 932 ))
	SELF.coverLayer:setPosition(ccp( 0, 118 ))
	SELF.coverLayer:setVisible(false)
	SELF.mainUI:addChildAt(SELF.coverLayer, zOrder)  

	SELF.mainUI:getChildByName("btn_inventory_L"):getChildByName("txt_bag_ArrangeBtn"):setString(getTextByKey("bag_ArrangeBtn"))
  	SELF.mainUI:getChildByName("btn_inventory_R"):getChildByName("txt_bag_SellBtn"):setString(getTextByKey("bag_SellBtn"))
    
  	SELF.mainUI:getChildByName("inventory_title"):getChildByName("txt_inventory"):getChildByName("txt_inventory"):setString(getTextByKey("bag_Slot"))
  	
  	SELF.mainUI:getChildByName("inventory_title"):getChildByName("btn_inventory_switch"):getChildByName("txt_btn_inventory_switch"):getChildByName("txt_btn_inventory_switch"):setString(getTextByKey("bag_ExpandBtn"))

  	--初始化queueTreasureList
	queueTreasureList = {}
	local gameData = DataManager.getGameInitData()
	for BattleArrayId = 1,3 do
		local quedata = gameData.sharkUserBattleArray[BattleArrayId] and gameData.sharkUserBattleArray[BattleArrayId].sharkUserQueue or {}
		local matdata = gameData.sharkUserBattleArray[BattleArrayId] and gameData.sharkUserBattleArray[BattleArrayId].sharkMatrices and 
						gameData.sharkUserBattleArray[BattleArrayId].sharkMatrices.sharkMatrices or {} 
		for k,v in pairs(quedata) do
			if (v.treasureId and v.treasureId ~= 0) then 
				if not queueTreasureList[v.treasureId] then 
					queueTreasureList[v.treasureId] = BitOperManager.data[BattleArrayId]
				else
					queueTreasureList[v.treasureId] = queueTreasureList[v.treasureId] + BitOperManager.data[BattleArrayId]
				end	
			end
		end	
	end

	--卖出按钮
    local function onClickBtSell(e)
		if SELF.coverLayer:isVisible() then --todo
			do return end
		end
		
		if BackpackUIStatus == BACKPACK_STATUS.NORMAL then
			runChangeBtnSellAction(BackpackUIStatus)
			BackpackUIStatus = BACKPACK_STATUS.CHECKBOX
			idsToSell = {}
		else
			runChangeBtnSellAction(BackpackUIStatus)
			BackpackUIStatus = BACKPACK_STATUS.NORMAL
			idsToSell = {}
		end
		
		SELF:refreshTable(true) --标记
  	end

  	SELF.sortOrder = SORT_ORDER.ASC
    for index,bt in ipairs(SELF.sortButton) do
        bt:setVisible(false)
        bt:setZOrder(101)
    end

	local bt_sell = Button:create(SELF.mainUI:getChildByName("btn_inventory_R"))
  	bt_sell:addEventListener(Events.kStart, onClickBtSell)
  	SELF.btnSell = bt_sell
  	  --排序按钮        
	local btSortUI = SELF.mainUI:getChildByName("btn_inventory_L")
	local btSort = Button:create(btSortUI)    
	btSort:addEventListener(Events.kStart, onClickSort , SELF )
	--扩容按钮
    local function onClickSwitch(e)
		SELF:setTableViewsEnabled(false)
		SELF.targetInfoPanel = MessageBoxPanel:create(SELF, MessageBoxType.kEnsureBuyTreasureGridWarning, {setTargetInfoPanelNil = true})
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
		--不显示扩容
		SELF.mainUI:getChildByName("inventory_title"):getChildByName("btn_inventory_switch"):setVisible(false)
		SELF.mainUI:getChildByName("inventory_title"):getChildByName("txt_inventory_num"):setVisible(false)
		SELF.mainUI:getChildByName("inventory_title"):getChildByName("txt_inventory"):setVisible(false)
		SELF.mainUI:getChildByName("inventory_title"):getChildByName("txt_tochose"):getChildByName("txt"):setString(getTextByKey("Treasure_text_32"))
	end

	SELF.treasure_data = DataManager.getTreasuresData() 
	
	if HeMemDataHolder:getString("notShowEquipedTreasure") == "true" then --todo
    	local tempTable = {}
		for k,v in pairs(SELF.treasure_data) do
			if v.cardId == 0 then
				table.insert(tempTable , v)
			end
		end
		for i = #SELF.treasure_data, 1, -1 do
			table.remove(SELF.treasure_data, i)
		end
		for k,v in pairs(tempTable) do
			table.insert(SELF.treasure_data , v)
		end
    end

	for i,treasure in pairs(SELF.treasure_data) do
        SELF.treasure_data[i].quality = MetaManager.treasure_meta[treasure.metaId].rare
		-- SELF.treasure_data[i].price = MetaManager.treasure_data[SELF.equip_data[i].metaId].sellPriceCoe * MetaManager.equip_level[SELF.equip_data[i].level].sellPriceBase
    end

    --过滤规则
    if SELF.argv.params and SELF.argv.params.filterFunc ~= nil then
        local id_list = SELF.argv.params.filterFunc(SELF.treasure_data)
        SELF.treasure_data = id_list
    end 

	--没有宝物的显示 
  	local defaultNoSpiritText = getTextByKey("Treasure_text_35")
	SELF.noSpiritText = TextField:create(defaultNoSpiritText, "Arial", 30)
	local winSize = CCDirector:sharedDirector():getWinSize()
	local textHeight = self.mainUI:getChildByName("package_train_card"):getPositionY() + 
					   self.mainUI:getChildByName("package_train_card"):getContentSize().height / 2
	SELF.noSpiritText:setPosition(ccp(winSize.width / 2, textHeight))
	SELF.noSpiritText:setVisible(#SELF.treasure_data == 0)
	SELF.mainUI:addChild(SELF.noSpiritText)
	table.insert(SELF.group1, SELF.noSpiritText) 

	local function onGetSpirit( evt )  --去求宝
		SELF:replaceScene( TreasureGachaScene )
	end
	SELF.getSpiritDisplay = self.mainUI:getChildByName("btn")
	local getSpiritBtn = Button:create(SELF.getSpiritDisplay)
	getSpiritBtn:addEventListener(Events.kStart, onGetSpirit, self)
	self.mainUI:getChildByName("btn"):getChildByName("txt_gostage"):setString(getTextByKey("Treasure_text_36"))
	getSpiritBtn:setVisible(#SELF.treasure_data == 0) 
	table.insert(SELF.group1, SELF.getSpiritDisplay) 

    local treasureGridTotalNum = TreasureManager.calcTreasureTotalGridNum()
    SELF.mainUI:getChildByName("inventory_title"):getChildByName("txt_inventory_num"):getChildByName("font"):setString(TreasureManager.calcTreasureUsingGridNum().."/"..treasureGridTotalNum)

	if HeMemDataHolder:getString("savedSortOrder_treasure") == "" then
		sortTreasureFunc({context = SORT_TYPE.RARE_DESC})
	else
		sortTreasureFunc({context = tonumber(HeMemDataHolder:getString("savedSortOrder_treasure"))}) --todo
	end

	SELF.tableUI = self:createTableView(SELF.treasure_data)
    SELF.mainUI:addChildAt(SELF.tableUI , zOrder)
    SELF:addChild(SELF.mainUI)

	if (BackpackUIStatus == BACKPACK_STATUS.OPTION) then --单选退出的情况
		SELF.mainUI:getChildByName("btn_inventory_R"):setVisible(false)
		SELF.tableUI:reloadData()
	end
	BaseUIScene.onInit(SELF)

	if (SELF.argv.showStrength) then
		--显示战斗力更新
		DataManager.fightCapacityMaybeUpdated()
	end
end 

local TABLEVIEW_CELL_TAG = -1001
local CELL_WIDTH = BAGCONFIG.WIDTH
local CELL_HEIGHT = 206  --原版185
local TABLEVIEW_WIDTH = BAGCONFIG.WIDTH
local TABLEVIEW_PIXIEL_Y = 50
local TABLEVIEW_HEIGHT = BAGCONFIG.HEIGHT - 80 + TABLEVIEW_PIXIEL_Y
local TABLEVIEW_POS_X = 0
local TABLEVIEW_POS_Y = (1280-BAGCONFIG.HEIGHT)/2-35 - TABLEVIEW_PIXIEL_Y
local CHARGE_OFFSETX = 200

local TAG_PIC = 1001
local TAG_TXT_CARD_NAME = 1002
local TAG_TXT_CHALLENGE = 1003
local TAG_TXT_ENABLEEVOLUTION = 1004
local TAG_TXT_ATK_NUM = 1005
local TAG_TXT_DEF_NUM = 1006
local TAG_TXT_HP_NUM = 1007
local TAG_ICON_CHALLENGE = 1008
local TAG_TXT_LV_NUM = 1009
local TAG_ICON_CHECKBOX = 1010
local TAG_ICON_CHECKBOX_BG = 1011
local TAG_ICON_WHITE = 1012
local TAG_ICON_GREEN = 1013
local TAG_ICON_BLUE = 1014
local TAG_ICON_PURPLE = 1015
local TAG_ICON_ORANGE = 1016
local TAG_ICON_RED = 1017
local TAG_ICON_GOLD = 1018
local TAG_ICON_SELECTED = 1019
local TAG_TXT_SELLCOIN = 1020
local TAG_TXT_EXP = 1021
local TAG_ICON_SELLCOIN = 1022
local TAG_BTN_TRAIN = 1023
local TAG_TXT_EQUIPED = 1024
local TAG_PIC_REWARD = 1025

local TAG_FIRST_STAR = 10001

local TAG_FLAG_FIR = 1026
local TAG_FLAG_SEC = 1027
local TAG_FLAG_THD = 1028
local TAG_BTN_UPSTAR = 1029
local TAG_TXT_ATK_EX = 1030
local TAG_TXT_DEF_EX = 1031
local TAG_TXT_HP_EX = 1032
local TAG_YOU = 1033
local TAG_LOCK = 1034

function TreasureBackpackScene:refreshUI(toAppointTreasure)
	SELF.treasure_data = DataManager.getTreasuresData()
	if HeMemDataHolder:getString("notShowEquipedTreasure") == "true" then
    	local tempTable = {}
		for k,v in pairs(SELF.treasure_data) do
			if v.cardId == 0 then
				table.insert(tempTable , v)
			end
		end
		for i = #SELF.treasure_data, 1, -1 do
			table.remove(SELF.treasure_data, i)
		end
		for k,v in pairs(tempTable) do
			table.insert(SELF.treasure_data , v)
		end

		--没有可显示的元神时提示去凝神
		if #tempTable == 0 then
			SELF.noSpiritText:setVisible(true) 
			if SELF.getSpiritDisplay then 
				SELF.getSpiritDisplay:setVisible(true) 
			end
		else
			SELF.noSpiritText:setVisible(false)
			if SELF.getSpiritDisplay then  
				SELF.getSpiritDisplay:setVisible(false) 
			end
		end
    end
	for i,treasure in pairs(SELF.treasure_data) do
        SELF.treasure_data[i].quality  = MetaManager.treasure_meta[treasure.metaId].rare
    end
    local zOrder = SELF.mainUI:getChildByName("bg_inventory_red"):getZOrder() + 1
    if SELF.tableUI then
    	SELF.tableUI:removeFromParentAndCleanup(true)
    end

    if HeMemDataHolder:getString("savedSortOrder_treasure") == "" then
		sortTreasureFunc({context = SORT_TYPE.RARE_DESC})
	else
		sortTreasureFunc({context = tonumber(HeMemDataHolder:getString("savedSortOrder_treasure"))})
	end
    
	SELF.tableUI = self:createTableView(SELF.treasure_data)
	SELF.tableUI:setTouchEnabled(SELF.tableVeiwEnableStatus)
    SELF.mainUI:addChildAt(SELF.tableUI , zOrder)

    if toAppointTreasure then
    	local toAppointTreasureIndex = 0
    	local tableOffset = SELF.tableUI:getContentOffset()
    	for k,v in pairs(SELF.treasure_data) do
    		if v.treasureId == toAppointTreasure.treasureId then
    			toAppointTreasureIndex = k
    		end
    	end
    	local minOffsetY
		local maxOffsetY
		local numberOfCells = SELF.tableUI.tableViewRenderer:numberOfCells()
	    local cellSize = SELF.tableUI.tableViewRenderer:getContentSize()
	    local viewSize = SELF.tableUI:getViewSize()
		local offsetY = (toAppointTreasureIndex - #SELF.treasure_data + 2) * cellSize.height

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

    local treasureGridTotalNum = TreasureManager.calcTreasureTotalGridNum()
    SELF.mainUI:getChildByName("inventory_title"):getChildByName("txt_inventory_num"):getChildByName("font"):setString(TreasureManager.calcTreasureUsingGridNum().."/"..treasureGridTotalNum)
end


function TreasureBackpackScene:createTableView(data)
	local TreasureBackpackSceneRenderer = class(TableViewRenderer)
	function TreasureBackpackSceneRenderer:ctor(width, height)
		self.list = data
		local builder = LayoutBuilder:createWithContentsOfFile("scene/package_new.json")
		builder.useArtLabelTTF = true
		self.builder = builder
	end

	local firstStarPosX,firstStarPosY, starPixielX
	
	function TreasureBackpackSceneRenderer:buildCell(container)
		local cell = self.builder:build("package_inventory_baowu") --todo 名字要改
	    cell:setPosition(ccp(0, 206))   
	    cell:setTag(TABLEVIEW_CELL_TAG)
	    container:addChild(cell)

	    cell:getChildByName("frame_card"):setVisible(false)
		cell:getChildByName("frame_card"):setTag(TAG_PIC)
		cell:getChildByName("normal_card_small"):setVisible(false);
		cell:getChildByName("package_txt_inventory_card_name_1"):setTag(TAG_TXT_CARD_NAME)
		cell:getChildByName("package_txt_inventory_card_name_1"):getChildByName("package_txt_inventory_card_name_1"):setTag(TAG_TXT_CARD_NAME)
		cell:getChildByName("txt_icon_inverntory_equiped"):setTag(TAG_TXT_CHALLENGE)
		cell:getChildByName("txt_icon_inverntory_equiped"):getChildByName("txt_icon_stageList_challenge"):setTag(TAG_TXT_CHALLENGE)
		cell:getChildByName("txt_icon_inverntory_equiped"):getChildByName("txt_icon_stageList_challenge"):setString(getTextByKey("equip_equipped"))
		cell:getChildByName("package_txt_wecandoanything"):setTag(TAG_TXT_ENABLEEVOLUTION)
		cell:getChildByName("package_txt_wecandoanything"):getChildByName("txt"):setTag(TAG_TXT_ENABLEEVOLUTION)
		cell:getChildByName("txt_cc_max"):setTag(TAG_TXT_EQUIPED)
		cell:getChildByName("txt_cc_max"):getChildByName("txt_cc_max"):setTag(TAG_TXT_EQUIPED)
		cell:getChildByName("txt_fangyuli"):setTag(TAG_TXT_ATK_NUM)
		cell:getChildByName("txt_smz"):setTag(TAG_TXT_DEF_NUM)
		cell:getChildByName("txt_bj"):setTag(TAG_TXT_HP_NUM)
		cell:getChildByName("txt_01"):setTag(TAG_TXT_ATK_EX)
		cell:getChildByName("txt_01"):getChildByName("txt_01"):setTag(TAG_TXT_ATK_EX)
		cell:getChildByName("txt_02"):setTag(TAG_TXT_DEF_EX)
		cell:getChildByName("txt_02"):getChildByName("txt_02"):setTag(TAG_TXT_DEF_EX)
		cell:getChildByName("txt_03"):setTag(TAG_TXT_HP_EX)
		cell:getChildByName("txt_03"):getChildByName("txt_03"):setTag(TAG_TXT_HP_EX)
		cell:getChildByName("txt_you"):setTag(TAG_YOU)
		cell:getChildByName("txt_you"):getChildByName("txt"):setTag(TAG_YOU)
		cell:getChildByName("icon_lock_big"):setTag(TAG_LOCK)

		cell:getChildByName("icon_stageList_challenge"):setTag(TAG_ICON_CHALLENGE)
		if not firstStarPosX and not firstStarPosY then
			firstStarPosX, firstStarPosY = cell:getChildByName("icon_star_1").refCocosObj:getPosition()
		end
		cell:getChildByName("txt_lv_num"):setTag(TAG_TXT_LV_NUM)
		cell:getChildByName("txt_lv_num"):getChildByName("txt_lv_num"):setTag(TAG_TXT_LV_NUM)

		cell:getChildByName("icon_star_1"):setVisible(false)
		cell:getChildByName("icon_star_2"):setVisible(false)
		if not starPixielX then
			local posX, posY = cell:getChildByName("icon_star_2").refCocosObj:getPosition()
			starPixielX = firstStarPosX - posX
		end --这是星星的距离啊
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
		--cell:getChildByName("earth_yellow9_panel"):setVisible(false)
		cell:getChildByName("flash_light9_panel"):setTag(TAG_ICON_SELECTED)
		cell:getChildByName("txt_sellv_font"):setTag(TAG_TXT_SELLCOIN)  --todo 暂时没有 银币的部分
		cell:getChildByName("txt_sellv_font"):getChildByName("txt"):setTag(TAG_TXT_SELLCOIN)
		cell:getChildByName("txt_sellv"):setTag(TAG_TXT_EXP)
		cell:getChildByName("txt_sellv"):getChildByName("txt"):setString(getTextByKey("cardInfo_exp"))
		cell:getChildByName("icon_slivercoin"):setTag(TAG_ICON_SELLCOIN)
		cell:getChildByName("package_btn_blue_short_sx_sb"):setTag(TAG_BTN_TRAIN)
		cell:getChildByName("package_btn_blue_short_sx_sb"):getChildByName("txt_sx"):setString(getTextByKey("Treasure_titel_6"))
		cell:getChildByName("btn_equipEnhance_Title"):setTag(TAG_BTN_UPSTAR)
		cell:getChildByName("btn_equipEnhance_Title"):getChildByName("txt_equipEnhance_Title"):setString(getTextByKey("Treasure_titel_5"))

		cell:getChildByName("icon_squad_1"):setTag(TAG_FLAG_FIR)
		cell:getChildByName("icon_squad_2"):setTag(TAG_FLAG_SEC)
		cell:getChildByName("icon_squad_3"):setTag(TAG_FLAG_THD)
		cell:getChildByName("icon_squad_1"):getChildByName("icon_squad1"):setTag(TAG_FLAG_FIR)
		cell:getChildByName("icon_squad_2"):getChildByName("icon_squad2"):setTag(TAG_FLAG_SEC)
		cell:getChildByName("icon_squad_3"):getChildByName("icon_squad3"):setTag(TAG_FLAG_THD)
	end
	
	local function setTextByTag(cell, tag, str)
		local txt = cell:getChildByTag(tag):getChildByTag(tag)
		setNodeText(txt, str)
	end
	
	local function setNodeVisibleByTag(cell, tag, visible)
		cell:getChildByTag(tag):setVisible(visible)
	end
	
	function TreasureBackpackSceneRenderer:setData(rawCocosObj, index)
		local cell = self:getChildByTag(rawCocosObj, TABLEVIEW_CELL_TAG)

		setNodeVisibleByTag(cell ,TAG_TXT_ATK_EX , false )
		setNodeVisibleByTag(cell ,TAG_TXT_DEF_EX , false )
		setNodeVisibleByTag(cell ,TAG_TXT_HP_EX , false )
		setNodeVisibleByTag(cell, TAG_TXT_CHALLENGE, false)
		setNodeVisibleByTag(cell, TAG_ICON_CHALLENGE, false)
		if SELF["treasure_data"][index + 1] then
			local treasureInfo = SELF["treasure_data"][index + 1]

			setNodeVisibleByTag(cell, TAG_LOCK, treasureInfo.lock)
			--删图
			if cell:getChildByTag(TAG_PIC_REWARD) then
				-- cell:getChildByTag(TAG_PIC_REWARD):removeFromParentAndCleanup(true)
				cell:removeChildByTag(TAG_PIC_REWARD, true)
			end		
			--添图 todo
			local params = {}
			params.sourceDisplay = cell:getChildByTag(TAG_PIC)
			params.showInCenter = true
			local headCard = CanonGoodIcon.createGoodIcon(ResourceEnum.TREASURE, treasureInfo.metaId, 1, params)
			headCard:setTag(TAG_PIC_REWARD)
			cell:addChild(headCard.refCocosObj, cell:getChildByTag(TAG_PIC):getZOrder())
			headCard:dispose()

			--属性及其加成
			local subAttrTable = {
				[1] = TAG_TXT_ATK_EX,
				[2] = TAG_TXT_DEF_EX,
				[3] = TAG_TXT_HP_EX
			}
			local attributes = {}
			attributes[3],attributes[2],attributes[1] = TreasureSystemUtils.CountAttandDefandHp(treasureInfo,treasureInfo.level)
			for i = 1,3 do
				if attributes[i] then 
					setNodeVisibleByTag(cell , subAttrTable[i] , true)
					local str = ""..attributes[i]
					setTextByTag(cell , subAttrTable[i] , str)
					local color = TreasureManager.getColorByRarity(treasureInfo.quality)
					cell:getChildByTag(subAttrTable[i]):getChildByTag(subAttrTable[i]):setColor(color)
				end
			end

			--品质及其颜色
			setTextByTag(cell, TAG_YOU, TreasureManager.getTreasureQua( TreasureSystemUtils.CheckPotentialRank(treasureInfo) ))
			setNodeColor(cell:getChildByTag(TAG_YOU):getChildByTag(TAG_YOU),TreasureManager.getColorByRarity(TreasureSystemUtils.CheckPotentialRank(treasureInfo) + 1))

			setTextByTag(cell, TAG_TXT_CARD_NAME, TreasureManager.getTreasureName( treasureInfo ), true)
			setTextByTag(cell, TAG_TXT_LV_NUM, "" .. treasureInfo.level)

			for i = 1, 7 do
				setNodeVisibleByTag(cell, TAG_FIRST_STAR - 1 + i, i <= TreasureManager.getTreasureRare( treasureInfo ))
			end 

			for quality = 1, 7 do
				setNodeVisibleByTag(cell, TAG_ICON_WHITE + quality - 1, quality == TreasureManager.getTreasureRare( treasureInfo ))
			end

			setNodeVisibleByTag(cell, TAG_BTN_TRAIN, false)
			setNodeVisibleByTag(cell, TAG_BTN_UPSTAR, false)

			--阵容状态
			if DataManager.getGameInitData().sharkUser.level < (MetaManager.game_meta.gameSettingConfig.lineupUnlockLevel or 43) then
				cell:getChildByTag(TAG_FLAG_FIR):setVisible(false)
				cell:getChildByTag(TAG_FLAG_SEC):setVisible(false)
				cell:getChildByTag(TAG_FLAG_THD):setVisible(false)
			else
				cell:getChildByTag(TAG_FLAG_FIR):getChildByTag(TAG_FLAG_FIR):setVisible(true)
				cell:getChildByTag(TAG_FLAG_SEC):getChildByTag(TAG_FLAG_SEC):setVisible(true)
				cell:getChildByTag(TAG_FLAG_THD):getChildByTag(TAG_FLAG_THD):setVisible(true)
				if not queueTreasureList[treasureInfo.treasureId] then
					cell:getChildByTag(TAG_FLAG_FIR):getChildByTag(TAG_FLAG_FIR):setVisible(false)
					cell:getChildByTag(TAG_FLAG_SEC):getChildByTag(TAG_FLAG_SEC):setVisible(false)
					cell:getChildByTag(TAG_FLAG_THD):getChildByTag(TAG_FLAG_THD):setVisible(false)
				else
					if BitOperManager:_and(queueTreasureList[treasureInfo.treasureId],1,3) == 0 then 
						cell:getChildByTag(TAG_FLAG_FIR):getChildByTag(TAG_FLAG_FIR):setVisible(false)
					end
					if BitOperManager:_and(queueTreasureList[treasureInfo.treasureId],2,3) == 0 then 
						cell:getChildByTag(TAG_FLAG_SEC):getChildByTag(TAG_FLAG_SEC):setVisible(false)
					end
					if BitOperManager:_and(queueTreasureList[treasureInfo.treasureId],4,3) == 0 then 
						cell:getChildByTag(TAG_FLAG_THD):getChildByTag(TAG_FLAG_THD):setVisible(false)
					end
				end
			end
			
			if BackpackUIStatus == BACKPACK_STATUS.NORMAL then
				setNodeVisibleByTag(cell, TAG_ICON_SELLCOIN, false)
				setNodeVisibleByTag(cell, TAG_TXT_SELLCOIN, false)
				setNodeVisibleByTag(cell, TAG_TXT_EXP, false)
				setNodeVisibleByTag(cell, TAG_ICON_CHECKBOX_BG, false)
				setNodeVisibleByTag(cell, TAG_ICON_CHECKBOX, false)
				setNodeVisibleByTag(cell, TAG_ICON_SELECTED, false)
				setNodeVisibleByTag(cell, TAG_TXT_EQUIPED , true)
				if TreasureManager.isLevelSaigou( treasureInfo ) then 
					setNodeVisibleByTag(cell, TAG_BTN_TRAIN, true)	
				else
					setNodeVisibleByTag(cell, TAG_BTN_UPSTAR, true)	
				end
			elseif BackpackUIStatus == BACKPACK_STATUS.OPTION then
				setNodeVisibleByTag(cell, TAG_ICON_SELLCOIN, false)
				setNodeVisibleByTag(cell, TAG_TXT_SELLCOIN, false)
				setNodeVisibleByTag(cell, TAG_TXT_EXP, false)
				setNodeVisibleByTag(cell, TAG_ICON_CHECKBOX_BG, false)
				setNodeVisibleByTag(cell, TAG_ICON_CHECKBOX, false)
				setNodeVisibleByTag(cell, TAG_ICON_SELECTED, false)
				setNodeVisibleByTag(cell, TAG_TXT_EQUIPED , true)
			else	
				setNodeVisibleByTag(cell, TAG_TXT_ENABLEEVOLUTION, false)

				setNodeVisibleByTag(cell, TAG_ICON_SELLCOIN, true)
				setNodeVisibleByTag(cell, TAG_TXT_SELLCOIN, true)
				setTextByTag(cell, TAG_TXT_SELLCOIN, MetaManager.treasure_meta[treasureInfo.metaId].basicPrice)
				setNodeVisibleByTag(cell, TAG_TXT_EXP, false)

				setNodeVisibleByTag(cell, TAG_ICON_CHECKBOX_BG, true)
				setNodeVisibleByTag(cell, TAG_TXT_EQUIPED , false)
				
				local selected = false;
				for k,v in pairs(idsToSell)
				do
					if v == treasureInfo.treasureId then
						selected = true;
						break;
					end
				end
				setNodeVisibleByTag(cell, TAG_ICON_CHECKBOX, selected)
				setNodeVisibleByTag(cell, TAG_ICON_SELECTED, selected)
			end

			local cardName
			if treasureInfo.cardId ~= 0 then
				if treasureInfo.cardId > 0 then
					for k,v in pairs(DataManager.getCardsData())
					do
						if v.cardId == treasureInfo.cardId then
							cardName = getTextByKey(MetaManager.card_meta[v.metaId].name)
							break;
						end
					end
				end
			end

			if cardName then
				local str = Localization:getInstance():getText("bag_EquippedText", {cardname = cardName})
				setTextByTag(cell , TAG_TXT_EQUIPED , str, true)
				setNodeVisibleByTag(cell, TAG_TXT_CHALLENGE, true)
				setNodeVisibleByTag(cell, TAG_ICON_CHALLENGE, true)
				setNodeVisibleByTag(cell, TAG_ICON_CHECKBOX_BG, false)
				setNodeVisibleByTag(cell, TAG_ICON_CHECKBOX, false)
				setNodeVisibleByTag(cell, TAG_ICON_SELECTED, false)
			else
				if (queueTreasureList[treasureInfo.treasureId] or treasureInfo.lock) then 
					setNodeVisibleByTag(cell, TAG_ICON_CHECKBOX_BG, false) --不显示卖出的框框
					setNodeVisibleByTag(cell, TAG_ICON_CHECKBOX, false)
				end
				setNodeVisibleByTag(cell, TAG_TXT_EQUIPED , false)
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
		local selectedCell = SELF.tableUI:cellAtIndex(evt.data):getChildByTag(TABLEVIEW_CELL_TAG)
		self._data = SELF["treasure_data"][evt.data + 1]

		if BackpackUIStatus == BACKPACK_STATUS.CHECKBOX then
			if queueTreasureList[SELF._data.treasureId] == nil and not self._data.lock then
				if SELF._data.cardId <= 0 then
					local selected = false 
					for k,v in pairs(idsToSell)
					do
						if v == SELF._data.treasureId then
							selected = true;
							table.remove(idsToSell, k)
							SELF.sellPrice = SELF.sellPrice - MetaManager.treasure_meta[SELF._data.metaId].basicPrice
							break;
						end
					end
					if not selected then
						table.insert(idsToSell, SELF._data.treasureId)
						SELF.sellPrice = SELF.sellPrice + MetaManager.treasure_meta[SELF._data.metaId].basicPrice
					end
					setNodeVisibleByTag(selectedCell, TAG_ICON_CHECKBOX, not selected)		
					setNodeVisibleByTag(selectedCell, TAG_ICON_SELECTED, not selected)
					
					SELF:setSellMenuVisible(#idsToSell > 0)
				end
			end
		elseif BackpackUIStatus==BACKPACK_STATUS.OPTION then
			if SELF.argv.enterScene == "CardQueueScene"  then
				
				--获取要修改的内存数据
				local GameData = DataManager.getGameInitData()
				local cards = DataManager.getCardsData()
				local treasure = DataManager.getTreasuresData()
			
				local originalCardId = 0 --表示已经装备了这个宝物的卡牌Id 不一定有
				for _, aEquip in pairs(treasure) do
					if (aEquip.treasureId == SELF._data.treasureId) then
						if (aEquip.cardId ~= 0) then
							originalCardId = aEquip.cardId 
						end
						break
					end
				end
				
				local function afterSetupEquip(e)
					SELF.waitRequest = false;
					g_shouldCalc = true;

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
					
					--给目标卡牌上宝宝
					local nowEquipId = 0
					for _, aEquip in pairs (treasure) do
						if aEquip.cardId == SELF.argv.params.cardId then 
							nowEquipId = aEquip.treasureId
						end
					end
					aCard.treasureId = SELF._data.treasureId
					GameData.sharkCards.sharkCards[cardKey] = aCard
					
					--给原卡牌上宝宝
					if (originalCard) then
						originalCard.treasureId = nowEquipId
					end
					GameData.sharkCards.sharkCards[originalCardKey] = originalCard
					
					--宝宝上对应的卡牌信息
					for _, aEquip in pairs(treasure) do
						if (aEquip.treasureId == SELF._data.treasureId) then
							aEquip["cardId"] = aCard.cardId
						else
							if aEquip.treasureId == nowEquipId then
								aEquip["cardId"] = originalCard and originalCard.cardId or 0
							end
						end
					end

					--阵容信息
					if GameData.sharkUser.level >= (MetaManager.game_meta.gameSettingConfig.lineupUnlockLevel or 43) then  
						local BattleArrayId = GameData.sharkUserExtendMore.battleArrayId
						for k,v in pairs(GameData.sharkUserBattleArray[BattleArrayId].sharkUserQueue) do
							if (originalCard) then
								if (originalCard.cardId == v.cardId) then v.treasureId = originalCard.treasureId end
							end
							if (aCard.cardId == v.cardId) then v.treasureId = aCard.treasureId end
						end
					end							

					DataManager.setGameInitData(GameData)
					DataManager.setTreasuresData(treasure)
					
					if SELF.argv.returnScene == "CardQueueScene" then
						if (SELF.argv.params and SELF.argv.params.backToTreasure) then
							local argv = { enterScene="TreasureBackpackScene", returnScene=(SELF.argv.params and SELF.argv.params.preReturnScene), params={backToTreasure = true} }
							SELF:replaceScene(CardQueueScene, argv)
						else
							local argv = {enterScene="TreasureBackpackScene",returnScene=(SELF.argv.params and SELF.argv.params.preReturnScene),params=nil}
							SELF:replaceScene( CardQueueScene , argv)
						end
					elseif SELF.argv.returnScene == "CardRebirthScene" then
						local argv = {enterScene="TreasureBackpackScene", params=SELF._data}
	                	SELF:replaceScene(CardRebirthScene , argv)						
					else
						local argv = {showStrength = true , params={}}
						SELF:replaceScene( TreasureBackpackScene , argv)
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
					local params = {cardId = SELF.argv.params.cardId, treasureId = SELF._data.treasureId}

					--发请求
					SetupTreasureRequest.sendRequest(params ,afterSetupEquip , afterSetupEquipFailed )
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
					local equipName = MetaManager.treasure_meta[SELF._data.metaId].nameKey
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
			elseif SELF.argv.enterScene == "CardRebirthScene"  then
				local argv = {enterScene="TreasureBackpackScene", params=SELF._data}
            	SELF:replaceScene(CardRebirthScene , argv)		
			end
		elseif BackpackUIStatus==BACKPACK_STATUS.NORMAL then 
			local posInCell = selectedCell:convertToNodeSpace(evt.globalPosition)
			local itemPosX, itemPosY = selectedCell:getChildByTag(TAG_BTN_TRAIN):getPosition()
			local itemRect = {}
			itemRect.x = itemPosX
			itemRect.y = itemPosY - 66
			itemRect.width = 168
			itemRect.height = 66
			local event = {
				context = {
					container = self,
					treasureId = self._data.treasureId,
					SelectNum = 1,
					NewIndex = evt.data + 1, --升星
					enterAndReturnScene = "TreasureBackpackScene"
				}
			}
			if inArea(posInCell.x, posInCell.y, itemRect) then
				if TreasureManager.isLevelSaigou( self._data ) then --升星
					if TreasureManager.getTreasureRare( self._data ) >= 6 then
						SuspensionLabel:showContent(SELF, getTextByKey("Treasure_tips23"))
					else
						event.context.SelectNum = 3
						TreasureSystem.PopTreasureInfoPanel( event )
					end
				else --强化
					if TreasureManager.isSaigou( self._data ) then
						SuspensionLabel:showContent(SELF, getTextByKey("Treasure_tips21"))
					else
						event.context.SelectNum = 2
						TreasureSystem.PopTreasureInfoPanel( event )
					end

				end
				return
			end
			TreasureSystem.PopTreasureInfoPanel( event )
		end
	end

	
	local cell_height = 206  --原版185
	local buttonTag = {}
	table.insert(buttonTag, TAG_BTN_TRAIN)
	table.insert(buttonTag, TAG_BTN_UPSTAR)

	local result = {
		item_width = 708.65,
		table_width = 708.65,
		table_height = 836.70,
		table_posX = 0.85,
		table_posY = 120.80
	}
  	local renderer = TreasureBackpackSceneRenderer.new(result.item_width, cell_height)
  	local list = TableView:create(renderer, result.table_width, result.table_height, TABLEVIEW_CELL_TAG, buttonTag)
	
  	list:addEventListener(DisplayEvents.kTouchItem, onListItemTouch )
  	list:setPosition(ccp(result.table_posX, result.table_posY))
  	return list
end

local MAXCELLAMOUNT = 6
function TreasureBackpackScene:generateAnimatedCells() --做背包效果
	local function getStartIndexAndEndIndex(tableview)
		if tableview.refCocosObj==nil then
			do return 9999 end
		end
		local offsetY = tableview:getContentOffset().y
		local container = tableview.refCocosObj:getContainer()
		local minOffsetY = tableview:getViewSize().height - container:getContentSize().height * container:getScaleY()
		return math.floor((offsetY - minOffsetY) / 206)  --原版185
	end

	self.animatedCells = {}
	for i = getStartIndexAndEndIndex(SELF.tableUI), #self.treasure_data - 1
	do
		local cell = SELF.tableUI:cellAtIndex(i)
		if cell then
			table.insert(self.animatedCells, cell)
			if table.getn(self.animatedCells) >= MAXCELLAMOUNT then
				break;
			end
		end
	end
end

function TreasureBackpackScene:buyGridRequest(buy)
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

	local function afterBuyGrid(  )
		SuspensionLabel:showContent(SELF, getTextByKey("Treasure_text_33"))
		SELF:recalcBagInfo()
	end
		
	BuyTreasureGridRequest.sendRequestDefalut(afterBuyGrid)
end

function TreasureBackpackScene:recalcBagInfo()
	SELF.usedSpace = TreasureManager.calcTreasureUsingGridNum()
	SELF.totalSpace = TreasureManager.calcTreasureTotalGridNum()
	SELF.mainUI:getChildByName("inventory_title"):getChildByName("txt_inventory_num"):getChildByName("font"):setString(tostring(SELF.usedSpace).."/" .. SELF.totalSpace)
end

function TreasureBackpackScene:onSellFinish()
	SELF.usedSpace = TreasureManager.calcTreasureUsingGridNum()
	SELF.totalSpace = TreasureManager.calcTreasureTotalGridNum()
	SELF.mainUI:getChildByName("inventory_title"):getChildByName("txt_inventory_num"):getChildByName("font"):setString(tostring(SELF.usedSpace).."/" .. SELF.totalSpace)

	if #SELF.treasure_data == 0 and not tosetvisible then
		setCocosObjectColor(SELF.btnSell.display, ccc3(80, 80, 80))
		SELF.btnSell:setEnable(false)
		SELF.noSpiritText:setVisible(true) 
		SELF.getSpiritDisplay:setVisible(true) 
	end
	SuspensionLabel:showContent(SELF, getTextByKey("Treasure_text_38"))
	
	runChangeBtnSellAction()
	BackpackUIStatus = BACKPACK_STATUS.NORMAL
	idsToSell = {}
	
end

function TreasureBackpackScene:setSellMenuVisible(visible)
	local function setSellMenuText()
		local text = ""
		text = getTextByKey("Treasure_text_42")
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
				SELF.targetInfoPanel = ItemSellMessageBoxPanel:create( SELF , {treasureData= idsToSell , bagCategory = BAGCATEGORY.treasure}) 
				SELF:addChild(SELF.targetInfoPanel)
				SELF.targetInfoPanel:scaleIn()
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

function TreasureBackpackScene:dispose()
	BaseUIScene.dispose(self)
end

function TreasureBackpackScene:doEnterAnimation()
  self:preEnterAnimation()
  self:startEnterAnimation()
end

function TreasureBackpackScene:preEnterAnimation()
  BaseUIScene.preEnterAnimation(self)
end

function TreasureBackpackScene:startEnterAnimation()
  BaseUIScene.startEnterAnimation(self)
  self:generateAnimatedCells()
  local function enterActionFinished()
    self:nodeAnimationFinished()
  end

  ViewControlUtil.showTableViewAction(SELF.tableUI, visibleSize)
  
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

  for k,v in pairs(self.group4)
  do
	v:setPositionX(v:getPositionX() - visibleSize.width)
	v:runAction(CCMoveBy:create(TOTALENTERDURATION - CELLENTERDURATION, ccp(visibleSize.width, 0)))
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

	if self.argv.params and self.argv.params.showSellFinish then
		SuspensionLabel:showContent(self, getTextByKey("sellItem_spiritSuccess"))
	end
end

function TreasureBackpackScene:sufEnterAnimation()
	BaseUIScene.sufEnterAnimation(self)
	
	--facebook share first get purple/orange spirt info
	if FacebookShareManager.isOpenFacebookShareFunc() then
		local purpleSpirit = false
		local oriangeSpirit = false
		for k,v in pairs(SELF.treasure_data) do
			if purpleSpirit and oriangeSpirit then
				break
			end
			--purple
			if v.quality == 4 and not purpleSpirit then
				if FacebookShareManager.facebookShareSpirit(FacebookSpiritShareID.PURPLE) then
					return
				else
					purpleSpirit = true
				end
			end
			--orange
			if v.quality == 5 and not oriangeSpirit then
				if FacebookShareManager.facebookShareSpirit(FacebookSpiritShareID.ORANGE) then
					return
				else
					oriangeSpirit = true
				end
			end
		end
	end
end

function TreasureBackpackScene:doExitAnimation()
  self:preExitAnimation()
  self:startExitAnimation()
end

function TreasureBackpackScene:preExitAnimation()
  BaseUIScene.preExitAnimation(self)
  self.tableUI.refCocosObj:setScrollBar(nil)
  self.tableUI.refCocosObj:setScrollTrack(nil)
end

function TreasureBackpackScene:startExitAnimation()
  BaseUIScene.startExitAnimation(self)
  self:generateAnimatedCells()
  local function enterActionFinished()
	self.mainUI:removeChild(SELF.tableUI, true) 
    self:nodeAnimationFinished()
  end

  ViewControlUtil.disappearTableViewAction(SELF.tableUI, visibleSize)
  
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

  for k,v in pairs(self.group4)
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
  
	
end

function TreasureBackpackScene:sufExitAnimation()
	BaseUIScene.sufExitAnimation(self)
end

function TreasureBackpackScene:back()
	if SELF.argv.returnScene == "CardQueueScene" then
		if (SELF.argv.params and SELF.argv.params.backToTreasure) then
			local argv = { enterScene="TreasureBackpackScene", returnScene=(SELF.argv.params and SELF.argv.params.preReturnScene), params={backToTreasure = true} }
			SELF:replaceScene(CardQueueScene, argv)
		else
			SELF:replaceScene(CardQueueScene, {enterScene="TreasureBackpackScene", returnScene= (SELF.argv.params and SELF.argv.params.preReturnScene)})
		end
	elseif SELF.argv.returnScene == "TreasureBackpackScene" then
		SELF:replaceScene( TreasureBackpackScene )
	elseif SELF.argv.returnScene == "CardRebirthScene" then
		SELF:replaceScene(CardRebirthScene)
    else
        SELF:replaceScene(MainMenuScene)
    end
end

function TreasureBackpackScene:setTableViewsEnabled( v )
	if (v) then
		SELF.touchDisableSetTimes = SELF.touchDisableSetTimes - 1
		if (SELF.touchDisableSetTimes <= 0) then
			SELF.tableUI:setTouchEnabled(v)
			SELF.mainUI:setTouchEnabled(v)
			SELF.tableVeiwEnableStatus = v
		end
	else
		SELF.touchDisableSetTimes = SELF.touchDisableSetTimes + 1
		SELF.tableUI:setTouchEnabled(v)
		SELF.mainUI:setTouchEnabled(v)
		SELF.tableVeiwEnableStatus = v
	end
end