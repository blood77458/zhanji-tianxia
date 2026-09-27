require "hecore.display.CocosObject"
require "hecore.display.Director"
require "hecore.display.Scene"
require "hecore.ui.LayoutBuilder"
require "canon.scene.LoadingScene"
require "canon.customUI/CanonCard"
require "canon.scene.BaseUIScene"

require "canon.request.UpgradeMatrixRequest"
require "canon.panel.MatrixUpgradePanel"

require "canon.panel.MagicCircleIntroducePanel"

MATRIX_ID = {
EIGHT_MATRIX = 10,--八门阵
}

local curSharkMatricesData
local previousBattleCount

local function getMatrixLevelIdByIdAndLevel(matrixId, level)--根据ID和LEVEL获取MATRIX_LEVEL的ID
	local matrixLevelId = 1000
	for k,data in pairs(MetaManager.matrix_level) do
		if data.matrixObtain == matrixId and data.matrixLevel == level then
			matrixLevelId = data.id
			break;
		end
	end
	return matrixLevelId
end

local function completeCurSharkMatricesData()--自动补全数据
	for k, data in pairs(curSharkMatricesData) do 
		if not data.matrixLevelId then
			data.matrixLevelId = getMatrixLevelIdByIdAndLevel(data.matrixId, data.matrixLevel)
		end
		
		if not data.sharkMatrixGrids then
			data.sharkMatrixGrids = {}
		end
		local previousGridsTable = data.sharkMatrixGrids
		data.sharkMatrixGrids = {}
		
		for key ,value in pairs(previousGridsTable) do 
			data.sharkMatrixGrids[value.posId + 1] = value
		end
		
		local grids = string.split(MetaManager.matrix_level[data.matrixLevelId].gridUnlock, '|')
		for key ,value in ipairs(grids) do
			if data.sharkMatrixGrids[key] then
				data.sharkMatrixGrids[key].matrixGridId = tonumber(value)
			else
				data.sharkMatrixGrids[key] = {posId = key - 1, cardId = -1, matrixGridId = tonumber(value)}
			end
		end
		
		local bonusAtrrsTable = CommonManager:getMatrixBonus(data)
		if not data.hpBonus then
			data.hpBonus = bonusAtrrsTable.hp
		end
		if not data.atkBonus then
			data.atkBonus = bonusAtrrsTable.att
		end
		if not data.defBonus then
			data.defBonus = bonusAtrrsTable.def
		end
		
	end
end

local function getCurSharkMatricesData()--获取阵列数据
	if not curSharkMatricesData then
		curSharkMatricesData = DataManager.getSharkMatricesData()
		for k, data in pairs(MetaManager.matrix_meta) do--添加已解锁数据
			local alreadyInMatrix = false
			local isUnlock = (data.unlockMatrixId == 0)
			for curKey,curValue in pairs(curSharkMatricesData) do 
				if data.id == curValue.matrixId then
					alreadyInMatrix = true
					break;
				elseif data.unlockMatrixId == curValue.matrixId then
					local matrixLevelId = getMatrixLevelIdByIdAndLevel(curValue.matrixId, curValue.matrixLevel)
					isUnlock = (MetaManager.matrix_level[matrixLevelId].nextMatrix == 0)
					data.matrixLevelId = matrixLevelId
				end
			end
			
			if not alreadyInMatrix and isUnlock then
				table.insert(curSharkMatricesData, {matrixId = data.id, matrixLevel = 0})
			end
		end
		completeCurSharkMatricesData()
		
		local function matricesSortFun(a, b)--阵列排序
			return a.matrixId < b.matrixId
		end
		table.sort(curSharkMatricesData, matricesSortFun)
	end
	return curSharkMatricesData
end

local function isMatrixLevelMaxByMatrixLevelId(matrixLevelId)
	return (MetaManager.matrix_level[matrixLevelId].nextMatrix == 0)
end

MatrixScene = class(BaseUIScene)
local visibleSize = CCSizeMake(720, 1280)

function MatrixScene:ctor()
	self.title = getTextByKey("matrix_enter")
	curSharkMatricesData = nil;
	self.curMatrixIndex = 1
	self.cardDataTable = {}
	self.curSceneEnum = SceneEnum.MatrixScene
end

function MatrixScene:create( argv )
  if argv then 
    self.argv = argv 
  else
    self.argv = {enterScene=nil,returnScene=nil,params={}}
  end
    
  local scene = MatrixScene.new()
		
  scene:initScene()
  return scene
end

function MatrixScene:onInit()	
	BaseUIScene.initBackGround(self)
	
	for k, v in pairs(DataManager.getCardsData()) do
		self.cardDataTable[v.cardId] = v
	end
	
	getCurSharkMatricesData()
	
	self.builder = LayoutBuilder:createWithContentsOfFile("scene/camp.json")
	self.builder.useArtLabelTTF = true
	
	self:showMatrix(self.curMatrixIndex)
	BaseUIScene.onInit(self)
	
	if previousBattleCount and self.argv.enterScene == "BackpackScene" then
		--显示战斗力更新 FIGHT_CAPACITY_MODIFY by zheng.che @ 2014-12-22
		DataManager.fightCapacityMaybeUpdated()
	end
	previousBattleCount = nil;

	if self.argv.params.cardId and self.argv.params.infoPanelTabType then
		local gridInfo
		for _, aGridInfo in pairs(curSharkMatricesData[self.curMatrixIndex].sharkMatrixGrids) do
			if aGridInfo.cardId == self.argv.params.cardId then
				gridInfo = aGridInfo
				break
			end
		end
		self.selectPosId = gridInfo.posId
		self._data = self.cardDataTable[gridInfo.cardId]
		self.targetInfoPanel = CardInfoNewPanel:create( self, nil, nil, {tabType = self.argv.params.infoPanelTabType})
		PopoutManager:sharedManager():popout(self.targetInfoPanel, kPopoutDir.kScale, true, false ,self) 
	end
	
end

function MatrixScene:completeCurSharkMatricesData()
	completeCurSharkMatricesData()
end

function MatrixScene.filterCardFunc(cardList)
	local result = {}
	
	local tempQueue ={}

	-- 如果是填空格，就走这套逻辑
	-- 新规则，允许阵法中的武将直接互换by dangchao
	if MatrixScene.previousCardId == nil then
		for key, value in pairs(CommonManager.getQueueData()) do
			tempQueue[value] = key
		end
		
		for k, v in pairs(CommonManager:getMatrixCardData()) do
			tempQueue[v] = k
		end
	end

	
	for _, v in pairs(cardList) do
		if (v.cardId ~= MatrixScene.previousCardId) and (tempQueue[v.cardId] == nil) then
			table.insert(result, v)
		end
	end
	return result
end

function MatrixScene:changeMatrixCard(cardId)
	MatrixScene.previousCardId = cardId

	local argv = {
	enterScene="MatrixScene",
	returnScene="MatrixScene",
	params=
	{filter=BACKPACK_FILTER.CARD,
	filterFunc = MatrixScene.filterCardFunc,
	matrixId = curSharkMatricesData[self.curMatrixIndex].matrixId,
	posId = self.selectPosId,
	previousCardId = cardId,
	isCardTrain = false,
	matrixGridType = MetaManager.matrix_grid[curSharkMatricesData[self.curMatrixIndex].sharkMatrixGrids[self.selectPosId + 1].matrixGridId].type
	}
	}
	previousBattleCount = CommonManager:getLocalPlayerStrength()
  self:replaceScene( BackpackScene, argv)
end

function MatrixScene:createMainUIByMatrixId(matrixId)
	local function onClickUpgradeButton(evt)
		self.targetInfoPanel = MatrixUpgradePanel:create(self, curSharkMatricesData[self.curMatrixIndex])
		PopoutManager:sharedManager():popout(self.targetInfoPanel, kPopoutDir.kScale, true, false ,self)
	end
	
	local function onClickDisableGrid(evt)
		SuspensionLabel:showContent(self, getTextByKey("grid_unlock_remind"))
	end
	
	local function onClickGrid(evt)
		local gridInfo = curSharkMatricesData[self.curMatrixIndex].sharkMatrixGrids[evt.context]
		self.selectPosId = gridInfo.posId
		if gridInfo.cardId > 0 then
			self._data = self.cardDataTable[gridInfo.cardId]
			local unsavedCardId = CardTrainingScene.getUnsavedCardId()
			local aPanel
			local showUnsavedPanel
			if unsavedCardId then
				self._data = self.cardDataTable[unsavedCardId]
				aPanel = CardInfoNewPanel:create( self, nil, nil, {tabType = tabTypeEnum.cultivate, forceClose = true})
				showUnsavedPanel = function()
					local aScene = Director.sharedDirector():getRunningScene()
					local aPanel = AssistantMessageBoxPanel:create( aScene, AsMessageBoxType.notFinished )
				    aScene:addChild(aPanel)
				    aPanel:scaleIn()
				end
			else
				aPanel = CardInfoNewPanel:create( self)
			end
			self.targetInfoPanel = aPanel
			PopoutManager:sharedManager():popout(self.targetInfoPanel, kPopoutDir.kScale, true, false ,self, nil, showUnsavedPanel)
		else--goto backpackscene
			self:changeMatrixCard()
		end
	end
	
	self.disableGridButtons = {}
	self.enableGridButtons = {}
	
	local matrixView
	if matrixId == MATRIX_ID.EIGHT_MATRIX then
		matrixView = self.builder:build("camp")
		self:addChild(matrixView)	
		matrixView:getChildByName("txt_camp_5"):getChildByName("txt"):setString(getTextByKey("matrix_add_remind"))
		matrixView:getChildByName("txt_camp_2"):getChildByName("txt"):setString(getTextByKey("matrix_skill_remind"))
		self.upgradeButton = Button:create(matrixView:getChildByName("btn_camp_lvup"))
		self.upgradeButton:addEventListener(Events.kStart, onClickUpgradeButton)
		
		for i = 1, 8 do 
			self.disableGridButtons[i] = Button:create(matrixView:getChildByName("camp_ball_combine_" .. tostring(i)))
			self.disableGridButtons[i]:addEventListener(Events.kStart, onClickDisableGrid)
			self.enableGridButtons[i] = Button:create(matrixView:getChildByName("camp_item" .. tostring(i)))
			self.enableGridButtons[i]:addEventListener(Events.kStart, onClickGrid, i)
		end
	end
	
	--添加阵魂灯显示begin
	--刷新镇魂信息
	local curMatrixId = MetaManager.getCurInBattleMatrixId()
	MagicCircleManager.RefreshMagicCircleInfoByMatrixId(curMatrixId)
	matrixView:getChildByName("camp_ball_combine_9"):setVisible(false)
	matrixView:getChildByName("camp_item9"):setVisible(false)
	local ballPos = matrixView:getChildByName("camp_ball_combine_9"):getPosition()
	local magicCircleOpen = MetaManager.game_meta.gameSettingConfig.magicCircleOpen or 7
	--以下三状态 表示 阵魂灯不同状态下 flash中要显示图层的名字
	local magicCircleBallStatus = "camp_ball_inactive"
	local magicCircleFazhenCircleStatus = "FZ1_1"
	local magicCircleFazhenSquareStatus = "FZ3_1"
	local curMagicCircleStatus = MagicCircleManager.GetCurMagicCircleStatus()
	
	local function showMagicCircleStatus()
		local ball = FlashSprite:create("EVO2/zhenhun_magicCircle")
		if curMagicCircleStatus == MagicCircleStatus.Lock then
			ball:changeAnimation(0)
		elseif curMagicCircleStatus == MagicCircleStatus.White then
			ball:changeAnimation(0)
		elseif curMagicCircleStatus == MagicCircleStatus.Green then
			magicCircleBallStatus = "camp_green"
			magicCircleFazhenCircleStatus = "FZ1_2"
			magicCircleFazhenSquareStatus = "FZ3_2"
			
			ball:changeAnimation(1)
		elseif curMagicCircleStatus == MagicCircleStatus.Blue then
			magicCircleBallStatus = "camp_ball"
			magicCircleFazhenCircleStatus = "FZ1"
			magicCircleFazhenSquareStatus = "FZ3"
			
			ball:changeAnimation(2)
		end
		--控制周围8个球的显示状态
		for i = 1,8 do
			matrixView:getChildByName("camp_ball_combine_" .. tostring(i)):getChildByName("camp_ball_inactive"):setVisible(false)
			matrixView:getChildByName("camp_ball_combine_" .. tostring(i)):getChildByName("camp_green"):setVisible(false)
			matrixView:getChildByName("camp_ball_combine_" .. tostring(i)):getChildByName("camp_ball"):setVisible(false)
			matrixView:getChildByName("camp_ball_combine_" .. tostring(i)):getChildByName(magicCircleBallStatus):setVisible(true)
		end
		--控制法阵外圆的显示状态
		matrixView:getChildByName("FZ1"):setVisible(false)
		matrixView:getChildByName("FZ1_1"):setVisible(false)
		matrixView:getChildByName("FZ1_2"):setVisible(false)
		matrixView:getChildByName(magicCircleFazhenCircleStatus):setVisible(true)
		--控制法阵中间方块的显示状态
		matrixView:getChildByName("FZ3"):setVisible(false)
		matrixView:getChildByName("FZ3_1"):setVisible(false)
		matrixView:getChildByName("FZ3_2"):setVisible(false)
		matrixView:getChildByName(magicCircleFazhenSquareStatus):setVisible(true)
		
		--呼吸灯效果
		if curMagicCircleStatus == MagicCircleStatus.Green or curMagicCircleStatus == MagicCircleStatus.Blue then
			local fadeDuring = 1.6
			local fadeToMin = 90
			local fadeToMax = 255
			local fadeTo = CCFadeTo:create(fadeDuring,fadeToMin)
			local fadeToReverse = CCFadeTo:create(fadeDuring,fadeToMax)
			matrixView:getChildByName(magicCircleFazhenSquareStatus):runAction(CCRepeatForever:create(CCSequence:createWithTwoActions(fadeTo, fadeToReverse)))
			for i = 1,4 do
				local fadeTo = CCFadeTo:create(fadeDuring,fadeToMin)
				local fadeToReverse = CCFadeTo:create(fadeDuring,fadeToMax)
				matrixView:getChildByName(magicCircleFazhenCircleStatus):getChildByName(""..i):runAction(CCRepeatForever:create(CCSequence:createWithTwoActions(fadeTo, fadeToReverse)))
			end
			
		end
		--控制中心动画球的显示状态
		
		ball:setPosition(ballPos.x,ballPos.y)
		matrixView:addChild(CocosObject.new(ball))
	end
	showMagicCircleStatus()
	
	--阵魂灯按钮
	local function onMagciCircleBtnClick(event, x, y)
		if curMagicCircleStatus == MagicCircleStatus.Lock then
			SuspensionLabel:showContent(self, getTextByKey("magicCircle_babytalk2",{num = magicCircleOpen}))
		else
			self.targetInfoPanel = MagicCircleIntroducePanel:create( self)
			PopoutManager:sharedManager():popout(self.targetInfoPanel, kPopoutDir.kScale, true, false ,self) 
		end
	end
	local btnLayerSize = matrixView:getChildByName("camp_ball_combine_9"):getGroupBounds().size
	local magicCircleBtnLayer = Layer:create()
	magicCircleBtnLayer:changeWidthAndHeight(btnLayerSize.width, btnLayerSize.height)
	magicCircleBtnLayer:setPosition(ccp(ballPos.x - btnLayerSize.width/2,ballPos.y - btnLayerSize.height/2))
	local magicCircleBtn = Button:create(magicCircleBtnLayer)
	magicCircleBtn:addEventListener(Events.kStart, onMagciCircleBtnClick )
	matrixView:addChild(magicCircleBtnLayer)
	--添加阵魂灯显示end
	return matrixView
end

function MatrixScene:showMatrix(matrixIndex)--显示阵列
	local previousUI = self.mainUI 
	self.mainUI = self:createMainUIByMatrixId(curSharkMatricesData[matrixIndex].matrixId)
	if previousUI then--runaction todo
		previousUI:removeFromParentAndCleanup(true)
	else -- immediately show
	end
	self:refreshMatrixData(matrixIndex)
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

function MatrixScene:refreshMatrixData(matrixIndex)--刷新加成，上阵卡牌，等级，按钮等信息
	if not matrixIndex then
		matrixIndex = self.curMatrixIndex
	end
	self.mainUI:getChildByName("txt_camp_1"):getChildByName("txt"):setString("LV:" .. curSharkMatricesData[matrixIndex].matrixLevel)
	self.mainUI:getChildByName("txt_camp_value"):getChildByName("txt"):setString(tostring(curSharkMatricesData[matrixIndex].atkBonus))
	self.mainUI:getChildByName("txt_camp_value2"):getChildByName("txt"):setString(tostring(curSharkMatricesData[matrixIndex].defBonus))
	self.mainUI:getChildByName("txt_camp_value3"):getChildByName("txt"):setString(tostring(curSharkMatricesData[matrixIndex].hpBonus))
	
	local upgradeEnable = not isMatrixLevelMaxByMatrixLevelId(curSharkMatricesData[matrixIndex].matrixLevelId)
	self.upgradeButton:setEnable(upgradeEnable)
	self.mainUI:getChildByName("btn_camp_lvup"):getChildByName("btn"):setVisible(upgradeEnable)
	if upgradeEnable then
		self.mainUI:getChildByName("btn_camp_lvup"):getChildByName("txt"):setString(getTextByKey("matrix_upgrade_button"))
	else
		self.mainUI:getChildByName("btn_camp_lvup"):getChildByName("txt"):setString(getTextByKey("matrix_level_max_remind"))
	end
	
	for k, data in ipairs(curSharkMatricesData[matrixIndex].sharkMatrixGrids) do 
		self.enableGridButtons[k].display:getChildByName("normal_card_small"):setVisible(false)
		if tonumber(data.matrixGridId) == 0 then--未开启
			--self.mainUI:getChildByName("camp_ball_combine_" .. tostring(k)):setVisible(true)
			--self.mainUI:getChildByName("camp_item" .. tostring(k)):setVisible(false)
			self.disableGridButtons[k]:setEnable(true)
			self.disableGridButtons[k].display:setVisible(true)
			self.enableGridButtons[k]:setEnable(false)
			self.enableGridButtons[k].display:setVisible(false)
		else
			self.disableGridButtons[k]:setEnable(false)
			self.disableGridButtons[k].display:setVisible(false)
			self.enableGridButtons[k]:setEnable(true)
			self.enableGridButtons[k].display:setVisible(true)
			local cardDisplay = self.enableGridButtons[k].display:getChildByName("showGridCard")
			if cardDisplay then
				cardDisplay:removeFromParentAndCleanup(true)
			end
			
			local gridType = MetaManager.matrix_grid[data.matrixGridId].type
			if gridType == 1 then--atk
				self.enableGridButtons[k].display:getChildByName("icon_combine"):getChildByName("icon_def"):setVisible(false)
				self.enableGridButtons[k].display:getChildByName("icon_combine"):getChildByName("icon_atk"):setVisible(true)
				self.enableGridButtons[k].display:getChildByName("icon_combine"):getChildByName("icon_hp"):setVisible(false)
			elseif gridType == 2 then--def
				self.enableGridButtons[k].display:getChildByName("icon_combine"):getChildByName("icon_def"):setVisible(true)
				self.enableGridButtons[k].display:getChildByName("icon_combine"):getChildByName("icon_atk"):setVisible(false)
				self.enableGridButtons[k].display:getChildByName("icon_combine"):getChildByName("icon_hp"):setVisible(false)
			else--hp
				self.enableGridButtons[k].display:getChildByName("icon_combine"):getChildByName("icon_def"):setVisible(false)
				self.enableGridButtons[k].display:getChildByName("icon_combine"):getChildByName("icon_atk"):setVisible(false)
				self.enableGridButtons[k].display:getChildByName("icon_combine"):getChildByName("icon_hp"):setVisible(true)
			end
			
			local addSprite = self.enableGridButtons[k].display:getChildByName("formation_5")
			
			if data.cardId > 0 then--有出阵卡牌
				local cardMeta = MetaManager.card_meta[self.cardDataTable[data.cardId].metaId]
				local aCardData = getCardInfoFromInitData(data.cardId)
				local showGridCard = getHeadIconCanonCardByMetaId(CommonManager:changeAvatarByCardInfo( aCardData ), aCardData.lock)
				local fakeCardSprite = self.enableGridButtons[k].display:getChildByName("normal_card_small")
				showGridCard:setPositionXY(fakeCardSprite:getPositionX(), fakeCardSprite:getPositionY())
				showGridCard.name = "showGridCard";
				self.enableGridButtons[k].display:addChildAt(showGridCard, addSprite:getZOrder() + 1)
				self.enableGridButtons[k].display:getChildByName("txt_item_name"):getChildByName("txt_item_name"):setString(getTextByKey(cardMeta.name))
				addSprite:setVisible(false)
			else
				self.enableGridButtons[k].display:getChildByName("txt_item_name"):getChildByName("txt_item_name"):setString(getTextByKey("gridName_" .. tostring(k)))
				addSprite:setVisible(true)
			end
		end
	end
	
end

function MatrixScene:refreshUIForPanelInfo(aCardId, extraParams)
	self.cardDataTable = {}
	for k, v in pairs(DataManager.getCardsData()) do
		self.cardDataTable[v.cardId] = v
	end
	getCurSharkMatricesData()
	self.mainUI:getChildByName("txt_camp_value"):getChildByName("txt"):setString(tostring(curSharkMatricesData[self.curMatrixIndex].atkBonus))
	self.mainUI:getChildByName("txt_camp_value2"):getChildByName("txt"):setString(tostring(curSharkMatricesData[self.curMatrixIndex].defBonus))
	self.mainUI:getChildByName("txt_camp_value3"):getChildByName("txt"):setString(tostring(curSharkMatricesData[self.curMatrixIndex].hpBonus))
	self:refreshMatrixData(self.curMatrixIndex)
end

function MatrixScene:getPanelInfoData(aCardId)
	for k, aCardData in pairs(self.cardDataTable) do
		if aCardData.cardId == aCardId then
			return aCardData
		end
	end
end

function MatrixScene:dispose()	
	BaseUIScene.dispose(self)
end

function MatrixScene:doEnterAnimation()
  self:preEnterAnimation()
  self:startEnterAnimation()
end

function MatrixScene:preEnterAnimation()
	CanonPlayBackgroundMusic("music/background.mp3", true)
  BaseUIScene.preEnterAnimation(self)
end

function MatrixScene:startEnterAnimation()
  BaseUIScene.startEnterAnimation(self)
  local function enterActionFinished()
    self:nodeAnimationFinished()
  end
  self.mainUI:setPositionX(self.mainUI:getPositionX() - visibleSize.width)
  local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(0.3, ccp(visibleSize.width, 0)))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.mainUI:runAction(CCSequence:create(arr))
end

function MatrixScene:sufEnterAnimation()
	BaseUIScene.sufEnterAnimation(self)
	CommonManager:checkEnableSkill(self)
	if GuideConfig.kMatrix == nil then
    GuideConfig.kMatrix = "Guide_Matrix"
  end
  ExeNewGuide( GuideConfig.kMatrix )
end

function MatrixScene:doExitAnimation()
  self:preExitAnimation()
  self:startExitAnimation()
end

function MatrixScene:preExitAnimation()
  BaseUIScene.preExitAnimation(self)
end

function MatrixScene:startExitAnimation()
  BaseUIScene.startExitAnimation(self)
  local function enterActionFinished()
      self:nodeAnimationFinished()
  end
  local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(0.3, ccp(-visibleSize.width, 0)))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.mainUI:runAction(CCSequence:create(arr))	
end

function MatrixScene:sufExitAnimation()
	BaseUIScene.sufExitAnimation(self)
end

function MatrixScene:back()
	self:replaceScene(CardQueueScene)
end