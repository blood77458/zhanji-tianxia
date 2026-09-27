--
-- EquipQuickUpgradeScene.lua
-- Author: zheng.che
-- Date: 2014-04-23 16:52:38
-- 限时秒杀活动
--
require "canon.request.UpgradeEquipForOneCardRequest"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

local exchangeTable_width = visibleSize.width
local exchangeTable_height = 640
local exchangeItem_width = visibleSize.width
local exchangeItem_height = 640
local exchangeTable_posX = 16.5
local exchangeTable_posY = 315
 local cellTag = 1024

local enter_animation_duration = 0.3
local original_scroll_duration = 0.5

local refresh = true


local tableOffsetUpper = 0
local tableOffsetLower = 0
local rollSpeed = 0
local ROLLTIME = 10

EquipQuickUpgradeScene = class(BaseUIScene)

 

local function onClickUpgrade(evt)
  self = evt.context
  print("~~~~~~~~~~~~~~~~~~~~~~~强化按钮")
  local function FlashFinish()
    for i=1,3 do
      if self.Starflash[i] and self.StarFlashdisplay[i] then
        self.Starflash[i]:removeFromParentAndCleanup(true)
        self.StarFlashdisplay[i]:unregisterEndAnimationScriptHandler()
      end
    end
    -- print("~~~~~~~~~~~~~~~~~结束了")
    self:setTableViewsEnabled(true)
    -- self.UpgardeButton:setEnable(true)
  end

  local function showflash(flashPos,num)
    local fspt = FlashSprite:create("EVO2/equip")
    fspt:changeAnimation(0)
    fspt:setLoop(false)
    local fspt_co = CocosObject.new(fspt)
    -- print(flashPos.x.."~~~~~~~~~~~~~~"..flashPos.y)
    fspt:setPosition(flashPos.x+60, flashPos.y - visibleSize.height+260)
    
    self:addChild(fspt_co)

    fspt:registerEndAnimationScriptHandler(FlashFinish)
    
    self.Starflash[num] = fspt_co
    self.StarFlashdisplay[num] = fspt
  end
  
 
  
   local function upgradeEquipSucceed(event)
   
    RewardManager:gainReward({itemType = ResourceEnum.COIN, amount = -self.allCost})
    -- print("~~~~~~~~~~~~~~~~~")
    local previous_strength = CommonManager:getLocalPlayerStrength()
    
    local aNewEquip = event.data.sharkEquips
    local aEquiplist = {}
    for i,Equip in ipairs(aNewEquip) do
        aEquiplist[Equip.equipId] = Equip
    end
    -- print("~~~~~~~~~~~~~aNewEquip = "..tostringRich(aNewEquip))
    local aSharkEquips = DataManager.getEquipsData()
    --print(table.tostring(aSharkEquips))
    for aIndex, aEquip in pairs(aSharkEquips) do
      for _,NewEquip in ipairs(aNewEquip) do
        if aEquip.equipId == NewEquip.equipId then
          -- table.remove(aSharkEquips, aIndex)
          -- table.insert(aSharkEquips, NewEquip)
          aSharkEquips[aIndex] = NewEquip
        end
      end
     
    end

    for i=1,3 do
      if self.queue[self.oldSelectNo].equips[i] then
        for _,Equip in ipairs(aNewEquip) do
          -- print("~~~~~~~~~~~~~~~~在匹配")
          if self.queue[self.oldSelectNo].equips[i]["equipId"] == Equip.equipId then
            -- print("~~~~~~~~~~~~~~~~~~匹配了 = "..tostringRich(Equip))

            self.queue[self.oldSelectNo].equips[i] = Equip
          end
        end
      end
    end

    
 

    DataManager.setEquipsData(aSharkEquips)
   
    -- self.queue[self.oldSelectNo].equips = aNewEquip
    
    -- print("~~~~~~~~~~~~~self.iconPos = "..tostringRich(self.iconPos))
    for i,pos in ipairs(self.iconPos) do
      -- print("~~~~~~~~~~~~~~pos"..pos.x)
      showflash(pos,i)
    end
    self:loadPlayerData()
    self:loadQueueData()
    self.iconPos = {}
    self.upgardeEquipId = {}
    self.allCost = 0
    self:AcountAllCoin(self.selectedCardNo)
    --文件初始化
    -- print("~~~~~~~~~~~~~~~self.allCost = "..self.allCost)
    self:setMoney (self.allCost)
    local aContent = Localization:getInstance():getText("strengthenAll_tips")
    SuspensionLabel:showContent(self, aContent)
    self.refreshSelf()
    self:setTableViewsEnabled(false)
    -- self.UpgardeButton:setEnable(false)
    -- --显示战斗力更新 FIGHT_CAPACITY_MODIFY by zheng.che @ 2014-12-22
    DataManager.fightCapacityMaybeUpdated()
  end

  -- print("~~~~~~~~~~~~~~~~~~ self.upgardeEquipId = "..tostringRich( self.upgardeEquipId))
   UpgradeEquipForOneCardRequest.sendRequestDefalut(self.upgardeEquipId,upgradeEquipSucceed)

end

-------------------------------------------------------------------------------------
-- 初始化
-------------------------------------------------------------------------------------
function EquipQuickUpgradeScene:ctor()
  self.cellWidth = exchangeItem_width

  self.selectedCardNo = 1
  self.tableOffsetUpperTarget = 0
  self.tableOffsetLowerTarget = 0
  self.rolling = false
  
  self.playerTeamData = nil
  
  self.userLevel = 0
  self.userLevel = nil
  self.cardsInfo = nil
  self.equipsData = nil
  self.queue = {}

  self.equipMetaConfig = NULL
  self.equipProperty = NULL
  self.equipLevelConfig = NULL
  self.nextEquipLevelConfig = NULL
  self.propertyValue = 0
  self.additionPropertyValue = 0
  self.equipEvolveLevelConfig = NULL
  self.upgradeCost = 0
  self.CoinCellList = {}
  self.upgardeEquipId = {}
  self.quickUpgradeLevel = 0

  self.oldSelectNo = 0
  self.allCost = -1
  self.iconPos = {}
  self.CanUpgrade = {}

  self.Starflash = {}
  self.StarFlashdisplay = {}
  self.adjudeButtonStatus = true
  self.scrollButtonStatus = true

  self.isCurShowSpiritTableView = false
  self.title = Localization:getInstance():getText("strengthenAll_titel")
  self.curSceneEnum = SceneEnum.EquipQuickUpgradeScene
  self.showParticles = {}
end



function EquipQuickUpgradeScene:setTableViewsEnabled(v)
      self.listTableView:setTouchEnabled(v)
end

function EquipQuickUpgradeScene:setFullCard(CardmetaId)
  if self.fullCard then
    self.fullCard:removeFromParentAndCleanup(true)
  end
  -- self.fullCard = CanonFullCard:create(self.mainUI:getChildByName("full"))
  -- self.fullCard:setScaleX(2)
  -- self.fullCard:setScaleY(2.25)
  
  -- --显示卡牌大图
  -- self.fullCard:setCard(CardmetaId)
  local display = self.mainUI:getChildByName("full")
  display:setVisible(false)
  local bigCardSpriteFrame = getFullCardSpriteFrame(CardmetaId)
  local cardSprite = CCSprite:createWithSpriteFrame(bigCardSpriteFrame)
  self.fullCard = CocosObject.new(cardSprite)
  self.fullCard:setAnchorPoint(ccp(0.5, 0.5))
  self.fullCard:setPositionXY(display:getPositionX(), display:getPositionY())
  self.fullCard:setScaleX(2)
  self.fullCard:setScaleY(2.25)
  self.fullCard:setOpacity(70)
  display:getParent():addChildAt(self.fullCard, display:getZOrder())

end
-------------------------------------------------------------------------------------
-- 创建
-------------------------------------------------------------------------------------
function EquipQuickUpgradeScene:create(argv,container, params)
   self.container =argv.params.container
   self.curSceneEnum = SceneEnum.CardQueueScene
  if argv then
    self.argv = argv
    self.argv.params = self.argv.params or {}
    if argv.enterScene == "CardQueueScene" then
          --从队伍进入
      self.playerTeamData = argv.params.playerTeamData
      

    end
    
  else
    self.argv = { enterScene=nil, returnScene=nil, params={} }
  end
  local s = EquipQuickUpgradeScene.new()
  s:initScene()

  return s
end

-------------------------------------------------------------------------------------
-- 初始化
-------------------------------------------------------------------------------------
function EquipQuickUpgradeScene:onInit()
  BaseUIScene.initBackGround(self)
  self:loadPlayerData()
  self:loadQueueData()
 --刷新整个列表显示
  local function refreshSelf()

    for i = #self.dataList, 1, -1 do
      table.remove(self.dataList, i)
    end

    local tempList = self.queue--EquipQuickUpgradeScene.getTodaySaleList()
    --print("tempList = " .. table.tostring(tempList))

    for _, v in ipairs(tempList) do
      table.insert(self.dataList, v)
    end
    
    self.listTableView:reloadData()
    
    -- print("~~~~~~~~~~~~~~~~~~~~~self.CoinCellList = "..tostringRich(self.CoinCellList))
    --移动到初始位置
    -- print("~~~~~~~~~~~~~~~~self.selectedCardNo = "..tostringRich(self.selectedCardNo))
    self:gotoIndex(self.selectedCardNo, true)
  end
  self.refreshSelf = refreshSelf
  self.userLevel = DataManager.getCurrUser().level

  -- self.queue = self.container.queue
  --刷新其中某一条数据显示
 

  

  --初始化界面显示
  self.builder = LayoutBuilder:createWithContentsOfFile("scene/details_card.json")
  self.builder.useArtLabelTTF = true
  self.mainUI = self.builder:build("EquipmentAll")
  self:addChild(self.mainUI)

  --初始化各种组件
  self.leftdisplay = self.mainUI:getChildByName("icon_sliding_l")

  self.rightdisplay = self.mainUI:getChildByName("icon_sliding_r")

  self.CardNameTxt = self.mainUI:getChildByName("txt_details_card_45"):getChildByName("txt")
  
  self.LevelTxt = self.mainUI:getChildByName("txt_lv"):getChildByName("txt")
  self.dataList = {}

  
  self.listTableView = self:createListTableView()
  self.mainUI:addChild(self.listTableView)

  --改按钮层级
  self.mainUI:removeChild(self.leftdisplay , false)
  self.mainUI:addChild(self.leftdisplay)
  self.mainUI:removeChild(self.rightdisplay, false)
  self.mainUI:addChild(self.rightdisplay)
  self.Btndisplay = self.mainUI:getChildByName("btn_chr3")
  self.Btndisplay:getChildByName("txt"):setString(getTextByKey("strengthenAll_titel"))
  self.UpgardeButton = Button:create(self.Btndisplay)
  self.UpgardeButton:addEventListener(Events.kStart, onClickUpgrade, self)
  
  
  
  if (self.argv.enterScene == "EquipEvolveScene" or
      self.argv.enterScene == "CardQueueScene" or
    self.argv.params.rollTo) then
    if self.argv.params.cardPos then
       self.selectedCardNo = self.argv.params.cardPos
    else
       local rollto =  HeMemDataHolder:getInteger("CardQueue_RollTo")
      rollto = (rollto>#self.queue) and #self.queue or rollto
      -- print("~~~~~~~~~~~~rollto = "..tostringRich(rollto))
      if rollto > 0 then
        self.selectedCardNo = rollto
      end
    end
  end
 
  
  
  --先刷新一下状态
  self.refreshSelf()
  
  
  local cellNum = (#self.queue >= 10) and 10 or (#self.queue + 1)
  -- print("~~~~~~~~~~~~~~~~~~~cellNum = "..cellNum)
  if self.selectedCardNo + 3  <= cellNum then
    self.tableOffsetUpperTarget = -(self.selectedCardNo-1)*(exchangeItem_width)
  else
    local offset = (cellNum - 4 >= 0) and (cellNum - 4) or 0
    self.tableOffsetUpperTarget = -offset*(exchangeItem_width)
  end
  self.listTableView:setContentOffset(ccp(-(self.selectedCardNo-1)*720,0))
  self.rolling = true
  DataManager.fightCapacityMaybeUpdated()
  BaseUIScene.onInit(self)



end

function EquipQuickUpgradeScene:loadPlayerData()
  SpiritManager.getPlayerAllSpiritOfferedAttribute()
    self.userLevel = DataManager.getCurrUser().level
    self.cardsInfo = table.clone(DataManager.getCardsData(), true)
    self.equipsData = table.clone(DataManager.getEquipsData(), true)
    self.matrixCardInfo = {}
    for k, v in pairs(CommonManager:getMatrixCardData()) do
      table.insert(self.matrixCardInfo, CommonManager:getCardMetaByCardId(v, self.cardsInfo).id)
    end
      
    --获取队列信息
    self.queue = table.clone(CommonManager.getQueueData(), true)
    for key,value in pairs(self.queue) do
    self.queue[key] = CommonManager.getSubTableByKey(
      self.cardsInfo,
      {name = "cardId", value=value}
    )
    end
end


function EquipQuickUpgradeScene:loadQueueData()
  --所有装备及卡牌Meta信息
  local equipsMeta = {}
  
  local equipIdList = {}
  for aKey, aEquip in pairs(self.equipsData) do
    equipsMeta[aEquip.equipId] = tonumber(aEquip.metaId)
    equipIdList[aEquip.equipId] = aKey
  end
    
  for _, aCard in pairs(self.queue) do
    aCard.equipIds = aCard.equipIds and aCard.equipIds or {}
    
    --载入装备详情
    aCard.equips = {}
    for key, aEquipId in pairs(aCard.equipIds) do
      local aMeta = equipsMeta[aEquipId]
      local aEquipInfo = MetaManager.equip_meta[aMeta]
      local aPosition = aEquipInfo.position
      
      aCard.equips[aPosition] = self.equipsData[equipIdList[aEquipId]]
    end
  end
  local equipsPrefixId = {}
  for _, value in pairs(equipsMeta) do
    equipsPrefixId[MetaManager.equip_meta[value]["prefixId"]] = true
  end
end


--移动到某一位置
function EquipQuickUpgradeScene:gotoIndex(aIndex, forceMove)
  --延时结束
  local function actionFinished()
    self.moving = false
  end

  if not self.moving then
    --print("-exchangeTable_width * (aIndex - 1) = " .. (-exchangeTable_width * (aIndex - 1)))
    self:setCurrentSelectIndex(aIndex)
    if forceMove then
      --直接移动 没有缓动 没有延时处理
      self.listTableView:setContentOffset(ccp(-exchangeTable_width * (aIndex - 1), 0))
    else
      self.listTableView:setContentOffsetInDuration(ccp(-exchangeTable_width * (aIndex - 1), 0), original_scroll_duration)
      self.moving = true

      --延时处理
      local arr2 = CCArray:create()
      arr2:addObject(CCDelayTime:create(original_scroll_duration))
      arr2:addObject(CCCallFunc:create(actionFinished))
      self:runAction(CCSequence:create(arr2))
    end
  end
end

--设置当前选择的数据
function EquipQuickUpgradeScene:setCurrentSelectIndex(aIndex)
  local tempCombineData = self.dataList[aIndex]
  if tempCombineData then
    self.currentSelectedIndex = aIndex
    self.currentSelectedCombineData = tempCombineData
    --print("self.currentSelectedCombineData = " .. table.tostring(self.currentSelectedCombineData))

    if self.currentSelectedIndex <= 1 then
      self.leftdisplay:setVisible(false)
    else
      self.leftdisplay:setVisible(true)
    end

    if self.currentSelectedIndex >= #self.dataList then
      self.rightdisplay:setVisible(false)
    else
      self.rightdisplay:setVisible(true)
    end
  end
end

function EquipQuickUpgradeScene:setMoney (money)
     local txt = self.mainUI:getChildByName("txt_2"):getChildByName("txt")
      txt:setString(money)
    local currUser = DataManager.getCurrUser()
    if (money <= tonumber(currUser.coins, 10)) and money > 0 then
       self.Btndisplay:getChildByName("btn"):setVisible(true)
       self.UpgardeButton:setEnable(true)
       txt:setColor(ccc3(255,255,255))
    elseif #self.upgardeEquipId == 0  then
       self.Btndisplay:getChildByName("btn"):setVisible(false)
       self.UpgardeButton:setEnable(false)
       txt:setColor(ccc3(255,255,255))
    else
       self.Btndisplay:getChildByName("btn"):setVisible(false)
       self.UpgardeButton:setEnable(false)
       txt:setColor(ccc3(234 ,85,4))
    end
end



function EquipQuickUpgradeScene:onUpdate(dt)
  BaseUIScene.onUpdate(self, dt)
  if self.CardNameTxt:getString() ~= getTextByKey(MetaManager.card_meta[self.queue[self.selectedCardNo].metaId].name) then
    self.CardNameTxt:setString(getTextByKey(MetaManager.card_meta[self.queue[self.selectedCardNo].metaId].name))
    
  end  
  

  if self.LevelTxt:getString() ~= tostring(self.queue[self.selectedCardNo].level) then
    self.LevelTxt:setString(self.queue[self.selectedCardNo].level)
  end

  if (rollSpeed==0 and self.rolling) then

    rollSpeed = (tableOffsetUpper - self.tableOffsetUpperTarget)/ROLLTIME
    rollSpeed = math.abs(rollSpeed)
  end
  if self.oldSelectNo ~= self.selectedCardNo then
   
    -- print("~~~~~~~~~~~~~~~~self.queue[self.selectedCardNo] = "..tostringRich(self.queue[self.selectedCardNo]))
    self:setFullCard(self.queue[self.selectedCardNo].metaId)
    self.iconPos = {}
    self.upgardeEquipId = {}
    self.allCost = 0
    self:AcountAllCoin(self.selectedCardNo)
    --文件初始化
    -- print("~~~~~~~~~~~~~~~self.allCost = "..self.allCost)
    self:setMoney (self.allCost)
    self.oldSelectNo = self.selectedCardNo
  
  end

  if (self.listTableView:getContentOffset().x % exchangeItem_width ) ~= 0 and self.scrollButtonStatus then
    self.UpgardeButton:setEnable(false)
    self.scrollButtonStatus = false
    self.adjudeButtonStatus = true
  elseif (self.listTableView:getContentOffset().x % exchangeItem_width ) == 0  and self.adjudeButtonStatus then  
    if self.Btndisplay:getChildByName("btn"):isVisible() then
      self:setMoney (self.allCost)
    end
    self.adjudeButtonStatus = false
    self.scrollButtonStatus = true
  end

end


-------------------------------------------------------------------------------------------------------------------------------------------------------tableview

-------------------------------------------------------------------------------------
-- 生成列表
-------------------------------------------------------------------------------------

local TAG_FIRST_STAR = 10001
local EquipPropertyEnum = {kHp = "Hp", kAttack = "Attack", kDefence = "Defence"}
function EquipQuickUpgradeScene:createListTableView(tableViewSizes)
 
  local buttonTag = {}
  local aExchangeScene = self
  local ExchangeTableViewRenderer = class(TableViewRenderer)
 
  
  
  local firstStarPosX,firstStarPosY, starPixielX
  
  self.mainUI:getChildByName("txt_1"):getChildByName("txt"):setString(getTextByKey("equipEnhance_CoinConsume"))
   
  
  
  local container = self
  function ExchangeTableViewRenderer:ctor(width, height)
    self.list = aExchangeScene.dataList
  end

  --创建单元
  function ExchangeTableViewRenderer:buildCell(container)
    --print("buildCell")
    local builder = LayoutBuilder:createWithContentsOfFile("scene/details_card.json")
    local aCombineCell = builder:build("list_equipmen_common")
    container:addChild(aCombineCell)
    aCombineCell:setTag(cellTag)
   
    for i = 1, 3 do
      local aCell = aCombineCell:getChildByName("list_equipmen" .. i)
      aCell:setTag(-10 - i)
      
      local aEmptyCell = aCombineCell:getChildByName("list_equipmen_empty" .. i)
      aEmptyCell:setVisible(false)
      aEmptyCell:setTag(-20 - i)


      local  aEmptyCelltxt = aEmptyCell:getChildByName("txt_1")
      aEmptyCelltxt:setTag(-11)
      aEmptyCelltxt:getChildByName("txt"):setTag(-11)

      --装备图标
      local aGoodIcon = aCombineCell:getChildByName("reward_normal_card_small_sb"..i)--11
      aGoodIcon:setVisible(false)
      aGoodIcon:setTag(-110-i)

      --装备等级
      local aNowLevelTxt = aCombineCell:getChildByName("txt_level"..i)--12
      aNowLevelTxt:setTag(-120-i)
      aNowLevelTxt:getChildByName("txt"):setTag(-120-i)

      --装备名字
      local aNameTxt = aCombineCell:getChildByName("txt_details_card_21_"..i)--14
      aNameTxt:setTag(-140-i)
      aNameTxt:getChildByName("txt"):setTag(-140-i)

      --强化旧等级
      local aOldLevelTxt = aCell:getChildByName("txt_details_card_14")
      aOldLevelTxt:setTag(-15)
      aOldLevelTxt:getChildByName("txt"):setTag(-15)

      local aOldLevelTxt1 = aCell:getChildByName("txt_new")
      aOldLevelTxt1:setTag(-33)
      aOldLevelTxt1:getChildByName("txt"):setTag(-33)

      --强化新等级
      local aNewLevelTxt = aCell:getChildByName("txt_3")
      aNewLevelTxt:setTag(-16)
      aNewLevelTxt:getChildByName("txt"):setTag(-16)

      --最高等级
      local aHighLevelTxt = aCell:getChildByName("txt_2")
      aHighLevelTxt:setTag(-17)
      aHighLevelTxt:getChildByName("txt"):setTag(-17)

      --强化数据
      local aUpgradeDataTxt = aCell:getChildByName("txt_5")
      aUpgradeDataTxt:setTag(-18)
      aUpgradeDataTxt:getChildByName("txt"):setTag(-18)

      --强化数据2
      local aUpgradeNewDataTxt = aCell:getChildByName("txt_1")
      aUpgradeNewDataTxt:setTag(-19)
      aUpgradeNewDataTxt:getChildByName("txt"):setTag(-19)

       --强化加成数据
      local aAdditionDataTxt = aCell:getChildByName("txt_4")
      aAdditionDataTxt:setTag(-20)
      aAdditionDataTxt:getChildByName("txt"):setTag(-20)
      

    local POSx = aCell:getChildByName("formation_icon_star_sb"):getPositionX()
    local POSY = aCell:getChildByName("formation_icon_star_sb"):getPositionY()
    for i = 1, 7
    do
      local aStarSpt = Sprite:create(UI_RES_PATH.."/common_new/common_star_sb.png")
      aStarSpt:setAnchorPoint(ccp(0,1))
      POSx = POSx + 28
      aStarSpt:setPosition(ccp(POSx,POSY))
      aStarSpt:setTag( TAG_FIRST_STAR - 1 + i)
      aCell:addChild(aStarSpt)
    end

      -- --强化到Max
      local aMaxDataTxt = aCell:getChildByName("txt_details_card_46")
      aMaxDataTxt:setTag(-21)
      aMaxDataTxt:getChildByName("txt"):setTag(-21)
      --
      -- aMaxDataTxt:getChildByName("txt"):setString("123")


      --左边血量标志
      local aLeftHpIcon = aCell:getChildByName("card_icon_hp")
      aLeftHpIcon:setVisible(false)
      aLeftHpIcon:setTag(-22)
      --左边防标志
      local aLeftDefIcon = aCell:getChildByName("card_icon_def")
      aLeftDefIcon:setVisible(false)
      aLeftDefIcon:setTag(-23)
      --左边攻标志
      local aLeftAttIcon = aCell:getChildByName("card_icon_atk")
      aLeftAttIcon:setVisible(false)
      aLeftAttIcon:setTag(-24)
      --右边血量标志
      local aRightHpIcon = aCell:getChildByName("card_icon_hp2")
      aRightHpIcon:setVisible(false)
      aRightHpIcon:setTag(-25)
      --右边防标志
      local aRightDefIcon = aCell:getChildByName("card_icon_def 2")
      aRightDefIcon:setVisible(false)
      aRightDefIcon:setTag(-26)
      --右边攻标志
      local aRightAttIcon = aCell:getChildByName("card_icon_atk2")
      aRightAttIcon:setVisible(false)
      aRightAttIcon:setTag(-27)
      --Max标志
      local aLeftHpIcon = aCell:getChildByName("icon_max")
      aLeftHpIcon:setVisible(false)
      aLeftHpIcon:setTag(-28)
      
      local aRightLVIcon = aCell:getChildByName("formation_icon_lv_sb2")
      aRightLVIcon:setVisible(false)
      aRightLVIcon:setTag(-30)

      local aRightLVIcon = aCell:getChildByName("card_icon_arrow_green_sb")
      aRightLVIcon:setVisible(false)
      aRightLVIcon:setTag(-32)

      local aChooseBtnIcon = aCombineCell:getChildByName("btn_the_choose"..i)
      aChooseBtnIcon:setVisible(false)
      aChooseBtnIcon:setTag(-310-i)
      aChooseBtnIcon:getChildByName("btn"):setTag(-310-i)
      local Btndisplaytxt1 = aChooseBtnIcon:getChildByName("txt")
      Btndisplaytxt1:setString(getTextByKey("strengthenAll_up"))
      -- card_icon_arrow_green_sb
       


      local CheckBox = aCombineCell:getChildByName("btn_not_selected_all"..i)--29
      CheckBox:setVisible(false)
      CheckBox:setTag(-201-i)
      local SelectedBox = aCombineCell:getChildByName("btn_selected_all"..i)--33
      SelectedBox:setVisible(false)
      SelectedBox:setTag(-301-i)
    
    end
    
  end
  
  local function setNodeVisibleByTag(cell, tag, visible)
    cell:getChildByTag(tag):setVisible(visible)
  end

  local function setTextByTag(cell, tag, str)
    local txt = cell:getChildByTag(tag):getChildByTag(tag)
    setNodeText(txt, str)
  end

  local function setColorByTag(cell, tag,color)
    local txt = cell:getChildByTag(tag):getChildByTag(tag)
    txt:setColor(color)
  end
  
  



  local function AdjudeUpgradeType(metaId,level)

    self.equipMetaConfig = MetaManager.equip_meta[tonumber(metaId, 10)]
    self.equipLevelConfig = MetaManager.equip_level[level]
  
    if tonumber(self.equipMetaConfig.basicAtk, 10) > 0 then
      self.equipProperty = EquipPropertyEnum.kAttack
      self.propertyValue = self.equipMetaConfig.basicAtk + self.equipMetaConfig.atkSCoe * self.equipLevelConfig.atk
    elseif tonumber(self.equipMetaConfig.basicDefence, 10) > 0 then
      self.equipProperty = EquipPropertyEnum.kDefence
      self.propertyValue = self.equipMetaConfig.basicDefence + self.equipMetaConfig.defSCoe * self.equipLevelConfig.def
    elseif tonumber(self.equipMetaConfig.basicHp, 10) > 0 then
      self.equipProperty = EquipPropertyEnum.kHp
      self.propertyValue = self.equipMetaConfig.basicHp + self.equipMetaConfig.hpSCoe * self.equipLevelConfig.hp
    end
    self.propertyValue = math.modf(self.propertyValue)
    
    for _, v in ipairs(MetaManager.equip_evolve_level) do
      if tonumber(self.equipMetaConfig.evolveLevel, 10) == tonumber(v.evolveLevel, 10) then
        self.equipEvolveLevelConfig = v
        break
      end
    end

      local currUser = DataManager.getCurrUser()
      if currUser.level ~= level then
          local quickUpgradeCost = 0
          
          
          local tempMaxLevel = math.min(tonumber(self.equipEvolveLevelConfig.levelMax, 10), currUser.level)
          -- print("~~~~~~~~~~~~~~~~~~level = "..tostringRich(level))
            self.quickUpgradeLevel = tempMaxLevel
            for i = level, tempMaxLevel - 1 do
              local aEquipLevelConfig = MetaManager.equip_level[i]
              local aCost = tonumber(self.equipMetaConfig.coinConsumeCoe, 10) * tonumber(aEquipLevelConfig.upgradeCoinBase, 10)
              -- if (quickUpgradeCost + math.modf(aCost)) <= tonumber(currUser.coins, 10) then
                quickUpgradeCost = quickUpgradeCost + aCost
                quickUpgradeCost = math.modf(quickUpgradeCost)
                -- self.quickUpgradeLevel = i + 1
            end
         
          -- print("~~~~~~~~~~~~~~~~~~~self.quickUpgradeLevel = "..self.quickUpgradeLevel)
        
        self.nextEquipLevelConfig = MetaManager.equip_level[tempMaxLevel]
        if tonumber(self.equipMetaConfig.basicAtk, 10) > 0 then
          self.additionPropertyValue = math.modf(self.equipMetaConfig.basicAtk + self.equipMetaConfig.atkSCoe * self.nextEquipLevelConfig.atk) - self.propertyValue
        elseif tonumber(self.equipMetaConfig.basicDefence, 10) > 0 then
          self.additionPropertyValue = math.modf(self.equipMetaConfig.basicDefence + self.equipMetaConfig.defSCoe * self.nextEquipLevelConfig.def) - self.propertyValue
        elseif tonumber(self.equipMetaConfig.basicHp, 10) > 0 then
          self.additionPropertyValue = math.modf(self.equipMetaConfig.basicHp + self.equipMetaConfig.hpSCoe * self.nextEquipLevelConfig.hp) - self.propertyValue
        end
      end

  end


  
  --获得数据
  function ExchangeTableViewRenderer:setData( rawCocosObj, index )
    local aCombineCell = self:getChildByTag(rawCocosObj, cellTag)
    local aCombineData = self.list[index+1]
    local aCardNo = index+1
    
    -- container.CoinList = {}
    local AllCost = 0

    for i=1,3 do
      local oldIcon = aCombineCell:getChildByTag(-100-i)
        if oldIcon then
          oldIcon:removeFromParentAndCleanup(true)
        end
      local cell = aCombineCell:getChildByTag(-10 - i)
      local Emptycell = aCombineCell:getChildByTag(-20 - i)
      setNodeVisibleByTag(cell,-22,false)
      setNodeVisibleByTag(cell,-23,false)
      setNodeVisibleByTag(cell,-24,false)
      setNodeVisibleByTag(cell,-25,false)
      setNodeVisibleByTag(cell,-26,false)
      setNodeVisibleByTag(cell,-27,false)
      setNodeVisibleByTag(aCombineCell,-201-i,false)
      setNodeVisibleByTag(aCombineCell,-301-i,false)
      setNodeVisibleByTag(aCombineCell,-140-i,false)
      setNodeVisibleByTag(aCombineCell,-110-i,false)
      
      if aCombineData.equips[i] ~= nil then
        cell:setVisible(true)
        Emptycell:setVisible(false)
        aCombineCell:getChildByTag(-110-i):setVisible(false)
        setNodeVisibleByTag(aCombineCell,-140-i,true)
      
        local key = i
        local aEquip = aCombineData.equips[i]
        local currUser = DataManager.getCurrUser()
        AdjudeUpgradeType(aEquip["metaId"],aEquip.level)
        -- container:AcountCoin(aCardNo,i,aEquip,container.equipMetaConfig,container.equipEvolveLevelConfig)
        
    
        for i = 1, 7 do
          setNodeVisibleByTag(cell, TAG_FIRST_STAR - 1 + i, i <MetaManager.equip_meta[aEquip["metaId"]]["quality"])--quality

        end 
        

       local aCardDisplay = aCombineCell:getChildByTag(-110-i)

       -- print("~~~~~~~~~~~~~~~~~~~~aCardDisplay.x"..tostring(aCardDisplay:getPositionX()))
       -- print("~~~~~~~~~~~~~~~~~~~~aCardDisplay.y"..tostring(aCardDisplay:getPositionY()))
        
        local params = {}
        params.sourceDisplay = aCardDisplay
        params.showInCenter = true
        -- print("~~~~~~~~~~~~~container.upgardeEquipId = "..tostringRich(container.upgardeEquipId))
        

        local icon = CanonGoodIcon.createGoodIcon(ResourceEnum.EQUIP, aEquip["metaId"], 0, params)
        local item_lv_bg = Sprite:createWithSpriteFrameName("item_lv_bg.png")
        item_lv_bg:setPosition(ccp(23, 49))
        card_lv = TextField:create("lv" .. aEquip.level,"Arial", 20)
        card_lv:setPosition(ccp(42, 10))
        item_lv_bg:addChild(card_lv)
        icon:addChild(item_lv_bg)
        aCombineCell:addChild(icon.refCocosObj,2001)
        if icon then
          icon:setTag(-100-i)
          icon:dispose()
        end
        
        local equipNameLabel = aCombineCell:getChildByTag(-140-i):getChildByTag(-140-i)
        --equipNameLabel = tolua.cast(equipNameLabel, "CCLabelTTF")
        setNodeText(equipNameLabel,getTextByKey(MetaManager.equip_meta[aEquip["metaId"]]["name"]))
        
        aCombineCell:getChildByTag(-140-i):setZOrder(2001)
       
        
        -- local MaxLevel = MetaManager.equip_evolve_level[MetaManager.equip_meta[aEquip["metaId"]].evolveLevel].levelMax
        local metaIdConfig = MetaManager.equip_meta[aEquip["metaId"]]
        -- print("~~~~~~~~~~~metaIdConfig = "..tostringRich(metaIdConfig.evolveLevel))
        if metaIdConfig.evolveLevel < metaIdConfig.maxEvolveLevel then
            -- print("~~~~~~~~~~~~~~满阶")
            aCombineCell:getChildByTag(-310-i):getChildByTag(-310-i):setVisible(true)
        else
        --   print("~~~~~~~~~~~~~~未满阶"..tostringRich(aEquip))
             aCombineCell:getChildByTag(-310-i):getChildByTag(-310-i):setVisible(false)
        end
        setTextByTag(cell,-15,aEquip.level)
        setTextByTag(cell,-33,"/"..container.equipEvolveLevelConfig.levelMax)
        setTextByTag(cell,-18,container.propertyValue)
        if container.equipProperty == EquipPropertyEnum.kAttack then
          setNodeVisibleByTag(cell,-24,true)
        elseif container.equipProperty == EquipPropertyEnum.kDefence then
          setNodeVisibleByTag(cell,-23,true)
        elseif container.equipProperty == EquipPropertyEnum.kHp then
          setNodeVisibleByTag(cell,-22,true)
        end

        if container.equipEvolveLevelConfig.levelMax == aEquip.level then

          setNodeVisibleByTag(cell,-30,false)
          setNodeVisibleByTag(cell,-19,false)
          setNodeVisibleByTag(cell,-20,false)
          setNodeVisibleByTag(cell,-17,false)
          setNodeVisibleByTag(cell,-16,false)
          setNodeVisibleByTag(aCombineCell,-201-i,false)
          setNodeVisibleByTag(aCombineCell,-301-i,false)
          setNodeVisibleByTag(cell,-28,true)
          setNodeVisibleByTag(cell,-21,true)
          setNodeVisibleByTag(cell,-32,true)
          setTextByTag(cell,-21, getTextByKey("equipEnhance_Tips"))--equip_Evolve
          setColorByTag(cell, -15,ccc3(0,0,0))
          setNodeVisibleByTag(aCombineCell,-310-i,true)
          

          
        elseif aEquip.level == currUser.level  then
          setNodeVisibleByTag(cell,-30,false)
          setNodeVisibleByTag(cell,-19,false)
          setNodeVisibleByTag(cell,-20,false)
          setNodeVisibleByTag(cell,-17,false)
          setNodeVisibleByTag(cell,-16,false)
          setNodeVisibleByTag(aCombineCell,-201-i,false)
          setNodeVisibleByTag(aCombineCell,-301-i,false)
          setNodeVisibleByTag(cell,-28,false)
          setNodeVisibleByTag(cell,-21,false)
          setNodeVisibleByTag(cell,-32,false)
          setNodeVisibleByTag(aCombineCell,-310-i,false)
          setColorByTag(cell, -15,ccc3(234 ,85,4))
        else
          -- print("~~~~~~~~~~~~~~~~有勾选框")
          setNodeVisibleByTag(cell,-30,true)
          setNodeVisibleByTag(cell,-19,true)
          setNodeVisibleByTag(cell,-20,true)
          setNodeVisibleByTag(cell,-17,true)
          setNodeVisibleByTag(cell,-16,true)
          setNodeVisibleByTag(aCombineCell,-301-i,true)
          setNodeVisibleByTag(aCombineCell,-201-i,true)
          setNodeVisibleByTag(cell,-28,false)
          setNodeVisibleByTag(cell,-21,false)
          setNodeVisibleByTag(cell,-32,true)
          setNodeVisibleByTag(aCombineCell,-310-i,false)
          setColorByTag(cell, -15,ccc3(0,0,0))
          if container.equipProperty == EquipPropertyEnum.kAttack then
            setNodeVisibleByTag(cell,-27,true)
          elseif container.equipProperty == EquipPropertyEnum.kDefence then
            setNodeVisibleByTag(cell,-26,true)
          elseif container.equipProperty == EquipPropertyEnum.kHp then
            setNodeVisibleByTag(cell,-25,true)
          end
          setTextByTag(cell,-19,container.propertyValue)
          setTextByTag(cell,-20,"+"..container.additionPropertyValue)
          setTextByTag(cell,-16,container.quickUpgradeLevel)
          setTextByTag(cell,-17,"/"..container.equipEvolveLevelConfig.levelMax)

        end


      else
         cell:setVisible(false)
         Emptycell:setVisible(true)
          
         setTextByTag(Emptycell,-11,getTextByKey("strengthenAll_text"..i))
      end
    end
  end

   -- 设置table每个元素的监听器
  --------------------
  local function onListItemTouch( evt )
    local aIndex = evt.data
    local aCell = self.listTableView:cellAtIndex(aIndex)
    local posInCell = aCell:convertToNodeSpace(evt.globalPosition)
    local childs = aCell:getChildByTag(cellTag)

    -- print("~~~~~~~~~~~~~~~aIndex = "..aIndex)
    local iconSize = {
      height = 110,
      width = 110,
    }--]]
    local checkSize ={
    height = 45,
    width = 45,
  }

    local upgradeSize ={
    height = 50,
    width = 133,
  }

    local CellSize ={
    height = 200,
    width = 680,
  }
    
    function getTouchedItemIndex()
     
      local aCombineData = container.queue[aIndex+1]

      for i=1, 3 do
        local aEquip = aCombineData.equips[i]
        if aEquip then
          local aBtnArea = childs:getChildByTag(-110-i)
          
          if ((posInCell.x > aBtnArea:getPositionX()-iconSize.width*0) and
            (posInCell.x < aBtnArea:getPositionX()+iconSize.width) and
            (posInCell.y > aBtnArea:getPositionY()-iconSize.height*0.9) and
            (posInCell.y < aBtnArea:getPositionY()+iconSize.height/20)) then
            return i
          end
        end
      end

      for i=1,3 do
        local aEquip = aCombineData.equips[i]
        if aEquip then
          local aBtnArea = childs:getChildByTag(-301-i)
          
          if ((posInCell.x > aBtnArea:getPositionX()-checkSize.width/4) and
            (posInCell.x < aBtnArea:getPositionX()+checkSize.width) and
            (posInCell.y > aBtnArea:getPositionY()-checkSize.height*1.1) and
            (posInCell.y < aBtnArea:getPositionY()+checkSize.height/5)) then
            return i+3
          end
        end
      end
        for i=1,3 do
          local aEquip = aCombineData.equips[i]
          if aEquip then
            local aBtnArea = childs:getChildByTag(-310-i)
            
            if ((posInCell.x > aBtnArea:getPositionX()-upgradeSize.width/20) and
              (posInCell.x < aBtnArea:getPositionX()+upgradeSize.width*1.3) and
              (posInCell.y > aBtnArea:getPositionY()-upgradeSize.height*1.1) and
              (posInCell.y < aBtnArea:getPositionY()+upgradeSize.height/5)) then
              return i+6
            end
          end
        end

        for i=1,3 do
          local aEquip = aCombineData.equips[i]
          if not aEquip then
            local aBtnArea = childs:getChildByTag(-20 - i)
            
            if ((posInCell.x > aBtnArea:getPositionX()-CellSize.width/10) and
              (posInCell.x < aBtnArea:getPositionX()+CellSize.width) and
              (posInCell.y > aBtnArea:getPositionY()-CellSize.height/20) and
              (posInCell.y < aBtnArea:getPositionY()+CellSize.height)) then
              return i+9
            end
          end
        end
      
      return -1
    end

    function handleEquipMateIdList(equipId,num)
      for i,Id in ipairs(container.upgardeEquipId) do
        if Id == equipId then
          table.remove(container.iconPos,i)
          table.remove(container.upgardeEquipId,i)
          return
        end
      end

      local x = childs:getChildByTag(-110-num):getPositionX()
     local y = childs:getChildByTag(-110-num):getPositionY()
     -- print("~~~~~~~~~~~~~position = "..tostringRich(x))
     local flashPos = self.listTableView:convertToWorldSpace(ccp(x, y))
     table.insert(container.iconPos,flashPos)
     table.insert(container.upgardeEquipId,equipId)
    end
    

    local itemIndex = getTouchedItemIndex()
    -- print("~~~~~~~~~~~~~~itemIndex = "..tostring(itemIndex))
    local aCombineData = container.queue[aIndex+1]
    if  (itemIndex<4 and itemIndex>0) then

    
   
      local aEquip = aCombineData.equips[itemIndex]
      if aEquip then
        local argv = {
                          enterScene = "EquipQuickUpgradeScene",
                          returnScene = "EquipQuickUpgradeScene",
                          originalScene = "EquipQuickUpgradeScene",
                          params = {
                                     equip = aEquip,
                                     container = {queue = container.queue},
                                     cardPos = self.selectedCardNo,
                                     EquipPos = itemIndex,

                                  }

                       }
        local targetInfoPanel = EquipInfoNewPanel:create(aEquip, argv)
        PopoutManager:sharedManager():popout(targetInfoPanel, kPopoutDir.kScale, true, false ,self) 
      end
    elseif (itemIndex<7 and itemIndex>3) then
        if childs:getChildByTag(-201-itemIndex+3):isVisible() then
          local coin = self.CoinCellList[itemIndex-3]
          local aEquip = aCombineData.equips[itemIndex-3]
          handleEquipMateIdList(aEquip["equipId"],itemIndex-3)
          if childs:getChildByTag(-301-itemIndex+3):isVisible() then
            self.allCost = self.allCost - coin
            container:setMoney(self.allCost)
            childs:getChildByTag(-301-itemIndex+3):setVisible(false)
          else
            self.allCost = self.allCost + coin
            container:setMoney(self.allCost)
            childs:getChildByTag(-301-itemIndex+3):setVisible(true)
          end
          -- print("~~~~~~~~~~~~~~~~~~~~~~~~~话费的银币 = "..tostring(coin))
        end 
      elseif (itemIndex<10 and itemIndex>6) then
         -- print("~~~~~~~~~~~~~~升阶")
          if childs:getChildByTag(-310-itemIndex+6):isVisible()  then
           local aEquip = aCombineData.equips[itemIndex-6]
           if aEquip then
            local metaIdConfig = MetaManager.equip_meta[aEquip["metaId"]]
            
             local argv = {
                            enterScene = "EquipQuickUpgradeScene",
                            returnScene = "EquipQuickUpgradeScene",
                            originalScene = "EquipQuickUpgradeScene",
                            params = {
                                       equip = aCombineData.equips[itemIndex-6],
                                       container = {queue = container.queue},
                                       cardPos = self.selectedCardNo,
                                       EquipPos = itemIndex-6,

                                    }

                         }
            if metaIdConfig.evolveLevel < metaIdConfig.maxEvolveLevel then
             self:replaceScene( EquipEvolveScene, argv )
            end
          end 
        end
      elseif (itemIndex<13 and itemIndex>9) then
        local aEquip = aCombineData.equips[itemIndex-9]

        if not aEquip then
          if childs:getChildByTag(-20-itemIndex+9):isVisible() and  (not childs:getChildByTag(-10-itemIndex+9):isVisible()) then
            
           
             local Quickargv = {
                            enterScene = "CardQueueScene",
                            returnScene = "CardQueueScene",
                           
                            params = {
                                       equip = aCombineData.equips[itemIndex-9],
                                       container = {queue = container.queue},
                                       cardPos = self.selectedCardNo,
                                       EquipPos = itemIndex-9,

                                    }
                          }
                HeMemDataHolder:setInteger("EquipChange_Position", itemIndex-9)
                HeMemDataHolder:setInteger("EquipChange_NowEquipId", 0)
                local argv = {
                  enterScene="CardQueueScene",
                  returnScene="CardQueueScene",
                    params={
                      --cardPos = cardNo,
                      cardId = aCombineData.cardId,
                      tabIndex = BAGCATEGORY.equip,
                      filter = BACKPACK_FILTER.EQUIP,
                      filterFunc = CardQueueScene.equipFilterFunc,
                      isCardTrain = false,
                      argvs = Quickargv,
                      
                    }
                }
                self:replaceScene( BackpackScene , argv)
          end
        end
    end
  end
  
  local function onSelectItem( evt )
    if container.selectedCardNo and container.selectedCardNo == evt.globalPosition + 1 then
      return
    end
    container.selectedCardNo = evt.globalPosition + 1
    container:setCurrentSelectIndex(container.selectedCardNo)
  end

  --开始
  
  self.mainUI:getChildByName("list_equipmen_common"):setVisible(false)


  local renderer = ExchangeTableViewRenderer.new(exchangeItem_width, exchangeItem_height)
  local aTableView = TableView:create(renderer, exchangeTable_width, exchangeTable_height, cellTag, buttonTag)
  aTableView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch)
  aTableView:addEventListener(DisplayEvents.kSelectItem, onSelectItem , self)
  aTableView:setPosition(ccp(exchangeTable_posX, exchangeTable_posY))
  aTableView:setDirection(kCCScrollViewDirectionHorizontal)
  aTableView:setPageEnabled(true)--自动对齐位置
  self.table = aTableView
  -- aTableView:setDragEnabled(false)--不能拖拽
  return aTableView
end



--计算强化的银币数
function EquipQuickUpgradeScene:AcountAllCoin(select)
  -- for i,aCard in ipairs(self.queue) do
  -- print("~~~~~~~~~~~~~~select = "..select)
    local aCard = self.queue[select]
    local aCell = self.listTableView:cellAtIndex(select-1)
    local childs = aCell:getChildByTag(cellTag)
    if aCard.equips then
      -- print("~~~~~~~~~~~~~~aEquip = "..tostringRich(aCard.equips))
       for i=1,3 do
        

        if aCard.equips[i] ~= nil then
          local aEquip = aCard.equips[i]
           -- AdjudeUpgradeType(aEquip["metaId"],aEquip.level)
           local equipMetaConfig = MetaManager.equip_meta[tonumber(aEquip["metaId"], 10)]
           local equipEvolveLevelConfig = nil
            for _, v in ipairs(MetaManager.equip_evolve_level) do
              if tonumber(equipMetaConfig.evolveLevel, 10) == tonumber(v.evolveLevel, 10) then
                equipEvolveLevelConfig = v
                break
              end
            end
          local quickUpgradeCost = 0
          local quickUpgradeLevel = 0
          local currUser = DataManager.getCurrUser()
          local tempMaxLevel = math.min(tonumber(equipEvolveLevelConfig.levelMax, 10), currUser.level)
          if tempMaxLevel == aEquip.level then
            quickUpgradeCost = 0
          else
            for i = aEquip.level, tempMaxLevel - 1 do
              local aEquipLevelConfig = MetaManager.equip_level[i]
              local aCost = tonumber(equipMetaConfig.coinConsumeCoe, 10) * tonumber(aEquipLevelConfig.upgradeCoinBase, 10)
              -- if (self.quickUpgradeCost + math.modf(aCost)) <= tonumber(currUser.coins, 10) then
                quickUpgradeCost = quickUpgradeCost + aCost
                quickUpgradeCost = math.modf(quickUpgradeCost)
                -- quickUpgradeLevel = i + 1
              -- else
              --   break
              -- end
            end
          end
          self.allCost = self.allCost + quickUpgradeCost
          self.CoinCellList[i] = quickUpgradeCost
          if quickUpgradeCost ~= 0 then
             local x = childs:getChildByTag(-110-i):getPositionX()
             local y = childs:getChildByTag(-110-i):getPositionY()
             -- print("~~~~~~~~~~~~~position = "..tostringRich(x))
             local flashPos = ccp(x, y)
             table.insert(self.iconPos,flashPos)
             table.insert(self.upgardeEquipId,aEquip["equipId"])
             if childs:getChildByTag(-201-i):isVisible() then
               if not childs:getChildByTag(-301-i):isVisible() then
                 childs:getChildByTag(-301-i):setVisible(true)
               end
             end
          end
          
        end
      end
    end
  -- end
   
   
end


-- --全部清空
-- function EquipQuickUpgradeScene.allClear()
--   EquipQuickUpgradeScene.clearSaleInfoHash()
-- end

-- 返回按钮
----------------------------------------
function EquipQuickUpgradeScene:back()
  if (self.argv.returnScene == "CardQueueScene") then
      self:replaceScene(CardQueueScene, {enterScene="EquipQuickUpgradeScene", returnScene= (self.argv.params and self.argv.params.preReturnScene)})
  end
 
end

----------------------------------------
-- 进入场景动画,被父类onInit()方法调用
----------------------------------------
function EquipQuickUpgradeScene:doEnterAnimation()
  self:preEnterAnimation()
  self:startEnterAnimation()
end

----------------------------------------
----------------------------------------
function EquipQuickUpgradeScene:preEnterAnimation()
  BaseUIScene.preEnterAnimation(self)
end

----------------------------------------
----------------------------------------
function EquipQuickUpgradeScene:startEnterAnimation()
  BaseUIScene.startEnterAnimation(self)
  local function enterActionFinished()
    self:nodeAnimationFinished()
  end
  self.mainUI:setPositionX(self.mainUI:getPositionX() - visibleSize.width)
  local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.mainUI:runAction(CCSequence:create(arr))
  self.listTableView:setPositionX(self.listTableView:getPositionX() - visibleSize.width)
  self.listTableView:runAction(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
  
 
end

----------------------------------------
-- 场景切换时，被父类的replaceScene调用
----------------------------------------
function EquipQuickUpgradeScene:doExitAnimation()
   self:preExitAnimation()
   self:startExitAnimation()
   self.listTableView:runAction(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0))) 
   --self.arrowLayer:runAction(CCMoveBy:create(0.5, ccp(-visibleSize.width, 0))) 
end

----------------------------------------
----------------------------------------
function EquipQuickUpgradeScene:preExitAnimation()
  BaseUIScene.preExitAnimation(self)
end

----------------------------------------
----------------------------------------
function EquipQuickUpgradeScene:startExitAnimation()
  BaseUIScene.startExitAnimation(self)
  local function enterActionFinished()
    self:nodeAnimationFinished()
  end
  local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width-100, 0)))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.mainUI:runAction(CCSequence:create(arr))
end

----------------------------------------
----------------------------------------
function EquipQuickUpgradeScene:sufExitAnimation()
  BaseUIScene.sufExitAnimation(self)
end

function EquipQuickUpgradeScene:dispose()
  EquipQuickUpgradeScene.super.dispose(self)
end