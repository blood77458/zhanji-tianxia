--------------------------------------------------------------------------------
-- CardTrainingScene.lua - 卡牌培养界面
-- author: fangzhou.long
-- date: 2013-08-14
--------------------------------------------------------------------------------
require "hecore.display.CocosObject"
require "hecore.display.Director"

require "hecore.ui.Button"
require "hecore.ui.LayoutBuilder"

require "canon.data.MetaManager"
require "canon.models.CommonManager"
require "canon.models.RewardManager"

require "canon.panel.AssistantMessageBoxPanel"

require "canon.scene.BaseUIScene"

require "canon.request.LoginServerRequest"
require "canon.request.CardTrainingRequest"
require "canon.request.SaveCardTrainRequest"
require "canon.request.GiveUpCardTrainRequest"
require "canon.request.GetPropsRequest"
require "canon.scene.BackpackScene"

require "canon.customUI.CanonCard"
require "canon.panel.AttributeChangePanel"
require "canon.data.MetaManager"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()
CardTrainingScene = class(BaseUIScene)

local cardInfo = {
  ["name"] = "关羽", --卡片名
  ["level"] = 999, --卡片等级
  ["usedPotential"] = 99999999, --卡片潜力点
  ["attTrainValue"] = 99999999, --卡片攻击力
  ["defTrainValue"] = 99999999, --卡片防御力
  ["hpTrainValue"] = 99999999, --卡片HP
}

function CardTrainingScene:ctor()
    self.title  = Localization:getInstance():getText("cardTrain_Title")
    self.mainUI = nil
	self.soulStone = nil --魂石数量
    self.trainLevelSelected = 1 --初始选择的培养等级
    self.trainStatus = nil
	self.trainConfig = MetaManager.getCardTrainConfig()--获取培养配置信息
	self.icons = {}
    self.labelTable = {}
end

function CardTrainingScene:create( argv )
    self.params = argv
	self.cardId = argv.params.card.cardId
    local s = CardTrainingScene.new()
    s:initScene()
    return s
end

----------------------------------------
-- 初始化UI界面
----------------------------------------
function CardTrainingScene:initUI()
  BaseUIScene.initBackGround(self)
  local builder = LayoutBuilder:createWithContentsOfFile("scene/card_new.json")
  builder.useArtLabelTTF = true
  self.mainUI = builder:build("card_cardTraining")
  
  self:initCardInfo()
  self:initCardTrainLevel()
  self:initBtns()
  --self.labelLayer = Layer:create()
  --self.labelArea:addChild(self.labelLayer)
  self:addChild(self.mainUI)
  BaseUIScene.onInit(self)
  
  if (self.trainStatus) then
    local aPanel = AssistantMessageBoxPanel:create( self, AsMessageBoxType.notFinished )
    self:addChild(aPanel)
    aPanel:scaleIn()
    
    self.labelTable = {}
    for key, value in pairs(self.unsavedInfo) do
      if (key=="unsavedAttTrainValue") then
        self.labelTable.atk = value
		if (value>0) then
			self.fireOnIcon = 1
		end
      elseif (key=="unsavedDefTrainValue") then
        self.labelTable.def = value
		if (value>0) then
			self.fireOnIcon = 2
		end
      elseif (key=="unsavedHpTrainValue") then
        self.labelTable.hp = value
		if (value>0) then
			self.fireOnIcon = 3
		end
      end
    end
    self:refreshLabel()
  end
end

----------------------------------------
-- 初始化函数
----------------------------------------
function CardTrainingScene:onInit()
	self.soulStone = CommonManager.getSubTableByKey(
		DataManager.getPropsData(),
		{name = "metaId", value = self.trainConfig.pydMetaId}
	)
	self.soulStone = self.soulStone and self.soulStone or {
		metaId = self.trainConfig.pydMetaId,
		amount = 0,
	}
	self:initCardData()
	--初始化场景UI
	self:initUI()
	--self.loading:setVisible(false)
end

local labelInfo = {
  ["cap"] = {},
  ["atk"] = {},
  ["def"] = {},
  ["hp"] = {},
}

----------------------------------------
----------------------------------------
function CardTrainingScene:refreshLabel()
  local area = self.mainUI:getChildByName("card_cardTraining_cardInfo")
  
  local numTable = {
      ["atk"] = self.labelTable.atk and self.labelTable.atk or 0,
      ["def"] = self.labelTable.def and self.labelTable.def or 0,
      ["hp"] = self.labelTable.hp and self.labelTable.hp or 0,
  }
  
  numTable.cap = numTable.atk + numTable.def + numTable.hp
  
  for key, aNumber in pairs( numTable ) do
    if (aNumber==0) then
	  labelInfo[key]:setVisible(false)
    else
	  local sprite = labelInfo[key]
      if (key == "cap") then
        labelInfo[key] = createNumberEffect(-aNumber, sprite:getPosition().x, sprite:getPosition().y, NumberColorEnum.blue, true, 1.2, true)
      elseif (aNumber>0) then
        labelInfo[key] = createNumberEffect(aNumber, sprite:getPosition().x, sprite:getPosition().y, NumberColorEnum.green, true, 1.2, true)
      else
        labelInfo[key] = createNumberEffect(aNumber, sprite:getPosition().x, sprite:getPosition().y, NumberColorEnum.red, true, 1.2, true)
      end
	  sprite:setVisible(false)
    end
	area:addChild(labelInfo[key])
  end
  
  self:refreshCardInfo()
end

----------------------------------------
----------------------------------------
function CardTrainingScene:initLabelInfo()
  local area = self.mainUI:getChildByName("card_cardTraining_cardInfo")
  --self.labelArea = area
  local nameStr = "card_lbl_parameter_add_"
  for key, value in pairs(labelInfo) do
    labelInfo[key] = area:getChildByName(nameStr .. key)
  end
  self:refreshLabel()
end

----------------------------------------
----------------------------------------
function CardTrainingScene:refreshCardInfo()
  local area = self.mainUI:getChildByName("card_cardTraining_cardInfo")
  
  local aCardNums = CommonManager:getSimpleCardProperties(self.cardId)
  local aCardMetaConfig = MetaManager.card_meta[cardInfo.metaId]
  local aCardRareConfig = MetaManager.card_rare[aCardMetaConfig.rare]
  aCardNums.potential = aCardRareConfig.addPotential * cardInfo.level
  
  local cardPotential = aCardNums.potential
  cardInfo.nowPotential = cardPotential-cardInfo.usedPotential
  
  area:getChildByName("card_txt_cardTraining"):getChildByName("txt_cardTraining"):setString(getTextByKey(cardInfo.name))
  area:getChildByName("card_txt_cardTrain_capacity_num"):getChildByName("font"):setString(cardInfo.nowPotential)
  --下方信息
  area:getChildByName("card_txt_card_icon_atk_num"):getChildByName("font"):setString(math.floor(aCardNums.att))
  area:getChildByName("card_txt_card_icon_def_num"):getChildByName("font"):setString(math.floor(aCardNums.def))
  area:getChildByName("card_txt_card_icon_hp_num"):getChildByName("font"):setString(math.floor(aCardNums.hp))
end

----------------------------------------
----------------------------------------
function CardTrainingScene:initCardInfo()
  local area = self.mainUI:getChildByName("card_cardTraining_cardInfo")
  --初始化文字
  --记录icon以便播放粒子特效
  self.icons[1] = area:getChildByName("card_icon_atk")
  self.icons[2] = area:getChildByName("card_icon_def")
  self.icons[3] = area:getChildByName("card_icon_hp")
  
  local card = area:getChildByName("card_frameM")
  local card2 = getBigCanonCardNoInfoByMetaId(cardInfo.metaId)
  self.icons[0] = card2
  
  local card_position = card:getPosition()
  local card_size = card:getGroupBounds().size

  card2:setScale(180/card2:getGroupBounds().size.width)
  card2:setPosition(ccp(card_position.x,card_position.y))
  card2:setZOrder(1001)
  
  area:addChild(card2)
  card:setVisible(false)
  
  area:getChildByName("card_txt_lv_num"):getChildByName("font"):setString(cardInfo.level)
  area:getChildByName("card_txt_lv_num"):getChildByName("font"):setColor(ccc3(255,255,255))
  area:getChildByName("card_txt_cardTrain_capacity"):getChildByName("txt_txt_cardTrain_capacity"):setString(Localization:getInstance():getText("cardTrain_capacity"))
  area:getChildByName("card_txt_cardTrain_capacity_num"):getChildByName("font"):setColor(ccc3(255,255,255))
  
  --初始化信息
  self:refreshCardInfo()
  --增减信息
  self:initLabelInfo()
end

local trainLvlBtn = {}

----------------------------------------
----------------------------------------
function CardTrainingScene:refreshTrainLevelBtn()
  local keys = {"low", "mid", "lowmany", "midmany"}
  for key, value in pairs(trainLvlBtn) do
    if (key == keys[self.trainLevelSelected]) then
      value:getChildByName("bg_cardTraining_optionSelected"):setVisible(true)
    else
      value:getChildByName("bg_cardTraining_optionSelected"):setVisible(false)
    end
  end
end

----------------------------------------
----------------------------------------
function CardTrainingScene:refreshTrainLevelDesc( area )
  local str = {
      Localization:getInstance():getText("cardTrain_level_desc",{num=self.trainConfig.pydCost , min=self.trainConfig.normalTrainFloor , max=self.trainConfig.normalTrainCeil}),
      Localization:getInstance():getText("cardTrain_level_desc",{num=self.trainConfig.pydCost , min=self.trainConfig.specialTrainFloor , max=self.trainConfig.specialTrainCeil}),
      Localization:getInstance():getText("cardTrain_level_desc",{num=self.trainConfig.pydCost*10 , min=self.trainConfig.normalTrainFloor*10 , max=self.trainConfig.normalTrainCeil*10}),
      Localization:getInstance():getText("cardTrain_level_desc",{num=self.trainConfig.pydCost*10 , min=self.trainConfig.specialTrainFloor*10 , max=self.trainConfig.specialTrainCeil*10}),}
  area:getChildByName("card_txt_cardTrain_level_desc"):getChildByName("txt_cardTrain_level_desc"):setString(str[self.trainLevelSelected])
end

----------------------------------------
----------------------------------------
function CardTrainingScene:refreshSoulStone()
  local soulStoneLabel = self.mainUI:getChildByName("card_cardTraining_cardTrainLevel"):getChildByName("card_txt_cardTrain_soulstone_num"):getChildByName("font")
  soulStoneLabel:setString(self.soulStone.amount)  
end

----------------------------------------
----------------------------------------
function CardTrainingScene:initCardTrainLevel()
  local area = self.mainUI:getChildByName("card_cardTraining_cardTrainLevel")
  local nameStr = "card_btn_cardTrain_level"
  
  local cardTrainConfig = MetaManager.getCardTrainConfig()
  local trainCost = cardTrainConfig.ybCost
  
  trainLvlBtn.low = area:getChildByName(nameStr .. "low")
  trainLvlBtn.mid = area:getChildByName(nameStr .. "mid")
  trainLvlBtn.lowmany = area:getChildByName(nameStr .. "lowmany")
  trainLvlBtn.midmany = area:getChildByName(nameStr .. "midmany")
  
  trainLvlBtn.low:getChildByName("txt_cardTrain_levellow"):setString(Localization:getInstance():getText("cardTrain_levellow"))
  trainLvlBtn.mid:getChildByName("txt_cardTrain_levelmid_L"):setString(Localization:getInstance():getText("cardTrain_levelmid"))
  trainLvlBtn.mid:getChildByName("txt_cardTrain_levelmid_R"):setString(trainCost .. "")
  trainLvlBtn.lowmany:getChildByName("txt_cardTrain_levellowmany"):setString(Localization:getInstance():getText("cardTrain_levellowmany",{num=10}))
  trainLvlBtn.midmany:getChildByName("txt_cardTrain_levelmidmany_L"):setString(Localization:getInstance():getText("cardTrain_levelmidmany",{num=10}))
  trainLvlBtn.midmany:getChildByName("txt_cardTrain_levelmidmany_R"):setString((trainCost * 10) .. "")
  
  area:getChildByName("card_txt_cardTrain_soulstone"):getChildByName("txt_cardTrain_soulstone"):setString(Localization:getInstance():getText("cardTrain_soulstone"))
  
  local function onClickTrainLvlBtn(evt)
    local keys = {low = 1, mid = 2, lowmany = 3, midmany = 4}
    
    self.trainLevelSelected = keys[evt.context]
    self:refreshTrainLevelBtn()
    self:refreshTrainLevelDesc( area )
  end
  
  for key, value in pairs(trainLvlBtn) do
    value = Button:create(value)
    value:addEventListener(Events.kStart, onClickTrainLvlBtn, key)  
  end
  
  self:refreshTrainLevelBtn()
  self:refreshTrainLevelDesc( area )
  self:refreshSoulStone()
end

local trainActnBtn = {}

----------------------------------------
----------------------------------------
function CardTrainingScene:refreshTrainActionBtn()
   if ( self.trainStatus ) then
    trainActnBtn.save:getChildByName("txt_cardTrain_Btn"):setString(Localization:getInstance():getText("cardTrain_saveBtn"))
    trainActnBtn.retry:setVisible(true)
    trainActnBtn.abandon:setVisible(true)
  else
    trainActnBtn.save:getChildByName("txt_cardTrain_Btn"):setString(Localization:getInstance():getText("cardTrain_Btn"))
    trainActnBtn.retry:setVisible(false)
    trainActnBtn.abandon:setVisible(false)
  end
end

----------------------------------------
----------------------------------------
function CardTrainingScene:initBtns()
  trainActnBtn.retry = self.mainUI:getChildByName("card_btn_cardTrain_retryBtn")
  trainActnBtn.save = self.mainUI:getChildByName("card_btn_cardTrain")
  trainActnBtn.abandon = self.mainUI:getChildByName("card_btn_cardTrain_abandonBtn")
  
  trainActnBtn.retry:getChildByName("txt_cardTrain_retryBtn"):setString(Localization:getInstance():getText("cardTrain_retryBtn"))
  trainActnBtn.abandon:getChildByName("txt_cardTrain_abandonBtn"):setString(Localization:getInstance():getText("cardTrain_abandonBtn"))
  
  self:refreshTrainActionBtn()  
  
  local function onClickTrainActnBtn(evt)
    local keys = {retry = 1, save = 2, abandon = 3}
    local pushed = keys[evt.context]
    
    self.labelTable = {
      ["cap"] = 0,
      ["atk"] = 0,
      ["def"] = 0,
      ["hp"] = 0,
    }
    
    local trainOpt = {
      cardId = self.cardId,
      special = (self.trainLevelSelected == 2 or self.trainLevelSelected == 4),
      trainTimes = (self.trainLevelSelected == 3 or self.trainLevelSelected == 4) and 10 or 1
    }
    
    if (pushed==1) then
      --重试
      if ((cardInfo.nowPotential <= 0) and ((self.trainLevelSelected==2) or (self.trainLevelSelected==4)) and CardTrainingScene.canShowAssistantPanel()) then
          local aPanel = AssistantMessageBoxPanel:create( self, AsMessageBoxType.notEnoughPotential, trainOpt )
          self:addChild(aPanel)
          aPanel:scaleIn()
      else
          self:trainCard( trainOpt )
      end
        
      self.labelTable = {
        ["cap"] = -2,
      }
    elseif (pushed == 2) then
      if (self.trainStatus) then
        --保存
		g_previousBattleCount = CommonManager:getLocalPlayerStrength()
        self.trainStatus = false
        self:saveCardTrain( trainOpt )
      else
        --开始培养
        if ((cardInfo.nowPotential <= 0) and ((self.trainLevelSelected==2) or (self.trainLevelSelected==4)) and CardTrainingScene.canShowAssistantPanel()) then
          local aPanel = AssistantMessageBoxPanel:create( self, AsMessageBoxType.notEnoughPotential, trainOpt )
          self:addChild(aPanel)
          aPanel:scaleIn()
        else
          self:trainCard( trainOpt )
        end
        
        self.labelTable = {
          ["cap"] = -2,
        }
      end
    else
      --放弃
      self:giveUpCardTrain( trainOpt )
    end
  end
  
  for key, value in pairs(trainActnBtn) do
    value = Button:create(value)
    value:addEventListener(Events.kStart, onClickTrainActnBtn, key)  
  end
end

function CardTrainingScene.getUnsavedTrainInfo()
  local unsavedInfo = {
    trainCardId = 0,
    trainValueSaved = true,
    unsavedAttTrainValue = 0,
    unsavedDefTrainValue = 0,
    unsavedHpTrainValue = 0,
  }
  local GameInitData = DataManager.getGameInitData()
  local cardsInfo = GameInitData.sharkCards
  for key, value in pairs(cardsInfo) do
    if (unsavedInfo[key]) then
      unsavedInfo[key] = value
    end
  end
  return unsavedInfo
end

function CardTrainingScene.getUnsavedCardId()
  local GameInitData = DataManager.getGameInitData()
  local cardsInfo = GameInitData.sharkCards
  local unsavedInfo = CardTrainingScene.getUnsavedTrainInfo()
  
  if (not unsavedInfo.trainValueSaved) then
    if (unsavedInfo.trainCardId ~= 0) then
        local cardsData = cardsInfo.sharkCards
        local isFind = false
        for key ,data in pairs(cardsData) do
          if unsavedInfo.trainCardId == data.cardId then
            isFind = true
            break
          end
        end

        if isFind then
          return unsavedInfo.trainCardId
        end
    end
  end
  return nil
end

----------------------------------------
----------------------------------------
function CardTrainingScene:initCardData()
  local GameInitData = DataManager.getGameInitData()
  local cardsInfo = GameInitData.sharkCards
  
  self.unsavedInfo = {
    trainCardId = 0,
    trainValueSaved = true,
    unsavedAttTrainValue = 0,
    unsavedDefTrainValue = 0,
    unsavedHpTrainValue = 0,
  }

  for key, value in pairs(cardsInfo) do
    if (self.unsavedInfo[key]) then
      self.unsavedInfo[key] = value
    end
  end

  if (not self.unsavedInfo.trainValueSaved) then
    if (self.unsavedInfo.trainCardId ~= 0) then
        local cardsData = cardsInfo.sharkCards
        local isFind = false
        for key ,data in pairs(cardsData) do
          if self.unsavedInfo.trainCardId == data.cardId then
            isFind = true
          end
        end

        if isFind then
          self.cardId = self.unsavedInfo.trainCardId
          self.trainStatus = true
        end
    end
  end
    
  local cardsData = cardsInfo.sharkCards
  local cardData = CommonManager.getSubTableByKey(
    cardsData,
    {name = "cardId", value = self.cardId}
  )
  for key, value in pairs(cardData) do
    --print(key, value)
    if (cardInfo[key]) then
      cardInfo[key] = value
    end
  end
  
  cardInfo.metaId = cardData.metaId
  
  local aCard = MetaManager.card_meta[cardInfo.metaId]
  for key, value in pairs(aCard) do
    cardInfo[key] = value
  end
end

----------------------------------------
-- 进入场景动画,被父类onInit()方法调用
----------------------------------------
function CardTrainingScene:doEnterAnimation()
  self:preEnterAnimation()
  self:startEnterAnimation()
end

----------------------------------------
-- 返回按钮
----------------------------------------
function CardTrainingScene:back()
	if (self.params.returnScene == "CardQueueScene") then
		self:replaceScene(CardQueueScene, {enterScene="CardTrainingScene"})
	elseif (self.params.returnScene == "MatrixScene") then
		self:replaceScene(MatrixScene)
	else
		self:replaceScene(BackpackScene)
	end
end

----------------------------------------
----------------------------------------
function CardTrainingScene:preEnterAnimation()
  BaseUIScene.preEnterAnimation(self)
  CanonPlayBackgroundMusic("music/background.mp3", true)
end

----------------------------------------
----------------------------------------
function CardTrainingScene:startEnterAnimation()
  BaseUIScene.startEnterAnimation(self)
  
  local function enterActionFinished()
    self:nodeAnimationFinished()
  end
  
  local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(0.5, ccp(visibleSize.width, 0)))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.mainUI:setPositionX(self.mainUI:getPositionX() - visibleSize.width)
  self.mainUI:runAction(CCSequence:create(arr))
end

----------------------------------------
----------------------------------------
function CardTrainingScene:sufEnterAnimation()
  BaseUIScene.sufEnterAnimation(self)
end

----------------------------------------
-- 场景切换时，被父类的replaceScene调用
----------------------------------------
function CardTrainingScene:doExitAnimation()
   self:preExitAnimation()
   self:startExitAnimation()
end

----------------------------------------
----------------------------------------
function CardTrainingScene:preExitAnimation()
  BaseUIScene.preExitAnimation(self)
end

----------------------------------------
----------------------------------------
function CardTrainingScene:startExitAnimation()
  BaseUIScene.startExitAnimation(self)
  
  local function enterActionFinished()
    self:nodeAnimationFinished()
  end
  
  local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(0.5, ccp(-visibleSize.width-100, 0)))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.mainUI:runAction(CCSequence:create(arr))
  --self.friendsTableView:runAction(CCSequence:create(arr))
end

----------------------------------------
----------------------------------------
function CardTrainingScene:sufExitAnimation()
  BaseUIScene.sufExitAnimation(self)
end

function CardTrainingScene:dispose()
  CardTrainingScene.super.dispose(self)
end

function CardTrainingScene:playFireOnCard()
	local particle = CCParticleSystemQuad:create("effect/fx_card_upwave.plist")
	particle:setPositionX(self.icons[0]:getPositionX()+self.icons[0]:getBounds().size.width/2)
	particle:setPositionY(self.icons[0]:getPositionY()-self.icons[0]:getBounds().size.height/2)
	particle:setAutoRemoveOnFinish(true)
	self.mainUI:getChildByName("card_cardTraining_cardInfo"):addChild(CocosObject.new(particle))
end

function CardTrainingScene:playFireOnIcon(i)
	--[[local aFspt = FlashSprite:create("battle/fire")
	aFspt:setScale(0.5)
	aFspt:changeAnimation(0)
	aFspt:setLoop(false)
	aFspt:setPositionX(self.icons[i]:getPositionX()+self.icons[i]:getBounds().size.width/2)
	aFspt:setPositionY(self.icons[i]:getPositionY()-self.icons[i]:getBounds().size.height/2)
	aFspt = CocosObject.new(aFspt)
	self.mainUI:getChildByName("card_cardTraining_cardInfo"):addChild(aFspt)]]
	self:playFireOnCard()
end

----------------------------------------
----------------------------------------
function CardTrainingScene:trainCard( trainOpts )
  --金币检查
  if (trainOpts.special) then
    local gemsNow = CalculationManager.calcComplex_getGemsNow()
    if (gemsNow < trainOpts.trainTimes * self.trainConfig.ybCost) then
      local aPanel = AssistantMessageBoxPanel:create( self, AsMessageBoxType.addCoin )
      self:addChild(aPanel)
      aPanel:scaleIn()
      return
    end
  end
  
  --物品数量检查
  if (self.soulStone.amount < (trainOpts.trainTimes * self.trainConfig.pydCost) ) then
    local aPanel = AssistantMessageBoxPanel:create( self, AsMessageBoxType.notEnoughSoulStone )
    self:addChild(aPanel)
    aPanel:scaleIn()
    return
  end
  
  local function afterTrainCard(event)
    self.labelTable = {}
    for key, value in pairs(event.data) do
      if (key=="attTrainValue") then
        self.labelTable.atk = value
		if (value>0) then
			self.fireOnIcon = 1
		end
      elseif (key=="defTrainValue") then
        self.labelTable.def = value
		if (value>0) then
			self.fireOnIcon = 2
		end
      elseif (key=="hpTrainValue") then
        self.labelTable.hp = value
		if (value>0) then
			self.fireOnIcon = 3
		end
      end
    end
	self.soulStone.amount = self.soulStone.amount - trainOpts.trainTimes * self.trainConfig.pydCost
	local negativeReward = {
		{	itemType = ResourceEnum.GEMS,
			amount = (trainOpts.special) and (-1 * trainOpts.trainTimes * self.trainConfig.ybCost) or 0,
		},
		{	itemType = ResourceEnum.PROP,
			metaId = self.trainConfig.pydMetaId,
			amount = (-1 * trainOpts.trainTimes * self.trainConfig.pydCost)
		}
	}
	RewardManager:getReward(negativeReward)
	
    self.trainStatus = true
    self:refreshLabel()
    self:refreshTrainActionBtn()
    self:refreshSoulStone()
  end
  
  --构造请求
  local request = CardTrainingRequest.new( trainOpts, rpc.SendingPriority.kHigh )
  request:addEventListener( RequestNotifyEnum.TrainCardSucceed, afterTrainCard )
  --发送请求
  request:start()
end

----------------------------------------
----------------------------------------
function CardTrainingScene:saveCardTrain( params )
  local function afterSaveTrain(event)
    for key, value in pairs(event.data.sharkCard) do
      if (cardInfo[key]) then
        cardInfo[key] = value
      end
    end

	self:playFireOnIcon(self.fireOnIcon)
    cardInfo.usedPotential = event.data.sharkCard.usedPotential
	
	local CardsData = DataManager.getCardsData()
	for key,aCard in pairs(CardsData) do
		if (aCard.cardId == event.data.sharkCard.cardId) then
			CardsData[key] = event.data.sharkCard
      --如果是阵列中的卡牌，就清空g_previousBonusTable
      local queueData = {}
      local matrixCardData = CommonManager:getMatrixCardData()
      for k,v in ipairs(matrixCardData) do 
        if not queueData[v] then
          queueData[v] = k + 100
        end
      end
      if queueData[aCard.cardId] and queueData[aCard.cardId] > 100 then
        g_previousBonusTable = nil;
      end

			break
		end
	end
	DataManager.setCardsData(CardsData)
	local GameInitData = DataManager.getGameInitData()
	GameInitData.sharkCards["trainValueSaved"] = true
	DataManager.setGameInitData(GameInitData)
	
	self:refreshLabel()
    self:refreshCardInfo()
    self:refreshTrainActionBtn()
          
    --显示战斗力更新 FIGHT_CAPACITY_MODIFY by zheng.che @ 2014-12-22
    DataManager.fightCapacityMaybeUpdated()
  end
  
  --构造请求
  local request = SaveCardTrainRequest.new( params, rpc.SendingPriority.kHigh )
  request:addEventListener( RequestNotifyEnum.SaveCardTrainSucceed, afterSaveTrain )
  --发送请求
  request:start()
end

----------------------------------------
-- 放弃培养
----------------------------------------
function CardTrainingScene:giveUpCardTrain( params, noRefresh )
  local function afterGiveUPTrain(event)
    for key, value in pairs(event.data.sharkCard) do
      if (cardInfo[key]) then
        cardInfo[key] = value
      end
    end
    cardInfo.usedPotential = event.data.sharkCard.usedPotential
    self.trainStatus = false
    local GameInitData = DataManager.getGameInitData()
    GameInitData.sharkCards["trainValueSaved"] = true
    DataManager.setGameInitData(GameInitData)
	if ( not noRefresh) then
		self:refreshLabel()
		self:refreshCardInfo()
		self:refreshTrainActionBtn()
	end
  end
  
  --构造请求
  local request = GiveUpCardTrainRequest.new( params, rpc.SendingPriority.kHigh )
  request:addEventListener( RequestNotifyEnum.GiveUpCardTrainSucceed, afterGiveUPTrain )
  --发送请求
  request:start()
end

function CardTrainingScene:callFuncBeforeSceneChange( aReplaceFunc )
	if (self.trainStatus) then
		self.replaceFunc = aReplaceFunc
		local aPanel = AssistantMessageBoxPanel:create( self, AsMessageBoxType.giveUp, trainOpt )
		self:addChild(aPanel)
		aPanel:scaleIn()
	else
		aReplaceFunc()
	end
end

function CardTrainingScene.canShowAssistantPanel()
	local userId = DataManager.getCurrUser().uid
	local time = CCUserDefault:sharedUserDefault():getIntegerForKey(
    "lastPotentialHintTimeInTraining_" .. userId
	)
  if (time == nil) then
    return true
  end
  
  if ((TimeUtil.getServerTimeSeconds() - time) >= TimeUtil.DAY) then
    return true
  end
  return false
end

function CardTrainingScene.saveNoShowAssistantPanel()
	local userId = DataManager.getCurrUser().uid
	CCUserDefault:sharedUserDefault():setIntegerForKey(
		"lastPotentialHintTimeInTraining_" .. userId,
		TimeUtil.getServerTimeSeconds()
	)
end