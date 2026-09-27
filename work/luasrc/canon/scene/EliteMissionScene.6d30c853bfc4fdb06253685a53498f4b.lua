--------------------------------------------------------------------------------
-- EliteMissionScene.lua - 精英关卡界面: 动态显示所有精英关卡状态，购买挑战次数，发起挑战
-- author: xiaojie.bai
-- date: 2013-09-26 10:40
--------------------------------------------------------------------------------

require "canon.scene.BaseUIScene"

require "canon.models.EliteManager"
require "canon.models.CalculationManager"
require "canon.models.RewardManager"
require "canon.canonUtils"
require "canon.utils.ViewControlUtil"
require "canon.utils.IdUtil"

require "canon.panel.EliteSweepConfirmPopmPanel"
require "canon.panel.CanonMessageBox"
require "canon.panel.AssistantMessageBoxPanel"
require "canon.request.GetEliteInfoRequest"
require "canon.request.ChallengeEliteRequest"
require "canon.request.ResetEliteRequest"

require "canon.manager.BagCalcManager"
require "canon.manager.DailyDataManager"

require "canon.data.MetaManager"

--焦点变化事件
local function onFocusChanged(evt)
  local self = evt.context
  self:setTableViewsEnabled(evt.data == nil)
end

------------------------------------------------------------------------------------------------------

EliteMissionScene = class(BaseUIScene)
local visibleSize = CCDirector:sharedDirector():getVisibleSize()

function EliteMissionScene:ctor()
  self.title = getTextByKey("elite_title")
  self.argv = nil
  
  self.mainUI = nil
  self.contentLayer = nil
  
  self.missionTableView = nil
  self.cityTableView = nil
end

function EliteMissionScene:create(argv)
  local scene = EliteMissionScene.new()
  
  if(argv) then
    scene.argv = argv
  else 
    scene.argv = {enterScene = nil, returnScene = nil, params = {}}
  end
  
  scene.paramEliteMissionId = scene.argv.params.eliteMissionId
  
  scene.maxMissionId = 0 --最大普通关卡id
  scene.selectedCityId = nil --当前选择的城市id
  scene.selectedCityTableIdx = nil --城市菜单选中
  scene.selectedMissionId = nil --当前选择的关卡id
  
  scene.eliteInfo = {maxFinishedEliteId = 0, lstSharkEliteInfo = {}} --玩家的关卡信息
  scene.maxFinishedEliteId = 0
  scene.id2EliteInfo = {}
  scene.cityTableView = nil
  scene.missionTableView = nil
  
  scene.currUser = DataManager.getCurrUser()
  scene.vipLevel = scene.currUser.vipLevel
  
  scene:initScene()
  return scene
end

function EliteMissionScene:back()
  local returnScene = self.argv.returnScene or ChallengeEntersScene
  if(returnScene == "EquipEvolveScene" or returnScene == EquipEvolveScene) then
    returnScene = MainMenuScene 
  end
  
  self:replaceScene(returnScene)
end

function EliteMissionScene:setTableViewsEnabledInner(v)
  if(self.cityTableView) then
    self.cityTableView:setTouchEnabled(v)
  end
  if(self.missionTableView) then
    self.missionTableView:setTouchEnabled(v)
  end
end

--------------------
-- 创建城池标签
--------------------
function EliteMissionScene:createCityTableView()
  local eliteCityInfos = EliteManager.getCityInfos(self.maxFinishedEliteId)
  local maxCityId = EliteManager.DICT.FIRST_ELITE_CITYID
  if(eliteCityInfos and #eliteCityInfos > 0) then
    maxCityId = eliteCityInfos[#eliteCityInfos].cityId
  end
  if(maxCityId < self.selectedCityId) then
    self.selectedCityId = maxCityId
  end
  
  local builder = LayoutBuilder:createWithContentsOfFile(EliteManager.DICT.RESOURCE_FILE)
  local selectedCityId = self.selectedCityId
  for idx, cityInfo in ipairs(eliteCityInfos) do
    cityInfo.selected = false
    if(cityInfo.cityId == selectedCityId) then
      cityInfo.selected = true
      self.selectedCityTableIdx = idx
    end
  end
  
  local CityTableViewRenderer = class(TableViewRenderer)
  function CityTableViewRenderer:ctor(width, height)
    self.list = eliteCityInfos
  end
  
  function CityTableViewRenderer:buildCell(container)
    local aCell = builder:build("btn/elite_btn_title_city")
    container:addChild(aCell)
    aCell:setTag(-1001)
    
    local font = aCell:getChildByName("font")
    font:setTag(-10)
    local btn = aCell:getChildByName("btn")
    btn:setTag(-11)
    local disable = aCell:getChildByName("disable")
    disable:setTag(-12)
    local inactive = aCell:getChildByName("inactive")
    inactive:setTag(-13)
  end
  
  function CityTableViewRenderer:setData(rawCocosObj, index)
    local aCell = self:getChildByTag(rawCocosObj, -1001)
    
    local eliteCityInfo = self.list[index + 1]
    local font = aCell:getChildByTag(-10)
    ViewControlUtil.setLableText(font, getTextByKey(eliteCityInfo.cityNameKey))
    
    if(eliteCityInfo.selected) then
      aCell:getChildByTag(-11):setVisible(true)
      aCell:getChildByTag(-12):setVisible(false)
      aCell:getChildByTag(-13):setVisible(false)
    elseif(eliteCityInfo.open) then
      aCell:getChildByTag(-11):setVisible(false)
      aCell:getChildByTag(-12):setVisible(true)
      aCell:getChildByTag(-13):setVisible(false)
    else
      aCell:getChildByTag(-11):setVisible(false)
      aCell:getChildByTag(-12):setVisible(false)
      aCell:getChildByTag(-13):setVisible(true)
    end
  end
  
  local function onListItemTouch(evt)
    local index = evt.data + 1
    if(index == self.selectedCityTableIdx) then
      return nil
    end
    
    local aCell = self.cityTableView:cellAtIndex(index - 1)
    local posInCell = aCell:convertToNodeSpace(evt.globalPosition)
    local btnCity = aCell:getChildByTag(-1001)
    local picBtnCity = btnCity:getChildByTag(-11)
    if (posInCell.x < btnCity:getPositionX() or posInCell.x > (btnCity:getPositionX() + picBtnCity:getContentSize().width)) then
      return nil
    end
    
    local selectingCityInfo = eliteCityInfos[index]
    if(not selectingCityInfo.open) then
      return nil
    end
    
    for _, cityInfo in ipairs(eliteCityInfos) do
      cityInfo.selected = false
      if(_ == index) then
        cityInfo.selected = true
        self.selectedCityId = cityInfo.cityId
      end
    end
    
    self.selectedCityTableIdx = index
    local needRefresh = true
    if needRefresh then --TODO
      ViewControlUtil.refreshAndLocateTableView(self.cityTableView, index)
    end
    
    --切换城市动画
    local function missionTableExitFinished()
      self.contentLayer:removeChild(self.missionTableView)
      self.missionTableView = self:createMissionTableView(self.selectedCityId)
      self.contentLayer:addChild(self.missionTableView)
      ViewControlUtil.showTableViewAction(self.missionTableView, visibleSize)
    end
    ViewControlUtil.disappearTableViewAction(self.missionTableView, visibleSize, missionTableExitFinished)
  end
  
  local renderer = CityTableViewRenderer.new(EliteManager.DICT.ITEM_CITY_WIDTH, EliteManager.DICT.ITEM_CITY_HEIGHT)
  local aTableView = TableView:create(renderer, EliteManager.DICT.TB_CITY_WIDTH, EliteManager.DICT.TB_CITY_HEIGHT)
  aTableView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch)
  aTableView:setPosition(ccp(EliteManager.DICT.TB_CITY_POSX, EliteManager.DICT.TB_CITY_POSY))
  aTableView:setDirection(kCCScrollViewDirectionHorizontal)
  
  local selectedIdx = 0
  for i, eliteCityInfo in ipairs(eliteCityInfos) do
    selectedIdx = i
    if(self.selectedCityId == eliteCityInfo.cityId) then
      break
    end
  end
  
  ViewControlUtil.refreshAndLocateTableView(aTableView, selectedIdx)
  
  return aTableView
end

--------------------
-- 创建关卡表格
--------------------
function EliteMissionScene:createMissionTableView(cityId, seletedMissionId)
  local id2EliteInfo = self.id2EliteInfo
  local maxFinishedEliteId = self.maxFinishedEliteId
  local maxMissionId = self.maxMissionId
  
  local eliteMissions = EliteManager.getEliteMissionsByCityId(cityId)
  local canRefreshChallengeTimes = EliteManager.canRefreshChallengeTimes(self.vipLevel)
  local eliteConsumeEnergy = EliteManager.getEliteSetting().eliteConsumeEnergy;
  local eliteRefreshGoldCost = EliteManager.getEliteSetting().eliteRefreshGoldCost;
  
  local strConsumeEnergy = getTextByKey("elite_consumeEnergy")
  local strChallengeBtn = getTextByKey("elite_challengeBtn")
  local strChallengeTimes1 = getTextByKey("elite_challengeTimes1")
  local strChallengeTimes2 = getTextByKey("elite_challengeTimes2")
  
  local strEliteMayGet = getTextByKey("elite_reward")
  local strEliteExp = getTextByKey("elite_exp")
  local strEliteCoin = getTextByKey("elite_coin")
  
  local MissionTableViewRenderer = class(TableViewRenderer)
  local builder = LayoutBuilder:createWithContentsOfFile(EliteManager.DICT.RESOURCE_FILE)
  
  function MissionTableViewRenderer:ctor(width, height)
    self.list = eliteMissions
  end
  
  local cellTag = -1001
  local buttonTag = {18}
  function MissionTableViewRenderer:buildCell(container)
    local aCell = builder:build("elite_item_elite_info")
    container:addChild(aCell)
    aCell:setTag(-1001)
    
    local txtChallengeTime1 = aCell:getChildByName("elite_txt_challengeTime1")
    txtChallengeTime1:setTag(10)
    txtChallengeTime1:getChildByName("font"):setTag(10)
    
    local txtChallengeTime2 = aCell:getChildByName("elite_txt_challengeTime2")
    txtChallengeTime2:setTag(11)
    txtChallengeTime2:getChildByName("font"):setTag(10)
    
    local txtChallengeNum = aCell:getChildByName("elite_txt_challengeNum")
    txtChallengeNum:setTag(12)
    txtChallengeNum:getChildByName("font"):setTag(10)
    
    local txtCostEnergyNum = aCell:getChildByName("elite_txt_cost_stamina")
    txtCostEnergyNum:setTag(13)
    txtCostEnergyNum:getChildByName("font"):setTag(10)
    
    local txtCostEnergy = aCell:getChildByName("elite_txt_coststamina")
    txtCostEnergy:setTag(14)
    txtCostEnergy:getChildByName("font"):setTag(10)
    
    local txtEliteName = aCell:getChildByName("elite_txt_elite_name")
    txtEliteName:setTag(15)
    txtEliteName:getChildByName("font"):setTag(10)
    
    local itemFrame1 = aCell:getChildByName("elite_item_frame1")
    itemFrame1:setTag(16)
    
    local btnChallenge = aCell:getChildByName("elite_btn_challenge")
    btnChallenge:setTag(18)
      local btnChallengeFontMid = btnChallenge:getChildByName("font_mid")
      btnChallengeFontMid:setTag(10)
      btnChallengeFontMid:setString(strChallengeBtn)
      btnChallengeFontMid:setVisible(false)
      local btnChallengeFontRight = btnChallenge:getChildByName("font_right")
      btnChallengeFontRight:setTag(11)
      btnChallengeFontRight:setString(strChallengeBtn)
      btnChallengeFontRight:setVisible(false)
      local btnChallengeIconCoinEvent = btnChallenge:getChildByName("icon_coinEvent")
      btnChallengeIconCoinEvent:setTag(12)
      btnChallengeIconCoinEvent:setVisible(false)
      local btnChallengeBtn = btnChallenge:getChildByName("btn")
      btnChallengeBtn:setTag(13)
      btnChallengeBtn:setVisible(false)
      local btnChallengeDisable = btnChallenge:getChildByName("disable")
      btnChallengeDisable:setTag(14)
      btnChallengeDisable:setVisible(false)
    
    local txtExpReward = aCell:getChildByName("elite_txt_expreward"):getChildByName("font"):setString(strEliteExp)
    local txtCoinReward = aCell:getChildByName("elite_txt_coinreward"):getChildByName("font"):setString(strEliteCoin)
    
    local txtEliteExp = aCell:getChildByName("elite_txt_elite_exp")
    txtEliteExp:setTag(19)
    txtEliteExp:getChildByName("font"):setTag(10)
    local txtEliteCoin = aCell:getChildByName("elite_txt_elite_coin")
    txtEliteCoin:setTag(20)
    txtEliteCoin:getChildByName("font"):setTag(10)
    
    local txtMayGet = aCell:getChildByName("elite_txt_mayget")
    txtMayGet:setTag(21)
    txtMayGet:getChildByName("font"):setString(strEliteMayGet)
    
    local txtEquipName = aCell:getChildByName("elite_txt_equipname")
    txtEquipName:setTag(22)
    txtEquipName:getChildByName("font"):setTag(10)
  end
  
  function MissionTableViewRenderer:setData(rawCocosObj, index)
    local aCell = self:getChildByTag(rawCocosObj, -1001)
    
    local eliteMissionInfo = self.list[index + 1]
    local eliteMissionName = getTextByKey(eliteMissionInfo.stageDesc)
    
    --清除图片信息
    local canonItem = aCell:getChildByTag(-10)
    if canonItem then
      canonItem:removeFromParentAndCleanup(true)
    end
    local canonCard = aCell:getChildByTag(-11)
    if canonCard then
      canonCard:removeFromParentAndCleanup(true)
    end
    
    local txtChallengeTime1 = aCell:getChildByTag(10):getChildByTag(10)
    ViewControlUtil.setLableText(txtChallengeTime1, strChallengeTimes1)
    
    local txtChallengeTime2 = aCell:getChildByTag(11):getChildByTag(10)
    ViewControlUtil.setLableText(txtChallengeTime2, strChallengeTimes2)
    
    local txtChallengeNum = aCell:getChildByTag(12):getChildByTag(10)
    local challengeNum = id2EliteInfo[eliteMissionInfo.id] and id2EliteInfo[eliteMissionInfo.id].challengeNum or 0
    ViewControlUtil.setLableText(txtChallengeNum, challengeNum .. "/" .. eliteMissionInfo.maxChallengesPerDay)
    
    local txtCostEnergyNum = aCell:getChildByTag(13):getChildByTag(10)
    ViewControlUtil.setLableText(txtCostEnergyNum, eliteConsumeEnergy)
    
    local txtCostEnergy = aCell:getChildByTag(14):getChildByTag(10)
    ViewControlUtil.setLableText(txtCostEnergy, strConsumeEnergy)
    
    local txtEliteName = aCell:getChildByTag(15):getChildByTag(10)
    ViewControlUtil.setLableText(txtEliteName, eliteMissionName)
    
    local itemFrame1 = aCell:getChildByTag(16)
    local canonItem = nil
    if(eliteMissionInfo.propId > 0) then
      if IdUtil.isCardFragment(eliteMissionInfo.propId) then
        canonItem = getHeadIconNoStarCanonCardByMetaId(eliteMissionInfo.propId)
        if IdUtil.isCardFragment(eliteMissionInfo.propId) then
          local aSmallIcon = Sprite:create("Item/Picture/Prop_soul.png")
          aSmallIcon:setPosition( ccp(37, 47) )
          canonItem:addChild(aSmallIcon)
        end
      elseif IdUtil.isCard(eliteMissionInfo.propId) then
        canonItem = getHeadIconCanonCardByMetaId(eliteMissionInfo.propId)
      else
        canonItem = getCanonItemByMetaId(eliteMissionInfo.propId)
      end
      local itemFrameSb = CocosObject.new(itemFrame1)
      ViewControlUtil.adjustItemByFrame(canonItem, itemFrameSb)
      if IdUtil.isSpirit(eliteMissionInfo.propId) then
        canonItem:setScale(1.2 * canonItem:getScale())
      end
      aCell:addChild(canonItem.refCocosObj, 1003)
      
      canonItem:setTag(-10)
      canonItem:dispose()
    end
    itemFrame1:setVisible(false)
    
    local isUnlock = EliteManager.isEliteMissionUnlock(eliteMissionInfo, maxFinishedEliteId, maxMissionId)
    local isTimesOut = challengeNum >= eliteMissionInfo.maxChallengesPerDay
    local btnChallenge = aCell:getChildByTag(18)
      local btnChallengeFontMid = btnChallenge:getChildByTag(10)
      local btnChallengeFontRight = btnChallenge:getChildByTag(11)
      local btnChallengeIconCoinEvent = btnChallenge:getChildByTag(12)
      if((isTimesOut and canRefreshChallengeTimes) and isUnlock) then
        btnChallengeFontMid:setVisible(false)
        btnChallengeFontRight:setVisible(true)
        btnChallengeIconCoinEvent:setVisible(true)

        --显示按钮上文本
        if EliteManager.canEliteMissionSweep(eliteMissionInfo, maxFinishedEliteId, maxMissionId) then
          --能扫荡
          setNodeText(btnChallengeFontRight, getTextByKey("stage_stageClear"))--扫荡
        else
          --不能扫荡
          setNodeText(btnChallengeFontRight, strChallengeBtn)--挑战
        end
      else
        btnChallengeFontMid:setVisible(true)
        btnChallengeFontRight:setVisible(false)
        btnChallengeIconCoinEvent:setVisible(false)

        --显示按钮上文本
        if EliteManager.canEliteMissionSweep(eliteMissionInfo, maxFinishedEliteId, maxMissionId) then
          --能扫荡
          setNodeText(btnChallengeFontMid, getTextByKey("stage_stageClear"))--扫荡
        else
          --不能扫荡
          setNodeText(btnChallengeFontMid, strChallengeBtn)--挑战
        end
      end
      
      local btnChallengeBtn = btnChallenge:getChildByTag(13)
      local btnChallengeDisable = btnChallenge:getChildByTag(14)
      if((isTimesOut and not canRefreshChallengeTimes) or (not isUnlock)) then
        btnChallengeDisable:setVisible(true)
        btnChallengeBtn:setVisible(false)
        
        btnChallenge.ignoreTouch = true
        if(btnChallenge.setTouchEnabled) then
          btnChallenge:setTouchEnabled(false)
        end
      else
        btnChallengeDisable:setVisible(false)
        btnChallengeBtn:setVisible(true)
        
        btnChallenge.ignoreTouch = false
        if(btnChallenge.setTouchEnabled) then
          btnChallenge:setTouchEnabled(true)
        end
      end
    
    local txtEliteExp = aCell:getChildByTag(19):getChildByTag(10)
    ViewControlUtil.setLableText(txtEliteExp, eliteMissionInfo.exp)
    local txtEliteCoin = aCell:getChildByTag(20):getChildByTag(10)
    ViewControlUtil.setLableText(txtEliteCoin, eliteMissionInfo.coin)
    
    local sbTxtMayGet = aCell:getChildByTag(21)
    local sbTxtEquipName = aCell:getChildByTag(22)
    if(canonItem) then
      local metaId = eliteMissionInfo.propId
      local metaName = nil
      if(IdUtil.isEquip(metaId)) then
        local equipMeta = MetaManager.equip_meta[metaId]
        if(equipMeta) then
          metaName = getTextByKey(equipMeta.name)
        end
      elseif(IdUtil.isProp(metaId)) then
        local propMeta = MetaManager.prop_meta[metaId]
        if(propMeta) then
          metaName = getTextByKey(propMeta.name)
        end
      elseif (IdUtil.isEquipFragment(metaId)) then
        local equipFragmentMeta = MetaManager.equip_fragment_meta[metaId]
        local equipMeta = MetaManager.equip_meta[equipFragmentMeta.equipId]
        if(equipMeta) then
          metaName = getTextByKey(equipMeta.name) .. getTextByKey("fragment_equipTab")
        end
      elseif IdUtil.isSpirit(metaId) then
        local spiritMeta = MetaManager.spirit_meta[metaId]
        if spiritMeta then
          metaName = getTextByKey(spiritMeta.nameKey)
        end
      elseif IdUtil.isCard(metaId) then
        local cardMeta = MetaManager.card_meta[metaId]
        if cardMeta then
          metaName = getTextByKey(cardMeta.name)
        end
      elseif IdUtil.isCardFragment(metaId) then
        local cardFragmentMeta = MetaManager.card_fragment_meta[metaId]
        local cardMeta = MetaManager.card_meta[cardFragmentMeta.cardId]
        if cardMeta then
          metaName = getTextByKey(cardMeta.name) .. getTextByKey("fragment_cardTab")
        end
      end
      if(metaName) then
        local txtEquipName = sbTxtEquipName:getChildByTag(10)
        ViewControlUtil.setLableText(txtEquipName, metaName)
      else
        he_log_warning("item is not configured: " .. metaId)
      end
      sbTxtMayGet:setVisible(true)
      sbTxtEquipName:setVisible(true)
    else
      sbTxtMayGet:setVisible(false)
      sbTxtEquipName:setVisible(false)
    end
  end
  
  local function onListItemTouch(evt)
    local aIndex = evt.data + 1
    local aCell = self.missionTableView:cellAtIndex(aIndex - 1)
    local posInCell = aCell:convertToNodeSpace(evt.globalPosition)
    local btnChallenge = aCell:getChildByTag(-1001):getChildByTag(18)
    local picBtnChallenge = btnChallenge:getChildByTag(13)
    
    local eliteMissionInfo = eliteMissions[aIndex]
    if ViewControlUtil.isInAreaPic(posInCell, btnChallenge, picBtnChallenge) then
      local challengeNum = id2EliteInfo[eliteMissionInfo.id] and id2EliteInfo[eliteMissionInfo.id].challengeNum or 0
      local isTimesOut = challengeNum >= eliteMissionInfo.maxChallengesPerDay
      local isUnlock = EliteManager.isEliteMissionUnlock(eliteMissionInfo, maxFinishedEliteId, maxMissionId)
      
      --体力判断
      if isUnlock and ((not isTimesOut) or canRefreshChallengeTimes) then
        --按钮显示可点的情况 才判断这些
        local currEnergy = CalculationManager.calcComplex_getEnergyNow()
        if(currEnergy < eliteConsumeEnergy) then
          local function showMainActor()
            self.targetInfoPanel = MainActorPanel:create( self )
            PopoutManager:sharedManager():popout(self.targetInfoPanel, kPopoutDir.kScale, true, false ,self)
          end
          
          local hasEnergyProp, energyPropList = BagCalcManager.getEnergyPropList()
          if hasEnergyProp then -- 有体力道具
            local function callback(aEnergyPropId)
              local function usePropSucceed(event)
                local aReward = {
                  {	itemType = ResourceEnum.PROP, metaId = aEnergyPropId, amount = -1
                  },
                  {	itemType = ResourceEnum.ENERGY,
                    amount = event.data.rewards[1].amount,
                  }
                }
                RewardManager:getReward(aReward)
                CanonPlayEffect("music/sfx_engly_lvup.wav")
                SuspensionLabel:showContent(self, getTextByKey("propInfo_energyReplenished"))
              end
              
              local function usePropFailed(event)
                if event.data.retCode == 712308 then
                  CanonMessageBox.ShowText(ShowButtonType.ID_OK, getTextByKey("propInfo_energyFull"))
                elseif event.data.retCode == 712301 then
                  local textNoProp = getTextByKey("popup_noProp", {propname = propname})
                  CanonMessageBox:Show(ShowButtonType.ID_OK, textNoProp)
                end
              end
              
              local request = UsePropRequest.new( {propId = aEnergyPropId, amount = 1}, rpc.SendingPriority.kHigh )
              request:addEventListener( RequestNotifyEnum.UsePropSucceed, usePropSucceed )
              request:addEventListener( RequestNotifyEnum.UsePropFailed, usePropFailed )
              request:start()
            end
            local aPanel = EEPSupplyPanel:create(self, energyPropList, callback, true)
            self:addChild(aPanel)
            aPanel:scaleIn()
            --CanonMessageBox.showText(ShowButtonType.ID_OK_CANCEL, aString, {callbackFunc = useEnergyProp})
          else --无体力道具
            local function callback()
            end
            local aPanel = EENPSupplyPanel:create(self, {supplyType = EESupplyTypeEnum.Energy, callback = callback})
            self:addChild(aPanel)
            aPanel:scaleIn()
          end
          
          return nil
        end
      end
      --体力判断↑
      
      if (not isTimesOut and isUnlock) then -- 可以挑战
        
        --背包是否满
        local isBagFull = BagCalcManager.isFull()
        if(isBagFull) then
          local aContent = getTextByKey("bagFull_move")
          -- SuspensionLabel:showContent(self, aContent)
          NewPackageFullPanel:show()
          return
        end

        --真的可以挑战

        --挑战流程
        local function fight()
          local function onChallengeEliteSucc(data)
            if(data.data) then
              local battleWin = data.data.win
              local nextMissionId = eliteMissionInfo.id
              if(battleWin and nextMissionId > maxFinishedEliteId) then
                EliteManager.setMaxFinishedEliteId(nextMissionId)
                nextMissionId = EliteManager.getNextEliteInfo(nextMissionId)
              end

              if battleWin then
                local negativeReward = {
                  {
                    itemType = ResourceEnum.ENERGY,
                    amount = -1 * eliteConsumeEnergy,
                  }
                }
                RewardManager:getReward(negativeReward)
              end
              
              data.data.selectId = eliteMissionInfo.id --传递当前战斗关卡id，用于战斗显示
              Director:sharedDirector():replaceScene(BattleScene:create(data.data, BattleBackType.kEliteMissionScene, BattleEnterEnum.kEliteMissionScene, nil, nextMissionId))
            end
          end
          local function onChallengeEliteFail(error)
            local errorCode = tonumber(error.data)
            if(errorCode == CommErrorCodes.ELITE_SETTING_NOTCONFIG.code) then
              CanonMessageBox:showCommErrorBox(CommErrorCodes.ELITE_SETTING_NOTCONFIG)
            elseif(errorCode == CommErrorCodes.ELITE_CHALLENGETIMES_REACH.code) then
              CanonMessageBox:showCommErrorBox(CommErrorCodes.ELITE_CHALLENGETIMES_REACH)
            elseif(errorCode == CommErrorCodes.ELITE_GRID_FULL.code) then
              CanonMessageBox:showCommErrorBox(CommErrorCodes.ELITE_GRID_FULL)
            elseif(errorCode == CommErrorCodes.ELITE_PREMISSION_UNLOCK.code) then
              CanonMessageBox:showCommErrorBox(CommErrorCodes.ELITE_PREMISSION_UNLOCK)
            elseif(errorCode == CommErrorCodes.ELITE_REQUIREMISSION_UNLOCK.code) then
              CanonMessageBox:showCommErrorBox(CommErrorCodes.ELITE_REQUIREMISSION_UNLOCK)
            else
              CanonMessageBox:showCommUnHandleErrorBox(errorCode)
            end
          end
          --
          local params = {eliteId = eliteMissionInfo.id}
          local challengeEliteRequest = ChallengeEliteRequest.new(params, rpc.SendingPriority.kHigh)
          challengeEliteRequest:addEventListener(RequestNotifyEnum.ChallengeEliteSucceed, onChallengeEliteSucc)
          challengeEliteRequest:addEventListener(RequestNotifyEnum.ChallengeEliteFailed, onChallengeEliteFail)
          challengeEliteRequest:start()
        end
        --挑战流程↑

        --扫荡 or 挑战
        if EliteManager.canEliteMissionSweep(eliteMissionInfo, maxFinishedEliteId, maxMissionId) then
          --扫荡流程
          local function onCompleted()
            --扫荡结束
            if SystemManager.debug then
              print("id2EliteInfo[eliteMissionInfo.id] = " .. tostringRich(id2EliteInfo[eliteMissionInfo.id]))
            end

            --更新"能否刷新"状态
            canRefreshChallengeTimes = EliteManager.canRefreshChallengeTimes(self.vipLevel)

            --刷新列表
            local currentOffset = self.missionTableView:getContentOffset().y
            self.missionTableView:reloadData()
            self.missionTableView:setContentOffset(ccp(0, currentOffset), false)

            --确认是否升级
            CityMainScene:checkUserLevelUp()
          end
          if not id2EliteInfo[eliteMissionInfo.id] then
            --如果没有挑战过 则先生成一个空的挑战数据 当扫荡完毕后 需要更新显示此数值
            id2EliteInfo[eliteMissionInfo.id] = {challengeNum = 0}
          end
          EliteSweepConfirmPopmPanel.pop(eliteMissionInfo, id2EliteInfo[eliteMissionInfo.id], fight, onCompleted)
        else
          --挑战流程
          fight()
        end
        
      elseif (canRefreshChallengeTimes and isUnlock) then -- 购买金币区域
        local strConfirmPurchase = getTextByKey("elite_confirmPurchase", {gold = eliteRefreshGoldCost, num = eliteMissionInfo.maxChallengesPerDay})
        
        ----
        -- 购买次数
        ----
        local function onPurchase()
          local gemsEnough = CalculationManager.calcComplex_getGemsNow() >= eliteRefreshGoldCost
          if(gemsEnough) then
            local function onResetEliteSucc(data)
              id2EliteInfo[eliteMissionInfo.id].challengeNum = 0
              ViewControlUtil.refreshTableView(self.missionTableView, true)
              
              local negativeReward = {
                {
                  itemType = ResourceEnum.GEMS,
                  amount = -1 * eliteRefreshGoldCost,
                }
              }
              RewardManager:getReward(negativeReward)
              
              DailyDataManager.incrResetEliteNum(1)
            end
            local function onResetEliteFail(error)
              local errorCode = tonumber(error.data)
            end
            
            local params = {eliteId = eliteMissionInfo.id}
            local resetEliteRequest = ResetEliteRequest.new(params, rpc.SendingPriority.kHigh)
            resetEliteRequest:addEventListener(RequestNotifyEnum.ResetEliteSucceed, onResetEliteSucc)
            resetEliteRequest:addEventListener(RequestNotifyEnum.ResetEliteFailed, onResetEliteFail)
            resetEliteRequest:start()
          else
            local aPanel = AssistantMessageBoxPanel:create( self, AsMessageBoxType.addCoin )
            self:addChild(aPanel)
            aPanel:scaleIn()
          end
        end
        
        CanonMessageBox.showText(ShowButtonType.ID_OK_CANCEL, strConfirmPurchase, {callbackFunc = onPurchase}, nil, nil)
      else
        return nil
      end
    end
  end
  
  local renderer = MissionTableViewRenderer.new(EliteManager.DICT.ITEM_MISSION_WIDTH, EliteManager.DICT.ITEM_MISSION_HEIGHT)
  local aTableView = TableView:create(renderer, 
      EliteManager.DICT.TB_MISSION_WIDTH, 
      EliteManager.DICT.TB_MISSION_HEIGHT,
      cellTag,
      buttonTag,
      CCScale9Sprite:create("pic/scroll.png"), 
      CCScale9Sprite:create("pic/scroll.png"),
      eliteMissions
    )
  aTableView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch)
  aTableView:setPosition(ccp(EliteManager.DICT.TB_MISSION_POSX, EliteManager.DICT.TB_MISSION_POSY))
  
  -- 定位选中关卡位置 --
  local selectedIdx = 0
  for i, eliteMissionInfo in ipairs(eliteMissions) do
    local isUnlock = EliteManager.isEliteMissionUnlock(eliteMissionInfo, maxFinishedEliteId, maxMissionId)
    if(not isUnlock) then
      break
    end
    
    selectedIdx = i
    if(seletedMissionId and eliteMissionInfo.id == seletedMissionId) then --设置了默认选中关卡
      break
    end
  end
  ViewControlUtil.refreshAndLocateTableView(aTableView, selectedIdx)
  
  return aTableView
end

function EliteMissionScene:onInit()
	BaseUIScene.initBackGround(self)
	local builder = LayoutBuilder:createWithContentsOfFile(EliteManager.DICT.RESOURCE_FILE)
  self.mainUI = builder:build("elite_page_elite_list")
  self:addChild(self.mainUI)
  
  -- content layer
  self.contentLayer = Layer:create()
  self.contentLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
  self:addChild(self.contentLayer)
  
  self.maxMissionId = EliteManager.getMaxMissionId()
  self.maxFinishedEliteId = EliteManager.getMaxFinishedEliteId()
  self.selectedCityId = EliteManager.DICT.FIRST_ELITE_CITYID
  
  
  
	BaseUIScene.onInit(self)
end

function EliteMissionScene:dispose()
  UiStackManager_EventDispatcher:removeEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged)
  EliteMissionScene.super.dispose(self)
end

function EliteMissionScene:doEnterAnimation()
  self:preEnterAnimation()
  self:startEnterAnimation()
end

function EliteMissionScene:preEnterAnimation()
  BaseUIScene.preEnterAnimation(self)
  
  CanonPlayBackgroundMusic("music/background.mp3", true)
end

function EliteMissionScene:startEnterAnimation()
  BaseUIScene.startEnterAnimation(self)
  
  local function enterActionFinished()
    self:nodeAnimationFinished()
  end
  
  local function getCCSequence()
    local arr = CCArray:create()
    arr:addObject(CCMoveBy:create(0.3, ccp(visibleSize.width, 0)))
    arr:addObject(CCCallFunc:create(enterActionFinished))
    
    return CCSequence:create(arr)
  end
  
  self.mainUI:setPositionX(self.mainUI:getPositionX() - visibleSize.width)
  self.contentLayer:setPositionX(self.contentLayer:getPositionX() - visibleSize.width)
  self.mainUI:runAction(getCCSequence())
  self.contentLayer:runAction(getCCSequence())
end

function EliteMissionScene:sufEnterAnimation()
  BaseUIScene.sufEnterAnimation(self)
  
  if IsGuideExecuted(GuideConfig.kRisk3) then --主要新手引导的最后一个执行完后，才执行这个
    ExeNewGuide(GuideConfig.kElite) --新手引导
  end

  local seletedMissionId = self.maxFinishedEliteId
  if(self.maxFinishedEliteId > 0) then
    if(self.paramEliteMissionId) then
      local eliteMeta = EliteManager.getEliteMissionByMissionId(self.paramEliteMissionId)
      if(eliteMeta) then
        local isUnlock = EliteManager.isEliteMissionUnlock(eliteMeta, self.maxFinishedEliteId, self.maxMissionId)
        if(isUnlock) then
          self.selectedCityId = eliteMeta.cityId
          seletedMissionId = self.paramEliteMissionId
        else 
          local finishNewCityInfo = EliteManager.isFinishEliteCity(self.maxFinishedEliteId, self.maxMissionId)
          self.selectedCityId = finishNewCityInfo.nextCityId
        end
      end
    else
      local finishNewCityInfo = EliteManager.isFinishEliteCity(self.maxFinishedEliteId, self.maxMissionId)
      self.selectedCityId = finishNewCityInfo.nextCityId
    end
  end
  
  local function onGetEliteInfoSucc(data)
    if(data.data) then
      self.eliteInfo = data.data
      if(self.eliteInfo.lstSharkEliteInfo) then
        for _, eliteInfo in pairs(self.eliteInfo.lstSharkEliteInfo) do
          self.id2EliteInfo[eliteInfo.eliteId] = eliteInfo
        end
      end
    end
    
    if(self.contentLayer.isDisposed) then  -- 异步调用主场景已销毁
      return
    end
    local function tableViewTouchBegin(evt)
      evt.context:setDragEnabled(true)
    end

    self.cityTableView = self:createCityTableView()
    self.cityTableView:addEventListener("tableCellTouchBegin", tableViewTouchBegin , self.cityTableView)
    self.contentLayer:addChild(self.cityTableView)
    
    self.missionTableView = self:createMissionTableView(self.selectedCityId, seletedMissionId)
    self.missionTableView:addEventListener("tableCellTouchBegin", tableViewTouchBegin , self.missionTableView)
    self.contentLayer:addChild(self.missionTableView)
    
    ViewControlUtil.showTableViewAction(self.missionTableView, visibleSize)
	
	--facebook share eliteMission clean info
	FacebookShareManager.facebookShareEliteMission()

    --加事件
    UiStackManager_EventDispatcher:addEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged, self)
  end
  
  local function onGetEliteInfoError(error)
    local errorCode = tonumber(error.data)
    print(errorCode)
  end
  
  --获取精英关卡信息
  local getEliteInfoRequest = GetEliteInfoRequest.new(nil, rpc.SendingPriority.kHigh)
  getEliteInfoRequest:addEventListener(RequestNotifyEnum.GetEliteInfoSucceed, onGetEliteInfoSucc)
  getEliteInfoRequest:addEventListener(RequestNotifyEnum.GetEliteInfoFailed, onGetEliteInfoError)
  getEliteInfoRequest:start()

end

function EliteMissionScene:doExitAnimation()
  self:preExitAnimation()
  self:startExitAnimation()
end

function EliteMissionScene:preExitAnimation()
  BaseUIScene.preExitAnimation(self)
end

function EliteMissionScene:startExitAnimation()
  BaseUIScene.startExitAnimation(self)
  
  local function exitActionFinished()
    self:nodeAnimationFinished()
  end
  
  local function getCCSequence()
    local arr = CCArray:create()
    arr:addObject(CCMoveBy:create(0.3, ccp(-visibleSize.width, 0)))
    arr:addObject(CCCallFunc:create(exitActionFinished))
    
    return CCSequence:create(arr)
  end
  
  self.mainUI:runAction(getCCSequence())
  self.contentLayer:runAction(getCCSequence())
end

function EliteMissionScene:sufExitAnimation()
  BaseUIScene.sufExitAnimation(self)
end

-- 控制列表能否拖动
function EliteMissionScene:setTableViewsEnabled(v)
  if self.missionTableView then
    self.missionTableView:setTouchEnabled(v)
  end
end